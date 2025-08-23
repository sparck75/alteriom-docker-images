# Security Practices Implementation Guide

> **For AI Agents and Developers**: This document provides a comprehensive guide on how to implement the security practices used in the alteriom-docker-images repository in other repositories or as reusable workflows.

## Overview

The alteriom-docker-images repository implements a comprehensive multi-layer security approach that can be replicated in other repositories. This guide documents all security practices, tools, and implementation patterns so they can be reused in organizational security templates or other repositories.

## 🏗️ Architecture Overview

### Security Scanning Pipeline Structure

```yaml
# High-level security job structure
jobs:
  security-validation:
    # Basic vulnerability scanning (8+ tools)
  
  code-analysis:
    # Static analysis with SARIF integration
  
  build-and-deploy:
    # Container security scanning and validation
```

## 🔧 Implementation Components

### 1. Multi-Tool Security Scanning

The repository uses a comprehensive security scanner script that implements 20+ enterprise security tools:

#### Basic Security Tools (Always Enabled)
- **Trivy Filesystem Scan** - Container and filesystem vulnerability detection
- **Trivy Configuration Scan** - Infrastructure misconfigurations and security issues
- **Safety Python Scan** - Python package vulnerability database scanning
- **pip-audit Scan** - Enhanced Python dependency vulnerability analysis
- **OSV Scanner** - Google's Open Source Vulnerability database scanning
- **Grype Vulnerability Scan** - Anchore's comprehensive vulnerability scanner
- **Docker Scout Scan** - Docker's official security vulnerability scanner
- **Node.js Dependency Scan** - JavaScript/NPM package vulnerability detection

#### Advanced Security Tools (Optional)
- **Gitleaks** - Git repository secrets and credential scanning
- **TruffleHog** - Advanced secrets detection with high accuracy
- **ClamAV Antivirus** - Malware and virus scanning with updated definitions
- **Terrascan** - Infrastructure as Code compliance and security analysis
- **Conftest** - Open Policy Agent (OPA) policy validation
- **Enhanced Docker Bench** - Container security best practices validation
- **Bandit Static Analysis** - Python code security issue detection
- **Semgrep Security Rules** - Multi-language static analysis security scanning
- **Checkov Compliance** - Infrastructure compliance and security validation

### 2. Dockerfile Security Implementation

```yaml
# Hadolint Dockerfile scanning
- name: Run production Dockerfile security scan
  uses: hadolint/hadolint-action@v3.1.0
  with:
    dockerfile: production/Dockerfile
    format: sarif
    output-file: hadolint-production.sarif
    no-fail: true

- name: Upload production Dockerfile scan results
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: hadolint-production.sarif
    category: 'hadolint-production'
```

### 3. Container Security Best Practices

#### Base Image Security
```dockerfile
# Use minimal, security-patched base images
FROM python:3.11-slim

# Create non-root user early
RUN useradd -m -u 1000 builder

# Security updates and package installation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        essential-packages-only && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add HEALTHCHECK for container monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD command-to-check-health || exit 1

# Use non-root user
USER builder
WORKDIR /workspace
```

#### Runtime Security Configuration
```bash
# Example secure container execution
docker run --rm \
  --read-only \
  --user 1000:1000 \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  -v ${PWD}:/workspace \
  image:tag command
```

### 4. Dependency Security Management

#### Python Dependencies
```yaml
- name: Python dependency security scan
  run: |
    python -m pip install --upgrade pip safety pip-audit
    
    # Create requirements files with security fixes
    echo "platformio==6.1.13" > requirements.txt
    echo "setuptools>=70.0.0" >> requirements.txt
    echo "starlette>=0.40.0" >> requirements.txt
    
    # Multiple scanning tools for comprehensive coverage
    safety scan --file requirements.txt --output json --save-as safety-results.json || true
    pip-audit --requirement requirements.txt --format=json --output=pip-audit-results.json || true
    
    # OSV Scanner for additional coverage
    osv-scanner --requirements requirements.txt --json > osv-results.json || true
```

### 5. SARIF Integration for Security Tab

