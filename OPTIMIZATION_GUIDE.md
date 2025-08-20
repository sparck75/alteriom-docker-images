# Docker Image Size Optimizations

This document explains the optimizations made to reduce Docker image sizes for the Alteriom PlatformIO builder images.

## Summary of Changes

The Docker images have been optimized to significantly reduce size while maintaining full PlatformIO functionality:

### Production Image Optimizations

**Before:**
- Pre-installed ESP32/ESP8266 platforms in image
- Retained all build tools in final image
- Included unnecessary packages (curl, unzip, wget, cmake, etc.)
- Duplicate packages (git and git-core)

**After:**
- ESP platforms installed at runtime (smaller base image)
- Build tools removed after PlatformIO installation
- Only essential packages retained (git, ca-certificates)
- Single optimized RUN layer

### Development Image Optimizations  

**Before:**
- Duplicated all production packages plus dev tools
- Included unnecessary packages (sudo, build-essential, etc.)
- Multiple RUN layers

**After:**
- Streamlined to essential dev tools only (vim, less, htop)
- Optimized single RUN layer
- Removed unnecessary packages

## Size Reduction Benefits

The optimizations provide:

1. **Smaller base images** - Faster pulls and deployments
2. **Reduced layer count** - Better Docker cache efficiency  
3. **Runtime platform installs** - Always get latest ESP platform versions
4. **Cleaner final images** - No leftover build artifacts

## Migration Guide

### For CI/CD Systems

No changes needed to usage - the images work identically:

```bash
# Production builder (unchanged usage)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Development image (unchanged usage)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest --version
```

### For Local Development

The first build with a new image may take slightly longer as ESP platforms are downloaded:

```bash
# First run downloads platforms (one-time setup)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Subsequent runs are fast
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev
```

## Alternative Optimization Approaches

Several optimization variants are available in the repository:

- `production/Dockerfile.optimized` - Multi-stage build approach
- `production/Dockerfile.alpine` - Alpine Linux base (smallest)
- `production/Dockerfile.minimal` - Current optimized approach
- `development/Dockerfile.optimized` - Extends published production image

Use `scripts/compare-image-optimizations.sh` to test different approaches.

## Technical Details

### Package Removal Strategy

Build tools are installed, used for PlatformIO installation, then removed:

```dockerfile
RUN apt-get install gcc g++ make libffi-dev libssl-dev \
    && pip3 install platformio==6.1.13 \
    && apt-get remove -y gcc g++ make libffi-dev libssl-dev \
    && apt-get autoremove -y
```

### Runtime Platform Installation

ESP platforms are installed when first needed:

```bash
# Platforms auto-install on first use
pio run -e esp32dev  # Downloads espressif32 platform if needed
```

### Layer Optimization

All package operations combined into single RUN instruction to minimize layers and intermediate images.

## Troubleshooting

**Q: Platform download fails in restricted networks**
A: Use the original Dockerfiles with pre-installed platforms for restricted environments.

**Q: First build takes longer**
A: Normal - ESP platforms are downloaded once and cached for subsequent builds.

**Q: Need additional tools in production image**  
A: Consider using the development image or adding tools to your build process.