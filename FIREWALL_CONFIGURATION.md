# Firewall Configuration for Copilot Coding Agent

This document provides a comprehensive list of URLs and domains that need to be allowlisted for the Copilot coding agent to function properly with the alteriom-docker-images repository.

## Overview

The repository uses various scripts and GitHub Actions that require network access to external services. When using the Copilot coding agent in a restricted network environment, certain URLs may be blocked by firewall rules. This document helps identify and configure the necessary allowlist entries.

## Critical Network Access Requirements

### GitHub API Access
- **URL**: `https://api.github.com/repos/sparck75/alteriom-docker-images/actions/runs`
- **Purpose**: Check GitHub Actions workflow status via scripts/verify-images.sh
- **Blocking Impact**: High - Prevents status verification and workflow monitoring
- **Error Type**: HTTP block
- **Command**: `curl -s -f "https://api.github.com/repos/sparck75/alteriom-docker-images/actions/runs"`

### Badge Services
- **Domain**: `img.shields.io`
- **Purpose**: README badges for repository status, releases, and metrics
- **Blocking Impact**: Medium - Breaks badge display in README
- **Error Type**: DNS block
- **Commands**: 
  - `curl -I -s https://img.shields.io/github/v/release/sparck75/alteriom-docker-images`
  - `wget --spider https://img.shields.io/github/actions/workflow/status/...`

### Container Registry Access
- **Domain**: `ghcr.io`
- **Purpose**: GitHub Container Registry for Docker image operations
- **Blocking Impact**: Critical - Prevents image pulls/pushes and verification
- **Error Type**: DNS/HTTP block
- **Commands**: 
  - `docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest`
  - `docker push ghcr.io/sparck75/alteriom-docker-images/dev:latest`

## Extended Network Access Requirements

### Python Package Management
- **Domain**: `pypi.org`
- **Purpose**: Python package installation during Docker builds
- **Blocking Impact**: Critical - Prevents PlatformIO installation
- **Commands**: `pip install platformio==6.1.13`

- **Domain**: `files.pythonhosted.org`
- **Purpose**: Python package downloads
- **Blocking Impact**: Critical - Prevents package downloads

### PlatformIO Dependencies
- **Domain**: `dl.espressif.com`
- **Purpose**: ESP toolchain downloads
- **Blocking Impact**: High - Prevents ESP platform setup

- **Domain**: `github.com`
- **Purpose**: PlatformIO platform and framework downloads
- **Blocking Impact**: High - Prevents platform installations

### Docker Hub (Fallback)
- **Domain**: `registry-1.docker.io`
- **Purpose**: Base image pulls (python:3.11-slim)
- **Blocking Impact**: Critical - Prevents Docker builds

- **Domain**: `auth.docker.io`
- **Purpose**: Docker Hub authentication
- **Blocking Impact**: Critical - Prevents base image access

## Complete Allowlist Configuration

### Required Domains for Full Functionality
```
# GitHub Services
api.github.com
github.com
ghcr.io

# Badge Services
img.shields.io

# Python Package Management
pypi.org
files.pythonhosted.org

# ESP Development
dl.espressif.com

# Docker Services
registry-1.docker.io
auth.docker.io
index.docker.io
```

### Required URLs for Copilot Agent
```
# GitHub API (for workflow status checks)
https://api.github.com/repos/sparck75/alteriom-docker-images/actions/runs
https://api.github.com/repos/sparck75/alteriom-docker-images/releases/latest

# Badge URLs (for README display)
https://img.shields.io/github/v/release/sparck75/alteriom-docker-images
https://img.shields.io/github/actions/workflow/status/sparck75/alteriom-docker-images/build-and-publish.yml
https://img.shields.io/github/license/sparck75/alteriom-docker-images
https://img.shields.io/github/last-commit/sparck75/alteriom-docker-images

# Container Registry
https://ghcr.io/v2/sparck75/alteriom-docker-images/builder/manifests/latest
https://ghcr.io/v2/sparck75/alteriom-docker-images/dev/manifests/latest
```

## Firewall Configuration by Functionality

