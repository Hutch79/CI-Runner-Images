#!/usr/bin/env bash
##############################################################################
# Shared test functions for development scripts
# 
# This library provides smoke and integration test functions
# used by both build-all.sh and test-images.sh
#
# Source this file in other scripts:
#   source "$(dirname "$0")/lib-tests.sh"
#
# Available functions:
#   run_smoke_test <image_tag> <image_dir>
#   run_integration_test <image_tag> <folder_name>
##############################################################################

# Get the repository root directory
get_repo_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

REPO_ROOT="$(get_repo_root)"

##############################################################################
# Smoke tests - Basic functionality checks
##############################################################################

run_smoke_test() {
    local test_tag="$1"
    local image_dir="$2"
    
    # Test 1: Image runs
    if ! docker run --rm "$test_tag" echo "✓ Image runs" > /dev/null 2>&1; then
        return 1
    fi
    
    # Test 2: Git is installed
    if ! docker run --rm "$test_tag" git --version > /dev/null 2>&1; then
        return 1
    fi
    
    # Test 3: Node.js is installed
    if ! docker run --rm "$test_tag" node --version > /dev/null 2>&1; then
        return 1
    fi
    
    # Test 4: Curl is installed
    if ! docker run --rm "$test_tag" curl --version > /dev/null 2>&1; then
        return 1
    fi
    
    # Test 5: Check for .NET if dotnet image
    if [[ "$image_dir" == *"dotnet"* ]]; then
        if ! docker run --rm "$test_tag" dotnet --version > /dev/null 2>&1; then
            return 1
        fi
    fi
    
    # Test 6: Check for Node.js if node image
    if [[ "$image_dir" == *"node"* ]]; then
        if ! docker run --rm "$test_tag" npm --version > /dev/null 2>&1; then
            return 1
        fi
    fi
    
    return 0
}

##############################################################################
# Integration tests - Project-specific tests
##############################################################################

run_integration_test() {
    local test_tag="$1"
    local folder_name="$2"
    
    if [[ -f "$REPO_ROOT/tests/projects/$folder_name/test-build.sh" ]]; then
        if bash "$REPO_ROOT/tests/projects/$folder_name/test-build.sh" "$test_tag" > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        # No test script found is not an error
        return 0
    fi
}
