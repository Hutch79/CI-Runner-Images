#!/bin/bash
set -euo pipefail

IMAGE_TAG="$1"
IMAGE_DIR="$2"
FOLDER_NAME=$(basename "$IMAGE_DIR")
CONFIG_FILE="$IMAGE_DIR/smoke-tests.yml"

echo "Running smoke tests for $FOLDER_NAME (image: $IMAGE_TAG)"

failed_tests=""

# Function to run a command in the container and capture output
run_in_container() {
    local cmd="$1"
    docker run --rm "$IMAGE_TAG" bash -c "$cmd" 2>&1
}

# Function to validate output
validate_output() {
    local name="$1"
    local output="$2"
    local expected_contains="${3:-}"
    local expected_matches="${4:-}"
    local expected_version="${5:-}"

    echo "Test: $name"
    echo "Output: $output"

    local failed=false

    if [ -n "$expected_contains" ]; then
        if ! echo "$output" | grep -q "$expected_contains"; then
            echo "❌ FAIL: Expected to contain '$expected_contains'"
            failed=true
        fi
    fi

    if [ -n "$expected_matches" ]; then
        if ! echo "$output" | grep -E -q "$expected_matches"; then
            echo "❌ FAIL: Expected to match regex '$expected_matches'"
            failed=true
        fi
    fi

    if [ -n "$expected_version" ]; then
        # For .NET, check major version
        if [[ "$FOLDER_NAME" == dotnet-* ]]; then
            major="${FOLDER_NAME#dotnet-}"
            if [[ "$major" == "multi" ]]; then
                # For multi, check if multiple versions are installed
                if ! echo "$output" | grep -q "$expected_version"; then
                    echo "❌ FAIL: Expected .NET $expected_version in output"
                    failed=true
                fi
            else
                if ! echo "$output" | grep -E -q "^$major\."; then
                    echo "❌ FAIL: Expected .NET major version $major"
                    failed=true
                fi
            fi
        fi
    fi

    if [ "$failed" = false ]; then
        echo "✅ PASS"
        return 0
    else
        failed_tests="$failed_tests$name; "
        return 1
    fi
}

# General tests for base functionality (always run)
echo "=== General Tests ==="
GENERAL_TESTS=(
    "Git Version:git --version:git version"
    "Node Version:node --version:v[0-9]"
    "Curl Version:curl --version:curl"
    "Bash Version:bash --version:GNU bash"
)

for test in "${GENERAL_TESTS[@]}"; do
    IFS=':' read -r name cmd expect <<< "$test"
    output=$(run_in_container "$cmd" || echo "Command failed")
    validate_output "$name" "$output" "$expect" || true
done

# Image-specific tests from config
if [ -f "$CONFIG_FILE" ]; then
    echo "=== Image-Specific Tests ==="
    # Assume yq is installed or use python to parse YAML
    # For simplicity, use python3 -c to parse YAML
    python3 -c "
import yaml
import sys
with open('$CONFIG_FILE') as f:
    config = yaml.safe_load(f)
    for test in config:
        print(f'TEST:{test[\"name\"]}:{test[\"command\"]}:{test.get(\"expected_contains\", \"\")}:{test.get(\"expected_matches\", \"\")}:{test.get(\"expected_version\", \"\")}')
" | while IFS=':' read -r _ name cmd contains matches version; do
        output=$(run_in_container "$cmd" || echo "Command failed")
        validate_output "$name" "$output" "$contains" "$matches" "$version" || true
    done
else
    echo "⚠️  Warning: No config file found at $CONFIG_FILE. Skipping image-specific tests."
fi

if [ -n "$failed_tests" ]; then
    echo "Failed tests: ${failed_tests% }"
    echo "failed-tests=${failed_tests% }" >> $GITHUB_OUTPUT
    # Write results to file for other jobs to read
    echo "$FOLDER_NAME:failed" >> smoke-test-results.txt
    exit 1
else
    echo "All smoke tests passed for $FOLDER_NAME!"
    echo "$FOLDER_NAME:passed" >> smoke-test-results.txt
fi