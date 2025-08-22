# 🛡️ Service Monitoring & Health Checks

This document explains the comprehensive service monitoring and health check system implemented for ESP32/ESP8266 Docker images.

## Overview

The service monitoring system provides **multi-layered validation** to ensure Docker images are not just available, but fully functional for ESP32/ESP8266 development workflows.

## Service Check Implementation

### 1. Docker HEALTHCHECK Instructions

**Location**: `production/Dockerfile` and `development/Dockerfile` (lines 46-47)

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/platformio --version || exit 1
```

**Purpose**: 
- Validates PlatformIO binary is accessible and functional
- Enables Docker daemon health status reporting
- Supports orchestration system health monitoring
- Triggers automatic restart policies when containers become unhealthy

**Health Check Behavior**:
- **Interval**: 30 seconds between checks
- **Timeout**: 10 seconds per check
- **Start Period**: 5 seconds grace period after container start
- **Retries**: 3 consecutive failures before marking unhealthy

### 2. Service Monitoring Script

**Location**: `scripts/service-monitoring.sh`

**Comprehensive Validation Categories**:

#### Image Availability Check ✅
- Validates images are published and pullable from registry
- Tests both production and development images
- Reports registry connectivity issues

#### Health Check Validation 🩺  
- Starts containers and monitors Docker HEALTHCHECK status
- Validates health check commands execute successfully
- Tests health check timing and reliability

#### PlatformIO Service Functionality 🔧
- Tests core PlatformIO commands (`--version`, `--help`, `platform list`)
- Validates service readiness for ESP32/ESP8266 development
- Handles network restrictions gracefully

#### Container Runtime Validation ⚙️
- Tests container start/stop behavior
- Validates logging functionality
- Ensures containers run as expected

### 3. Quick Status Check

**Location**: `scripts/status-check.sh`

**Enhanced Features**:
- Quick image availability verification
- Basic service functionality testing
- Clear status reporting with actionable guidance
- Integration-ready for CI/CD pipelines

## GitHub Actions Integration

### Workflow Jobs with Improved Naming

- **`enterprise-security-validation`**: Comprehensive 20+ tool security scanning
- **`vulnerability-assessment`**: Core security vulnerability detection
- **`docker-image-pipeline`**: Build, test, and deployment pipeline

### Service Validation Steps

**Location**: `.github/workflows/build-and-publish.yml`

```yaml
- name: Service Health Validation
  run: |
    chmod +x scripts/service-monitoring.sh
    ./scripts/service-monitoring.sh
```

**Artifacts**: Service monitoring results are uploaded as CI artifacts for 30-day retention.

## Service Check Reports

### Automated Reporting

Service monitoring generates comprehensive reports in `service-monitoring-results/`:

```
service-monitoring-results/
├── image-availability.txt          # Registry connectivity results
├── health-checks.txt              # Docker HEALTHCHECK validation
├── platformio-service.txt         # PlatformIO functionality tests
├── container-runtime.txt          # Runtime behavior validation
└── service-monitoring-summary.md  # Executive summary report
```

### Report Format Example

```markdown
# ESP32/ESP8266 Docker Images - Service Monitoring Report

## Executive Summary
- **Total Checks**: 12
- **Passed**: 11  
- **Failed**: 1
- **Success Rate**: 92%

## Health Check Implementation Details
Both images implement Docker HEALTHCHECK instructions for:
- PlatformIO service accessibility validation
- Container health status reporting
- Orchestration system integration
```

## Usage Instructions

### Quick Status Check
```bash
# Fast status verification (10-15 seconds)
./scripts/status-check.sh
```

### Comprehensive Service Monitoring
```bash
# Full service validation (2-5 minutes)
./scripts/service-monitoring.sh
```

### CI/CD Integration
Service monitoring is automatically integrated into the GitHub Actions workflow and runs after successful image builds.

## Service Health Indicators

### ✅ Healthy Service Status
- Images pullable from registry
- Docker HEALTHCHECK passing
- PlatformIO commands functional
- Container runtime stable

### ⚠️ Warning Indicators  
- Some commands timeout (expected in restricted networks)
- Partial functionality available
- Non-critical checks fail

### ❌ Unhealthy Service Status
- Images not available
- Health checks failing
- PlatformIO service non-functional
- Container runtime issues

## Best Practices

### For Developers
1. **Always run status check** before using images in projects
2. **Check service monitoring reports** when troubleshooting issues
3. **Monitor GitHub Actions** for build and service validation status

### For Administrators
1. **Review service monitoring artifacts** in CI/CD runs
2. **Set up alerts** for service check failures
3. **Monitor health check metrics** in production deployments

### For CI/CD Integration
1. **Include service validation** in deployment pipelines
2. **Use status checks** for readiness verification
3. **Monitor service health trends** over time

## Troubleshooting Service Issues

### Image Availability Problems
- Check GitHub Actions build status
- Verify registry authentication
- Wait for build completion (15-30 minutes)

### Health Check Failures
- Review container logs for errors
- Check PlatformIO installation
- Validate Dockerfile HEALTHCHECK syntax

### Service Functionality Issues
- Test in unrestricted network environment
- Check for network connectivity problems
- Review PlatformIO platform installation

---

**Service Monitoring System Version**: 2.0  
**Last Updated**: August 2025  
**Maintainer**: @sparck75