# Alteriom Security Practices Migration Guide

> **For Alteriom Development Teams**: This guide provides step-by-step instructions for implementing the comprehensive security practices from alteriom-docker-images into your existing and new repositories.

## 🎯 Overview

This migration guide helps you implement the battle-tested security practices from the alteriom-docker-images repository into your Alteriom projects. These practices include multi-layer security scanning, container security validation, SARIF integration for GitHub Security tab, and comprehensive vulnerability assessment.

## 📋 Pre-Migration Checklist

### Repository Requirements
- [ ] GitHub repository with Actions enabled
- [ ] Admin or maintainer access to the repository
- [ ] Docker-based projects (for container security scanning)
- [ ] Python/Node.js projects (for dependency scanning)

### Required GitHub Permissions
Your repository needs these permissions for full security integration:
- [ ] **Security Events** - Write access for SARIF uploads
- [ ] **Contents** - Read access for code scanning
- [ ] **Actions** - Access to run workflows

### Network Requirements
Ensure your CI environment can access:
- [ ] `api.github.com` - GitHub API for security events
- [ ] `pypi.org` - Python package vulnerability databases
- [ ] `npmjs.com` - Node.js package databases
- [ ] `ghcr.io` - Container registry access

## 🚀 Quick Start Migration

### Option 1: Full Security Suite (Recommended)
Copy the complete security implementation from alteriom-docker-images:

```bash
# 1. Add security workflow
mkdir -p .github/workflows
curl -o .github/workflows/security-validation.yml \
  https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/.github/workflows/build-and-publish.yml

# 2. Add security scripts
mkdir -p scripts
curl -o scripts/comprehensive-security-scanner.sh \
  https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/scripts/comprehensive-security-scanner.sh
curl -o scripts/sarif-aggregator.sh \
  https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/scripts/sarif-aggregator.sh

# 3. Make scripts executable
chmod +x scripts/*.sh
```

### Option 2: Minimal Security (Basic)
For smaller projects, implement essential security checks only:

```bash
# Add basic security workflow
mkdir -p .github/workflows
cat > .github/workflows/security-basic.yml << 'EOF'
name: Basic Security Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
EOF
```

## 📦 Repository-Specific Configurations

### For Docker-Based Projects

#### 1. Container Security Workflow
```yaml
name: Container Security Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  container-security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build image for scanning
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:security-scan
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Run Trivy container scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:security-scan'
          format: 'sarif'
          output: 'trivy-container-results.sarif'
      
      - name: Upload container scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-container-results.sarif'
          category: 'container-security'
      
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
          category: 'dockerfile-security'
```

#### 2. Add Container Security Scripts
```bash
# Create container-specific security script
cat > scripts/container-security-scan.sh << 'EOF'
#!/bin/bash
set -euo pipefail

IMAGE_NAME="${1:-}"
if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

echo "🔍 Running container security scan for: $IMAGE_NAME"

# Install Trivy if not present
if ! command -v trivy &> /dev/null; then
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# Create results directory
mkdir -p security-results

# Comprehensive container scanning
echo "📋 Scanning for vulnerabilities..."
trivy image --format json --output security-results/container-vulnerabilities.json "$IMAGE_NAME"
trivy image --format table "$IMAGE_NAME" > security-results/container-report.txt

# Configuration scanning
echo "🔧 Scanning container configuration..."
trivy config --format json --output security-results/container-config.json .

# Secret scanning
echo "🔐 Scanning for secrets..."
trivy fs --scanners secret --format json --output security-results/secrets-scan.json .

echo "✅ Container security scan completed. Results in security-results/"
EOF

chmod +x scripts/container-security-scan.sh
```

### For Python Projects

