#!/bin/bash

# Test Suite for Phase 2B: Vulnerability Correlation & Intelligence
# Validates vulnerability correlation engine, severity normalization, and risk assessment

set -euo pipefail

# Test configuration
TEST_DIR="/tmp/phase2b-test-$(date +%s)"
SCAN_RESULTS_DIR="$TEST_DIR/comprehensive-security-results"
CORRELATION_OUTPUT_DIR="$SCAN_RESULTS_DIR/correlation"

# Color definitions for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if terminal supports colors
if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" ]] || [[ "${CI:-}" ]]; then
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' NC=''
fi

# Print test status messages
print_test() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}✅ $message${NC}" ;;
        "FAIL") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "TEST") echo -e "${PURPLE}🧪 $message${NC}" ;;
        "SETUP") echo -e "${CYAN}🔧 $message${NC}" ;;
    esac
}

# Set up test environment
setup_test_environment() {
    print_test "SETUP" "Setting up Phase 2B test environment..."
    
    mkdir -p "$SCAN_RESULTS_DIR"/{basic,advanced,reports,artifacts,sarif}
    mkdir -p "$CORRELATION_OUTPUT_DIR"/{raw,processed,reports,metrics}
    
    # Set environment variable for scripts
    export SCAN_RESULTS_DIR="$SCAN_RESULTS_DIR"
    
    print_test "PASS" "Test environment setup completed"
}

# Create mock security scan results for testing
create_mock_scan_results() {
    print_test "SETUP" "Creating mock security scan results for correlation testing..."
    
    # Create mock Trivy results with diverse vulnerabilities
    cat > "$SCAN_RESULTS_DIR/trivy-results.json" << 'EOF'
{
  "Results": [
    {
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2021-44228",
          "Severity": "CRITICAL",
          "Title": "Log4j Remote Code Execution",
          "Description": "Apache Log4j2 <=2.14.1 JNDI features do not protect against attacker controlled LDAP and other JNDI related endpoints.",
          "PkgName": "log4j-core",
          "InstalledVersion": "2.14.0",
          "FixedVersion": "2.15.0",
          "CVSS": {
            "nvd": {
              "V3Score": 10.0
            }
          },
          "PublishedDate": "2021-12-10T10:15:09.000Z"
        },
        {
          "VulnerabilityID": "CVE-2022-22965",
          "Severity": "HIGH",
          "Title": "Spring Framework RCE",
          "Description": "A Spring MVC or Spring WebFlux application running on JDK 9+ may be vulnerable to remote code execution (RCE) via data binding on JDK 9+.",
          "PkgName": "spring-core",
          "InstalledVersion": "5.3.16",
          "FixedVersion": "5.3.18",
          "CVSS": {
            "nvd": {
              "V3Score": 9.8
            }
          },
          "PublishedDate": "2022-04-01T23:15:08.000Z"
        },
        {
          "VulnerabilityID": "CVE-2021-23337",
          "Severity": "MEDIUM",
          "Title": "lodash Prototype Pollution",
          "Description": "Lodash versions prior to 4.17.21 are vulnerable to Command Injection via the template function.",
          "PkgName": "lodash",
          "InstalledVersion": "4.17.20",
          "FixedVersion": "4.17.21",
          "CVSS": {
            "nvd": {
              "V3Score": 7.2
            }
          },
          "PublishedDate": "2021-02-15T13:15:12.000Z"
        }
      ]
    }
  ]
}
EOF
    
    # Create mock Safety results (Python security)
    cat > "$SCAN_RESULTS_DIR/safety-results.json" << 'EOF'
[
  {
    "vulnerability_id": "39611",
    "vulnerability": "Jinja2 before 2.11.3 allows XSS by leveraging the xmlattr filter's lack of autoescape functionality.",
    "package": "jinja2",
    "installed_version": "2.10.1",
    "fixed_versions": ["2.11.3"]
  },
  {
    "vulnerability_id": "42194",
    "vulnerability": "Requests before 2.25.1 allows attackers to bypass intended access restrictions via URL redirection to an arbitrary host.",
    "package": "requests",
    "installed_version": "2.24.0",
    "fixed_versions": ["2.25.1"]
  }
]
EOF
    
    # Create mock Hadolint results (Dockerfile linting)
    cat > "$SCAN_RESULTS_DIR/hadolint-results.json" << 'EOF'
