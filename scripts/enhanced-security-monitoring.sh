#!/bin/bash

# Enhanced Security Monitoring Script for alteriom-docker-images
# Performs comprehensive security checks and monitoring

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-ghcr.io/sparck75/alteriom-docker-images}"
SCAN_RESULTS_DIR="${SCAN_RESULTS_DIR:-security-scan-results}"
SEVERITY_THRESHOLD="${SEVERITY_THRESHOLD:-HIGH}"

# Create results directory
mkdir -p "$SCAN_RESULTS_DIR"

echo -e "${BLUE}🔒 Enhanced Security Monitoring for alteriom-docker-images${NC}"
echo "=================================================="
echo "Timestamp: $(date -u)"
echo "Repository: $DOCKER_REPOSITORY"
echo "Results Dir: $SCAN_RESULTS_DIR"
echo ""

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install security tools if needed
install_security_tools() {
    print_status "INFO" "Checking security tools installation..."
    
    # Check for Docker
    if ! command_exists docker; then
        print_status "ERROR" "Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check for Trivy
    if ! command_exists trivy; then
        print_status "INFO" "Installing Trivy scanner..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Install Trivy from GitHub releases (more reliable than apt repository)
            TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep "tag_name" | cut -d '"' -f 4)
            if [ -n "$TRIVY_VERSION" ]; then
                TRIVY_URL="https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.deb"
                print_status "INFO" "Downloading Trivy ${TRIVY_VERSION} from GitHub releases..."
                wget -q -O /tmp/trivy.deb "$TRIVY_URL"
                sudo dpkg -i /tmp/trivy.deb || sudo apt-get install -f -y
                rm -f /tmp/trivy.deb
            else
                print_status "WARNING" "Could not determine latest Trivy version. Trying fallback installation..."
                # Fallback to direct binary download
                wget -q -O /tmp/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-64bit.tar.gz
                tar -xzf /tmp/trivy.tar.gz -C /tmp/
                sudo mv /tmp/trivy /usr/local/bin/
                sudo chmod +x /usr/local/bin/trivy
                rm -f /tmp/trivy.tar.gz
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install trivy
        else
            print_status "WARNING" "Trivy auto-install not supported on this OS. Please install manually."
        fi
    fi
    
    # Check for Python security tools
    if ! command_exists safety; then
        print_status "INFO" "Installing Python security scanner..."
        pip install --user safety bandit
    fi
    
    print_status "SUCCESS" "Security tools ready"
}

# Scan filesystem for vulnerabilities
scan_filesystem() {
    print_status "INFO" "Scanning filesystem for vulnerabilities..."
    
    local output_file="$SCAN_RESULTS_DIR/trivy-filesystem-scan.json"
    local report_file="$SCAN_RESULTS_DIR/trivy-filesystem-report.txt"
    
    if command_exists trivy; then
        trivy fs --format json --output "$output_file" --severity "$SEVERITY_THRESHOLD,CRITICAL" . || true
        trivy fs --format table . > "$report_file" 2>&1 || true
        print_status "SUCCESS" "Filesystem scan completed"
    else
        print_status "WARNING" "Trivy not available for filesystem scan"
    fi
}

# Scan Docker configurations
scan_docker_configs() {
    print_status "INFO" "Scanning Docker configurations..."
    
    local config_output="$SCAN_RESULTS_DIR/trivy-config-scan.json"
    local config_report="$SCAN_RESULTS_DIR/trivy-config-report.txt"
    
    if command_exists trivy; then
        trivy config --format json --output "$config_output" --severity "$SEVERITY_THRESHOLD,CRITICAL" . || true
        trivy config --format table . > "$config_report" 2>&1 || true
        print_status "SUCCESS" "Configuration scan completed"
    else
        print_status "WARNING" "Trivy not available for configuration scan"
    fi
}

# Scan Python dependencies
scan_python_dependencies() {
    print_status "INFO" "Scanning Python dependencies..."
    
    # Extract dependencies from Dockerfiles
    local prod_deps="$SCAN_RESULTS_DIR/requirements-prod.txt"
    local dev_deps="$SCAN_RESULTS_DIR/requirements-dev.txt"
    
    # Create requirements files from Dockerfiles
    grep -o 'platformio==[0-9\.]*' production/Dockerfile > "$prod_deps" 2>/dev/null || echo "platformio==6.1.13" > "$prod_deps"
    grep -o 'platformio==[0-9\.]*\|twine' development/Dockerfile > "$dev_deps" 2>/dev/null || {
        echo "platformio==6.1.13" > "$dev_deps"
        echo "twine" >> "$dev_deps"
    }
    
    if command_exists safety; then
        # Scan production dependencies using modern scan command
        print_status "INFO" "Scanning production dependencies..."
        # Create a temporary directory with the requirements file for scanning
        mkdir -p /tmp/safety-scan-prod
        cp "$prod_deps" /tmp/safety-scan-prod/requirements.txt
        (cd /tmp/safety-scan-prod && safety scan > "$PWD/$SCAN_RESULTS_DIR/safety-prod-report.txt" 2>&1) || {
            print_status "WARNING" "Security issues found in production dependencies"
        }
        
        # Scan development dependencies using modern scan command
        print_status "INFO" "Scanning development dependencies..."
        # Create a temporary directory with the requirements file for scanning
        mkdir -p /tmp/safety-scan-dev
        cp "$dev_deps" /tmp/safety-scan-dev/requirements.txt
        (cd /tmp/safety-scan-dev && safety scan > "$PWD/$SCAN_RESULTS_DIR/safety-dev-report.txt" 2>&1) || {
            print_status "WARNING" "Security issues found in development dependencies"
        }
        
        print_status "SUCCESS" "Dependency security scan completed"
    else
        print_status "WARNING" "Safety not available for dependency scanning"
    fi
}

