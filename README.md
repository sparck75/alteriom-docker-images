# alteriom-docker-images

[![Latest Release](https://img.shields.io/github/v/release/sparck75/alteriom-docker-images?label=Latest%20Version)](https://github.com/sparck75/alteriom-docker-images/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/sparck75/alteriom-docker-images/build-and-publish.yml?branch=main&label=Build%20Status)](https://github.com/sparck75/alteriom-docker-images/actions/workflows/build-and-publish.yml)
[![License](https://img.shields.io/github/license/sparck75/alteriom-docker-images)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/sparck75/alteriom-docker-images)](https://github.com/sparck75/alteriom-docker-images/commits/main)

[![Production Image](https://img.shields.io/badge/docker-production%20builder-blue?logo=docker)](https://github.com/sparck75/alteriom-docker-images/pkgs/container/alteriom-docker-images%2Fbuilder)
[![Development Image](https://img.shields.io/badge/docker-development%20builder-blue?logo=docker)](https://github.com/sparck75/alteriom-docker-images/pkgs/container/alteriom-docker-images%2Fdev)

Pre-built PlatformIO builder images for the Alteriom project (ESP32 / ESP8266).

This repository contains optimized Dockerfiles and helper scripts to build and publish minimal PlatformIO images for ESP32/ESP8266 firmware builds. The images are optimized for size while maintaining full functionality.

**Status**: Docker tag generation issue has been fixed ✅

Contents
- production/Dockerfile  — optimized minimal builder image with PlatformIO (ESP platforms installed at runtime)
- development/Dockerfile — development image with extra tools and debugging utilities  
- scripts/build-images.sh — build and push helper script
- scripts/verify-images.sh — verify published images are available and working
- OPTIMIZATION_GUIDE.md — detailed guide on image size optimizations

Quick start

Pull the recommended builder image (replace `<your_user>` with the image owner):

```powershell
docker pull ghcr.io/<your_user>/alteriom-docker-images/builder:latest
```

Build firmware using the image:

```powershell
# mount your repository into /workspace and run PlatformIO inside the image
docker run --rm -v ${PWD}:/workspace ghcr.io/<your_user>/alteriom-docker-images/builder:latest pio run -e diag-esp32-c3
```

**Verify images are ready:**

```bash
# Check if images are published and working
./scripts/verify-images.sh
```

Build & publish (admin, one-time - run in an unrestricted network environment)

```powershell
# from the cloned Alteriom repo
# set GITHUB_TOKEN and DOCKER_REPOSITORY environment variables
./scripts/build-images.sh push
```

## Image Optimizations

The Docker images have been optimized for minimal size while maintaining full PlatformIO functionality:

**Key optimizations:**
- ESP32/ESP8266 platforms installed at runtime (smaller base image)
- Build tools removed after PlatformIO installation  
- Unnecessary packages eliminated
- Single-layer package installation for better caching

**Benefits:**
- Significantly smaller images for faster pulls
- Always get latest ESP platform versions
- Better Docker layer caching
- Same functionality and usage

See [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) for detailed information.

## CI / Automated builds

This repository includes a GitHub Actions workflow (`.github/workflows/build-and-publish.yml`) that automatically builds and publishes the production and development images when PRs are merged to main, on a daily schedule, and on manual dispatch. The workflow tags images with `:latest` and a date tag (YYYYMMDD). 

**Setup required:** The workflow is pre-configured to use GitHub Container Registry (GHCR) and requires no additional secrets setup. The workflow uses the built-in `GITHUB_TOKEN` for authentication.

**Admin Notes:** 
- Repository has been tested and builds are working as of August 2025
- Docker builds use Python 3.11-slim base image (compatible with current package repositories)
- Both production and development images build successfully with multi-platform support

**Optional configuration:** If you want to use a different container registry, set the following repository variables:

- `DOCKER_REPOSITORY` - target repository (e.g. `ghcr.io/<your_user>/alteriom-docker-images`) - optional, defaults to `ghcr.io/<owner>/alteriom-docker-images`

The workflow runs:
- **Automatically** when PRs are merged to the main branch
- **Daily** at 02:00 UTC  
- **Manually** via workflow dispatch in the Actions tab

Contribution and maintenance

If you'd like me to help maintain the CI and update images regularly, I can:

- Review and refine the Dockerfiles for size and reproducibility
- Add automated smoke tests that run a quick `pio run -e diag-esp32-c3` inside the image
- Keep the daily build workflow and perform periodic reviews when PlatformIO releases major changes

Repository structure

```
alteriom-docker-images/
├── production/
│   └── Dockerfile                   # Optimized minimal builder
├── development/
│   └── Dockerfile                   # Development tools + builder
├── scripts/
│   ├── build-images.sh             # Build and push helper
│   ├── verify-images.sh            # Image verification
│   └── compare-image-optimizations.sh  # Size comparison tool
├── OPTIMIZATION_GUIDE.md           # Detailed optimization guide
└── README.md
```

License
This repository is licensed under the MIT License. See `LICENSE` for details.
