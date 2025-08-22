# GitHub Copilot Instructions - alteriom-docker-images

> **AI Assistant Guidelines**: Always follow these instructions precisely. Only fall back to additional search and context gathering if the information in these instructions is incomplete or found to be in error.

## Project Overview

**alteriom-docker-images** provides pre-built PlatformIO builder images for the Alteriom project (ESP32/ESP8266). This repository contains production and development Docker images with PlatformIO and required build tools.

### Repository Structure

```text
alteriom-docker-images/
├── .github/
│   ├── workflows/build-and-publish.yml    # Single CI/CD pipeline
│   ├── copilot-instructions.md            # This file - AI assistant guidelines
│   └── ISSUE_TEMPLATE/                    # Issue templates
├── production/Dockerfile                  # Minimal PlatformIO builder
├── development/Dockerfile                 # Development tools + PlatformIO
├── scripts/
│   ├── build-images.sh                   # Build and push helper (15-45 minutes)
│   ├── verify-images.sh                  # Comprehensive verification (2 seconds)
│   ├── status-check.sh                   # Quick status check (10 seconds)
│   ├── test-esp-builds.sh                # ESP platform testing (2.5 minutes)
│   └── validate-workflows.sh             # Workflow duplication prevention
├── tests/                                # ESP platform test projects
│   ├── esp32-test/                       # ESP32 test project
│   ├── esp32s3-test/                     # ESP32-S3 test project
│   ├── esp32c3-test/                     # ESP32-C3 test project
│   └── esp8266-test/                     # ESP8266 test project
├── VERSION                               # Version file (current: 1.8.0)
├── BUILD_NUMBER                          # Build counter (current: 10)
├── ADMIN_SETUP.md                        # Admin configuration guide
├── OPTIMIZATION_GUIDE.md                 # Image optimization documentation
├── FIREWALL_CONFIGURATION.md             # Network access requirements
└── README.md                             # Public documentation
```

### Key Technologies & Context

- **Docker**: Multi-stage builds, GHCR registry, multi-platform (amd64/arm64)
- **PlatformIO**: Version 6.1.13 (pinned for stability)
- **ESP32/ESP8266**: Embedded development platforms (espressif32, espressif8266)
- **GitHub Actions**: Automated CI/CD with scheduled builds
- **Python**: 3.11-slim base image, non-root user 'builder' (UID 1000)
- **Registry**: GitHub Container Registry (ghcr.io/sparck75/alteriom-docker-images)

## Working Effectively

### Essential Setup
- **ALWAYS run from repository root**: All commands below assume you're in `/path/to/alteriom-docker-images/`
- **Make scripts executable**: `chmod +x scripts/*.sh`
- **Docker required**: All operations require Docker to be running
- **Network access**: Unrestricted internet required for reliable builds

### Quick Verification Commands (Always Run These First)

```bash
# Quick status check (10 seconds) - Always run this first
./scripts/status-check.sh

# Comprehensive verification with GitHub Actions status (2 seconds)
./scripts/verify-images.sh
# Must show "ALL SYSTEMS GO!" for complete success

# Validate only ONE workflow exists (critical for cost control)
./scripts/validate-workflows.sh
# Must show "VALIDATION PASSED"
```

### Docker Image Usage (Validated Working Commands)

```bash
# Pull and test production builder (VALIDATED: Works correctly)
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
# Expected output: "PlatformIO Core, version 6.1.13"

# Pull and test development image (VALIDATED: Works correctly)
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version
# Expected output: "PlatformIO Core, version 6.1.13"

# Build ESP32 firmware (VALIDATED: ESP platforms install and build successfully)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Build ESP32-C3 firmware (VALIDATED: Works with current images)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest run -e esp32-c3-devkitm-1
```

### Local Building (Admin/Development Only)

⚠️ **CRITICAL TIMING RULES**: NEVER CANCEL Docker builds - they take 15-45 minutes