#### 1. Python Security Workflow
```yaml
name: Python Security Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  python-security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install security tools
        run: |
          pip install safety bandit[toml] pip-audit
      
      - name: Run Safety check
        run: |
          safety check --json --output safety-results.json || true
          safety check --output safety-report.txt || true
      
      - name: Run Bandit security linter
        run: |
          bandit -r . -f json -o bandit-results.json || true
          bandit -r . -f txt -o bandit-report.txt || true
      
      - name: Run pip-audit
        run: |
          pip-audit --format=json --output=pip-audit-results.json || true
          pip-audit --format=text --output=pip-audit-report.txt || true
      
      - name: Convert Bandit results to SARIF
        run: |
          # Install sarif converter
          pip install sarif-om
          
          # Convert Bandit JSON to SARIF
          python << 'EOF'
import json
import os

def bandit_to_sarif(bandit_file, output_file):
    if not os.path.exists(bandit_file):
        return
    
    with open(bandit_file) as f:
        bandit_data = json.load(f)
    
    sarif_data = {
        "version": "2.1.0",
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        "runs": [{
            "tool": {
                "driver": {
                    "name": "Bandit",
                    "informationUri": "https://bandit.readthedocs.io/"
                }
            },
            "results": []
        }]
    }
    
    for result in bandit_data.get("results", []):
        sarif_result = {
            "ruleId": result.get("test_id", ""),
            "level": "warning" if result.get("issue_severity") == "MEDIUM" else "error",
            "message": {"text": result.get("issue_text", "")},
            "locations": [{
                "physicalLocation": {
                    "artifactLocation": {"uri": result.get("filename", "")},
                    "region": {"startLine": result.get("line_number", 1)}
                }
            }]
        }
        sarif_data["runs"][0]["results"].append(sarif_result)
    
    with open(output_file, 'w') as f:
        json.dump(sarif_data, f, indent=2)

bandit_to_sarif("bandit-results.json", "bandit-results.sarif")
EOF
      
      - name: Upload Bandit SARIF results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'bandit-results.sarif'
          category: 'bandit'
      
      - name: Upload security artifacts
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: python-security-results
          path: |
            *-results.json
            *-report.txt
```

### For Node.js Projects

#### 1. Node.js Security Workflow
```yaml
name: Node.js Security Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  nodejs-security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run npm audit
        run: |
          npm audit --audit-level=moderate --json > npm-audit-results.json || true
          npm audit --audit-level=moderate > npm-audit-report.txt || true
      
      - name: Run Semgrep security analysis
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/javascript
      
      - name: Upload security results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: nodejs-security-results
          path: |
            npm-audit-*
            semgrep-results.*
```

## 🔧 Advanced Configuration Options

### Custom Security Policy
Create `.github/security-policy.yml`:

```yaml
# Security policy configuration for Alteriom repositories
security:
  vulnerability_scanning:
    enabled: true
    schedule: "daily"
    severity_threshold: "MEDIUM"
    fail_on_critical: true
    
  dependency_updates:
    enabled: true
    auto_merge: false
    schedule: "weekly"
    
  secret_scanning:
    enabled: true
    patterns:
      - "api_key"
      - "password"
      - "secret"
      - "token"
      
  container_security:
    enabled: true
    dockerfile_linting: true
    base_image_scanning: true
    runtime_security: true

# Custom security tools configuration
tools:
  trivy:
    enabled: true
    formats: ["json", "sarif"]
    severity: "CRITICAL,HIGH,MEDIUM"
    
  hadolint:
    enabled: true
    dockerfile_rules: "strict"
    
  bandit:
    enabled: true
    confidence_level: "HIGH"
    
  safety:
    enabled: true
    full_report: true
```

### Environment-Specific Configuration

#### Development Environment
```yaml
# .github/workflows/security-dev.yml
name: Development Security Checks

on:
  push:
    branches: [ develop, feature/* ]

jobs:
  security-fast:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Quick security scan
        run: |
          # Run only essential security checks for faster feedback
          curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
          trivy fs --severity HIGH,CRITICAL .
```

#### Production Environment
```yaml
# .github/workflows/security-prod.yml
name: Production Security Validation

on:
  push:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  security-comprehensive:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Comprehensive security analysis
        run: |
          # Run full security suite including advanced tools
          chmod +x scripts/comprehensive-security-scanner.sh
          ADVANCED_MODE=true ./scripts/comprehensive-security-scanner.sh
```

