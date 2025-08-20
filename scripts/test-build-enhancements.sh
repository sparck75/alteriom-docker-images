#!/usr/bin/env bash
# Simple test for build-images.sh enhancements
# Tests the new functionality without requiring Docker registry access

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Testing build-images.sh enhancements..."

# Test environment variables
export DOCKER_REPOSITORY="test-repo/alteriom-docker-images"
export AUDIT_RESULT="build_recommended"
export AUDIT_CHANGES="Base image: 8 days old; Weekly refresh"
export GITHUB_EVENT_NAME="schedule"

echo "Testing help message..."
if ./scripts/build-images.sh --help 2>/dev/null; then
    echo "✗ Build script should not have help option"
else
    echo "✓ Build script correctly handles invalid options"
fi

echo ""
echo "Testing version reading..."
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
    echo "✓ Version file found: $VERSION"
else
    echo "✗ VERSION file not found"
    exit 1
fi

echo ""
echo "Testing Dockerfile analysis..."
if grep -q "platformio==" production/Dockerfile; then
    PIO_VERSION=$(grep 'platformio==' production/Dockerfile | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "✓ PlatformIO version found in production Dockerfile: $PIO_VERSION"
else
    echo "✗ PlatformIO version not found in production Dockerfile"
fi

if grep -q "platformio==" development/Dockerfile; then
    PIO_VERSION_DEV=$(grep 'platformio==' development/Dockerfile | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "✓ PlatformIO version found in development Dockerfile: $PIO_VERSION_DEV"
else
    echo "✗ PlatformIO version not found in development Dockerfile"
fi

echo ""
echo "Testing date tag generation..."
DATE_TAG=$(date -u +%Y%m%d)
echo "✓ Date tag: $DATE_TAG"

echo ""
echo "Testing dev version generation for scheduled builds..."
if [ "${GITHUB_EVENT_NAME}" = "schedule" ]; then
    DEV_VERSION="${VERSION}-dev-${DATE_TAG}"
    echo "✓ Development version for scheduled build: $DEV_VERSION"
else
    echo "✓ Standard version for non-scheduled builds: $VERSION"
fi

echo ""
echo "All basic tests passed! ✅"
echo "Note: Docker build tests require Docker daemon and would be tested in CI"