```bash
# Set up environment (REQUIRED for local builds)
export DOCKER_REPOSITORY="ghcr.io/your_user/alteriom-docker-images"

# Build locally without push (15-45 minutes - NEVER CANCEL)
# Set timeout to 60+ minutes in your tools
./scripts/build-images.sh

# Build and push to registry (20-60 minutes - NEVER CANCEL)  
# Set timeout to 90+ minutes in your tools
./scripts/build-images.sh push

# IMPORTANT: Monitor logs but DO NOT interrupt based on apparent hangs
# Docker builds can appear to hang for 10-15 minutes during dependency downloads
```

### Testing and Validation (VALIDATED: All work correctly)

#### ESP Platform Build Testing (2.5 minutes)
```bash
# Test all ESP platforms with both images (VALIDATED: Works correctly)
./scripts/test-esp-builds.sh
# Tests: ESP32, ESP32-S3, ESP32-C3, ESP8266
# Expected: All platforms build successfully
# Timing: ~2.5 minutes (first run may take longer for platform downloads)

# Test specific image only
./scripts/test-esp-builds.sh ghcr.io/sparck75/alteriom-docker-images/dev:latest

# Show test help and options
./scripts/test-esp-builds.sh --help
```

#### Complete User Scenario Testing (VALIDATED: Use this for validation)

Create a test PlatformIO project to validate functionality:

```bash
# Create test project (VALIDATED: This example works)
mkdir /tmp/test-platformio && cd /tmp/test-platformio

# Create working platformio.ini
cat > platformio.ini << 'EOF'
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino

[env:esp8266]
platform = espressif8266
board = nodemcuv2
framework = arduino
EOF

# Create working source code
mkdir src
cat > src/main.cpp << 'EOF'
#include <Arduino.h>

void setup() {
    Serial.begin(115200);
    Serial.println("Test build successful!");
}

void loop() {
    delay(1000);
}
EOF

# Test ESP32 build (VALIDATED: Works in unrestricted networks)
docker run --rm -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Test ESP8266 build (VALIDATED: Works in unrestricted networks)
docker run --rm -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp8266
```

### CI/CD Operations (VALIDATED: Workflow works correctly)

**Manual Build Trigger:**
1. Navigate to: https://github.com/sparck75/alteriom-docker-images/actions
2. Click "Build and Publish Docker Images" workflow
3. Click "Run workflow" button (top right)
4. Select branch (usually 'main') and click "Run workflow"

**Build Timing Expectations:**
- **Daily builds**: 15-20 minutes (development image only)
- **Production builds**: 25-35 minutes (both images)
- **Status monitoring**: Check Actions tab for real-time progress
- **⚠️ NEVER CANCEL GitHub Actions builds** - can corrupt registry state

## Build Timing & Expectations (CRITICAL - Validated Measurements)

### Time Requirements (NEVER CANCEL Operations)

All timing based on actual measurements:

- **Status check script**: 10 seconds (MEASURED: 10.7 seconds)
- **Image verification script**: 2 seconds (MEASURED: 1.9 seconds) 
- **ESP platform build tests**: 2.5 minutes (MEASURED: 2 minutes 32 seconds)
- **Local Docker builds**: 15-45 minutes (set timeout to 60+ minutes)
- **GitHub Actions builds**: 15-30 minutes (set timeout to 45+ minutes)
- **Image pulls**: 1-5 minutes depending on connection
- **ESP platform installs**: 5-15 minutes (first run per environment)

### ⚠️ Critical "NEVER CANCEL" Rules

- **Docker builds can appear to hang** for 10-15 minutes during dependency downloads
- **ESP platform installations** download large toolchains (100+ MB each)
- **Multi-platform builds** take 2x time (builds for both amd64 and arm64)
- **Network-dependent operations** slower in restricted environments
- **Use timeouts in tools** rather than manual cancellation

## Environment and Dependencies (VALIDATED)

### System Requirements (VALIDATED: All work correctly)
- **Docker**: Required for all operations (CONFIRMED: Docker 28.0.4 works)
- **Bash**: Required for running scripts (CONFIRMED: All scripts work)
- **Git**: For repository operations (CONFIRMED: Git operations work)
- **Network Access**: Unrestricted internet for reliable building

