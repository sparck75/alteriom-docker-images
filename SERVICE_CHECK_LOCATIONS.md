# 🔍 Service Check Implementation - Complete Location Guide

This document provides a comprehensive guide to **exactly where** service checks are implemented in the ESP32/ESP8266 Docker Images repository and how to access them.

## 📍 Primary Service Check Locations

### 1. 🛡️ Main Service Monitoring Script
**Location**: [`scripts/service-monitoring.sh`](scripts/service-monitoring.sh)  
**Purpose**: Comprehensive service validation with 6 categories  
**Enhanced Features**: Now includes ESP platform support and network connectivity validation with api.registry.platformio.org integration

```bash
# Run comprehensive service monitoring (2-5 minutes)
./scripts/service-monitoring.sh

# Output: Detailed dashboard and reports in service-monitoring-results/
```

**Service Categories Validated:**
1. **Image Availability** - Registry connectivity and metadata validation
2. **Health Check Validation** - Docker HEALTHCHECK functionality testing
3. **PlatformIO Service** - Core ESP32/ESP8266 functionality verification
4. **Container Runtime** - Execution behavior and command processing
5. **ESP Platform Support** - Platform installation and availability (NEW)
6. **Network Connectivity** - External service access validation with api.registry.platformio.org and collector.platformio.org (ENHANCED)

### 2. 🩺 Docker Health Check Implementation
**Locations**: 
- [`production/Dockerfile`](production/Dockerfile) (lines 46-47)
- [`development/Dockerfile`](development/Dockerfile) (lines 46-47)

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/platformio --version || exit 1
```

**Health Check Features:**
- ✅ **30-second intervals** with 10-second timeout
- ✅ **PlatformIO service verification** ensures core functionality
- ✅ **Container orchestration support** for Kubernetes/Docker Swarm
- ✅ **Automatic restart policies** triggered on unhealthy status

### 3. 🚀 CI/CD Service Validation Integration
**Location**: [`.github/workflows/build-and-publish.yml`](/.github/workflows/build-and-publish.yml)  
**Job**: `docker-image-pipeline` → `Comprehensive Service Health Validation` step

```yaml
- name: Comprehensive Service Health Validation
  env:
    DOCKER_REPOSITORY: ${{ env.DOCKER_REPOSITORY }}
    ADVANCED_MODE: 'true'
  run: |
    ./scripts/service-monitoring.sh
```

**CI/CD Integration Features:**
- ✅ **Automated execution** after successful image builds
- ✅ **GitHub Actions artifacts** with 30-day retention
- ✅ **GitHub summary integration** with key metrics display
- ✅ **Advanced mode** with enhanced network validation

### 4. ⚡ Quick Status Check
**Location**: [`scripts/status-check.sh`](scripts/status-check.sh)  
**Purpose**: Fast availability verification (10-15 seconds)

```bash
# Quick status verification
./scripts/status-check.sh
```

## 📊 Service Check Reports and Outputs

### Generated Reports Location
**Directory**: `service-monitoring-results/` (created during execution)

**Report Files:**
- `service-monitoring-dashboard.md` - **Complete service health dashboard**
- `service-monitoring-summary.md` - **Executive summary for CI/CD**
- `image-availability.txt` - Image registry connectivity results
- `health-checks.txt` - Docker HEALTHCHECK validation results
- `platformio-service.txt` - PlatformIO functionality test results
- `container-runtime.txt` - Runtime behavior validation results
- `esp-platform-support.txt` - ESP platform support validation (NEW)
- `network-connectivity.txt` - Network connectivity test results (NEW)

### GitHub Actions Artifacts
**Location**: GitHub Actions → Workflow runs → Artifacts section  
**Artifact Name**: `service-monitoring-results-{run_number}`  
**Retention**: 30 days

**To Access:**
1. Go to [GitHub Actions](https://github.com/sparck75/alteriom-docker-images/actions)
2. Click on any workflow run
3. Scroll to "Artifacts" section
4. Download `service-monitoring-results-{number}`

## 🔧 How to Run Service Checks

### Local Execution
```bash
# Navigate to repository root
cd alteriom-docker-images