```yaml
- name: Generate Security SARIF Reports
  if: always()
  run: |
    mkdir -p sarif-results
    
    # Convert tool outputs to SARIF format
    jq '
      {
        version: "2.1.0",
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        runs: [
          {
            tool: {
              driver: {
                name: "Trivy",
                version: "latest",
                informationUri: "https://trivy.dev"
              }
            },
            results: [
              .Results[]? | 
              select(.Vulnerabilities) |
              .Vulnerabilities[] |
              select(.Severity == "HIGH" or .Severity == "CRITICAL") |
              {
                ruleId: .VulnerabilityID,
                level: (if .Severity == "CRITICAL" then "error" elif .Severity == "HIGH" then "warning" else "note" end),
                message: {
                  text: (.Title + ": " + .Description)
                },
                locations: [
                  {
                    physicalLocation: {
                      artifactLocation: {
                        uri: (.Target // ".")
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ' trivy-results.json > sarif-results/trivy.sarif

- name: Upload SARIF to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: 'sarif-results/trivy.sarif'
    category: 'trivy-scan'
```

## 📋 Complete Implementation Template

### GitHub Actions Workflow Template

```yaml
name: Comprehensive Security Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Daily security scans

env:
  DOCKER_REPOSITORY: ghcr.io/your-org/your-repo

jobs:
  security-validation:
    name: "Security Validation & Vulnerability Assessment"
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    timeout-minutes: 45
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Run Comprehensive Security Scanner
        run: |
          # Copy the comprehensive-security-scanner.sh script from alteriom-docker-images
          # Or implement similar scanning logic
          chmod +x scripts/security-scanner.sh
          ADVANCED_MODE=false ./scripts/security-scanner.sh
      
      - name: Upload Security Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: security-results-${{ github.run_number }}
          path: security-results/
          retention-days: 30

  code-analysis:
    name: "Code Analysis & SARIF Integration"
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Run Trivy filesystem scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-fs-results.sarif'
          severity: 'CRITICAL,HIGH,MEDIUM'
      
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-fs-results.sarif'
          category: 'trivy-filesystem'
      
      - name: Run Dockerfile security scan
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          format: sarif
          output-file: hadolint-results.sarif
          no-fail: true
      
      - name: Upload Dockerfile scan results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: hadolint-results.sarif
          category: 'hadolint'

  container-security:
    name: "Container Security Scanning"
    runs-on: ubuntu-latest
    needs: [build-images]  # Assume you have a build job
    
    steps:
      - name: Container Image Security Scan
        run: |
          # Install security tools
          curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
          
          # Scan built images
          for image in "${IMAGES[@]}"; do
            trivy image --format json --output "trivy-${image_name}-results.json" "$image"
            trivy image --format table "$image" > "trivy-${image_name}-report.txt"
          done
      
      - name: Upload Container Security Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: container-security-${{ github.run_number }}
          path: |
            trivy-*-results.json
            trivy-*-report.txt
          retention-days: 30
```

## 🛠️ Security Script Implementation

### Core Security Scanner Script Structure

```bash
#!/bin/bash
# comprehensive-security-scanner.sh

set -euo pipefail

# Configuration
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-your-default-repo}"
SCAN_RESULTS_DIR="${SCAN_RESULTS_DIR:-security-results}"
ADVANCED_MODE="${ADVANCED_MODE:-false}"

# Error handling
error_handler() {
    local line_no=$1
    local error_code=$2
    echo "❌ Security scan failed at line $line_no (exit code: $error_code)"
    exit $error_code
}
trap 'error_handler ${LINENO} $?' ERR

# Create results structure
mkdir -p "$SCAN_RESULTS_DIR"/{basic,advanced,reports,sarif}

# Basic security scans (implement each function)
run_trivy_filesystem_scan() {
    trivy fs --format json --output "$SCAN_RESULTS_DIR/basic/trivy-filesystem.json" .
}

run_trivy_config_scan() {
    trivy config --format json --output "$SCAN_RESULTS_DIR/basic/trivy-config.json" .
}

run_python_security_scan() {
    pip install safety pip-audit
    safety scan --json > "$SCAN_RESULTS_DIR/basic/safety-results.json" || true
    pip-audit --format=json --output="$SCAN_RESULTS_DIR/basic/pip-audit-results.json" || true
}

run_osv_scanner() {
    # Install and run OSV scanner
    go install github.com/google/osv-scanner/cmd/osv-scanner@latest
    osv-scanner --json . > "$SCAN_RESULTS_DIR/basic/osv-results.json" || true
}

# Advanced security scans (optional)
run_secrets_scan() {
    if [ "$ADVANCED_MODE" = "true" ]; then
        # Install and run Gitleaks
        # Install and run TruffleHog
        echo "Running advanced secrets scanning..."
    fi
}

# Main execution
main() {
    echo "🛡️ Starting comprehensive security scan..."
    
    run_trivy_filesystem_scan
    run_trivy_config_scan
    run_python_security_scan
    run_osv_scanner
    
    if [ "$ADVANCED_MODE" = "true" ]; then
        run_secrets_scan
        # Add other advanced scans
    fi
    
    echo "✅ Security scan completed"
}

main "$@"
```

