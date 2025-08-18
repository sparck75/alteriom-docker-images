# alteriom-docker-images Development Instructions

Always follow these instructions precisely and only fall back to additional search and context gathering if the information in the instructions is incomplete or found to be in error.

Pre-built PlatformIO builder images for the Alteriom project (ESP32 / ESP8266). Contains production and development Docker images with PlatformIO and required build tools.

## Overview
This repository provides optimized Docker images for ESP32/ESP8266 firmware development using PlatformIO. The images are automatically built via GitHub Actions and published to GitHub Container Registry (GHCR). Use these instructions for all development, troubleshooting, and maintenance tasks.

## Quick Reference

### Essential Commands
```bash
# Verify images are published and working
./scripts/verify-images.sh              # Comprehensive check (30-60s)
./scripts/status-check.sh               # Quick status (10-15s)

# Pull and test production image
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Build firmware with Docker image
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Local build (admin only)
export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images
./scripts/build-images.sh              # Build only (15-45min)
./scripts/build-images.sh push         # Build and push (20-60min)
```

### Image Information
- **Production**: `ghcr.io/sparck75/alteriom-docker-images/builder:latest` (minimal, optimized)
- **Development**: `ghcr.io/sparck75/alteriom-docker-images/dev:latest` (with debug tools)
- **PlatformIO Version**: 6.1.13 (pinned for stability)
- **Base**: python:3.11-slim
- **Platforms**: linux/amd64, linux/arm64
- **Version Management**: ✅ Fully automated semantic versioning (current: 1.5.1)

### Automated Versioning Commands
```bash
# Check current version
cat VERSION

# View automated versioning documentation
cat AUTOMATED_VERSIONING.md

# Use semantic commits for automatic version bumping
git commit -m "feat: add new ESP32-S3 support"     # Minor bump
git commit -m "fix: resolve Docker build timeout"  # Patch bump  
git commit -m "feat!: breaking API changes"        # Major bump
```

## Working Effectively

### Prerequisites and Setup
- **Docker**: Required for all operations - ensure Docker is installed and running
- **Network Access**: Unrestricted internet access required for reliable builds (PyPI, GitHub, etc.)
  - See [FIREWALL_CONFIGURATION.md](../FIREWALL_CONFIGURATION.md) for complete firewall allowlist requirements
  - Critical domains: `api.github.com`, `ghcr.io`, `img.shields.io`, `pypi.org`
- **Environment**: Set `DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images` for local builds
- **Permissions**: Ensure Docker can run without sudo or use appropriate sudo commands

### Workflow Priority
1. **ALWAYS** verify images before use: `./scripts/verify-images.sh`
2. **USE SEMANTIC COMMITS** for automated version management
3. **NEVER CANCEL** long-running builds (can take 15-90 minutes)
4. **TEST IMMEDIATELY** after any Dockerfile changes
5. **USE TIMEOUTS** of 60+ minutes for local builds, 45+ minutes for CI builds

### Version Management Best Practices
- **✅ Automated**: Version numbers increment automatically on PR merges
- **✅ Semantic**: Use conventional commit messages for proper version bumping
- **✅ Manual Override**: Emergency version fixes supported with `[skip ci]`
- **⚠️ Important**: Never manually edit VERSION file without `[skip ci]` flag

### Image Verification and Status
- **Comprehensive check**: `./scripts/verify-images.sh` (30-60 seconds)
  - Checks GitHub Actions workflow status
  - Verifies image availability and functionality
  - Must show "ALL SYSTEMS GO!" for complete success
- **Quick status**: `./scripts/status-check.sh` (10-15 seconds)
  - Basic availability check
  - Useful for rapid validation
- **Version verification**: Both images should output "PlatformIO Core, version 6.1.13"
  ```bash
  docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
  docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version
  ```

### Docker Image Usage

#### Production Image (Recommended)
```bash
# Pull the optimized production builder
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest

# Verify functionality
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Build firmware (ESP32 example)
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Build with specific environment
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e diag-esp32-c3
```

#### Development Image (Debug/Development)
```bash
# Pull development image with extra tools
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest

# Use for interactive debugging
docker run -it --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest bash

# Run with debugging enabled
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest run -e esp32dev -v
```