### Minimal Configuration (Core Repository Operations)
For basic repository operations without Docker builds:
```
github.com
api.github.com
img.shields.io
```

### Docker Operations Configuration
For Docker image operations and verification:
```
github.com
api.github.com
ghcr.io
registry-1.docker.io
auth.docker.io
```

### Complete Development Configuration
For full development including local builds:
```
github.com
api.github.com
ghcr.io
img.shields.io
pypi.org
files.pythonhosted.org
dl.espressif.com
registry-1.docker.io
auth.docker.io
index.docker.io
```

## Detecting New Blocked URLs

### Common Blocking Patterns
When the Copilot agent encounters blocked URLs, it will typically show warnings like:
```
> [!WARNING]
> I tried to connect to the following addresses, but was blocked by firewall rules:
> 
> https://api.github.com/repos/sparck75/alteriom-docker-images/actions/runs
>   - Triggering command: curl -s -f REDACTED (http block)
> 
> img.shields.io
>   - Triggering command: curl -I -s REDACTED (dns block)
>   - Triggering command: wget --spider REDACTED (dns block)
```

### How to Handle New Blocks
1. **Document the blocked URL**: Note the exact URL and the triggering command
2. **Identify the purpose**: Determine what functionality is affected
3. **Add to allowlist**: Configure the domain/URL in repository settings
4. **Create GitHub issue**: For new blocking patterns, create an issue and assign to @sparck75
5. **Update this document**: Add new URLs to the appropriate sections

### Scripts That Make Network Calls
- `scripts/verify-images.sh`: GitHub API calls for workflow status
- `scripts/status-check.sh`: Docker registry calls for image verification
- `scripts/build-images.sh`: Docker registry for push operations
- GitHub Actions workflows: All network dependencies during CI/CD

## Issue Template for New Firewall Blocks

When encountering new blocked URLs, create a GitHub issue with this template:

```markdown
**Title**: New firewall block detected: [domain/URL]

**Description**:
The Copilot coding agent encountered a new firewall block:

**Blocked URL/Domain**: 
**Error Type**: (dns block/http block)
**Triggering Command**: 
**Affected Functionality**: 
**Impact Level**: (Critical/High/Medium/Low)

**Recommended Action**:
- [ ] Add to repository allowlist: [specific domain/URL]
- [ ] Update FIREWALL_CONFIGURATION.md
- [ ] Test functionality after allowlist update

**Context**:
[Describe what operation was being performed when the block occurred]
```

## Troubleshooting Network Issues

### Verification Commands
Test network access with these commands:
```bash
# Test GitHub API access
curl -I -s https://api.github.com/repos/sparck75/alteriom-docker-images/actions/runs

# Test badge services
curl -I -s https://img.shields.io/github/v/release/sparck75/alteriom-docker-images

# Test container registry
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest

# Test Python package access
curl -I -s https://pypi.org/simple/platformio/
```

### Common Solutions
1. **DNS Resolution Issues**: Check DNS configuration and add domain to DNS allowlist
2. **HTTP/HTTPS Blocks**: Add full URLs to HTTP allowlist
3. **Certificate Issues**: Ensure corporate certificates are properly configured
4. **Proxy Issues**: Configure Docker and curl to use corporate proxy

## Repository-Specific Considerations

### Scripts with Network Dependencies
- **verify-images.sh**: Requires GitHub API and Docker registry access
- **status-check.sh**: Requires Docker registry access only
- **build-images.sh**: Requires Docker registry and Python package access
- **test-esp-builds.sh**: Requires ESP toolchain downloads during first run

### GitHub Actions Network Requirements
The automated builds require access to all domains listed above since they:
- Pull base Docker images
- Install Python packages
- Download ESP toolchains
- Push to GitHub Container Registry
- Update GitHub releases

### Development Environment Setup
For local development with Copilot, ensure these minimum domains are accessible:
- `github.com` (repository access)
- `api.github.com` (workflow status)
- `ghcr.io` (image operations)
- `img.shields.io` (badge display)

---

*This document should be updated whenever new network access requirements are identified. For questions or issues, create a GitHub issue and assign to @sparck75.*