#!/usr/bin/env bash
##############################################################################
# Build and test all CI/CD job runner images
# 
# Usage:
#   ./dev/build-all.sh [options] [images...]
#
# Options:
#   --no-cache        Don't use build cache (slower, but fresh)
#   --skip-tests      Build only, don't run tests
#   --skip-smoke      Skip smoke tests (but run integration tests)
#   --skip-integration  Skip integration tests (but run smoke tests)
#   --remote-base     Use remote base image instead of local (default: use local)
#   --clean           Remove all local test images (prompts for confirmation)
#   --help            Show this help message
#
# Images:
#   base              Build base image only
#   dotnet            Build all .NET images
#   dotnet-8          Build .NET 8.0 image
#   dotnet-9          Build .NET 9.0 image
#   dotnet-10         Build .NET 10.0 image
#   node              Build all Node.js images
#   node-20           Build Node.js 20 image
#   node-22           Build Node.js 22 image
#   node-24           Build Node.js 24 image
#   all               Build all images (default)
#
# Behavior:
#   - If no images specified: Show help and exit
#   - If base image build fails: Stop immediately (abort all other builds)
#   - If other image build fails: Continue to next image
#   - If tests fail: Continue to next image (but report failures)
#   - Exit code: 0 if all successful, 1 if any failures
#
# Examples:
#   ./dev/build-all.sh                              # Show this help
#   ./dev/build-all.sh base                         # Build only base image
#   ./dev/build-all.sh dotnet-8 dotnet-9           # Build specific .NET versions (uses local base)
#   ./dev/build-all.sh --no-cache base              # Fresh rebuild of base
#   ./dev/build-all.sh --skip-tests node            # Build all node images, no tests
#   ./dev/build-all.sh dotnet --no-cache --skip-tests  # Fresh .NET builds, no tests (uses local base)
#   ./dev/build-all.sh dotnet-8 --remote-base       # Build with remote base image
#   ./dev/build-all.sh --clean                      # Remove all local test images
##############################################################################

set -euo pipefail

# Source shared test library
source "$(dirname "$0")/lib-tests.sh"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
USE_CACHE=true
RUN_TESTS=true
RUN_SMOKE=true
RUN_INTEGRATION=true
CLEAN_MODE=false
USE_REMOTE_BASE=false
REQUESTED_IMAGES=()

# Tracking variables
FAILED_BUILDS=()
FAILED_TESTS=()
TOTAL_BUILDS=0
SUCCESSFUL_BUILDS=0
BASE_BUILT=false

# Discover available images dynamically
mapfile -t AVAILABLE_IMAGES < <(find "$REPO_ROOT/images" -name "Dockerfile" -exec dirname {} \; | xargs -I {} basename {} | sort)

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

##############################################################################
# Helper functions
##############################################################################

# Check if a string is a valid image name
is_valid_image() {
    local name="$1"
    local image
    
    # Check if it's an individual image
    for image in "${AVAILABLE_IMAGES[@]}"; do
        if [[ "$image" == "$name" ]]; then
            return 0
        fi
    done
    
    # Check if it's a group pattern (e.g., "dotnet", "node")
    for image in "${AVAILABLE_IMAGES[@]}"; do
        if [[ "$image" == "$name"* ]] && [[ "$name" != "all" ]]; then
            return 0
        fi
    done
    
    # "all" is always valid
    if [[ "$name" == "all" ]]; then
        return 0
    fi
    
    return 1
}

# Generate help text about available images
generate_image_help() {
    echo "# Images:"
    
    local groups=()
    local seen=()
    
    # Collect unique prefixes for grouping
    for image in "${AVAILABLE_IMAGES[@]}"; do
        local prefix="${image%%-*}"
        
        # Check if we've already listed this prefix
        local is_new=true
        for seen_prefix in "${seen[@]}"; do
            if [[ "$seen_prefix" == "$prefix" ]]; then
                is_new=false
                break
            fi
        done
        
        if $is_new && [[ "$prefix" != "$image" ]]; then
            seen+=("$prefix")
        fi
    done
    
    # Show group options
    for group in "${seen[@]}"; do
        echo "#   $group              Build all $group images"
    done
    
    # Show individual images
    for image in "${AVAILABLE_IMAGES[@]}"; do
        echo "#   $image              Build $image image"
    done
    
    echo "#   all               Build all images (default)"
}