## 📋 Step-by-Step Migration Process

### Phase 1: Basic Implementation (Week 1)

#### Day 1-2: Repository Preparation
1. **Enable GitHub Security Features**
   ```bash
   # Go to Settings > Security & Analysis
   # Enable:
   # - Dependency graph
   # - Dependabot alerts
   # - Dependabot security updates
   # - Secret scanning
   # - Code scanning
   ```

2. **Add Basic Security Workflow**
   ```bash
   # Copy minimal security workflow
   mkdir -p .github/workflows
   curl -o .github/workflows/security-basic.yml \
     https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/.github/workflows/build-and-publish.yml
   
   # Customize for your repository
   sed -i 's/alteriom-docker-images/your-repo-name/g' .github/workflows/security-basic.yml
   ```

#### Day 3-4: Initial Testing
1. **Test Basic Security Scan**
   ```bash
   # Create a test branch
   git checkout -b security-implementation
   
   # Add the workflow and commit
   git add .github/workflows/security-basic.yml
   git commit -m "Add basic security scanning"
   git push origin security-implementation
   
   # Create PR to trigger security scan
   # Monitor the Actions tab for results
   ```

2. **Review Initial Results**
   - Check GitHub Security tab for findings
   - Review Actions logs for any errors
   - Document any false positives

#### Day 5: Documentation
1. **Add Security Documentation**
   ```bash
   # Copy security templates
   curl -o SECURITY.md \
     https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/SECURITY.md
   
   # Customize for your project
   # Update contact information
   # Adjust security policies for your team
   ```

### Phase 2: Enhanced Security (Week 2)

#### Day 1-3: Add Comprehensive Scanning
1. **Install Security Scripts**
   ```bash
   mkdir -p scripts
   
   # Copy comprehensive scanner
   curl -o scripts/comprehensive-security-scanner.sh \
     https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/scripts/comprehensive-security-scanner.sh
   
   # Copy SARIF aggregator
   curl -o scripts/sarif-aggregator.sh \
     https://raw.githubusercontent.com/sparck75/alteriom-docker-images/main/scripts/sarif-aggregator.sh
   
   # Make executable
   chmod +x scripts/*.sh
   ```

2. **Test Advanced Features**
   ```bash
   # Run local security scan
   ADVANCED_MODE=true ./scripts/comprehensive-security-scanner.sh
   
   # Review results
   ls -la comprehensive-security-results/
   ```

#### Day 4-5: Custom Integration
1. **Repository-Specific Customization**
   - Modify security thresholds for your risk tolerance
   - Add project-specific security rules
   - Configure custom SARIF uploaders for specialized tools

### Phase 3: Organization Integration (Week 3)

#### Day 1-2: Organization Setup
1. **Create Organization Security Repository**
   ```bash
   # This will be handled in a separate repository
   # Document the process for organization-wide templates
   ```

2. **Standardize Security Policies**
   - Create organization-wide security policies
   - Standardize branch protection rules
   - Set up organization-level secret scanning

#### Day 3-5: Rollout to Other Repositories
1. **Bulk Repository Updates**
   ```bash
   # Script to update multiple repositories
   # (This would be customized for your organization)
   ```

## 🔍 Validation and Testing

### Security Scan Validation
Run these commands to validate your security implementation:

```bash
# 1. Test basic functionality
./scripts/comprehensive-security-scanner.sh

# 2. Validate SARIF generation
ls -la comprehensive-security-results/sarif/

# 3. Check workflow syntax
yamllint .github/workflows/security-*.yml

# 4. Test container security (if applicable)
./scripts/container-security-scan.sh your-image:latest
```

### Expected Results
After successful implementation, you should see:

1. **GitHub Security Tab**
   - Vulnerability alerts from Trivy
   - Secret scanning results
   - Code scanning alerts