#### Common Usage Patterns
- **Mount workspace**: Always use `-v ${PWD}:/workspace` to mount your project
- **Remove containers**: Use `--rm` to automatically clean up containers
- **User permissions**: Images run as UID 1000, use `chown -R 1000:1000` if needed
- **Interactive mode**: Add `-it` for interactive shells or debugging

### Local Building (Admin/Development)

#### ⚠️ Important Considerations
- **CRITICAL**: Local builds often fail due to SSL certificate issues in restricted network environments
- **Time Requirements**: Build processes take 15-90 minutes - **NEVER CANCEL**
- **Network Requirements**: Unrestricted internet access required for reliable builds
- **Environment Setup**: Must export `DOCKER_REPOSITORY` before building

#### Build Commands
```bash
# Set up environment (required)
export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images

# Build locally without push (15-45 minutes)
./scripts/build-images.sh
# Set timeout to 60+ minutes - NEVER CANCEL

# Build and push to registry (20-60 minutes)
./scripts/build-images.sh push
# Set timeout to 90+ minutes - NEVER CANCEL

# Build and push development image only (10-30 minutes) - for daily builds
./scripts/build-images.sh dev-only
# Set timeout to 45+ minutes - NEVER CANCEL

# Check build status
./scripts/status-check.sh
```

#### Troubleshooting Local Builds
- **SSL certificate errors**: Normal in restricted environments
  - Solution: Run builds in unrestricted network environment
- **Timeout errors**: Increase timeout settings, don't cancel
- **Permission errors**: Ensure Docker permissions are correctly configured
- **Build failures**: Check network connectivity and Docker daemon status

### CI/CD Operations

#### Automatic Triggers
The GitHub Actions workflow (`.github/workflows/build-and-publish.yml`) triggers automatically on:
- **PR merges** to main branch (builds both production and development images)
- **Daily builds** at 02:00 UTC (development image only - cost optimized)
- **Manual dispatch** via GitHub Actions interface (builds both images)

#### Manual Build Process
1. Navigate to [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions)
2. Click "Build and Publish Docker Images" workflow
3. Click "Run workflow" button (top right)
4. Select branch (usually `main`)
5. Click "Run workflow" to start

#### Build Timing and Monitoring
- **Daily builds**: 15-20 minutes typically (development image only)
- **Production builds**: 25-35 minutes typically (both images)
- **Status**: Monitor via Actions tab for real-time progress
- **Artifacts**: Built images published to GHCR automatically
- **Tags**: Creates `:latest`, version, and date tags. Daily builds also create `:1.6.0-dev-YYYYMMDD` tags
- **⚠️ Never cancel builds** - can corrupt registry state

#### Post-Build Verification
```bash
# Wait 2-3 minutes after CI completion, then verify
./scripts/verify-images.sh

# Check new images are pullable
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest
```

## Testing and Validation

### Mandatory Validation Steps
**ALWAYS perform these checks after any changes:**

1. **Version Verification**
   ```bash
   # Both should output "PlatformIO Core, version 6.1.13"
   docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
   docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version
   ```

2. **Comprehensive System Check**
   ```bash
   # Must show "ALL SYSTEMS GO!" for complete success
   ./scripts/verify-images.sh
   ```

3. **Basic Functionality Test**
   ```bash
   # Should complete without errors (may fail in restricted networks)
   docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --help
   ```

### Complete Development Workflow Testing

#### Create Test PlatformIO Project
```bash
# Set up test environment
mkdir /tmp/test-platformio && cd /tmp/test-platformio

# Create platformio.ini
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

# Create source code
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
```

#### Test Build Process
```bash
# Test ESP32 build (may fail in restricted networks but validates image)
docker run --rm -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# Test ESP8266 build
docker run --rm -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp8266

# Test with development image
docker run --rm -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/dev:latest run -e esp32dev -v
```

#### Expected Behavior
- Commands should attempt to build (may fail due to network restrictions)
- No Docker-related errors (image not found, permission denied, etc.)
- PlatformIO should start and attempt platform installation
- Clean error messages if network-related failures occur

### Automated Testing Scripts

#### Available Test Scripts
```bash
# Test ESP platform builds with current images
./scripts/test-esp-builds.sh

# Verify admin setup is correct
./scripts/verify-admin-setup.sh

# Check for deprecated PlatformIO commands
./scripts/check-deprecated-commands.sh

# Compare image optimization results
./scripts/compare-image-optimizations.sh
```

