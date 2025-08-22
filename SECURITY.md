# Security Policy

## Overview

The alteriom-docker-images repository is committed to maintaining the highest security standards for our Docker images used in ESP32/ESP8266 development. This document outlines our security practices, vulnerability reporting process, and automated security measures.

## Automated Security Scanning 🔒

### Multi-Layer Security Approach

Our security scanning includes multiple layers of protection:

#### 1. **Source Code Security**
- **Trivy Filesystem Scanning**: Scans all source files for vulnerabilities
- **Trivy Configuration Scanning**: Analyzes configuration files and infrastructure as code
- **Severity Levels**: CRITICAL, HIGH, and MEDIUM vulnerabilities are detected and reported

#### 2. **Dockerfile Security**
- **Hadolint Scanning**: Both production and development Dockerfiles scanned for best practices
- **Security Rule Compliance**: Enforces Docker security best practices
- **SARIF Integration**: Results uploaded to GitHub Security tab for tracking

#### 3. **Dependency Security**
- **Python Package Scanning**: Uses Safety to scan PlatformIO and Python dependencies
- **Known Vulnerability Database**: Checks against CVE database for known security issues
- **Automated Updates**: Dependency vulnerabilities trigger security alerts

#### 4. **Container Image Security**
- **Post-Build Scanning**: Built images scanned for vulnerabilities before publishing
- **Runtime Security**: Containers run as non-root user (UID 1000) for enhanced security
- **Base Image Monitoring**: Python 3.11-slim base image vulnerabilities tracked

### Security Scan Schedule

| Scan Type | Trigger | Frequency | Scope |
|-----------|---------|-----------|-------|
| Source Code | PR/Push | Every commit | All files |
| Dockerfile | PR/Push | Every commit | Both Dockerfiles |
| Dependencies | PR/Push | Every commit | Python packages |
| Container Images | After build | Per image build | Built containers |
| Full Security Audit | Schedule | Daily with builds | Complete stack |

## Security Measures in Docker Images

### Base Image Security
- **Python 3.11-slim**: Minimal attack surface with only essential packages
- **Regular Updates**: Base images updated with security patches
- **Vulnerability Monitoring**: Automated scanning for base image CVEs

### Build Security
- **Non-root User**: All containers run as `builder` user (UID 1000)
- **Minimal Packages**: Only essential packages installed, build tools removed after use
- **Clean Environment**: Package caches and temporary files removed
- **Immutable Tags**: Version tags provide reproducible, secure builds

### Runtime Security
- **Read-only Filesystem**: Containers designed for read-only operation where possible
- **No Privileged Access**: Containers run without elevated privileges
- **Network Security**: Minimal network exposure, only required ports
- **Workspace Isolation**: User workspace mounted separately from system files

## Vulnerability Management

### Severity Classification

| Severity | Response Time | Action Required |
|----------|---------------|-----------------|
| **CRITICAL** | < 24 hours | Immediate patch release |
| **HIGH** | < 72 hours | Patch in next release |
| **MEDIUM** | < 1 week | Include in regular update cycle |
| **LOW** | Next major release | Address during planned updates |

### Automated Response
- **GitHub Security Alerts**: Automatic vulnerability notifications
- **Dependabot Integration**: Automated dependency update PRs
- **SARIF Reports**: Detailed vulnerability data in GitHub Security tab
- **Artifact Storage**: Scan results stored for 30 days for analysis

## Reporting Security Vulnerabilities

### How to Report
If you discover a security vulnerability in our Docker images or build process:

1. **Email**: Send details to [dominic.lavoie@gmail.com](mailto:dominic.lavoie@gmail.com)
2. **Subject**: Use "SECURITY: alteriom-docker-images vulnerability"
3. **GitHub Security Advisory**: Use GitHub's security advisory feature for coordinated disclosure

### What to Include
- **Description**: Clear description of the vulnerability
- **Reproduction Steps**: How to reproduce the issue
- **Impact Assessment**: Potential security impact
- **Suggested Fix**: If you have suggestions for remediation

### Response Process
1. **Acknowledgment**: Within 24 hours
2. **Initial Assessment**: Within 72 hours  
3. **Fix Development**: Based on severity classification
4. **Testing**: Security fix validation
5. **Release**: Coordinated disclosure and patch release
6. **Follow-up**: Post-release monitoring

## Security Best Practices for Users

### Using Our Images Securely

```bash
# Always use specific version tags for production
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:1.6.1

# Run with read-only filesystem when possible
docker run --rm --read-only -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest pio run

# Use non-root user (already configured in images)
docker run --rm --user 1000:1000 -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest pio --version

# Limit container capabilities
docker run --rm --cap-drop=ALL -v ${PWD}:/workspace \
  ghcr.io/sparck75/alteriom-docker-images/builder:latest pio run -e esp32dev
```

### Keeping Images Updated
- **Regular Updates**: Pull latest images regularly for security patches
- **Version Pinning**: Use specific version tags for reproducible builds
- **Security Monitoring**: Subscribe to GitHub repository notifications
- **Vulnerability Scanning**: Scan your own projects using our tools

## Security Features by Image

### Production Builder (`builder:latest`)
- ✅ Minimal package set (reduced attack surface)
- ✅ Non-root user (UID 1000)
- ✅ No development tools (production-focused)
- ✅ PlatformIO 6.1.13 (pinned, security-tested version)
- ✅ Python 3.11-slim base (security-patched)

### Development Builder (`dev:latest`)
- ✅ Development tools included (vim, htop, less)
- ✅ Non-root user (UID 1000)
- ✅ Additional debugging capabilities
- ✅ Same security base as production
- ✅ Twine for package publishing (development workflows)

## Compliance and Standards

### Security Standards
- **NIST Cybersecurity Framework**: Aligned with identify, protect, detect, respond, recover
- **Docker Security Best Practices**: Following CIS Docker Benchmark guidelines
- **OWASP Container Security**: Implementing OWASP container security principles
- **Supply Chain Security**: SLSA framework compliance for build integrity

### Audit Trail
- **Build Reproducibility**: All builds are reproducible with version tags
- **Change Tracking**: All changes tracked in Git with signed commits
- **Security Scan History**: 30-day retention of all security scan results
- **Vulnerability Response**: Complete audit trail of security issue responses

## Security Contact

**Security Team**: @sparck75  
**Email**: dominic.lavoie@gmail.com  
**Response Time**: 24 hours for critical issues

## Security Resources

- [GitHub Security Advisory](https://github.com/sparck75/alteriom-docker-images/security/advisories)
- [Vulnerability Reports](https://github.com/sparck75/alteriom-docker-images/security/advisories)
- [Security Scan Results](https://github.com/sparck75/alteriom-docker-images/security/code-scanning)
- [Dependency Graph](https://github.com/sparck75/alteriom-docker-images/network/dependencies)

---

**Last Updated**: August 2024  
**Version**: 1.0  
**Next Review**: Quarterly