[
  {
    "code": "DL3008",
    "message": "Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`",
    "level": "warning",
    "line": 12
  },
  {
    "code": "DL3009",
    "message": "Delete the apt-get lists after installing something",
    "level": "info",
    "line": 15
  },
  {
    "code": "DL3007",
    "message": "Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag",
    "level": "warning",
    "line": 3
  }
]
EOF

    # Create additional mock scan results for testing correlation
    cat > "$SCAN_RESULTS_DIR/grype-results.json" << 'EOF'
{
  "matches": [
    {
      "vulnerability": {
        "id": "CVE-2021-44228",
        "severity": "Critical"
      },
      "artifact": {
        "name": "log4j-core",
        "version": "2.14.0"
      }
    },
    {
      "vulnerability": {
        "id": "CVE-2022-1234",
        "severity": "High"
      },
      "artifact": {
        "name": "example-lib",
        "version": "1.0.0"
      }
    }
  ]
}
EOF
    
    print_test "PASS" "Mock security scan results created"
}

# Test vulnerability correlation engine core functionality
test_correlation_engine() {
    print_test "TEST" "Testing vulnerability correlation engine..."
    
    # Test 1: Script execution - check that it runs, exit code 1 is OK if high-risk vulns found
    local engine_exit_code=0
    SCAN_RESULTS_DIR="$SCAN_RESULTS_DIR" ./scripts/vulnerability-correlation-engine.sh >/dev/null 2>&1 || engine_exit_code=$?
    
    if [[ $engine_exit_code -eq 0 ]] || [[ $engine_exit_code -eq 1 ]]; then
        print_test "PASS" "Correlation engine executed successfully"
    else
        print_test "FAIL" "Correlation engine execution failed with exit code $engine_exit_code"
        echo "Debug: Running script with verbose output..."
        SCAN_RESULTS_DIR="$SCAN_RESULTS_DIR" ./scripts/vulnerability-correlation-engine.sh 2>&1 | tail -10
        return 1
    fi
    
    # Test 2: Output directory structure
    if [[ -d "$CORRELATION_OUTPUT_DIR" ]] && [[ -d "$CORRELATION_OUTPUT_DIR/raw" ]] && [[ -d "$CORRELATION_OUTPUT_DIR/processed" ]]; then
        print_test "PASS" "Correlation output directory structure created"
    else
        print_test "FAIL" "Correlation output directory structure missing"
        return 1
    fi
    
    # Test 3: Vulnerability extraction
    local extracted_files=0
    [[ -f "$CORRELATION_OUTPUT_DIR/raw/trivy-vulnerabilities.json" ]] && ((extracted_files++)) || true
    [[ -f "$CORRELATION_OUTPUT_DIR/raw/safety-vulnerabilities.json" ]] && ((extracted_files++)) || true
    [[ -f "$CORRELATION_OUTPUT_DIR/raw/hadolint-vulnerabilities.json" ]] && ((extracted_files++)) || true
    
    if [[ $extracted_files -ge 2 ]]; then
        print_test "PASS" "Vulnerability extraction successful ($extracted_files tool outputs processed)"
    else
        print_test "FAIL" "Insufficient vulnerability extraction ($extracted_files tool outputs)"
        return 1
    fi
    
    # Test 4: Severity normalization
    if [[ -f "$CORRELATION_OUTPUT_DIR/normalized-vulnerabilities.json" ]]; then
        local normalized_vulns=$(jq 'length' "$CORRELATION_OUTPUT_DIR/normalized-vulnerabilities.json" 2>/dev/null || echo 0)
        if [[ $normalized_vulns -gt 0 ]]; then
            print_test "PASS" "Severity normalization completed ($normalized_vulns vulnerabilities normalized)"
        else
            print_test "FAIL" "Severity normalization produced no results"
            return 1
        fi
    else
        print_test "FAIL" "Normalized vulnerabilities file not created"
        return 1
    fi
    
    # Test 5: Duplicate detection
    if [[ -f "$CORRELATION_OUTPUT_DIR/deduplicated-vulnerabilities.json" ]]; then
        local deduplicated_vulns=$(jq 'length' "$CORRELATION_OUTPUT_DIR/deduplicated-vulnerabilities.json" 2>/dev/null || echo 0)
        if [[ $deduplicated_vulns -gt 0 ]]; then
            print_test "PASS" "Duplicate detection completed ($deduplicated_vulns unique vulnerabilities)"
        else
            print_test "FAIL" "Duplicate detection produced no results"
            return 1
        fi
    else
        print_test "FAIL" "Deduplicated vulnerabilities file not created"
        return 1
    fi
    
    print_test "PASS" "All correlation engine tests passed"
}