#### Test Script Usage
- **Run before releases**: Always run `./scripts/test-esp-builds.sh`
- **Run after Dockerfile changes**: Test both images with sample builds
- **Run in CI**: Automated testing via GitHub Actions
- **Network considerations**: Some tests may fail in restricted environments

### Build Timing and Performance Expectations

#### Time Requirements (Never Cancel Operations)
- **Local Docker builds**: 15-45 minutes (set timeout to 60+ minutes)
- **GitHub Actions builds**: 15-30 minutes (set timeout to 45+ minutes)
- **Image pulls**: 1-5 minutes (depending on connection)
- **Verification scripts**: 30-60 seconds
- **ESP platform installs**: 5-15 minutes (first run per environment)

#### Performance Guidelines
- **Multi-platform builds**: Add 10-20 minutes for ARM64 builds
- **Network dependency**: Slower in restricted environments
- **Platform caching**: Subsequent builds faster due to Docker layer caching
- **Registry uploads**: 5-10 minutes depending on image size and network

#### ⚠️ Critical Timing Rules
- **NEVER CANCEL** any build or long-running command
- **Allow extra time** for network-dependent operations
- **Monitor logs** but don't interrupt based on apparent hangs
- **Use timeouts** rather than manual cancellation

## Repository Structure and Key Files

### Directory Organization
```
alteriom-docker-images/
├── .github/
│   ├── workflows/
│   │   ├── build-and-publish.yml    # Main CI/CD pipeline
│   │   └── publish-mydocker.yml     # Alternative publishing workflow
│   ├── copilot-instructions.md     # This file - Copilot development guide
│   └── custom-instruction.md       # General AI agent instructions
├── production/
│   └── Dockerfile                  # Optimized minimal PlatformIO builder
├── development/
│   └── Dockerfile                  # Development tools + PlatformIO + debugging
├── scripts/
│   ├── build-images.sh            # Build and push helper
│   ├── verify-images.sh           # Comprehensive verification
│   ├── status-check.sh            # Quick status check  
│   ├── test-esp-builds.sh         # ESP platform build testing
│   ├── verify-admin-setup.sh      # Admin configuration verification
│   ├── check-deprecated-commands.sh # PlatformIO command validation
│   └── compare-image-optimizations.sh # Image size analysis
├── tests/                         # Test configurations and validation
├── ADMIN_SETUP.md                # Admin configuration guide
├── COPILOT_ADMIN_SETUP.md        # Copilot-specific admin setup
├── OPTIMIZATION_GUIDE.md         # Image optimization documentation
├── README.md                     # Public usage documentation
├── VERSION                       # Current version for builds
└── LICENSE                       # MIT license
```

### Critical Files for Development

#### Must-Check After Changes
1. **GitHub Actions logs**: [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions)
   - Monitor build progress and failures
   - Check workflow execution details
   - Verify artifact publishing

2. **Dockerfile validation**: 
   ```bash
   # Verify syntax and build locally
   docker build -t test-build production/
   docker build -t test-build-dev development/
   ```

3. **Version and image testing**:
   ```bash
   # After any Dockerfile changes
   docker run --rm test-build --version
   docker run --rm test-build-dev --version
   ```

#### Configuration Files
- **VERSION**: Controls image versioning and tags
- **.github/workflows/build-and-publish.yml**: Main CI/CD configuration
- **production/Dockerfile**: Production image definition  
- **development/Dockerfile**: Development image with extra tools

#### Documentation Files
- **README.md**: Public-facing usage documentation
- **ADMIN_SETUP.md**: Administrator setup and configuration
- **OPTIMIZATION_GUIDE.md**: Image size optimization strategies
- **.github/copilot-instructions.md**: This comprehensive development guide

## Environment and Dependencies

### System Requirements
- **Docker**: Required for all build and test operations
  - Version: Docker 20.10+ recommended
  - BuildKit support for multi-platform builds
  - Sufficient disk space (2-5GB for builds)
- **Bash**: Required for running helper scripts
- **Git**: For repository operations and CI integration
- **Network Access**: Unrestricted internet required for reliable building
  - PyPI access for pip package installations
  - GitHub access for source code and base images
  - Registry access for publishing (GHCR)