2. **Actions Artifacts**
   - Comprehensive security reports
   - SARIF files for security integration
   - Detailed vulnerability assessments

3. **Regular Security Updates**
   - Daily/weekly security scans
   - Automated vulnerability reporting
   - Integration with GitHub Advanced Security

## 🚨 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Issue: Security events upload fails
# Solution: Ensure repository has security-events: write permission

# Check current permissions
cat .github/workflows/security-*.yml | grep -A 10 permissions:
```

#### Network Access Issues
```bash
# Issue: Tools can't download databases
# Solution: Verify network connectivity

curl -I https://api.github.com
curl -I https://pypi.org
```

#### False Positives
```bash
# Issue: Too many false positive alerts
# Solution: Add suppression files

# Create Trivy ignore file
cat > .trivyignore << 'EOF'
# Suppress specific CVEs that are false positives
CVE-2023-12345
EOF

# Create Bandit configuration
cat > .bandit << 'EOF'
[bandit]
skips = B101,B601
EOF
```

### Recovery Procedures

#### Reset Security Configuration
```bash
# Remove all security workflows
rm .github/workflows/security-*.yml

# Remove security scripts
rm -rf scripts/

# Start over with basic implementation
# Follow Phase 1 steps
```

#### Emergency Security Response
```bash
# For critical security findings:

# 1. Immediate response
git checkout main
git pull origin main

# 2. Create hotfix branch
git checkout -b security-hotfix-$(date +%Y%m%d)

# 3. Apply security patches
# (Make necessary changes)

# 4. Emergency deployment
git add .
git commit -m "SECURITY: Emergency security patches"
git push origin security-hotfix-$(date +%Y%m%d)
```

## 📞 Support and Resources

### Alteriom Internal Resources
- **Security Team**: Contact your internal security team for policy questions
- **DevOps Team**: For CI/CD and automation support
- **Repository Admins**: For permissions and access issues

### External Documentation
- [GitHub Advanced Security](https://docs.github.com/en/code-security)
- [Trivy Documentation](https://trivy.dev/)
- [SARIF Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/)
- [Container Security Best Practices](https://sysdig.com/blog/dockerfile-best-practices/)

### Emergency Contacts
- **Security Incidents**: Follow your organization's incident response procedure
- **Critical Vulnerabilities**: Escalate to security team immediately
- **CI/CD Issues**: Contact DevOps team

## 📈 Success Metrics

Track these metrics to measure security implementation success:

### Security Coverage Metrics
- [ ] **Vulnerability Detection**: % of repositories with security scanning enabled
- [ ] **Response Time**: Average time from vulnerability detection to resolution  
- [ ] **False Positive Rate**: % of security alerts that are false positives
- [ ] **SARIF Integration**: % of security findings visible in GitHub Security tab

### Implementation Metrics
- [ ] **Workflow Success Rate**: % of security scans that complete successfully
- [ ] **Coverage**: % of code covered by security analysis
- [ ] **Compliance**: % of repositories meeting security policy requirements

### Example Dashboard Queries
```bash
# Count security workflows across repositories
find . -name "security-*.yml" | wc -l

# Check SARIF upload success rate
grep -r "Upload.*SARIF" .github/workflows/ | wc -l

# Measure security finding resolution time
# (This would require GitHub API integration)
```

---

## ⚡ Quick Reference Commands

```bash
# Quick security scan
./scripts/comprehensive-security-scanner.sh

# Container security check
./scripts/container-security-scan.sh IMAGE_NAME

# Validate workflows
yamllint .github/workflows/

# Check security results
ls -la comprehensive-security-results/

# Upload SARIF to GitHub
gh api repos/:owner/:repo/code-scanning/sarifs \
  --method POST \
  --field commit_sha=HEAD \
  --field ref=refs/heads/main \
  --field sarif=@results.sarif
```

---

**Next Steps**: After completing this migration guide, consider implementing organization-wide security templates and policies in a dedicated security repository for centralized management across all Alteriom projects.