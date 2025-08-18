#!/usr/bin/env bash
# Build and (optionally) push Docker images for alteriom-docker-images
# Usage: ./alteriom-docker-images/scripts/build-images.sh [push|dev-only]
# Requires environment variables:
#   DOCKER_REPOSITORY (e.g. ghcr.io/your_user/alteriom-docker-images)
#   (optional) PLATFORMS for buildx platforms, default: linux/amd64,linux/arm64
#
# Options:
#   push      - Build and push both production and development images
#   dev-only  - Build and push only the development image (for daily builds)
#   (no args) - Build locally without pushing

set -euo pipefail

REPO=${DOCKER_REPOSITORY:-}
if [ -z "$REPO" ]; then
  echo "ERROR: DOCKER_REPOSITORY must be set (e.g. ghcr.io/your_user/alteriom-docker-images)"
  exit 2
fi

PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64}
DATE_TAG=$(date -u +%Y%m%d)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROD_CONTEXT="$ROOT_DIR/production"
DEV_CONTEXT="$ROOT_DIR/development"

# Read version from VERSION file
if [ -f "$ROOT_DIR/VERSION" ]; then
  VERSION=$(cat "$ROOT_DIR/VERSION" | tr -d '\n\r')
else
  VERSION="1.0.0"
fi

echo "Building version: $VERSION"

# For daily builds, create a dev-specific version tag
if [ "${1:-}" = "dev-only" ] && [ "${GITHUB_EVENT_NAME:-}" = "schedule" ]; then
  DEV_VERSION="${VERSION}-dev-$(date -u +%Y%m%d)"
  echo "Creating development version: $DEV_VERSION"
else
  DEV_VERSION="$VERSION"
fi

build_and_push(){
  local context="$1"
  local image="$2"
  local version="$3"
  echo "Building and pushing ${image} from ${context} with version ${version}"
  docker buildx build --platform "${PLATFORMS}" "${context}" \
    --build-arg VERSION="${version}" \
    --tag "${REPO}/${image}:latest" \
    --tag "${REPO}/${image}:${version}" \
    --tag "${REPO}/${image}:${DATE_TAG}" \
    --label "org.opencontainers.image.version=${version}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
    --push
}

build_local(){
  local context="$1"
  local tag="$2"
  local version="${3:-$VERSION}"
  echo "Local build ${tag} from ${context} with version ${version}"
  # Extract just the image name (before the colon) from the tag
  local image_name="${tag##*/}"
  image_name="${image_name%%:*}"
  # For local builds, don't use platform flag as it may not be supported
  docker build -t "${tag}" \
    -t "${REPO}/${image_name}:${version}" \
    --label "org.opencontainers.image.version=${version}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
    "${context}"
}

if [ "${1:-}" = "push" ]; then
  echo "Building and pushing both images to ${REPO}"
  build_and_push "${PROD_CONTEXT}" "builder" "${VERSION}"
  build_and_push "${DEV_CONTEXT}" "dev" "${VERSION}"
  echo "Done"
elif [ "${1:-}" = "dev-only" ]; then
  echo "Building and pushing development image only to ${REPO}"
  build_and_push "${DEV_CONTEXT}" "dev" "${DEV_VERSION}"
  echo "Development image build complete"
else
  echo "Building local (no push). Use: ./alteriom-docker-images/scripts/build-images.sh push to push to registry"
  build_local "${PROD_CONTEXT}" "${REPO}/builder:local"
  build_local "${DEV_CONTEXT}" "${REPO}/dev:local"
  echo "Local builds complete"
fi