# Test risk assessment functionality
test_risk_assessment() {
    print_test "TEST" "Testing contextual risk assessment..."
    
    # Test 1: Risk assessment report generation
    if [[ -f "$CORRELATION_OUTPUT_DIR/contextual-risk-assessment.json" ]]; then
        print_test "PASS" "Risk assessment report generated"
    else
        print_test "FAIL" "Risk assessment report not generated"
        return 1
    fi
    
    # Test 2: Risk summary generation
    if [[ -f "$CORRELATION_OUTPUT_DIR/reports/risk-summary.json" ]]; then
        print_test "PASS" "Risk summary report generated"
    else
        print_test "FAIL" "Risk summary report not generated"
        return 1
    fi
    
    # Test 3: Risk categorization validation
    local risk_categories=$(jq -r '.risk_distribution | keys[]' "$CORRELATION_OUTPUT_DIR/reports/risk-summary.json" 2>/dev/null | wc -l)
    if [[ $risk_categories -ge 3 ]]; then
        print_test "PASS" "Risk categorization working ($risk_categories categories)"
    else
        print_test "FAIL" "Insufficient risk categorization ($risk_categories categories)"
        return 1
    fi
    
    # Test 4: Priority scoring validation
    local has_priority_scores=$(jq '[.[] | select(.priority_score != null)] | length' "$CORRELATION_OUTPUT_DIR/contextual-risk-assessment.json" 2>/dev/null || echo 0)
    if [[ $has_priority_scores -gt 0 ]]; then
        print_test "PASS" "Priority scoring applied ($has_priority_scores vulnerabilities scored)"
    else
        print_test "FAIL" "Priority scoring not applied"
        return 1
    fi
    
    print_test "PASS" "All risk assessment tests passed"
}

# Test correlation report generation
test_correlation_reports() {
    print_test "TEST" "Testing correlation report generation..."
    
    # Test 1: Comprehensive JSON report
    if [[ -f "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" ]]; then
        if jq empty "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" 2>/dev/null; then
            print_test "PASS" "Comprehensive correlation report is valid JSON"
        else
            print_test "FAIL" "Comprehensive correlation report is invalid JSON"
            return 1
        fi
    else
        print_test "FAIL" "Comprehensive correlation report not generated"
        return 1
    fi
    
    # Test 2: Human-readable summary
    if [[ -f "$CORRELATION_OUTPUT_DIR/reports/correlation-summary.txt" ]]; then
        print_test "PASS" "Human-readable correlation summary generated"
    else
        print_test "FAIL" "Human-readable correlation summary not generated"
        return 1
    fi
    
    # Test 3: Report metadata validation
    local has_metadata=$(jq '.correlation_metadata != null' "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" 2>/dev/null || echo false)
    if [[ "$has_metadata" == "true" ]]; then
        print_test "PASS" "Report metadata included"
    else
        print_test "FAIL" "Report metadata missing"
        return 1
    fi
    
    # Test 4: Correlation metrics validation
    local has_metrics=$(jq '.correlation_metrics != null' "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" 2>/dev/null || echo false)
    if [[ "$has_metrics" == "true" ]]; then
        print_test "PASS" "Correlation metrics included"
    else
        print_test "FAIL" "Correlation metrics missing"
        return 1
    fi
    
    print_test "PASS" "All correlation report tests passed"
}

# Test file permissions and security
test_security_and_permissions() {
    print_test "TEST" "Testing file permissions and security..."
    
    # Test directory permissions
    local dir_perms=$(stat -c "%a" "$CORRELATION_OUTPUT_DIR" 2>/dev/null || echo "000")
    if [[ "$dir_perms" == "750" ]]; then
        print_test "PASS" "Correlation output directory has correct permissions (750)"
    else
        print_test "FAIL" "Correlation output directory has incorrect permissions ($dir_perms, expected 750)"
        return 1
    fi
    
    # Test that sensitive data is not exposed
    if ! grep -r "password\|secret\|token" "$CORRELATION_OUTPUT_DIR" >/dev/null 2>&1; then
        print_test "PASS" "No sensitive data exposed in correlation reports"
    else
        print_test "FAIL" "Potential sensitive data found in correlation reports"
        return 1
    fi
    
    print_test "PASS" "All security and permissions tests passed"
}