### Environment Variables
```bash
# Required for local builds
export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images

# Optional build configuration
export PLATFORMS=linux/amd64,linux/arm64  # Multi-platform build targets
export VERSION=1.4.0                      # Override version (read from VERSION file)
```

### GitHub Actions Configuration
- **Required Repository Secrets**:
  - `REGISTRY_USERNAME`: GitHub username or organization
  - `REGISTRY_TOKEN`: GitHub Personal Access Token with packages:write
  - `DOCKER_REPOSITORY`: Target registry path (defaults to ghcr.io/owner/alteriom-docker-images)
- **Required Permissions**:
  - Actions: read/write (for workflow execution)
  - Packages: write (for GHCR publishing)
  - Contents: read (for repository access)

### Network and Security Considerations
- **Restricted environments**: SSL certificate errors are common
  - Build in unrestricted network when possible
  - Use pre-published images for development
  - See [FIREWALL_CONFIGURATION.md](../FIREWALL_CONFIGURATION.md) for complete allowlist requirements
- **Registry authentication**: Uses GitHub token automatically in CI
- **Multi-platform builds**: Requires BuildKit and QEMU emulation
- **Firewall considerations**: Ensure Docker registry access (443/tcp)
- **Common firewall blocks**: `api.github.com`, `img.shields.io`, `ghcr.io`, `pypi.org`

## Image Registry and Distribution

### GitHub Container Registry (GHCR) Details
- **Registry URL**: `ghcr.io`
- **Production image**: `ghcr.io/sparck75/alteriom-docker-images/builder:latest`
- **Development image**: `ghcr.io/sparck75/alteriom-docker-images/dev:latest`
- **Authentication**: Uses GitHub Personal Access Token
- **Visibility**: Public registry, no authentication required for pulling
- **Multi-platform support**: Builds for linux/amd64 and linux/arm64

### Image Tagging Strategy
- **Latest tag**: `:latest` (always points to most recent build)
- **Date tags**: `:YYYYMMDD` (specific build dates for reproducibility)
- **Version tags**: `:v1.4.0` (semantic versioning from VERSION file)
- **SHA tags**: `:sha-<commit>` (for exact commit tracking)

### Image Specifications
```yaml
Production Image (builder):
  - Base: python:3.11-slim
  - Size: ~400-500MB (optimized)
  - PlatformIO: 6.1.13 (pinned)
  - User: builder (UID 1000)
  - Workdir: /workspace
  - Platforms: linux/amd64, linux/arm64

Development Image (dev):
  - Base: python:3.11-slim  
  - Size: ~600-800MB (includes debug tools)
  - PlatformIO: 6.1.13 (pinned)
  - Extra tools: git, vim, curl, debugging utilities
  - User: builder (UID 1000)
  - Workdir: /workspace
  - Platforms: linux/amd64, linux/arm64
```

### Registry Operations
```bash
# Pull specific versions
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:20240101
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:v1.4.0

# Check image information
docker inspect ghcr.io/sparck75/alteriom-docker-images/builder:latest

# List image layers and size
docker history ghcr.io/sparck75/alteriom-docker-images/builder:latest
```

## Troubleshooting and Common Issues

### Build and Network Issues
- **SSL certificate errors**: 
  - **Cause**: Common in restricted network environments
  - **Solution**: Run builds in unrestricted network environment
  - **Workaround**: Use pre-published images for development
  - **Command**: Test with `curl -I https://pypi.org` to verify network access
  - **Documentation**: See [FIREWALL_CONFIGURATION.md](../FIREWALL_CONFIGURATION.md) for complete allowlist

- **Firewall blocks during Copilot operations**:
  - **Symptom**: Warnings about blocked URLs (api.github.com, img.shields.io)
  - **Cause**: Corporate firewall blocking external services
  - **Solution**: Add required domains to firewall allowlist
  - **Critical domains**: `api.github.com`, `ghcr.io`, `img.shields.io`, `pypi.org`
  - **Action**: Create GitHub issue and assign to @sparck75 for new blocks

- **Docker build failures**:
  - **Cause**: Insufficient resources, network timeouts, base image issues
  - **Solution**: Increase Docker memory/disk, check network, update base images
  - **Command**: `docker system prune -a` to free space