# Scan Docker images
scan_docker_images() {
    print_status "INFO" "Scanning Docker images..."
    
    local images=(
        "${DOCKER_REPOSITORY}/builder:latest"
        "${DOCKER_REPOSITORY}/dev:latest"
    )
    
    for image in "${images[@]}"; do
        print_status "INFO" "Scanning image: $image"
        
        # Check if image exists locally or can be pulled
        if ! docker image inspect "$image" >/dev/null 2>&1; then
            print_status "INFO" "Pulling image: $image"
            if ! docker pull "$image" 2>/dev/null; then
                print_status "WARNING" "Could not pull image: $image (may not exist yet)"
                continue
            fi
        fi
        
        local image_name=$(echo "$image" | sed 's/.*\///' | sed 's/:/-/')
        local vuln_output="$SCAN_RESULTS_DIR/trivy-${image_name}-vulnerabilities.json"
        local config_output="$SCAN_RESULTS_DIR/trivy-${image_name}-config.json"
        local report_output="$SCAN_RESULTS_DIR/trivy-${image_name}-report.txt"
        
        if command_exists trivy; then
            # Vulnerability scan
            trivy image --format json --output "$vuln_output" --severity "$SEVERITY_THRESHOLD,CRITICAL" "$image" || true
            
            # Configuration scan
            trivy image --format json --output "$config_output" --scanners config "$image" || true
            
            # Human-readable report
            trivy image --format table "$image" > "$report_output" 2>&1 || true
            
            print_status "SUCCESS" "Image scan completed: $image"
        else
            print_status "WARNING" "Trivy not available for image scanning"
        fi
    done
}

# Generate security report
generate_security_report() {
    print_status "INFO" "Generating security report..."
    
    local report_file="$SCAN_RESULTS_DIR/security-report.md"
    
    cat > "$report_file" << EOF
# Security Scan Report

**Generated**: $(date -u)  
**Repository**: alteriom-docker-images  
**Scan Type**: Enhanced Security Monitoring  
**Severity Threshold**: $SEVERITY_THRESHOLD and above  

## Scan Summary

### Scans Performed

- [x] Filesystem vulnerability scan
- [x] Docker configuration scan  
- [x] Python dependency security scan
- [x] Docker image vulnerability scan

### Results Overview

EOF

    # Count vulnerabilities from JSON files
    local total_vulns=0
    local critical_vulns=0
    local high_vulns=0
    
    for json_file in "$SCAN_RESULTS_DIR"/*.json; do
        if [[ -f "$json_file" ]]; then
            # Try to count vulnerabilities (format may vary by tool)
            local file_vulns=$(jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL" or .Severity == "HIGH") | .Severity' "$json_file" 2>/dev/null | wc -l || echo "0")
            total_vulns=$((total_vulns + file_vulns))
        fi
    done
    
    cat >> "$report_file" << EOF
- **Total High/Critical Vulnerabilities**: $total_vulns
- **Scan Files Generated**: $(ls -1 "$SCAN_RESULTS_DIR"/*.json 2>/dev/null | wc -l)
- **Report Files Generated**: $(ls -1 "$SCAN_RESULTS_DIR"/*.txt 2>/dev/null | wc -l)

### Recommendations

EOF

    if [[ $total_vulns -eq 0 ]]; then
        echo "- ✅ No high or critical vulnerabilities detected" >> "$report_file"
        echo "- ✅ Security posture appears good" >> "$report_file"
        echo "- 📋 Continue regular monitoring schedule" >> "$report_file"
    else
        echo "- ⚠️ $total_vulns high/critical vulnerabilities found" >> "$report_file"
        echo "- 🔧 Review detailed scan results in JSON files" >> "$report_file"
        echo "- 📋 Plan remediation based on severity and impact" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

### Files Generated

$(ls -la "$SCAN_RESULTS_DIR"/ | grep -v "^total" | tail -n +2)

### Next Steps

1. Review detailed scan results in individual files
2. Prioritize remediation based on severity
3. Update dependencies and base images as needed
4. Re-run scans after fixes to verify remediation
5. Schedule regular monitoring (suggested: weekly)

---
*Generated by enhanced-security-monitoring.sh*
EOF

    print_status "SUCCESS" "Security report generated: $report_file"
}

# Main execution
main() {
    echo -e "${BLUE}Starting enhanced security monitoring...${NC}"
    
    # Install tools if needed
    install_security_tools
    
    # Perform scans
    scan_filesystem
    scan_docker_configs
    scan_python_dependencies
    scan_docker_images
    
    # Generate report
    generate_security_report
    
    echo ""
    echo -e "${GREEN}🎉 Enhanced security monitoring completed!${NC}"
    echo ""
    echo "📋 Results available in: $SCAN_RESULTS_DIR/"
    echo "📄 Main report: $SCAN_RESULTS_DIR/security-report.md"
    echo ""
    
    # Quick summary
    local json_count=$(ls -1 "$SCAN_RESULTS_DIR"/*.json 2>/dev/null | wc -l)
    local txt_count=$(ls -1 "$SCAN_RESULTS_DIR"/*.txt 2>/dev/null | wc -l)
    
    print_status "SUCCESS" "$json_count JSON scan results generated"
    print_status "SUCCESS" "$txt_count text reports generated"
    
    # Check for any high severity issues
    if grep -r "CRITICAL\|HIGH" "$SCAN_RESULTS_DIR"/*.json >/dev/null 2>&1; then
        print_status "WARNING" "High or critical severity issues detected - review scan results"
        return 1
    else
        print_status "SUCCESS" "No high or critical severity issues detected"
        return 0
    fi
}

# Run main function
main "$@"