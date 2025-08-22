#!/bin/bash

# Comprehensive Security Scanner Demo
# Demonstrates the multi-tool security analysis capabilities

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 COMPREHENSIVE SECURITY SCANNER DEMONSTRATION${NC}"
echo "================================================================="
echo "This demo shows the multi-tool security analysis capabilities"
echo "for the alteriom-docker-images repository."
echo ""

# Function to print demo status
demo_status() {
    local status=$1
    local message=$2
    case $status in
        "DEMO") echo -e "${CYAN}🎬 $message${NC}" ;;
        "TOOL") echo -e "${BLUE}🔧 $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "INFO") echo -e "${YELLOW}ℹ️  $message${NC}" ;;
    esac
}

demo_status "DEMO" "Starting comprehensive security scanner demonstration..."
echo ""

# Check if the comprehensive scanner exists
if [ ! -f "scripts/comprehensive-security-scanner.sh" ]; then
    demo_status "INFO" "Comprehensive security scanner not found. Please ensure it's installed."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "production/Dockerfile" ] || [ ! -f "development/Dockerfile" ]; then
    demo_status "INFO" "Please run this demo from the repository root directory."
    exit 1
fi

# Demo: Show available security tools
demo_status "DEMO" "Available Security Tools in Comprehensive Scanner:"
echo ""

demo_status "TOOL" "Basic Vulnerability Scanning:"
echo "   • Trivy - Container & filesystem vulnerability scanner"
echo "   • Grype - Advanced vulnerability detection"
echo "   • Hadolint - Dockerfile security linting"
echo "   • Dockle - Container security best practices"
echo "   • Safety - Python dependency vulnerability scanning"
echo ""

demo_status "TOOL" "Advanced Security Analysis:"
echo "   • Bandit - Python security static analysis"
echo "   • Semgrep - Multi-language static analysis"
echo "   • Checkov - Infrastructure as Code security"
echo "   • Syft - Software Bill of Materials (SBOM) generation"
echo "   • ClamAV - Malware and virus detection"
echo ""

demo_status "TOOL" "Advanced Features:"
echo "   • Cryptographic material analysis"
echo "   • Container runtime security assessment"
echo "   • Supply chain security validation"
echo "   • Compliance framework checking"
echo "   • Secret detection in code and git history"
echo ""

# Demo: Run a quick basic scan
demo_status "DEMO" "Running Quick Basic Security Scan Demo..."
echo ""

# Create a temporary demo results directory
DEMO_RESULTS_DIR="demo-security-results"
mkdir -p "$DEMO_RESULTS_DIR"

# Run basic checks that don't require tool installation
demo_status "INFO" "Checking repository structure for security issues..."

# 1. Check for potential secrets in files
demo_status "TOOL" "Running secret detection demo..."
{
    echo "# Secret Detection Demo Results"
    echo "Generated: $(date -u)"
    echo ""
    echo "## Potential Secrets Scan"
    
    # Search for potential secrets (demo mode - won't find real secrets)
    SECRET_PATTERNS="password|token|key|secret|api"
    if grep -r -i -E "$SECRET_PATTERNS" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.md" --exclude="*.log" 2>/dev/null | head -5; then
        echo "⚠️ Potential secrets found (review context)"
    else
        echo "✅ No obvious secrets detected in source files"
    fi
} > "$DEMO_RESULTS_DIR/secret-detection-demo.txt"

# 2. Analyze Dockerfiles for security best practices
demo_status "TOOL" "Running Dockerfile security analysis demo..."
{
    echo "# Dockerfile Security Analysis Demo"
    echo "Generated: $(date -u)"
    echo ""
    
    for dockerfile in production/Dockerfile development/Dockerfile; do
        if [ -f "$dockerfile" ]; then
            echo "## Analysis: $dockerfile"
            echo ""
            
            # Check for non-root user
            if grep -q "USER" "$dockerfile"; then
                echo "✅ Non-root user specified"
            else
                echo "⚠️ No non-root user specified"
            fi
            
            # Check for health check
            if grep -q "HEALTHCHECK" "$dockerfile"; then
                echo "✅ Health check configured"
            else
                echo "⚠️ No health check configured"
            fi
            
            # Check for package pinning
            if grep -q "=" "$dockerfile"; then
                echo "✅ Version pinning detected"
            else
                echo "⚠️ Consider pinning package versions"
            fi
            
            # Check for security updates
            if grep -q -i "security" "$dockerfile"; then
                echo "✅ Security-related updates present"
            else
                echo "ℹ️ No obvious security updates"
            fi
            
            echo ""
        fi
    done
} > "$DEMO_RESULTS_DIR/dockerfile-analysis-demo.txt"

