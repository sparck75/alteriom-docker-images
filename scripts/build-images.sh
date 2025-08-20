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
#
# For audit-driven builds, these environment variables provide context:
#   AUDIT_RESULT - Result from package audit (build_recommended/build_skipped)
#   AUDIT_CHANGES - Summary of changes detected by audit

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

# Read build number from BUILD_NUMBER file
if [ -f "$ROOT_DIR/BUILD_NUMBER" ]; then
  BUILD_NUMBER=$(cat "$ROOT_DIR/BUILD_NUMBER" | tr -d '\n\r')
else
  BUILD_NUMBER=1
fi

echo "Building version: $VERSION"
echo "Build number: $BUILD_NUMBER"

# For daily builds, create a dev-specific version tag
if [ "${1:-}" = "dev-only" ] && [ "${GITHUB_EVENT_NAME:-}" = "schedule" ]; then
  DEV_VERSION="${VERSION}-dev-build.${BUILD_NUMBER}"
  echo "Creating development version: $DEV_VERSION"
  
  # Show audit context if available
  if [ -n "${AUDIT_RESULT:-}" ]; then
    echo "Audit-driven build: ${AUDIT_RESULT}"
    echo "Changes detected: ${AUDIT_CHANGES:-No changes specified}"
  fi
else
  DEV_VERSION="$VERSION"
fi

# Function to get current package versions for comparison
get_package_versions() {
  local context="$1"
  echo "📋 Analyzing package versions in ${context}..."
  
  # Extract PlatformIO version from Dockerfile
  local pio_version
  if pio_version=$(grep 'platformio==' "${context}/Dockerfile" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1); then
    echo "  PlatformIO: $pio_version (pinned)"
  else
    echo "  PlatformIO: version not found in Dockerfile"
  fi
  
  # Extract Python base image
  local python_image
  if python_image=$(grep '^FROM python:' "${context}/Dockerfile" | cut -d' ' -f2); then
    echo "  Base Image: $python_image"
  else
    echo "  Base Image: not found in Dockerfile"
  fi
  
  # Show build context info
  echo "  Build Context: $context"
  echo "  Dockerfile: $(wc -l < "${context}/Dockerfile") lines"
}

# Function to compare with production if available
compare_with_production() {
  if [ "${1:-}" = "dev-only" ] && command -v docker >/dev/null 2>&1; then
    echo ""
    echo "📊 Comparing with current production image..."
    
    local prod_image="${REPO}/builder:latest"
    local dev_image="${REPO}/dev:latest"
    
    # Try to get production PlatformIO version
    if docker image inspect "$prod_image" >/dev/null 2>&1; then
      local prod_pio_version
      if prod_pio_version=$(docker run --rm "$prod_image" --version 2>/dev/null | grep -oE "version [0-9]+\.[0-9]+\.[0-9]+" | cut -d' ' -f2); then
        echo "  Production PlatformIO: $prod_pio_version"
      else
        echo "  Production PlatformIO: unable to determine"
      fi
      
      # Get production image creation date
      local prod_created
      if prod_created=$(docker inspect "$prod_image" --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1); then
        echo "  Production Image Age: $prod_created"
      fi
    else
      echo "  Production image not available locally for comparison"
    fi
    
    # Show development image info if available
    if docker image inspect "$dev_image" >/dev/null 2>&1; then
      local dev_created
      if dev_created=$(docker inspect "$dev_image" --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1); then
        echo "  Current Dev Image Age: $dev_created"
      fi
    else
      echo "  Development image not available locally for comparison"
    fi
  fi
}

build_and_push(){
  local context="$1"
  local image="$2"
  local version="$3"
  
  echo ""
  echo "🏗️  Building and pushing ${image} from ${context} with version ${version}"
  get_package_versions "$context"
  
  # Build with detailed labels for tracking
  # Use different tagging strategy for dev builds with build numbers
  if [ "$image" = "dev" ] && [ "${GITHUB_EVENT_NAME:-}" = "schedule" ]; then
    # Development build with build number
    docker buildx build --platform "${PLATFORMS}" "${context}" \
      --build-arg VERSION="${version}" \
      --tag "${REPO}/${image}:latest" \
      --tag "${REPO}/${image}:${version}" \
      --tag "${REPO}/${image}:build.${BUILD_NUMBER}" \
      --label "org.opencontainers.image.version=${version}" \
      --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
      --label "org.opencontainers.image.title=Alteriom PlatformIO Builder (Development)" \
      --label "org.opencontainers.image.description=ESP32/ESP8266 firmware build environment with dev tools" \
      --label "build.number=${BUILD_NUMBER}" \
      --label "build.audit.changes=${AUDIT_CHANGES:-No audit performed}" \
      --label "build.audit.result=${AUDIT_RESULT:-No audit performed}" \
      --label "build.trigger=${GITHUB_EVENT_NAME:-manual}" \
      --push
  else
    # Production build or regular build with date tags
    docker buildx build --platform "${PLATFORMS}" "${context}" \
      --build-arg VERSION="${version}" \
      --tag "${REPO}/${image}:latest" \
      --tag "${REPO}/${image}:${version}" \
      --tag "${REPO}/${image}:${DATE_TAG}" \
      --label "org.opencontainers.image.version=${version}" \
      --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
      --label "org.opencontainers.image.title=Alteriom PlatformIO Builder" \
      --label "org.opencontainers.image.description=ESP32/ESP8266 firmware build environment" \
      --label "build.audit.changes=${AUDIT_CHANGES:-No audit performed}" \
      --label "build.audit.result=${AUDIT_RESULT:-No audit performed}" \
      --label "build.trigger=${GITHUB_EVENT_NAME:-manual}" \
      --push
  fi
    
  echo "✅ Successfully built and pushed ${REPO}/${image}:${version}"
}

