# GitHub Copilot Instructions - alteriom-docker-images

> **AI Assistant Guidelines**: Always follow these instructions precisely. Only fall back to additional search and context gathering if the information in these instructions is incomplete or found to be in error.

## Project Overview

**alteriom-docker-images** provides pre-built PlatformIO builder images for the Alteriom project (ESP32/ESP8266). This repository contains production and development Docker images with PlatformIO and required build tools.

### Repository Structure

```text
alteriom-docker-images/
├── .github/
│   ├── workflows/build-and-publish.yml    # CI/CD automation
│   ├── copilot-instructions.md            # This file - AI assistant guidelines
│   └── custom-instruction.md              # Legacy custom instructions
├── production/Dockerfile                  # Minimal PlatformIO builder
├── development/Dockerfile                 # Development tools + PlatformIO
├── scripts/
│   ├── build-images.sh                   # Build and push helper
│   ├── verify-images.sh                  # Comprehensive verification
│   ├── status-check.sh                   # Quick status check
│   └── check-deprecated-commands.sh      # Maintenance utility
├── copilot-setup-steps.yml               # Copilot configuration guide
├── ADMIN_SETUP.md                        # Admin configuration guide
├── COPILOT_ADMIN_SETUP.md                # Copilot admin setup
└── README.md                             # Public documentation
```

### Key Technologies & Context

- **Docker**: Multi-stage builds, GHCR registry, multi-platform (amd64/arm64)
- **PlatformIO**: Version 6.1.13 (pinned for stability)
- **ESP32/ESP8266**: Embedded development platforms (espressif32, espressif8266)
- **GitHub Actions**: Automated CI/CD with scheduled builds
- **Python**: 3.11-slim base image, non-root user 'builder' (UID 1000)
- **Registry**: GitHub Container Registry (ghcr.io/sparck75/alteriom-docker-images)

## Command Reference

### Quick Status & Verification

```powershell
# Quick status check (10-15 seconds)
./scripts/status-check.sh

# Comprehensive verification with GitHub Actions status (30-60 seconds)
./scripts/verify-images.sh

# Check for deprecated commands
./scripts/check-deprecated-commands.sh
```

### Docker Image Usage

```powershell
# Pull and verify production builder
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Pull and verify development image
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest --version

# Expected output for both: "PlatformIO Core, version 6.1.13"

# Build firmware example
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev
```

### Local Building (Admin/Development)

```powershell
# Set up environment (required for local builds)
$env:DOCKER_REPOSITORY="ghcr.io/your_user/alteriom-docker-images"

# Build locally without push (15-45 minutes - NEVER CANCEL)
./scripts/build-images.sh

# Build and push to registry (20-60 minutes - NEVER CANCEL)
./scripts/build-images.sh push
```

### CI/CD Operations

```powershell
# Manual workflow trigger:
# 1. Navigate to: https://github.com/sparck75/alteriom-docker-images/actions
# 2. Click "Build and Publish Docker Images" workflow
# 3. Click "Run workflow" button
# 4. Select branch (usually 'main') and click "Run workflow"
```

## Validation & Testing

### Mandatory Validation Steps

**ALWAYS** perform these after making changes:

```powershell
# Test image functionality
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version

# Run comprehensive verification after CI builds complete
./scripts/verify-images.sh
# Must show "ALL SYSTEMS GO!" for complete success
```

### Complete User Scenario Testing

Create and test a PlatformIO project:

```powershell
# Create test project
mkdir $env:TEMP/test-platformio
cd $env:TEMP/test-platformio

# Create platformio.ini
@'
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
'@ | Out-File -FilePath platformio.ini -Encoding UTF8

# Create main.cpp
mkdir src
@'
#include <Arduino.h>
void setup() { Serial.begin(115200); }
void loop() { delay(1000); }
'@ | Out-File -FilePath src/main.cpp -Encoding UTF8

# Test with Docker image (may fail in restricted networks but validates command structure)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev
```

## Build Timing & Expectations

### Critical Timing Rules

- **NEVER CANCEL** any build or long-running command
- Local Docker builds: 15-45 minutes (set timeout to 60+ minutes)
- GitHub Actions builds: 15-30 minutes (set timeout to 45+ minutes)
- Image pulls: 1-5 minutes depending on connection
- Verification scripts: 30-60 seconds

### CI/CD Triggers

- **Automatic triggers**:
  - PR merges to main branch
  - Daily builds at 02:00 UTC
  - Manual dispatch via GitHub Actions tab