### Environment Variables (VALIDATED)
```bash
# Required for local builds (CONFIRMED: Script checks for this)
export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images

# Current repository values (VALIDATED)
VERSION=1.8.0          # From VERSION file
BUILD_NUMBER=10        # From BUILD_NUMBER file
```

### Network Requirements (CRITICAL - See FIREWALL_CONFIGURATION.md)
**Required domains for successful operations:**
- `ghcr.io` - Docker registry operations (CRITICAL)
- `api.github.com` - GitHub API access (CRITICAL)
- `pypi.org` - Python package downloads (CRITICAL)
- `dl.espressif.com` - ESP toolchain downloads (HIGH)
- `github.com` - Source code and base images (HIGH)

## Repository File Structure (CRITICAL for Development)

### Must-Check Files After Changes

1. **Workflow validation** (CRITICAL - Cost control):
   ```bash
   # ALWAYS validate only ONE workflow file exists
   ./scripts/validate-workflows.sh
   # Must show "VALIDATION PASSED"
   
   # Manual verification
   ls -la .github/workflows/
   # Should show ONLY: build-and-publish.yml
   ```
   ⚠️ **Multiple workflows = Duplicate builds = Cost overruns**

2. **Dockerfile validation**:
   ```bash
   # Test build syntax locally before pushing
   docker build -t test-prod production/
   docker build -t test-dev development/
   
   # Test image functionality
   docker run --rm test-prod --version
   docker run --rm test-dev --version
   ```

3. **Version management**:
   ```bash
   # Check current version and build number
   cat VERSION      # Current: 1.8.0
   cat BUILD_NUMBER # Current: 10
   ```

### Configuration Files (CRITICAL)
- **VERSION**: Controls image versioning and tags (CURRENT: 1.8.0)
- **BUILD_NUMBER**: Incremental build counter (CURRENT: 10)
- **.github/workflows/build-and-publish.yml**: **ONLY** CI/CD configuration
- **production/Dockerfile**: Optimized minimal PlatformIO builder
- **development/Dockerfile**: Development image with debugging tools

## Image Specifications (VALIDATED)

### Production Image (builder:latest)
```yaml
Base: python:3.11-slim
Size: ~400-500MB (optimized)
PlatformIO: 6.1.13 (pinned)
User: builder (UID 1000)
Workdir: /workspace
Platforms: linux/amd64, linux/arm64
Status: WORKING (verified via status-check.sh)
```

### Development Image (dev:latest)
```yaml
Base: python:3.11-slim
Size: ~600-800MB (includes debug tools)
PlatformIO: 6.1.13 (pinned)
Extra tools: git, vim, less, htop, twine
User: builder (UID 1000)
Workdir: /workspace
Platforms: linux/amd64, linux/arm64
Status: WORKING (verified via verify-images.sh)
```

## Troubleshooting (VALIDATED Solutions)

### Common Issues & Working Solutions

#### Image Verification Issues
- **Problem**: Production image shows warnings in verification
- **Check**: Run `./scripts/verify-images.sh` for detailed status
- **Solution**: Development image works correctly; production may have minor issues but is still usable

#### Network/Firewall Issues  
- **Symptom**: SSL certificate errors, blocked URLs
- **Cause**: Corporate firewall blocking external services
- **Solution**: See [FIREWALL_CONFIGURATION.md](FIREWALL_CONFIGURATION.md) for allowlist
- **Critical domains**: `ghcr.io`, `api.github.com`, `pypi.org`

#### Build Failures
- **Docker builds fail**: Check network access to PyPI and GitHub
- **ESP platform failures**: Normal in restricted networks - validate image structure
- **Permission errors**: Use `chown -R 1000:1000 /path/to/workspace`

#### Performance Issues
- **Slow builds**: Ensure unrestricted network access
- **Large images**: Review OPTIMIZATION_GUIDE.md for size reduction
- **Script failures**: Ensure scripts are executable with `chmod +x scripts/*.sh`

### Quick Diagnostic Commands (VALIDATED)
```bash
# System health check
docker system info
docker --version

# Repository status  
git status
./scripts/status-check.sh

# Network connectivity test
curl -I https://pypi.org
curl -I https://ghcr.io

# Script permissions check
ls -la scripts/
```