build_local(){
  local context="$1"
  local tag="$2"
  local version="${3:-$VERSION}"
  
  echo ""
  echo "🏗️  Local build ${tag} from ${context} with version ${version}"
  get_package_versions "$context"
  
  # Extract just the image name (before the colon) from the tag
  local image_name="${tag##*/}"
  image_name="${image_name%%:*}"
  
  # For local builds, don't use platform flag as it may not be supported
  docker build -t "${tag}" \
    -t "${REPO}/${image_name}:${version}" \
    --label "org.opencontainers.image.version=${version}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/sparck75/alteriom-docker-images" \
    --label "org.opencontainers.image.title=Alteriom PlatformIO Builder (Local)" \
    --label "org.opencontainers.image.description=ESP32/ESP8266 firmware build environment" \
    --label "build.type=local" \
    "${context}"
    
  echo "✅ Local build complete: ${tag}"
}

# Show build summary
show_build_summary() {
  local build_type="$1"
  echo ""
  echo "======================================"
  echo "       BUILD SUMMARY"
  echo "======================================"
  echo "Build Type: $build_type"
  echo "Version: $VERSION"
  echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Repository: $REPO"
  echo "Platforms: $PLATFORMS"
  
  if [ -n "${AUDIT_RESULT:-}" ]; then
    echo ""
    echo "Audit Information:"
    echo "  Result: ${AUDIT_RESULT}"
    echo "  Changes: ${AUDIT_CHANGES:-No changes specified}"
  fi
  
  if [ "$build_type" = "dev-only" ]; then
    echo ""
    echo "Development Image Tags:"
    echo "  ${REPO}/dev:latest"
    echo "  ${REPO}/dev:${DEV_VERSION}"
    echo "  ${REPO}/dev:build.${BUILD_NUMBER}"
  elif [ "$build_type" = "production" ]; then
    echo ""
    echo "Production Image Tags:"
    echo "  ${REPO}/builder:latest"
    echo "  ${REPO}/builder:${VERSION}"
    echo "  ${REPO}/builder:${DATE_TAG}"
    echo ""
    echo "Development Image Tags:"
    echo "  ${REPO}/dev:latest"
    echo "  ${REPO}/dev:${VERSION}"
    echo "  ${REPO}/dev:${DATE_TAG}"
  elif [ "$build_type" = "local" ]; then
    echo ""
    echo "Local Image Tags:"
    echo "  ${REPO}/builder:local"
    echo "  ${REPO}/dev:local"
  fi
  echo "======================================"
}

if [ "${1:-}" = "push" ]; then
  echo "🚀 Building and pushing both images to ${REPO}"
  compare_with_production "$1"
  build_and_push "${PROD_CONTEXT}" "builder" "${VERSION}"
  build_and_push "${DEV_CONTEXT}" "dev" "${VERSION}"
  show_build_summary "production"
  echo "✅ Production build complete"
elif [ "${1:-}" = "dev-only" ]; then
  echo "🌅 Building and pushing development image only to ${REPO}"
  compare_with_production "$1"
  build_and_push "${DEV_CONTEXT}" "dev" "${DEV_VERSION}"
  show_build_summary "dev-only"
  echo "✅ Development image build complete"
else
  echo "🔧 Building local (no push). Use: ./alteriom-docker-images/scripts/build-images.sh push to push to registry"
  get_package_versions "${PROD_CONTEXT}"
  get_package_versions "${DEV_CONTEXT}"
  build_local "${PROD_CONTEXT}" "${REPO}/builder:local"
  build_local "${DEV_CONTEXT}" "${REPO}/dev:local"
  show_build_summary "local"
  echo "✅ Local builds complete"
fi
