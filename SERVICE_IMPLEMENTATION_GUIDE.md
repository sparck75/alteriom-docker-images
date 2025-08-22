# Service Check Implementation Guide

This document provides a clear overview of where service checks are implemented in the ESP32/ESP8266 Docker images project.

## Overview

Service monitoring is implemented in **4 key locations** to ensure comprehensive validation:

1. **Docker Health Checks** (Built into images)
2. **Service Monitoring Script** (Standalone validation)
3. **CI/CD Integration** (Automated testing)
4. **Manual Validation Scripts** (Development/debugging)

## 1. Docker Health Checks

**Location:** `production/Dockerfile` and `development/Dockerfile` (Lines 46-47)

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/platformio --version || exit 1
```

**Purpose:** Built-in container health validation
**Validation:** PlatformIO service availability and functionality

## 2. Service Monitoring Script

**Location:** `scripts/service-monitoring-simple.sh`

**Categories Validated:**
- Image Availability (Production & Development images)
- PlatformIO Functionality (Version validation)
- Container Health (Runtime validation)
- Network Connectivity (Internet & PlatformIO API)

**Usage:**
```bash
# Basic validation
./scripts/service-monitoring-simple.sh

# Advanced mode
ADVANCED_MODE=true ./scripts/service-monitoring-simple.sh
```

**Output:** 
- Console status updates
- Summary report in `service-monitoring-results/service-monitoring-summary.md`

## 3. CI/CD Integration

**Location:** `.github/workflows/build-and-publish.yml`

**Workflow Step:** "Service Health Validation"

**Triggers:**
- After successful image builds
- On scheduled builds (when changes detected)
- On pull requests

**Integration:**
- Runs service monitoring automatically
- Reports results to GitHub Actions summary
- Uploads artifacts for detailed analysis

## 4. Manual Validation Scripts

**Quick Status Check:**
```bash
./scripts/status-check.sh          # 10-15 seconds
```

**Comprehensive Validation:**
```bash
./scripts/verify-images.sh         # 30-60 seconds
```

**ESP Platform Testing:**
```bash
./scripts/test-esp-builds.sh       # 5-15 minutes
```

## Service Categories

### Image Availability
- Tests if images can be pulled from registry
- Validates both production and development images
- Checks image metadata and accessibility

### PlatformIO Functionality  
- Validates PlatformIO version command
- Tests core functionality within containers
- Ensures ESP32/ESP8266 platform support

### Container Health
- Tests container startup and basic commands
- Validates help command functionality
- Ensures containers can execute properly

### Network Connectivity
- Tests internet connectivity
- Validates PlatformIO API access
- Checks registry connectivity for package management

## Health Status Levels

- **EXCELLENT (90-100%):** All systems operational
- **GOOD (75-89%):** Minor issues, system functional  
- **NEEDS_ATTENTION (<75%):** Significant issues requiring attention

## Integration with Development Workflow

### Pre-commit Testing
```bash
# Quick validation before commits
./scripts/service-monitoring-simple.sh
```

### Release Validation
```bash
# Comprehensive validation before releases
./scripts/verify-images.sh
```

### CI/CD Pipeline
Service monitoring runs automatically in GitHub Actions and provides:
- Real-time status in workflow logs
- Detailed summary in GitHub Actions dashboard
- Artifact uploads for historical analysis

## Troubleshooting

### Common Issues
1. **Image Pull Failures:** Registry authentication or network issues
2. **PlatformIO Version Failures:** Container runtime or PlatformIO installation issues
3. **Network Connectivity Failures:** Firewall restrictions or DNS issues

### Debug Commands
```bash
# Test specific image manually
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Check network connectivity
curl -I https://api.registry.platformio.org/v3/libraries

# Validate container health
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --help
```

## Implementation Benefits

1. **Automated Validation:** Continuous monitoring during CI/CD
2. **Early Detection:** Issues caught before deployment
3. **Clear Reporting:** Easy-to-understand status reports
4. **Historical Tracking:** Artifact storage for trend analysis
5. **Developer Friendly:** Simple scripts for local validation

---

*For technical support or questions about service monitoring implementation, refer to the repository documentation or create a GitHub issue.*