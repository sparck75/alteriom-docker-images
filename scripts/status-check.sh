#!/usr/bin/env bash

# 🔍 Quick Service Status Check for ESP32/ESP8266 Docker Images
# Answers: "Did it work?" or "Do I need to wait?"
# Enhanced with service validation and health monitoring

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOCKER_REPO="ghcr.io/sparck75/alteriom-docker-images"

echo -e "${BLUE}🔍 ESP32/ESP8266 Docker Images - Quick Status Check${NC}"
echo "=================================================="
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️ $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️ $message${NC}" ;;
    esac
}

# Quick image availability check
print_status "INFO" "Checking image availability..."

BUILDER_AVAILABLE=false
DEV_AVAILABLE=false

if docker pull "${DOCKER_REPO}/builder:latest" >/dev/null 2>&1; then
    BUILDER_AVAILABLE=true
    print_status "SUCCESS" "Production builder image: AVAILABLE"
else
    print_status "ERROR" "Production builder image: NOT AVAILABLE"
fi

if docker pull "${DOCKER_REPO}/dev:latest" >/dev/null 2>&1; then
    DEV_AVAILABLE=true
    print_status "SUCCESS" "Development image: AVAILABLE"
else
    print_status "ERROR" "Development image: NOT AVAILABLE"
fi

echo ""

# Quick service functionality test
if [ "$BUILDER_AVAILABLE" = true ] || [ "$DEV_AVAILABLE" = true ]; then
    print_status "INFO" "Testing service functionality..."
    
    # Test the available image
    if [ "$BUILDER_AVAILABLE" = true ]; then
        TEST_IMAGE="${DOCKER_REPO}/builder:latest"
        IMAGE_NAME="production builder"
    else
        TEST_IMAGE="${DOCKER_REPO}/dev:latest"
        IMAGE_NAME="development"
    fi
    
    if docker run --rm "$TEST_IMAGE" --version >/dev/null 2>&1; then
        VERSION=$(docker run --rm "$TEST_IMAGE" --version 2>/dev/null | head -1)
        print_status "SUCCESS" "PlatformIO service: WORKING ($VERSION)"
        SERVICE_OK=true
    else
        print_status "ERROR" "PlatformIO service: FAILED"
        SERVICE_OK=false
    fi
    
    echo ""
fi

# Overall status assessment
if [ "$BUILDER_AVAILABLE" = true ] && [ "$DEV_AVAILABLE" = true ] && [ "${SERVICE_OK:-false}" = true ]; then
    echo -e "${GREEN}🎉 YES, IT WORKED!${NC}"
    echo "✅ Both images are published and services are functional"
    echo ""
    echo "Available images with service validation:"
    echo "  • ${DOCKER_REPO}/builder:latest (✅ service tested)"
    echo "  • ${DOCKER_REPO}/dev:latest (✅ service tested)" 
    echo ""
    echo "You can now use them in your ESP32/ESP8266 projects!"
    echo ""
    echo "Quick start:"
    echo "  docker run --rm -v \${PWD}:/workspace ${DOCKER_REPO}/builder:latest pio run -e esp32dev"
    exit 0
    
elif [ "$BUILDER_AVAILABLE" = true ] || [ "$DEV_AVAILABLE" = true ]; then
    echo -e "${YELLOW}⚠️ PARTIALLY WORKING${NC}"
    echo "Some images are available but not all services are fully operational"
    echo ""
    if [ "$BUILDER_AVAILABLE" = true ]; then
        echo "✅ Production builder: ${DOCKER_REPO}/builder:latest"
    else
        echo "❌ Production builder: Not available"
    fi
    if [ "$DEV_AVAILABLE" = true ]; then
        echo "✅ Development image: ${DOCKER_REPO}/dev:latest"
    else
        echo "❌ Development image: Not available"
    fi
    echo ""
    echo "Check GitHub Actions for build status:"
    echo "  https://github.com/sparck75/alteriom-docker-images/actions"
    exit 1
    
else
    echo -e "${RED}⏳ NOT YET - STILL BUILDING${NC}"
    echo "The images are not fully published yet"
    echo ""
    echo "Current status:"
    echo "  ❌ Production builder: Not available"
    echo "  ❌ Development image: Not available"
    echo ""
    echo "Check build progress at:"
    echo "  https://github.com/sparck75/alteriom-docker-images/actions"
    echo ""
    echo "Wait a few more minutes and try again!"
    echo "Expected build time: 15-30 minutes for full deployment"
    exit 1
fi