- **Registry authentication failures**:
  - **Cause**: Invalid GitHub token, incorrect permissions
  - **Solution**: Regenerate token with packages:write permission
  - **Check**: Verify `docker login ghcr.io` works manually

### Image and Container Issues
- **Image not found errors**:
  - **Check**: Run `./scripts/verify-images.sh` to check publication status
  - **Monitor**: Check [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions) for build progress
  - **Verify**: Ensure correct image name and tag

- **Permission denied in container**:
  - **Cause**: File ownership mismatch between host and container
  - **Solution**: `chown -R 1000:1000 /path/to/workspace` (container runs as UID 1000)
  - **Alternative**: Use `docker run --user $(id -u):$(id -g)` for current user

- **Container startup failures**:
  - **Check**: Verify Docker daemon is running
  - **Test**: Run simple test: `docker run --rm hello-world`
  - **Logs**: Use `docker logs <container_id>` for error details

### CI/CD and Workflow Issues
- **GitHub Actions workflow failures**:
  - **Check**: [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions) for detailed logs
  - **Common causes**: Registry authentication, BuildKit configuration, resource limits
  - **Debug**: Re-run failed jobs with debug logging enabled

- **Publishing failures**:
  - **Verify**: Repository secrets are correctly configured
  - **Check**: Packages:write permission enabled for Actions
  - **Test**: Manual push with `docker push` to verify credentials

- **Multi-platform build issues**:
  - **Cause**: QEMU emulation problems, platform-specific dependencies
  - **Solution**: Test single platform first, then add multi-platform
  - **Command**: Use `docker buildx ls` to verify builder configuration

### Development and Testing Issues
- **PlatformIO build failures in container**:
  - **Expected**: May fail in restricted networks (PyPI/GitHub access required)
  - **Validate**: Ensure image structure is correct even if build fails
  - **Network test**: `docker run --rm <image> ping pypi.org`

- **Script execution failures**:
  - **Permissions**: Ensure scripts are executable: `chmod +x scripts/*.sh`
  - **Path issues**: Run scripts from repository root directory
  - **Dependencies**: Verify Docker is running and accessible

### Performance and Resource Issues
- **Slow build times**:
  - **Optimize**: Use Docker BuildKit and layer caching
  - **Network**: Ensure unrestricted internet access
  - **Resources**: Increase Docker memory allocation

- **Large image sizes**:
  - **Check**: Review `OPTIMIZATION_GUIDE.md` for size reduction strategies
  - **Compare**: Use `./scripts/compare-image-optimizations.sh`
  - **Analyze**: Use `docker history <image>` to identify large layers

### Quick Diagnostic Commands
```bash
# System health check
docker system info
docker system df

# Image verification
./scripts/verify-images.sh
./scripts/status-check.sh

# Build environment check
echo $DOCKER_REPOSITORY
docker buildx ls

# Network connectivity test
curl -I https://pypi.org
curl -I https://ghcr.io

# Repository status
git status
git log --oneline -5
```

## Development Workflows and Best Practices

### Standard Development Workflow
1. **Before making changes**:
   ```bash
   # Verify current state
   ./scripts/verify-images.sh
   git status
   docker system info
   ```

2. **Making Dockerfile changes**:
   ```bash
   # Test build locally first
   docker build -t test-image production/
   docker run --rm test-image --version
   
   # Test functionality
   docker run --rm -v ${PWD}:/workspace test-image --help
   ```

3. **Testing and validation**:
   ```bash
   # Run comprehensive tests
   ./scripts/test-esp-builds.sh
   ./scripts/verify-admin-setup.sh
   
   # Create test project and validate
   mkdir /tmp/test && cd /tmp/test
   # ... create test project as documented above
   ```

4. **Committing and deploying**:
   ```bash
   # Commit changes
   git add .
   git commit -m "feat: improve Dockerfile optimization"
   git push
   
   # Monitor CI build
   # Check Actions tab for build progress
   
   # Verify deployment
   sleep 300  # Wait for CI completion
   ./scripts/verify-images.sh
   ```

### Code Review and Quality Assurance