# Make scripts executable
chmod +x scripts/service-monitoring.sh
chmod +x scripts/status-check.sh

# Run comprehensive service monitoring
./scripts/service-monitoring.sh

# Or run quick status check
./scripts/status-check.sh
```

### CI/CD Execution
Service checks automatically run in GitHub Actions when:
- ✅ **Push to main branch** (after image builds)
- ✅ **Pull request builds** (after image builds)
- ✅ **Daily builds** (when audit determines build is needed)
- ✅ **Manual workflow dispatch** (after image builds)

### Manual Trigger
1. Go to [GitHub Actions](https://github.com/sparck75/alteriom-docker-images/actions)
2. Click "🚀 ESP32/ESP8266 Enterprise Docker Pipeline"
3. Click "Run workflow"
4. Wait for completion (15-30 minutes)
5. Download service monitoring artifacts

## 📈 Enhanced Service Monitoring Features (v2.0)

### New Capabilities
- 🚀 **ESP Platform Support Testing** - Validates ESP32/ESP8266 platform accessibility
- 🌐 **Network Connectivity Validation** - Tests api.registry.platformio.org and collector.platformio.org access
- 📊 **Performance Metrics** - Command execution timing analysis
- 🎯 **Resource Validation** - Memory constraint testing
- 📋 **Enhanced Reporting** - Comprehensive dashboard with health indicators
- 🔍 **Metadata Analysis** - Image size, layers, and creation date tracking

### Advanced Mode Features
When `ADVANCED_MODE=true` (default in CI/CD):
- Extended timeout values for network operations
- Detailed metadata extraction and analysis
- Enhanced error reporting and diagnostics
- Performance timing measurements
- Resource constraint validation

## 🎯 Understanding Service Check Results

### Health Status Indicators
- 🟢 **EXCELLENT**: All checks passed, minimal warnings
- 🟡 **GOOD**: Most checks passed, some warnings (85%+ success rate)
- 🔴 **NEEDS_ATTENTION**: Multiple failures, requires investigation

### Service Category Status Meanings
- ✅ **Operational**: Service fully functional
- ⚠️ **Limited**: Partial functionality, may have network restrictions
- ❌ **Failed**: Service not functional, requires attention

## 🚨 Troubleshooting Service Check Issues

### Common Issues and Solutions

#### Service Monitoring Script Not Found
```bash
# Ensure you're in repository root
pwd
ls -la scripts/service-monitoring.sh

# Make script executable
chmod +x scripts/service-monitoring.sh
```

#### Docker Images Not Available
```bash
# Check if images exist in registry
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest

# Check GitHub Actions for build status
# https://github.com/sparck75/alteriom-docker-images/actions
```

#### Network-Related Failures
- **api.registry.platformio.org access**: PlatformIO Package Registry API testing
- **collector.platformio.org access**: Expected in restricted environments
- **Platform installation timeouts**: Normal in corporate networks
- **Registry connectivity issues**: Check firewall settings

#### Health Check Failures
```bash
# Test health check command manually
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Expected output: "PlatformIO Core, version 6.1.13"
```

## 📚 Related Documentation

- **[SERVICE_MONITORING.md](SERVICE_MONITORING.md)** - Complete service monitoring guide
- **[README.md](README.md)** - Main usage documentation
- **[ADMIN_SETUP.md](ADMIN_SETUP.md)** - Administrator configuration
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** - Development guidelines

---

## 🎉 Summary

**Service checks are implemented in 4 key locations:**

1. **`scripts/service-monitoring.sh`** - Main comprehensive validation (6 categories)
2. **`production/Dockerfile` & `development/Dockerfile`** - Docker HEALTHCHECK instructions
3. **`.github/workflows/build-and-publish.yml`** - CI/CD integration with artifacts
4. **`scripts/status-check.sh`** - Quick verification utility

**To see service checks in action:**
- Run `./scripts/service-monitoring.sh` locally
- Check GitHub Actions artifacts after workflow runs
- Review `service-monitoring-results/` directory after execution

**Enhanced monitoring now includes ESP platform support validation and network connectivity testing with api.registry.platformio.org and collector.platformio.org access.**

---

*Service Check Implementation Guide v2.1 | Last Updated: August 2025*