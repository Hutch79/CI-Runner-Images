#!/usr/bin/env bash
##############################################################################
# Test existing local Docker images
#
# This script tests Docker images that already exist locally (built images).
# It doesn't build anything, just runs smoke and integration tests.
#
# Usage:
#   ./dev/test-images.sh [image-name] [options]
#
# Arguments:
#   image-name        Test specific image (optional, defaults to all)
#                     Examples: base, dotnet-8, node-24
#
# Options:
#   --skip-smoke      Skip smoke tests
#   --skip-integration  Skip integration tests
#   --help            Show this help message
#
# Examples:
#   ./dev/test-images.sh                      # Test all images
#   ./dev/test-images.sh dotnet-8             # Test dotnet-8 only
#   ./dev/test-images.sh --skip-integration   # Smoke tests only for all
#   ./dev/test-images.sh node-24 --skip-smoke # Integration tests only for node-24
##############################################################################

set -euo pipefail

# Source shared test library
source "$(dirname "$0")/lib-tests.sh"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_IMAGE=""
RUN_SMOKE=true
RUN_INTEGRATION=true

# Tracking
FAILED_TESTS=()
PASSED_TESTS=()

##############################################################################
# Functions
##############################################################################

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

show_help() {
    grep "^#" "$0" | sed 's/^# *//' | head -25
}

##############################################################################
# Parse arguments
##############################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-smoke)
            RUN_SMOKE=false
            shift
            ;;
        --skip-integration)
            RUN_INTEGRATION=false
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            # Treat as image name
            TEST_IMAGE="$1"
            shift
            ;;
    esac
done

##############################################################################
# Main
##############################################################################

main() {
    print_header "Test Docker Images"
    
    # If specific image requested, test only that
    if [[ -n "$TEST_IMAGE" ]]; then
        test_tag="local-test-$TEST_IMAGE:latest"
        
        print_info "Testing image: $TEST_IMAGE"
        
        # Check if image exists
        if ! docker image inspect "$test_tag" > /dev/null 2>&1; then
            print_error "Image not found: $test_tag"
            print_info "Try building with: ./dev/build-all.sh"
            exit 1
        fi
        
        local test_passed=true
        
        if $RUN_SMOKE; then
            if ! run_smoke_test "$test_tag" "images/$TEST_IMAGE"; then
                print_error "Smoke test failed"
                test_passed=false
            else
                print_success "Smoke tests passed"
            fi
        fi
        
        if $RUN_INTEGRATION && $test_passed; then
            if ! run_integration_test "$test_tag" "$TEST_IMAGE"; then
                print_error "Integration tests failed"
                test_passed=false
            else
                print_success "Integration tests passed"
            fi
        fi
        
        if $test_passed; then
            PASSED_TESTS+=("$TEST_IMAGE")
        fi
    else
        # Test all images
        mapfile -t IMAGE_DIRS < <(find "$REPO_ROOT/images" -name "Dockerfile" -exec dirname {} \; | sort)
        
        for image_dir in "${IMAGE_DIRS[@]}"; do
            local folder_name=$(basename "$image_dir")
            local test_tag="local-test-$folder_name:latest"
            
            echo ""
            print_header "Testing: $folder_name"
            
            # Check if image exists
            if ! docker image inspect "$test_tag" > /dev/null 2>&1; then
                print_warning "Image not found: $test_tag (skipping)"
                continue
            fi
            
            # Skip base image (no tests needed)
            if [[ "$folder_name" == "base" ]]; then
                print_info "Skipping base image (no tests)"
                continue
            fi
            
            local test_passed=true
            
            if $RUN_SMOKE; then
                if ! run_smoke_test "$test_tag" "$image_dir"; then
                    test_passed=false
                fi
            fi
            
            if $RUN_INTEGRATION && $test_passed; then
                if ! run_integration_test "$test_tag" "$folder_name"; then
                    test_passed=false
                fi
            fi
            
            if $test_passed; then
                PASSED_TESTS+=("$folder_name")
            else
                FAILED_TESTS+=("$folder_name")
            fi
        done
    fi
    
    # Summary
    echo ""
    print_header "Test Summary"
    
    echo "Passed: ${#PASSED_TESTS[@]}"
    if [[ ${#PASSED_TESTS[@]} -gt 0 ]]; then
        for passed in "${PASSED_TESTS[@]}"; do
            echo "  ✓ $passed"
        done
    fi
    
    echo ""
    echo "Failed: ${#FAILED_TESTS[@]}"
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        for failed in "${FAILED_TESTS[@]}"; do
            echo "  ✗ $failed"
        done
    fi
    
    if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
        print_success "All tests passed!"
        exit 0
    else
        print_error "Some tests failed"
        exit 1
    fi
}

main "$@"
