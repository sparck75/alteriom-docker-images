#!/usr/bin/env bash
# Test script for ESP32/ESP32-S3/ESP8266 firmware builds
# This script validates that the Docker images can successfully build firmware for all supported platforms

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_REPO="${DOCKER_REPOSITORY:-ghcr.io/sparck75/alteriom-docker-images}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test projects configuration
declare -A TEST_PROJECTS=(
    ["esp32"]="esp32-test:esp32dev"
    ["esp32s3"]="esp32s3-test:esp32-s3-devkitc-1" 
    ["esp32c3"]="esp32c3-test:esp32-c3-devkitm-1"
    ["esp8266"]="esp8266-test:nodemcuv2"
)

# Function to test building a project with a specific Docker image
test_build() {
    local image_name="$1"
    local project_dir="$2"
    local environment="$3"
    local platform_name="$4"
    
    print_status "Testing $platform_name build with $image_name"
    print_status "Project: $project_dir, Environment: $environment"
    
    local test_path="${REPO_ROOT}/tests/${project_dir}"
    
    if [[ ! -d "$test_path" ]]; then
        print_error "Test project directory not found: $test_path"
        return 1
    fi
    
    if [[ ! -f "$test_path/platformio.ini" ]]; then
        print_error "platformio.ini not found in: $test_path"
        return 1
    fi
    
    # Attempt to build the project
    # Create a temporary directory for PlatformIO core data to avoid permission issues
    local temp_platformio_dir=$(mktemp -d)
    
    print_status "Running: docker run --rm --user $(id -u):$(id -g) -e PLATFORMIO_CORE_DIR=/tmp/platformio -v \"$test_path:/workspace\" -v \"$temp_platformio_dir:/tmp/platformio\" \"$image_name\" run -e \"$environment\""
    
    if timeout 300 docker run --rm --user "$(id -u):$(id -g)" \
        -e "PLATFORMIO_CORE_DIR=/tmp/platformio" \
        -v "$test_path:/workspace" \
        -v "$temp_platformio_dir:/tmp/platformio" \
        "$image_name" run -e "$environment"; then
        print_success "$platform_name build completed successfully with $image_name"
        rm -rf "$temp_platformio_dir"
        return 0
    else
        local exit_code=$?
        rm -rf "$temp_platformio_dir"
        print_error "$platform_name build failed with $image_name (exit code: $exit_code)"
        return 1
    fi
}

# Function to check if Docker image exists and is accessible
check_image() {
    local image_name="$1"
    
    print_status "Checking if Docker image exists: $image_name"
    
    if docker image inspect "$image_name" >/dev/null 2>&1; then
        print_success "Image $image_name is available locally"
        return 0
    fi
    
    print_status "Image not found locally, attempting to pull: $image_name"
    
    if docker pull "$image_name"; then
        print_success "Successfully pulled image: $image_name"
        return 0
    else
        print_error "Failed to pull image: $image_name"
        return 1
    fi
}

# Function to test PlatformIO functionality
test_platformio_version() {
    local image_name="$1"
    
    print_status "Testing PlatformIO version with $image_name"
    
    if docker run --rm "$image_name" --version; then
        print_success "PlatformIO version check passed for $image_name"
        return 0
    else
        print_error "PlatformIO version check failed for $image_name"
        return 1
    fi
}

# Main testing function
run_tests() {
    local test_images=("$@")
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    if [[ ${#test_images[@]} -eq 0 ]]; then
        test_images=("${DOCKER_REPO}/builder:latest" "${DOCKER_REPO}/dev:latest")
    fi
    
    print_status "Starting ESP platform build tests"
    print_status "Testing with images: ${test_images[*]}"
    echo ""
    
    for image in "${test_images[@]}"; do
        echo "========================================"
        print_status "Testing Docker image: $image"
        echo "========================================"
        
        # Check if image is available
        if ! check_image "$image"; then
            print_error "Skipping tests for unavailable image: $image"
            continue
        fi
        
        # Test PlatformIO version
        if ! test_platformio_version "$image"; then
            print_error "Skipping build tests due to PlatformIO version failure"
            continue
        fi
        
        # Test each platform
        for platform in "${!TEST_PROJECTS[@]}"; do
            IFS=':' read -r project_dir environment <<< "${TEST_PROJECTS[$platform]}"
            ((total_tests++)) || true
            
            if test_build "$image" "$project_dir" "$environment" "$platform"; then
                ((passed_tests++)) || true
            else
                ((failed_tests++)) || true
            fi
            echo ""
        done
        echo ""
    done
    
    # Print summary
    echo "========================================"
    print_status "TEST SUMMARY"
    echo "========================================"
    print_status "Total tests: $total_tests"
    print_success "Passed tests: $passed_tests"
    
    if [[ $failed_tests -gt 0 ]]; then
        print_error "Failed tests: $failed_tests"
        echo ""
        print_error "Some tests failed. Please check the build logs above."
        return 1
    else
        echo ""
        print_success "All tests passed! ✅"
        print_success "Docker images can successfully build firmware for all ESP platforms."
        return 0
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [docker-image...]"
    echo ""
    echo "Test ESP platform firmware builds using Docker images."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Arguments:"
    echo "  docker-image  Docker image(s) to test (default: builder:latest and dev:latest)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Test with default images"
    echo "  $0 builder:latest                     # Test with specific image"
    echo "  $0 builder:latest dev:latest          # Test with multiple images"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_REPOSITORY   Docker repository prefix (default: ghcr.io/sparck75/alteriom-docker-images)"
    echo ""
    echo "Test Platforms:"
    echo "  - ESP32 (esp32dev environment)"
    echo "  - ESP32-S3 (esp32-s3-devkitc-1 environment)"
    echo "  - ESP32-C3 (esp32-c3-devkitm-1 environment)"
    echo "  - ESP8266 (nodemcuv2 environment)"
    exit 0
fi

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not available. Please install Docker to run tests."
    exit 1
fi

# Run the tests
run_tests "$@"
exit $?