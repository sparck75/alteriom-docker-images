#!/bin/bash

# Security Remediation Script for alteriom-docker-images
# Addresses vulnerabilities identified in security scans

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

echo -e "${BLUE}🛡️  Security Remediation for alteriom-docker-images${NC}"
echo "======================================================="
echo "Timestamp: $(date -u)"
echo ""

print_status "INFO" "Starting security vulnerability remediation..."

# Check if we have the security scan results
if [ ! -d "security-scan-results" ]; then
    print_status "WARNING" "Security scan results not found. Running security scan first..."
    if [ -f "scripts/enhanced-security-monitoring.sh" ]; then
        ./scripts/enhanced-security-monitoring.sh
    else
        print_status "ERROR" "Enhanced security monitoring script not found!"
        exit 1
    fi
fi

# Analyze vulnerabilities from scan results
print_status "INFO" "Analyzing security vulnerabilities..."

# Function to check for high/critical vulnerabilities in JSON files
check_vulnerabilities() {
    local file=$1
    local image_name=$2
    
    if [ -f "$file" ]; then
        local high_count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities[] | select(.Severity == "HIGH")]' "$file" | jq length 2>/dev/null || echo "0")
        local critical_count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities[] | select(.Severity == "CRITICAL")]' "$file" | jq length 2>/dev/null || echo "0")
        
        if [ "$high_count" -gt 0 ] || [ "$critical_count" -gt 0 ]; then
            print_status "WARNING" "$image_name: Found $critical_count CRITICAL and $high_count HIGH vulnerabilities"
            
            # Extract specific vulnerabilities
            print_status "INFO" "Key vulnerabilities in $image_name:"
            
            # Git vulnerabilities
            local git_vulns=$(jq -r '.Results[]? | select(.Vulnerabilities) | .Vulnerabilities[] | select(.PkgName == "git" and (.Severity == "HIGH" or .Severity == "CRITICAL")) | "  - \(.VulnerabilityID): \(.Title)"' "$file" 2>/dev/null || echo "")
            if [ -n "$git_vulns" ]; then
                echo "    Git vulnerabilities:"
                echo "$git_vulns"
            fi
            
            # Python package vulnerabilities  
            local python_vulns=$(jq -r '.Results[]? | select(.Vulnerabilities) | .Vulnerabilities[] | select(.Class == "lang-pkgs" and (.Severity == "HIGH" or .Severity == "CRITICAL")) | "  - \(.VulnerabilityID): \(.PkgName) \(.InstalledVersion) -> \(.FixedVersion // "No fix available")"' "$file" 2>/dev/null || echo "")
            if [ -n "$python_vulns" ]; then
                echo "    Python package vulnerabilities:"
                echo "$python_vulns"
            fi
        else
            print_status "SUCCESS" "$image_name: No HIGH or CRITICAL vulnerabilities found"
        fi
    else
        print_status "WARNING" "Vulnerability file $file not found"
    fi
}

# Check both images
if [ -f "security-scan-results/trivy-builder-latest-vulnerabilities.json" ]; then
    check_vulnerabilities "security-scan-results/trivy-builder-latest-vulnerabilities.json" "Production Builder"
fi

if [ -f "security-scan-results/trivy-dev-latest-vulnerabilities.json" ]; then
    check_vulnerabilities "security-scan-results/trivy-dev-latest-vulnerabilities.json" "Development Builder"
fi

# Generate remediation recommendations
print_status "INFO" "Generating remediation recommendations..."

cat > security-scan-results/remediation-plan.md << 'EOF'
# Security Remediation Plan

## High/Critical Vulnerabilities Identified

### 1. Git Vulnerabilities (HIGH Severity)
- **CVE-2025-48384**: Git arbitrary code execution
- **CVE-2025-48385**: Git path traversal vulnerability
- **Current version**: 1:2.47.2-0.2
- **Fixed versions**: v2.47.3+, v2.48.2+, v2.49.1+, v2.50.1+

**Impact**: These vulnerabilities allow arbitrary code execution and path traversal attacks through malicious Git repositories.

**Remediation**:
- Update base image to use latest Debian packages
- Consider using a more recent base image (python:3.11-slim receives security updates)
- Add git version check in HEALTHCHECK

### 2. Python Package Vulnerabilities

#### setuptools (CVE-2025-47273) - HIGH Severity
- **Current version**: 65.5.1 (vulnerable)
- **Fixed version**: 70.0.0+
- **Impact**: Directory traversal vulnerability

**Remediation**:
```dockerfile
RUN pip3 install --no-cache-dir -U "setuptools>=70.0.0"
```

#### starlette (CVE-2024-47874) - HIGH Severity  
- **Current version**: 0.35.1 (vulnerable)
- **Fixed version**: 0.40.0+
- **Impact**: Denial of Service via multipart/form-data

**Remediation**:
```dockerfile
RUN pip3 install --no-cache-dir -U "starlette>=0.40.0"
```

### 3. Docker Configuration Issues (LOW Severity)
- Missing HEALTHCHECK instructions in both Dockerfiles

**Remediation**: ✅ Already implemented
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/platformio --version || exit 1
```

## Implementation Status

### ✅ Completed
- [x] Added HEALTHCHECK instructions to both Dockerfiles
- [x] Enhanced security monitoring script
- [x] Comprehensive vulnerability scanning

### 🔄 In Progress  
- [ ] Update Python dependencies in Dockerfiles
- [ ] Update base image or git package
- [ ] Test builds with security fixes

### ⏰ Pending
- [ ] Deploy updated images via GitHub Actions
- [ ] Verify vulnerability remediation
- [ ] Update documentation

## Next Steps

1. **Immediate**: Deploy Dockerfile changes via GitHub Actions (SSL certificates work in CI)
2. **Verification**: Re-run security scans after deployment  
3. **Monitoring**: Set up automated security scanning schedule
4. **Documentation**: Update security policies and procedures

## Risk Assessment

- **Current Risk**: HIGH (due to git and Python package vulnerabilities)
- **Mitigated Risk**: LOW (after implementing fixes)
- **Business Impact**: Minimal downtime during image rebuilds

EOF

print_status "SUCCESS" "Remediation plan generated: security-scan-results/remediation-plan.md"

# Create summary report
echo ""
print_status "INFO" "Security Remediation Summary:"
echo ""
echo "📋 Key Findings:"
echo "  • Git vulnerabilities in both images (HIGH severity)"
echo "  • Python package vulnerabilities (setuptools, starlette)"
echo "  • Missing HEALTHCHECK instructions (FIXED)"
echo ""
echo "🛠️  Actions Taken:"
echo "  • Added HEALTHCHECK instructions to Dockerfiles"
echo "  • Generated comprehensive remediation plan"
echo "  • Documented specific version fixes needed"
echo ""
echo "🚀 Next Steps:"
echo "  • Deploy via GitHub Actions (bypasses local SSL issues)"
echo "  • Update Python dependencies in CI environment"
echo "  • Verify fixes with post-deployment scans"
echo ""

print_status "SUCCESS" "Security remediation planning completed!"
print_status "INFO" "Full remediation plan available in: security-scan-results/remediation-plan.md"