#!/bin/bash

# Integration test for Phase 2A + 2B workflow
# Demonstrates the complete security analysis pipeline

set -euo pipefail

# Configuration
TEST_DIR="/tmp/phase2-integration-test-$(date +%s)"
SCAN_RESULTS_DIR="$TEST_DIR/comprehensive-security-results"

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "PHASE") echo -e "${YELLOW}🚀 $message${NC}" ;;
    esac
}

# Setup test environment
setup_integration_test() {
    print_status "INFO" "Setting up Phase 2 integration test environment..."
    
    mkdir -p "$SCAN_RESULTS_DIR"/{basic,advanced,reports,artifacts,sarif}
    export SCAN_RESULTS_DIR="$SCAN_RESULTS_DIR"
    
    # Create realistic mock scan results
    cat > "$SCAN_RESULTS_DIR/trivy-results.json" << 'EOF'
{
  "Results": [
    {
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2021-44228",
          "Severity": "CRITICAL",
          "Title": "Log4j Remote Code Execution",
          "Description": "Apache Log4j2 <=2.14.1 JNDI features do not protect against attacker controlled LDAP.",
          "PkgName": "log4j-core",
          "InstalledVersion": "2.14.0",
          "FixedVersion": "2.15.0",
          "CVSS": {"nvd": {"V3Score": 10.0}},
          "PublishedDate": "2021-12-10T10:15:09.000Z"
        }
      ]
    }
  ]
}
EOF

    cat > "$SCAN_RESULTS_DIR/safety-results.json" << 'EOF'
[
  {
    "vulnerability_id": "39611",
    "vulnerability": "Jinja2 before 2.11.3 allows XSS by leveraging the xmlattr filter's lack of autoescape functionality.",
    "package": "jinja2",
    "installed_version": "2.10.1",
    "fixed_versions": ["2.11.3"]
  }
]
EOF

    cat > "$SCAN_RESULTS_DIR/hadolint-results.json" << 'EOF'
[
  {
    "code": "DL3008",
    "message": "Pin versions in apt get install",
    "level": "warning",
    "line": 12
  }
]
EOF
    
    print_status "SUCCESS" "Integration test environment ready"
}

# Run Phase 2A workflow
run_phase2a() {
    print_status "PHASE" "Running Phase 2A: SARIF Integration & Unified Reporting"
    
    # Run SARIF aggregator
    print_status "INFO" "Executing SARIF aggregator..."
    ./scripts/sarif-aggregator.sh >/dev/null 2>&1
    
    # Run unified security reporter  
    print_status "INFO" "Executing unified security reporter..."
    ./scripts/unified-security-reporter.sh >/dev/null 2>&1
    
    print_status "SUCCESS" "Phase 2A completed successfully"
}

# Run Phase 2B workflow
run_phase2b() {
    print_status "PHASE" "Running Phase 2B: Vulnerability Correlation & Intelligence"
    
    # Run vulnerability correlation engine
    print_status "INFO" "Executing vulnerability correlation engine..."
    local exit_code=0
    ./scripts/vulnerability-correlation-engine.sh >/dev/null 2>&1 || exit_code=$?
    
    # Exit code 0 or 1 is acceptable (1 means high-risk vulnerabilities found)
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        print_status "SUCCESS" "Phase 2B completed successfully"
    else
        echo "❌ Phase 2B failed with exit code $exit_code"
        return 1
    fi
}

# Analyze results
analyze_results() {
    print_status "PHASE" "Analyzing integrated security results"
    
    # Check Phase 2A outputs
    local sarif_count=$(find "$SCAN_RESULTS_DIR/sarif" -name "*.sarif" 2>/dev/null | wc -l)
    local report_count=$(find "$SCAN_RESULTS_DIR/reports" -name "*.html" -o -name "*.txt" -o -name "*.json" -o -name "*.csv" 2>/dev/null | wc -l)
    
    # Check Phase 2B outputs
    local correlation_count=$(find "$SCAN_RESULTS_DIR/correlation" -name "*.json" -o -name "*.txt" 2>/dev/null | wc -l)
    
    echo ""
    print_status "INFO" "Phase 2A Results:"
    echo "  - SARIF reports: $sarif_count"
    echo "  - Unified reports: $report_count"
    
    print_status "INFO" "Phase 2B Results:"
    echo "  - Correlation reports: $correlation_count"
    
    # Display summary statistics
    if [[ -f "$SCAN_RESULTS_DIR/correlation/vulnerability-correlation-report.json" ]]; then
        local total_vulns=$(jq -r '.vulnerability_summary.total_vulnerabilities' "$SCAN_RESULTS_DIR/correlation/vulnerability-correlation-report.json" 2>/dev/null || echo "0")
        local high_risk=$(jq -r '.vulnerability_summary.risk_distribution.high_risk' "$SCAN_RESULTS_DIR/correlation/vulnerability-correlation-report.json" 2>/dev/null || echo "0")
        local correlation_accuracy=$(jq -r '.correlation_metrics.correlation_accuracy' "$SCAN_RESULTS_DIR/correlation/vulnerability-correlation-report.json" 2>/dev/null || echo "0")
        
        echo ""
        print_status "INFO" "Correlation Summary:"
        echo "  - Total vulnerabilities analyzed: $total_vulns"
        echo "  - High-risk vulnerabilities: $high_risk"
        echo "  - Correlation accuracy: $(echo "$correlation_accuracy * 100" | bc -l 2>/dev/null | cut -d. -f1 || echo "N/A")%"
    fi
    
    print_status "SUCCESS" "Analysis completed"
}

# Display final summary
display_summary() {
    echo ""
    echo "🎉 Phase 2 Integration Test Summary"
    echo "=================================="
    echo ""
    print_status "SUCCESS" "Phase 2A (SARIF & Unified Reporting): ✅ Completed"
    print_status "SUCCESS" "Phase 2B (Correlation & Intelligence): ✅ Completed"
    echo ""
    print_status "INFO" "All reports available in: $SCAN_RESULTS_DIR"
    echo ""
    echo "📂 Key Output Files:"
    echo "  📊 $SCAN_RESULTS_DIR/sarif/unified-security-report.sarif"
    echo "  📝 $SCAN_RESULTS_DIR/reports/unified-security-report.html"
    echo "  🔗 $SCAN_RESULTS_DIR/correlation/vulnerability-correlation-report.json"
    echo "  📋 $SCAN_RESULTS_DIR/correlation/reports/correlation-summary.txt"
    echo ""
    
    if [[ "${KEEP_TEST_FILES:-}" != "true" ]]; then
        print_status "INFO" "Cleaning up test environment..."
        rm -rf "$TEST_DIR"
        print_status "SUCCESS" "Test cleanup completed"
    else
        print_status "INFO" "Test files preserved in: $TEST_DIR"
    fi
}

# Main execution
main() {
    echo "🔒 Phase 2 Security Implementation Integration Test"
    echo "================================================="
    echo ""
    
    setup_integration_test
    run_phase2a
    run_phase2b
    analyze_results
    display_summary
    
    echo ""
    print_status "SUCCESS" "Phase 2 integration test completed successfully!"
}

# Execute main function
main "$@"