# Test integration with existing Phase 2A components
test_phase2a_integration() {
    print_test "TEST" "Testing integration with Phase 2A components..."
    
    # Test 1: Compatibility with SARIF aggregator output directory
    if [[ -d "$SCAN_RESULTS_DIR/sarif" ]]; then
        print_test "PASS" "Compatible with existing SARIF directory structure"
    else
        print_test "FAIL" "SARIF directory structure not found"
        return 1
    fi
    
    # Test 2: Cross-references in reports
    if grep -qi "correlation" "$CORRELATION_OUTPUT_DIR/reports/correlation-summary.txt" 2>/dev/null; then
        print_test "PASS" "Correlation reports reference correlation data correctly"
    else
        print_test "FAIL" "Correlation reports don't reference correlation data"
        return 1
    fi
    
    print_test "PASS" "Phase 2A integration tests passed"
}

# Display test results summary
display_test_summary() {
    print_test "INFO" "Phase 2B test execution completed"
    echo ""
    
    local reports_count=$(find "$CORRELATION_OUTPUT_DIR" -name "*.json" | wc -l)
    local summary_size=$(stat -c%s "$CORRELATION_OUTPUT_DIR/reports/correlation-summary.txt" 2>/dev/null || echo 0)
    
    echo "📊 Test Results Summary:"
    echo "  - Correlation reports generated: $reports_count"
    echo "  - Summary report size: $(echo "$summary_size" | numfmt --to=iec-i 2>/dev/null || echo "$summary_size")B"
    
    if [[ -f "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" ]]; then
        local total_vulns=$(jq -r '.vulnerability_summary.total_vulnerabilities' "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" 2>/dev/null || echo "0")
        local high_risk=$(jq -r '.vulnerability_summary.risk_distribution.high_risk' "$CORRELATION_OUTPUT_DIR/vulnerability-correlation-report.json" 2>/dev/null || echo "0")
        echo "  - Total vulnerabilities processed: $total_vulns"
        echo "  - High-risk vulnerabilities: $high_risk"
    fi
    
    if [[ -f "$CORRELATION_OUTPUT_DIR/reports/correlation-summary.txt" ]]; then
        echo "  - Summary report: $(du -h "$CORRELATION_OUTPUT_DIR/reports/correlation-summary.txt" | cut -f1)"
    fi
    
    echo ""
    print_test "INFO" "Test artifacts available in: $TEST_DIR"
}

# Clean up test environment
cleanup_test_environment() {
    if [[ "${KEEP_TEST_FILES:-}" != "true" ]]; then
        print_test "INFO" "Cleaning up test environment..."
        rm -rf "$TEST_DIR"
        print_test "PASS" "Test cleanup completed"
    else
        print_test "INFO" "Test files preserved in: $TEST_DIR"
    fi
}

# Main test execution
main() {
    echo "🧪 Phase 2B Security Improvements Test Suite"
    echo "============================================="
    echo ""
    
    local test_passed=0
    local test_failed=0
    
    # Run test phases
    setup_test_environment
    create_mock_scan_results
    
    # Core functionality tests
    if test_correlation_engine; then
        ((test_passed++)) || true
    else
        ((test_failed++)) || true
    fi
    
    if test_risk_assessment; then
        ((test_passed++)) || true
    else
        ((test_failed++)) || true
    fi
    
    if test_correlation_reports; then
        ((test_passed++)) || true
    else
        ((test_failed++)) || true
    fi
    
    if test_security_and_permissions; then
        ((test_passed++)) || true
    else
        ((test_failed++)) || true
    fi
    
    if test_phase2a_integration; then
        ((test_passed++)) || true
    else
        ((test_failed++)) || true
    fi
    
    # Display results
    display_test_summary
    cleanup_test_environment
    
    echo ""
    echo "📊 Final Test Results:"
    print_test "PASS" "Tests passed: $test_passed"
    if [[ $test_failed -gt 0 ]]; then
        print_test "FAIL" "Tests failed: $test_failed"
        echo ""
        print_test "FAIL" "Phase 2B implementation validation failed"
        exit 1
    else
        print_test "PASS" "Tests failed: $test_failed"
        echo ""
        print_test "PASS" "Phase 2B implementation validation successful"
        return 0
    fi
}

# Execute main function
main "$@"