## 📖 Integration Examples

### Basic Integration
```yaml
# Add to any repository's .github/workflows/
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Security Scan
        run: |
          # Copy security scripts from alteriom-docker-images
          wget https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/scripts/comprehensive-security-scanner.sh
          chmod +x comprehensive-security-scanner.sh
          ./comprehensive-security-scanner.sh
```

### Advanced Integration with Custom Configuration
```yaml
jobs:
  security:
    runs-on: ubuntu-latest
    env:
      ADVANCED_MODE: true
      SCAN_RESULTS_DIR: custom-security-results
    steps:
      - uses: actions/checkout@v4
      - name: Custom Security Configuration
        run: |
          # Create custom requirements file
          echo "your-package==1.0.0" > requirements.txt
          
          # Run with custom settings
          DOCKER_REPOSITORY="your-repo" ./comprehensive-security-scanner.sh
```

## 🔒 Security Best Practices Checklist

### Container Security
- [ ] Use minimal base images (e.g., python:3.11-slim)
- [ ] Create non-root user (UID 1000)
- [ ] Remove package caches and build tools
- [ ] Add HEALTHCHECK instructions
- [ ] Pin specific versions of dependencies
- [ ] Use multi-stage builds to reduce attack surface

### Dependency Security
- [ ] Pin all dependency versions
- [ ] Regular security updates (Dependabot)
- [ ] Multiple scanning tools (Safety, pip-audit, OSV)
- [ ] SARIF integration for GitHub Security tab
- [ ] Automated vulnerability alerts

### Code Security
- [ ] Static analysis (Bandit, Semgrep)
- [ ] Secrets scanning (Gitleaks, TruffleHog)
- [ ] Configuration validation (Trivy config)
- [ ] Infrastructure as Code scanning (Terrascan, Checkov)

### Runtime Security
- [ ] Read-only filesystem where possible
- [ ] Drop unnecessary capabilities
- [ ] Security options (no-new-privileges)
- [ ] Resource limits and security constraints

## 📚 Reference Implementation

The complete implementation can be found in the alteriom-docker-images repository:

- **Main Workflow**: `.github/workflows/build-and-publish.yml`
- **Security Scanner**: `scripts/comprehensive-security-scanner.sh`
- **Security Policy**: `SECURITY.md`
- **Container Dockerfiles**: `production/Dockerfile`, `development/Dockerfile`

### Key Scripts to Copy/Reference:
1. `scripts/comprehensive-security-scanner.sh` - Main security scanning logic
2. `scripts/vulnerability-correlation-engine.sh` - Advanced vulnerability analysis
3. `scripts/test-esp-builds.sh` - Platform-specific testing patterns
4. `scripts/verify-images.sh` - Image verification patterns

## 🚀 Implementation Steps for New Repositories

1. **Copy Security Scripts**: Download security scanning scripts from alteriom-docker-images
2. **Adapt Configuration**: Modify environment variables and paths for your repository
3. **Update Workflows**: Integrate security jobs into your GitHub Actions
4. **Configure SARIF**: Set up SARIF uploads for GitHub Security tab integration
5. **Test Implementation**: Run security scans locally and in CI/CD
6. **Monitor Results**: Set up notifications and review processes for security findings

## 📧 Support and Questions

For questions about implementing these security practices:

- **Reference Repository**: [alteriom-docker-images](https://github.com/sparck75/alteriom-docker-images)
- **Security Practices**: See `SECURITY.md` in the reference repository
- **Example Workflows**: Check `.github/workflows/build-and-publish.yml`

---

**Last Updated**: August 2024  
**Version**: 1.0  
**Based on**: alteriom-docker-images security implementation  
**For**: Organizational security template development and reuse