#!/usr/bin/env bash
# Docker Image Verification Script
# Checks if Docker images are published and ready to use

set -euo pipefail

# Configuration
REPO_OWNER="sparck75"
REPO_NAME="alteriom-docker-images"
DOCKER_REPO="ghcr.io/${REPO_OWNER}/${REPO_NAME}"

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

check_workflow_status() {
    print_status "Checking GitHub Actions workflow status..."
    
    if ! command -v curl >/dev/null 2>&1; then
        print_warning "curl not available - skipping workflow status check"
        return 2
    fi
    
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs"
    local response
    
    if ! response=$(timeout 10 curl -s -f "$api_url" 2>/dev/null); then
        print_warning "Unable to check workflow status via GitHub API"
        return 2
    fi
    
    if [ -z "$response" ]; then
        print_warning "Empty response from GitHub API"
        return 2
    fi
    
    local in_progress_count
    in_progress_count=$(echo "$response" | grep -o '"status":"in_progress"' | wc -l 2>/dev/null || echo "0")
    in_progress_count=$(echo "$in_progress_count" | tr -d '\n\r ')
    
    if [ "$in_progress_count" -gt 0 ]; then
        print_warning "Found $in_progress_count workflow run(s) currently in progress"
        return 1
    else
        print_success "No workflows currently running"
        return 0
    fi
}

check_docker_image() {
    local image_name="$1"
    local image_type="$2"
    
    print_status "Checking $image_type image: $image_name"
    
    # Try to pull the image with timeout
    if ! timeout 30 docker pull "$image_name" >/dev/null 2>&1; then
        print_error "✗ Image $image_name is not available or cannot be pulled"
        return 1
    fi
    
    print_success "✓ Image $image_name is available"
    
    # Try to run the image to verify it works
    if ! timeout 15 docker run --rm "$image_name" --version >/dev/null 2>&1; then
        print_warning "! Image $image_name is available but may have issues running"
        return 1
    fi
    
    print_success "✓ Image $image_name runs correctly and PlatformIO is functional"
    return 0
}

main() {
    echo "=== Docker Image Verification Report ==="
    echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
    echo "Docker Registry: ${DOCKER_REPO}"
    echo ""
    
    # Check workflow status
    local workflow_status
    if check_workflow_status; then
        workflow_status="ok"
    else
        local ret=$?
        if [ $ret -eq 1 ]; then
            workflow_status="in_progress"
        else
            workflow_status="unknown"
        fi
    fi
    echo ""
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not available. Please install Docker to verify images."
        echo ""
        echo "=== SUMMARY ==="
        print_error "Cannot verify images without Docker"
        exit 1
    fi
    
    local images_ok=0
    local total_images=2
    
    # Check production image
    print_status "=== Checking Production Image ==="
    if check_docker_image "${DOCKER_REPO}/builder:latest" "production"; then
        ((images_ok++)) || true
    fi
    echo ""
    
    # Check development image  
    print_status "=== Checking Development Image ==="
    if check_docker_image "${DOCKER_REPO}/dev:latest" "development"; then
        ((images_ok++)) || true
    fi
    echo ""
    
    # Summary
    echo "=== SUMMARY ==="
    
    if [ "$workflow_status" = "ok" ] && [ $images_ok -eq $total_images ]; then
        print_success "✅ ALL SYSTEMS GO!"
        print_success "✅ No builds running and all images ($images_ok/$total_images) are ready to use"
        echo ""
        echo "You can use the images with:"
        echo "  docker pull ${DOCKER_REPO}/builder:latest"
        echo "  docker pull ${DOCKER_REPO}/dev:latest"
        exit 0
    elif [ "$workflow_status" = "in_progress" ]; then
        print_warning "⏳ BUILDS IN PROGRESS"
        print_warning "Current builds are still running"
        print_status "Found $images_ok/$total_images working images"
        print_status "Wait for current builds to complete for the latest versions"
        echo ""
        echo "Check build progress at:"
        echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
        exit 1
    elif [ $images_ok -eq 0 ]; then
        print_error "❌ NO IMAGES AVAILABLE"
        print_error "No working images found"
        echo ""
        echo "Check build logs at:"
        echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
        exit 1
    else
        print_warning "⚠️  PARTIAL SUCCESS"
        print_warning "Found $images_ok/$total_images working images"
        if [ "$workflow_status" = "in_progress" ]; then
            print_status "Current builds may still be in progress"
        fi
        echo ""
        echo "Check build status at:"
        echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
        exit 1
    fi
}

# Show usage if help requested
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Verifies that Docker images are published and ready to use."
    echo "Checks both GitHub Actions workflow status and Docker image availability."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Exit codes:"
    echo "  0  All images are available and working"
    echo "  1  Images not available or builds in progress"
    exit 0
fi

main "$@"