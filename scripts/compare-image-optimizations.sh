#!/usr/bin/env bash
# Compare different Docker image optimization approaches
# Usage: ./compare-image-optimizations.sh

set -euo pipefail

echo "=== Docker Image Size Optimization Comparison ==="
echo ""

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "Building different variants for size comparison..."
echo "(Note: Builds may fail in restricted network environments)"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

build_and_measure() {
    local name="$1"
    local dockerfile="$2" 
    local context="$3"
    
    echo -n "Building $name... "
    
    if docker build -f "$dockerfile" -t "alteriom-${name}:comparison" "$context" >/dev/null 2>&1; then
        local size=$(docker images --format "table {{.Size}}" "alteriom-${name}:comparison" | tail -n1)
        echo -e "${GREEN}✓${NC} Size: $size"
        return 0
    else
        echo -e "${RED}✗ Build failed${NC}"
        return 1
    fi
}

echo "=== Production Image Variants ==="

build_and_measure "current" "production/Dockerfile" "production/"
build_and_measure "optimized" "production/Dockerfile.optimized" "production/"
build_and_measure "alpine" "production/Dockerfile.alpine" "production/"
build_and_measure "minimal" "production/Dockerfile.minimal" "production/"

echo ""
echo "=== Development Image Variants ==="

build_and_measure "dev-current" "development/Dockerfile" "development/"
build_and_measure "dev-selfcontained" "development/Dockerfile.selfcontained" "development/"

echo ""
echo "=== Summary ==="
echo ""
echo "Optimization approaches:"
echo ""
echo "1. ${YELLOW}Current${NC}: Original Dockerfiles"
echo "   - Full build tools remain in final image"
echo "   - Pre-installs ESP platforms"
echo ""
echo "2. ${YELLOW}Optimized${NC}: Multi-stage build"
echo "   - Build stage for installations, clean final stage"
echo "   - Reduces build tool footprint"
echo ""
echo "3. ${YELLOW}Alpine${NC}: Alpine Linux base"
echo "   - Uses python:3.11-alpine instead of python:3.11-slim"
echo "   - Smaller base image, apk package manager"
echo ""
echo "4. ${YELLOW}Minimal${NC}: No pre-installed platforms"
echo "   - Smallest possible image"
echo "   - ESP platforms installed at runtime"
echo ""
echo "5. ${YELLOW}Self-contained Dev${NC}: Optimized but independent"
echo "   - Development tools without external dependencies"
echo "   - Easier to build and maintain"
echo ""
echo "Clean up comparison images:"
echo "docker rmi \$(docker images -q alteriom-*:comparison)"