#### Pre-commit Checklist
- [ ] Dockerfile builds locally without errors
- [ ] Images produce correct `--version` output  
- [ ] No increase in image size unless justified
- [ ] All scripts remain executable
- [ ] Documentation updated if needed
- [ ] CI/CD workflow tested if modified

#### Review Guidelines
- **Dockerfile changes**: Always test both production and development images
- **Script changes**: Verify all helper scripts work correctly
- **Workflow changes**: Test with workflow_dispatch before merging
- **Documentation**: Ensure examples remain current and accurate

### Security Best Practices
- **Base images**: Keep python:3.11-slim updated regularly
- **Dependencies**: Pin versions for reproducibility (PlatformIO 6.1.13)
- **User permissions**: Run as non-root user (UID 1000) in containers
- **Secrets**: Never commit tokens or credentials to repository
- **Network**: Minimize exposed ports and network access in containers

### Performance Optimization
- **Docker layers**: Minimize layers and optimize layer caching
- **Image size**: Regular optimization using techniques in OPTIMIZATION_GUIDE.md
- **Build time**: Use BuildKit and multi-stage builds where beneficial
- **Registry**: Use appropriate tagging strategy for caching

### Maintenance and Updates

#### Regular Maintenance Tasks
- **Monthly**: Update base images and rebuild
- **Quarterly**: Review and update PlatformIO version
- **As needed**: Update documentation and examples
- **On security alerts**: Immediately update affected dependencies

#### Version Management
- **VERSION file**: Update for significant changes
- **CHANGELOG**: Document changes and breaking changes
- **Tags**: Use semantic versioning for releases
- **Deprecation**: Provide clear migration paths for breaking changes

## Technical Specifications

### PlatformIO Configuration
- **Version**: 6.1.13 (pinned for stability and reproducibility)
- **Installation method**: pip install (not system package manager)
- **Platforms included**: espressif32, espressif8266 (when built in unrestricted environment)
- **Frameworks supported**: Arduino, ESP-IDF, PlatformIO native
- **Build tools**: Included toolchains for ESP32/ESP8266

### Container Architecture
- **Base image**: python:3.11-slim (Debian-based, minimal)
- **Architecture**: Multi-platform (linux/amd64, linux/arm64)
- **User model**: Non-root user 'builder' (UID 1000, GID 1000)
- **Working directory**: `/workspace` (mount point for projects)
- **Entry point**: PlatformIO CLI (`pio` command)

### Build System Integration
- **GitHub Actions**: Automated builds on push, schedule, and manual trigger
- **Docker BuildKit**: Multi-platform builds with advanced caching
- **Registry**: GitHub Container Registry (GHCR) for public distribution
- **Tagging**: Automatic tagging with date, version, and latest tags

### Additional Resources and References

### Documentation Links
- **Repository README**: [Usage documentation and quick start guide](README.md)
- **Admin Setup**: [Administrator configuration guide](ADMIN_SETUP.md)
- **Optimization Guide**: [Image size optimization strategies](OPTIMIZATION_GUIDE.md)
- **Firewall Configuration**: [Complete network access requirements](FIREWALL_CONFIGURATION.md)
- **GitHub Actions**: [Workflow configuration](.github/workflows/build-and-publish.yml)

### Copilot-Specific Resources
- **Firewall Issues**: When Copilot encounters blocked URLs, refer to [FIREWALL_CONFIGURATION.md](../FIREWALL_CONFIGURATION.md)
- **Network Troubleshooting**: Use the verification commands in the firewall configuration document
- **New Blocks**: Create GitHub issue with firewall block template and assign to @sparck75

### External References
- **PlatformIO Documentation**: [https://docs.platformio.org/](https://docs.platformio.org/)
- **Docker Best Practices**: [https://docs.docker.com/develop/best-practices/](https://docs.docker.com/develop/best-practices/)
- **GitHub Container Registry**: [https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### Community and Support
- **Issues**: Report bugs and request features via [GitHub Issues](https://github.com/sparck75/alteriom-docker-images/issues)
- **Discussions**: Community discussions via [GitHub Discussions](https://github.com/sparck75/alteriom-docker-images/discussions)
- **Releases**: Track releases and changelogs via [GitHub Releases](https://github.com/sparck75/alteriom-docker-images/releases)

---

*This comprehensive guide covers all aspects of development with the alteriom-docker-images repository. Always refer to this document first before seeking additional information.*