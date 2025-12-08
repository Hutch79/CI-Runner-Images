#!/bin/bash
set -euo pipefail

IMAGE_TAG="$1"
IMAGE_DIR="$2"
FOLDER_NAME=$(basename "$IMAGE_DIR")
CONFIG_FILE="$IMAGE_DIR/build-test.yml"

echo "Running integration tests for $FOLDER_NAME (image: $IMAGE_TAG)"

failed_tests=""

# Function to run a command in the container and capture output
run_in_container() {
    local cmd="$1"
    docker run --rm -v "$(pwd):/workspace" -w /workspace "$IMAGE_TAG" bash -c "$cmd" 2>&1
}

# Function to validate build test result
validate_build_test() {
    local project="$1"
    local should_build="$2"
    local test_script="/workspace/tests/projects/$project/test-build.sh"

    echo "Test: Build test for $project (expected: $should_build)"

    # Check if test script exists
    if ! docker run --rm -v "$(pwd):/workspace" "$IMAGE_TAG" test -f "$test_script"; then
        echo "❌ FAIL: Test script not found at $test_script"
        failed_tests="$failed_tests$project-script-missing; "
        return 1
    fi

    # Run the test script
    echo "Running test script: $test_script"
    if output=$(run_in_container "cd /workspace/tests/projects/$project && bash test-build.sh"); then
        result="success"
        echo "✅ Build succeeded"
        echo "Output: $output"
    else
        result="failure"
        echo "❌ Build failed"
        echo "Output: $output"
    fi

    # Check if result matches expectation
    if [ "$should_build" = "true" ] && [ "$result" = "success" ]; then
        echo "✅ PASS: Build succeeded as expected"
        return 0
    elif [ "$should_build" = "false" ] && [ "$result" = "failure" ]; then
        echo "✅ PASS: Build failed as expected"
        return 0
    else
        echo "❌ FAIL: Build result ($result) did not match expectation (should_build: $should_build)"
        failed_tests="$failed_tests$project-build-mismatch; "
        return 1
    fi
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  Warning: No build-test.yml config file found at $CONFIG_FILE. Skipping integration tests."
    exit 0
fi

echo "=== Build Integration Tests ==="

# Parse the YAML config and run tests
if command -v yq &> /dev/null; then
    # Use yq if available
    yq -o=json "$CONFIG_FILE" | jq -r '.[] | select(.project and .should_build) | "\(.project):\(.should_build)"' | while IFS=':' read -r project should_build; do
        validate_build_test "$project" "$should_build" || true
    done
elif command -v python3 &> /dev/null; then
    # Fallback to python3 if yq not available
    python3 -c "
import yaml
import sys
with open('$CONFIG_FILE') as f:
    config = yaml.safe_load(f)
    if isinstance(config, list):
        for item in config:
            if 'project' in item and 'should_build' in item:
                print(f'{item[\"project\"]}:{item[\"should_build\"]}')
    elif isinstance(config, dict) and 'project' in config and 'should_build' in config:
        print(f'{config[\"project\"]}:{config[\"should_build\"]}')
" | while IFS=':' read -r project should_build; do
    validate_build_test "$project" "$should_build" || true
done
else
    # Simple bash fallback for basic YAML parsing
    echo "Warning: Neither yq nor python3 available, using basic YAML parser"
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ $line == project:* ]]; then
            project=$(echo "$line" | sed 's/project:[[:space:]]*//')
        elif [[ $line == should_build:* ]]; then
            should_build=$(echo "$line" | sed 's/should_build:[[:space:]]*//')
            if [ -n "$project" ] && [ -n "$should_build" ]; then
                validate_build_test "$project" "$should_build" || true
                project=""
                should_build=""
            fi
        fi
    done < "$CONFIG_FILE"
fi

if [ -n "$failed_tests" ]; then
    echo "Failed tests: ${failed_tests% }"
    echo "failed-tests=${failed_tests% }" >> $GITHUB_OUTPUT
    # Write results to file for other jobs to read
    echo "$FOLDER_NAME:failed" >> integration-test-results.txt
    exit 1
else
    echo "All integration tests passed for $FOLDER_NAME!"
    echo "$FOLDER_NAME:passed" >> integration-test-results.txt
fi