- **Build artifacts**: Multi-platform images (linux/amd64, linux/arm64)
- **Tags**: `:latest` and date-based (`:YYYYMMDD`)

## Development Guidelines

### File Change Checklist

After modifying these files, always verify:

- **Dockerfiles** (`production/Dockerfile`, `development/Dockerfile`):
  - Test both images build successfully
  - Verify `--version` command works
  - Check for security vulnerabilities
  
- **Scripts** (`scripts/*.sh`):
  - Test script functionality
  - Verify error handling
  - Check PowerShell compatibility notes
  
- **Workflows** (`.github/workflows/*.yml`):
  - Check GitHub Actions logs
  - Verify registry authentication
  - Test manual trigger functionality

### Environment Requirements

- **Docker**: Required for all build and test operations
- **PowerShell/Bash**: Required for running helper scripts
- **Unrestricted network**: Required for reliable building (PyPI access for pip installs)
- **GitHub Actions**: Pre-configured for automated builds and publishing
- **DOCKER_REPOSITORY environment variable**: Required for local builds

## Troubleshooting Guide

### Common Issues & Solutions

#### SSL Certificate Errors

- **Issue**: Local builds fail with SSL certificate errors
- **Solution**: Normal in restricted environments. Build in unrestricted network or use pre-published images
- **Workaround**: Use GitHub Actions for building instead of local builds

#### Image Not Found

- **Issue**: Docker pull fails with "image not found"
- **Solution**: Run `./scripts/verify-images.sh` to check publication status and build progress
- **Check**: Verify GitHub Actions workflow completed successfully

#### Permission Denied in Container

- **Issue**: Docker container cannot access mounted files
- **Solution**: Ensure mounted workspace has correct ownership
- **PowerShell fix**: 

```powershell
# If using WSL2 backend
wsl sudo chown -R 1000:1000 /path/to/workspace
```

#### Workflow Failures

- **Issue**: GitHub Actions workflow fails
- **Solution**: Check [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions) for detailed logs
- **Common causes**: Registry authentication, buildx setup, network issues

### Debug Commands

```powershell
# Check Docker daemon status
docker info

# List local images
docker images ghcr.io/sparck75/alteriom-docker-images/*

# Check container logs
docker logs <container_id>

# Verify registry access
docker login ghcr.io

# Test image interactively
docker run -it --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest /bin/bash
```

## Security & Best Practices

### Security Guidelines

- **Non-root user**: Images run as 'builder' user (UID 1000) for security
- **No secrets in images**: Use environment variables for configuration
- **Registry authentication**: Uses GitHub token, no additional secrets required
- **Content exclusions**: Sensitive paths excluded from Copilot suggestions

### Code Quality Standards

- **Documentation**: All changes must include updated documentation
- **Testing**: Both production and development images must be tested
- **Version pinning**: Dependencies should be pinned for reproducibility
- **Error handling**: Scripts must handle common failure scenarios

### Copilot Best Practices

- **Context**: Include descriptive comments in Dockerfiles for better AI suggestions
- **Platform info**: Document ESP32/ESP8266 specific configurations in comments
- **Build arguments**: Explain multi-stage build reasoning
- **Dependencies**: Document library versions and compatibility requirements

## Advanced Usage

### Multi-Platform Development

```powershell
# Build for specific platform
docker buildx build --platform linux/amd64 -t test-image:amd64 .
docker buildx build --platform linux/arm64 -t test-image:arm64 .

# Test cross-platform functionality
docker run --rm --platform linux/amd64 ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
docker run --rm --platform linux/arm64 ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
```

### Custom Registry Usage

```powershell
# For custom registry deployment
$env:DOCKER_REPOSITORY="your-registry.com/your-org/alteriom-docker-images"
./scripts/build-images.sh push
```

### Development Workflow Integration

```bash
# Pre-commit hook example (save as .git/hooks/pre-commit)
#!/bin/bash
./scripts/verify-images.sh
if [ $? -ne 0 ]; then
    echo "Image verification failed. Commit aborted."
    exit 1
fi
```

## Links & Resources

- **Repository**: <https://github.com/sparck75/alteriom-docker-images>
- **GitHub Actions**: <https://github.com/sparck75/alteriom-docker-images/actions>
- **Container Registry**: <https://github.com/sparck75/alteriom-docker-images/pkgs/container/alteriom-docker-images%2Fbuilder>
- **PlatformIO Documentation**: <https://docs.platformio.org/>
- **Docker Best Practices**: <https://docs.docker.com/develop/dev-best-practices/>

---

**Version**: 2.0 | **Last Updated**: August 2025 | **Maintainer**: @sparck75
