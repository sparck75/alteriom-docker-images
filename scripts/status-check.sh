#!/usr/bin/env bash
# Quick status check for Docker images
# Answers the question: "Did it work?" or "Do I need to wait?"

set -euo pipefail

DOCKER_REPO="ghcr.io/sparck75/alteriom-docker-images"

echo "🔍 Checking if Docker images are published and ready to use..."
echo ""

# Quick check - can we pull both images?
if docker pull "${DOCKER_REPO}/builder:latest" >/dev/null 2>&1 && \
   docker pull "${DOCKER_REPO}/dev:latest" >/dev/null 2>&1; then
    
    echo "✅ YES, IT WORKED!"
    echo "✅ Both images are published and available"
    echo ""
    echo "Available images:"
    echo "  • ${DOCKER_REPO}/builder:latest"
    echo "  • ${DOCKER_REPO}/dev:latest"
    echo ""
    echo "You can now use them in your projects!"
    exit 0
else
    echo "⏳ NOT YET - STILL BUILDING"
    echo "⏳ The images are not fully published yet"
    echo ""
    echo "Current action is still running. Check progress at:"
    echo "  https://github.com/sparck75/alteriom-docker-images/actions"
    echo ""
    echo "Wait a few more minutes and try again!"
    exit 1
fi