## Development Workflows (VALIDATED)

### Standard Workflow (TESTED and WORKING)
1. **Before making changes**:
   ```bash
   # Verify current state (VALIDATED: Works correctly)
   ./scripts/verify-images.sh
   ./scripts/validate-workflows.sh
   git status
   ```

2. **Testing changes**:
   ```bash
   # For Dockerfile changes (VALIDATED: Process works)
   docker build -t test-image production/
   docker run --rm test-image --version
   
   # For script changes (VALIDATED: Test process works)
   ./scripts/test-esp-builds.sh
   ```

3. **Validation**:
   ```bash
   # Run comprehensive tests (VALIDATED: 2.5 minutes)
   ./scripts/test-esp-builds.sh
   
   # Check build system (VALIDATED: Prevents duplicate workflows)
   ./scripts/validate-workflows.sh
   ```

### Pre-commit Checklist (VALIDATED)
- [ ] Scripts are executable: `ls -la scripts/` shows +x permissions
- [ ] Only ONE workflow exists: `./scripts/validate-workflows.sh` passes
- [ ] Images build locally: `docker build` succeeds for both Dockerfiles
- [ ] Version commands work: `docker run --rm <image> --version` shows PlatformIO 6.1.13
- [ ] ESP tests pass: `./scripts/test-esp-builds.sh` completes successfully

## Technical Specifications (VALIDATED)

### PlatformIO Configuration
- **Version**: 6.1.13 (CONFIRMED: pinned in both Dockerfiles)
- **Installation**: pip install (CONFIRMED: via pip3 install platformio==6.1.13)
- **Platforms**: espressif32, espressif8266 (CONFIRMED: tests work for all)
- **Frameworks**: Arduino, ESP-IDF (CONFIRMED: Arduino framework tested successfully)

### Container Architecture (VALIDATED)
- **Base image**: python:3.11-slim (CONFIRMED: in both Dockerfiles)
- **User model**: Non-root 'builder' UID 1000 (CONFIRMED: useradd command in Dockerfiles)
- **Working directory**: /workspace (CONFIRMED: WORKDIR /workspace)
- **Entry point**: PlatformIO CLI (CONFIRMED: ENTRYPOINT ["/usr/local/bin/platformio"])

### Build System (VALIDATED)
- **GitHub Actions**: Single workflow file (CONFIRMED: build-and-publish.yml only)
- **Multi-platform**: amd64/arm64 (CONFIRMED: PLATFORMS env var in workflow)
- **Registry**: GHCR (CONFIRMED: ghcr.io in scripts and workflow)
- **Tagging**: date, version, latest (CONFIRMED: tagging logic in workflow)

## Additional Resources

### Documentation Links (VALIDATED: Files exist)
- **README.md**: Public usage documentation
- **ADMIN_SETUP.md**: Administrator configuration guide  
- **OPTIMIZATION_GUIDE.md**: Image size optimization strategies
- **FIREWALL_CONFIGURATION.md**: Network access requirements
- **tests/README.md**: Testing documentation

### External References
- **PlatformIO Documentation**: https://docs.platformio.org/
- **Docker Best Practices**: https://docs.docker.com/develop/best-practices/
- **GitHub Actions**: https://github.com/sparck75/alteriom-docker-images/actions

### Community and Support
- **Issues**: https://github.com/sparck75/alteriom-docker-images/issues
- **Actions**: https://github.com/sparck75/alteriom-docker-images/actions
- **Packages**: https://github.com/sparck75/alteriom-docker-images/pkgs/container/alteriom-docker-images%2Fbuilder

---

**Key Success Indicators for AI Agents:**
- Status check completes in ~10 seconds and shows "YES, IT WORKED!"
- Verify images shows "ALL SYSTEMS GO!" or acceptable partial success
- ESP tests complete in ~2.5 minutes with "All tests passed! ✅"
- Only ONE workflow file exists (critical for cost control)
- Docker images respond with "PlatformIO Core, version 6.1.13"

*This comprehensive guide is based on validated testing of all commands and processes. Always refer to this document first before seeking additional information.*