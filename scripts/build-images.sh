#!/usr/bin/env bash
# Build and (optionally) push Docker images for alteriom-docker-images
# Usage: ./alteriom-docker-images/scripts/build-images.sh [push]
# Requires environment variables:
#   DOCKER_REPOSITORY (e.g. ghcr.io/your_user/alteriom-docker-images)
#   (optional) PLATFORMS for buildx platforms, default: linux/amd64,linux/arm64

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

build_and_push(){
  local context="$1"
  local image="$2"
  echo "Building and pushing ${image} from ${context}"
  docker buildx build --platform "${PLATFORMS}" "${context}" \
    --build-arg VERSION="${VERSION}" \
    --tag "${REPO}/${image}:latest" \
    --tag "${REPO}/${image}:${VERSION}" \
    --tag "${REPO}/${image}:${DATE_TAG}" \
    --label "org.opencontainers.image.version=${VERSION}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
    --push
}

build_local(){
  local context="$1"
  local tag="$2"
  echo "Local build ${tag} from ${context}"
  # For local builds, don't use platform flag as it may not be supported
  docker build -t "${tag}" \
    -t "${REPO}/${tag##*/}:${VERSION}" \
    --label "org.opencontainers.image.version=${VERSION}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
    "${context}"
}

if [ "${1:-}" = "push" ]; then
  echo "Building and pushing images to ${REPO}"
  build_and_push "${PROD_CONTEXT}" "builder"
  build_and_push "${DEV_CONTEXT}" "dev"
  echo "Done"
else
  echo "Building local (no push). Use: ./alteriom-docker-images/scripts/build-images.sh push to push to registry"
  build_local "${PROD_CONTEXT}" "${REPO}/builder:local"
  build_local "${DEV_CONTEXT}" "${REPO}/dev:local"
  echo "Local builds complete"
fi