show_help() {
    grep "^#" "$0" | sed 's/^# *//' | head -40
}

##############################################################################
# Parse arguments
##############################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            USE_CACHE=false
            print_info "Cache disabled"
            shift
            ;;
        --skip-tests)
            RUN_TESTS=false
            print_info "Tests disabled"
            shift
            ;;
        --skip-smoke)
            RUN_SMOKE=false
            print_info "Smoke tests disabled"
            shift
            ;;
        --skip-integration)
            RUN_INTEGRATION=false
            print_info "Integration tests disabled"
            shift
            ;;
        --remote-base)
            USE_REMOTE_BASE=true
            print_info "Using remote base image"
            shift
            ;;
        --clean)
            CLEAN_MODE=true
            print_info "Clean mode enabled"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            # Check if it's a valid image name or a group
            if is_valid_image "$1"; then
                REQUESTED_IMAGES+=("$1")
                shift
            else
                print_error "Unknown option or image: $1"
                show_help
                exit 1
            fi
            ;;
    esac
done

##############################################################################
# Filter images based on request
##############################################################################

filter_images() {
    local all_images=("$@")
    
    # If no specific images requested, build all
    if [[ ${#REQUESTED_IMAGES[@]} -eq 0 ]]; then
        printf '%s\n' "${all_images[@]}"
        return
    fi
    
    # Expand groups into individual images
    local expanded=()
    for req in "${REQUESTED_IMAGES[@]}"; do
        if [[ "$req" == "all" ]]; then
            printf '%s\n' "${all_images[@]}"
            return
        fi
        
        # Check if it's a group (matches a prefix)
        local is_group=false
        for image in "${all_images[@]}"; do
            local image_name=$(basename "$image")
            # If request matches the start of an image name and isn't exact match
            if [[ "$image_name" == "$req"* ]] && [[ "$image_name" != "$req" ]]; then
                expanded+=("$image")
                is_group=true
            fi
        done
        
        # If not a group, must be an exact image match
        if ! $is_group; then
            for image in "${all_images[@]}"; do
                local image_name=$(basename "$image")
                if [[ "$image_name" == "$req" ]]; then
                    expanded+=("$image")
                    break
                fi
            done
        fi
    done
    
    printf '%s\n' "${expanded[@]}"
}

##############################################################################
# Build image function
##############################################################################

build_image() {
    local image_dir="$1"
    local folder_name=$(basename "$image_dir")
    local is_base=false
    
    if [[ "$folder_name" == "base" ]]; then
        is_base=true
    fi
    
    echo ""
    print_header "Building: $folder_name"
    
    # Get config values
    local registry=$(bash "$REPO_ROOT/scripts/config-loader.sh" registry-path)
    local image_name=$(bash "$REPO_ROOT/scripts/config-loader.sh" image-name "$folder_name")
    local base_image
    
    if $is_base; then
        base_image=$(bash "$REPO_ROOT/scripts/config-loader.sh" base-ubuntu)
    else
        # For dependent images: try to use local base first, fall back to remote if needed
        if $USE_REMOTE_BASE; then
            # Explicitly requested remote base
            base_image=$(bash "$REPO_ROOT/scripts/config-loader.sh" base-runner)
        else
            # Try to use local base image if it exists, otherwise use remote
            if docker image inspect local-test-base:latest > /dev/null 2>&1; then
                base_image="local-test-base:latest"
            else
                print_warning "Local base image not found, using remote: $(bash "$REPO_ROOT/scripts/config-loader.sh" base-runner)"
                base_image=$(bash "$REPO_ROOT/scripts/config-loader.sh" base-runner)
            fi
        fi
    fi
    
    # Set tag for local testing
    local test_tag="local-test-$folder_name:latest"
    
    print_info "Image directory: $image_dir"
    print_info "Base image: $base_image"
    print_info "Local tag: $test_tag"
    
    # Build options
    local build_opts="--platform linux/amd64"
    build_opts="$build_opts --build-arg BASE_IMAGE=$base_image"
    build_opts="$build_opts --tag $test_tag"
    build_opts="$build_opts --load"
    
    if ! $USE_CACHE; then
        build_opts="$build_opts --no-cache"
    fi
    
    # Build the image and capture output
    local build_output
    build_output=$(docker buildx build $build_opts "$image_dir" 2>&1) || {
        print_error "Failed to build: $folder_name"
        print_error "Build error details:"
        echo "$build_output" | sed 's/^/  /'
        FAILED_BUILDS+=("$folder_name")
        return 1
    }
    
    print_success "Built: $folder_name"
    ((SUCCESSFUL_BUILDS++))
    # Mark base as built if this is the base image
    if $is_base; then
        BASE_BUILT=true
    fi
    return 0
}

##############################################################################
# Test image function
##############################################################################

test_image() {
    local image_dir="$1"
    local folder_name=$(basename "$image_dir")
    local test_tag="local-test-$folder_name:latest"
    
    print_info "Running tests for: $folder_name"
    
    local test_passed=true
    
    # Smoke tests
    if $RUN_SMOKE; then
        print_info "Running smoke tests..."
        if ! run_smoke_test "$test_tag" "$image_dir"; then
            print_error "Smoke test failed: $folder_name"
            test_passed=false
        else
            print_success "Smoke tests passed: $folder_name"
        fi
    fi
    
    # Integration tests
    if $RUN_INTEGRATION && $test_passed; then
        print_info "Running integration tests..."
        if ! run_integration_test "$test_tag" "$folder_name"; then
            print_error "Integration tests failed: $folder_name"
            test_passed=false
        else
            print_success "Integration tests passed: $folder_name"
        fi
    fi
    
    if $test_passed; then
        print_success "Tests passed: $folder_name"
        return 0
    else
        print_error "Tests failed: $folder_name"
        FAILED_TESTS+=("$folder_name")
        return 1
    fi
}

##############################################################################
# Clean function - remove local test images
##############################################################################

clean_local_images() {
    print_header "Cleaning Local Test Images"
    
    # Find all local-test-* images
    local images=()
    mapfile -t images < <(docker images --filter "reference=local-test-*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null)
    
    if [[ ${#images[@]} -eq 0 ]]; then
        print_info "No local test images found to clean"
        return 0
    fi
    
    # Display all images that will be cleaned
    echo ""
    print_info "Found ${#images[@]} local test image(s) to clean:"
    echo ""
    
    local i=1
    for image in "${images[@]}"; do
        echo "  $i. $image"
        ((i++))
    done
    
    echo ""
    # Ask for confirmation - accept yes/y or no/n
    read -p "Do you want to remove these images? (yes/no): " -r confirmation
    
    # Normalize input to lowercase and check for yes/y or no/n
    confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$confirmation" == "yes" ]] || [[ "$confirmation" == "y" ]]; then
        # Proceed with cleanup
        :
    elif [[ "$confirmation" == "no" ]] || [[ "$confirmation" == "n" ]]; then
        print_warning "Cleanup cancelled"
        return 0
    else
        print_warning "Invalid response. Cleanup cancelled"
        return 0
    fi
    
    # Remove images
    echo ""
    local removed_count=0
    local failed_count=0
    
    for image in "${images[@]}"; do
        print_info "Removing: $image"
        
        if docker rmi "$image" > /dev/null 2>&1; then
            print_success "Removed: $image"
            removed_count=$((removed_count + 1))
        else
            print_error "Failed to remove: $image"
            failed_count=$((failed_count + 1))
        fi
    done
    
    echo ""
    print_info "Removed: $removed_count images"
    
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed to remove: $failed_count images"
        return 1
    fi
    
    return 0
}

##############################################################################
# Main execution
##############################################################################

main() {
    # Handle clean mode
    if $CLEAN_MODE; then
        clean_local_images
        exit $?
    fi
    
    # If no images were requested and no options provided, show help
    if [[ ${#REQUESTED_IMAGES[@]} -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    print_header "CI/CD Job Runners - Build All Images"
    
    echo "Configuration:"
    echo "  Cache: $([ $USE_CACHE = true ] && echo 'enabled' || echo 'disabled')"
    echo "  Tests: $([ $RUN_TESTS = true ] && echo 'enabled' || echo 'disabled')"
    echo "  Smoke tests: $([ $RUN_SMOKE = true ] && echo 'enabled' || echo 'disabled')"
    echo "  Integration tests: $([ $RUN_INTEGRATION = true ] && echo 'enabled' || echo 'disabled')"
    echo ""
    
    # Find all image directories
    mapfile -t ALL_IMAGE_DIRS < <(find "$REPO_ROOT/images" -name "Dockerfile" -exec dirname {} \; | sort)
    
    if [[ ${#ALL_IMAGE_DIRS[@]} -eq 0 ]]; then
        print_error "No Dockerfiles found"
        exit 1
    fi
    
    # Filter images based on request
    mapfile -t IMAGE_DIRS < <(filter_images "${ALL_IMAGE_DIRS[@]}")
    
    TOTAL_BUILDS=${#IMAGE_DIRS[@]}
    print_info "Found $TOTAL_BUILDS images to build"
    
    if [[ ${#REQUESTED_IMAGES[@]} -gt 0 ]]; then
        print_info "Building specific images: ${REQUESTED_IMAGES[*]}"
    fi
    
    local base_failed=false
    
    # Build all images
    for image_dir in "${IMAGE_DIRS[@]}"; do
        local folder_name=$(basename "$image_dir")
        
        if ! build_image "$image_dir"; then
            # If base image failed, abort everything
            if [[ "$folder_name" == "base" ]]; then
                print_error "Base image build failed! Aborting all builds."
                base_failed=true
                break
            fi
        fi
    done
    
    # If base failed, exit early
    if $base_failed; then
        print_header "Build Summary"
        print_error "Base image build failed - aborting"
        exit 1
    fi
    
    # Run tests if enabled and all builds succeeded
    if $RUN_TESTS && [[ ${#FAILED_BUILDS[@]} -eq 0 ]]; then
        for image_dir in "${IMAGE_DIRS[@]}"; do
            # Skip base image for tests (no tests needed for base)
            if [[ $(basename "$image_dir") != "base" ]]; then
                test_image "$image_dir"
            fi
        done
    fi
    
    # Print summary
    echo ""
    print_header "Build Summary"
    
    echo "Total builds: $TOTAL_BUILDS"
    echo "Successful builds: $SUCCESSFUL_BUILDS"
    echo "Failed builds: ${#FAILED_BUILDS[@]}"
    echo "Failed tests: ${#FAILED_TESTS[@]}"
    
    if [[ ${#FAILED_BUILDS[@]} -gt 0 ]]; then
        print_error "Failed builds:"
        for failed in "${FAILED_BUILDS[@]}"; do
            echo "  - $failed"
        done
    fi
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        print_error "Failed tests:"
        for failed in "${FAILED_TESTS[@]}"; do
            echo "  - $failed"
        done
    fi
    
    if [[ ${#FAILED_BUILDS[@]} -eq 0 ]] && [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
        print_success "All builds and tests passed!"
        exit 0
    else
        print_error "Some builds or tests failed"
        exit 1
    fi
}

main "$@"