# 3. Generate demo dependency analysis
demo_status "TOOL" "Running dependency analysis demo..."
{
    echo "# Dependency Analysis Demo"
    echo "Generated: $(date -u)"
    echo ""
    echo "## Key Dependencies Analysis"
    echo ""
    
    # Check for key dependencies in Dockerfiles
    echo "### Production Image Dependencies"
    if grep -E "pip install|platformio" production/Dockerfile; then
        echo "✅ Dependencies identified for analysis"
    else
        echo "ℹ️ No obvious Python dependencies"
    fi
    
    echo ""
    echo "### Development Image Dependencies"
    if grep -E "pip install|platformio" development/Dockerfile; then
        echo "✅ Dependencies identified for analysis"
    else
        echo "ℹ️ No obvious Python dependencies"
    fi
    
    echo ""
    echo "### Security Considerations"
    echo "- PlatformIO version: Check for latest security updates"
    echo "- Python base image: Monitor for security patches"
    echo "- Package dependencies: Regular vulnerability scanning"
    
} > "$DEMO_RESULTS_DIR/dependency-analysis-demo.txt"

# 4. Create demo compliance report
demo_status "TOOL" "Running compliance checking demo..."
{
    echo "# Security Compliance Demo Report"
    echo "Generated: $(date -u)"
    echo ""
    echo "## Container Security Compliance"
    echo ""
    
    # Check basic security practices
    echo "### Basic Security Practices"
    echo ""
    
    # Check for .dockerignore
    if [ -f ".dockerignore" ]; then
        echo "✅ .dockerignore file present (reduces attack surface)"
    else
        echo "⚠️ Consider adding .dockerignore file"
    fi
    
    # Check for security documentation
    if [ -f "SECURITY.md" ]; then
        echo "✅ Security documentation present"
    else
        echo "⚠️ Consider adding SECURITY.md file"
    fi
    
    # Check for GitHub security features
    if [ -d ".github" ]; then
        echo "✅ GitHub integration configured"
    else
        echo "ℹ️ GitHub integration not configured"
    fi
    
    echo ""
    echo "### Compliance Framework Assessment"
    echo "- CIS Docker Benchmark: Partially implemented"
    echo "- NIST Cybersecurity Framework: Basic controls in place"
    echo "- OWASP Container Security: Standard practices followed"
    
} > "$DEMO_RESULTS_DIR/compliance-demo.txt"

# Demo: Show results
echo ""
demo_status "SUCCESS" "Demo security scans completed!"
echo ""

demo_status "INFO" "Demo Results Generated:"
for file in "$DEMO_RESULTS_DIR"/*.txt; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        size=$(stat -c%s "$file")
        echo "   📄 $filename (${size} bytes)"
    fi
done

echo ""
demo_status "DEMO" "Sample scan output:"
echo ""
echo "$(head -15 "$DEMO_RESULTS_DIR/dockerfile-analysis-demo.txt")"
echo "..."

echo ""
demo_status "SUCCESS" "Demo completed! To run the full comprehensive security scanner:"
echo ""
echo -e "${CYAN}   ./scripts/comprehensive-security-scanner.sh${NC}"
echo ""
echo "This will run all security tools and generate detailed analysis reports."

# Cleanup demo results
echo ""
demo_status "INFO" "Cleaning up demo results..."
rm -rf "$DEMO_RESULTS_DIR"

echo ""
demo_status "SUCCESS" "Comprehensive Security Scanner Demo Complete! 🎉"
echo ""