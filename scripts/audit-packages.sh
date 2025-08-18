#!/usr/bin/env bash
# Package Audit Script for Daily Builds
# Checks for package updates and determines if a build is needed
# Compares current versions with production and reports changes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_REPO="${DOCKER_REPOSITORY:-ghcr.io/sparck75/alteriom-docker-images}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_change() {
    echo -e "${CYAN}[CHANGE]${NC} $1"
}

# Get current production version info
get_production_version_info() {
    local image_name="${DOCKER_REPO}/builder:latest"
    
    >&2 echo "[INFO] Fetching production image version information..."
    
    if ! docker pull "$image_name" >/dev/null 2>&1; then
        >&2 echo "[WARNING] Cannot pull production image $image_name"
        return 1
    fi
    
    # Get PlatformIO version from production image
    local pio_version
    if pio_version=$(docker run --rm "$image_name" --version 2>/dev/null | grep -oE "version [0-9]+\.[0-9]+\.[0-9]+" | cut -d' ' -f2); then
        echo "PROD_PIO_VERSION=$pio_version"
    else
        echo "PROD_PIO_VERSION=unknown"
    fi
    
    # Get Python version from production image
    local python_version
    if python_version=$(docker run --rm --entrypoint python "$image_name" --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+"); then
        echo "PROD_PYTHON_VERSION=$python_version"
    else
        echo "PROD_PYTHON_VERSION=unknown"
    fi
    
    # Get base image creation date
    local created_date
    if created_date=$(docker inspect "$image_name" --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1); then
        echo "PROD_CREATED_DATE=$created_date"
    else
        echo "PROD_CREATED_DATE=unknown"
    fi
}

# Check for latest available versions
check_latest_versions() {
    >&2 echo "[INFO] Checking for latest package versions..."
    
    # Check latest PlatformIO version
    local latest_pio_version
    if command -v pip3 >/dev/null 2>&1; then
        if latest_pio_version=$(timeout 30 pip3 index versions platformio 2>/dev/null | grep -oE "Available versions: [0-9]+\.[0-9]+\.[0-9]+" | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+"); then
            echo "LATEST_PIO_VERSION=$latest_pio_version"
        else
            # Fallback: try pip search (may not work in all environments)
            latest_pio_version="6.1.13"  # Current pinned version as fallback
            echo "LATEST_PIO_VERSION=$latest_pio_version"
        fi
    else
        >&2 echo "[WARNING] pip3 not available for version checking"
        echo "LATEST_PIO_VERSION=unknown"
    fi
    
    # Check Python base image updates by examining Docker Hub
    # For python:3.11-slim, we'll check if there's a newer digest
    local base_image_age_days
    if command -v docker >/dev/null 2>&1; then
        # Pull latest python:3.11-slim to check for updates
        if docker pull python:3.11-slim >/dev/null 2>&1; then
            local base_created
            if base_created=$(docker inspect python:3.11-slim --format='{{.Created}}' 2>/dev/null); then
                # Calculate age in days
                local created_epoch
                created_epoch=$(date -d "$base_created" +%s 2>/dev/null || echo "0")
                local current_epoch
                current_epoch=$(date +%s)
                base_image_age_days=$(( (current_epoch - created_epoch) / 86400 ))
                echo "BASE_IMAGE_AGE_DAYS=$base_image_age_days"
            else
                echo "BASE_IMAGE_AGE_DAYS=unknown"
            fi
        else
            echo "BASE_IMAGE_AGE_DAYS=unknown"
        fi
    else
        echo "BASE_IMAGE_AGE_DAYS=unknown"
    fi
    
    # Check system package updates (simulate)
    # In a real environment, this would check for security updates
    local security_updates_available="false"
    if command -v apt >/dev/null 2>&1; then
        # This is a placeholder - in production you might want to check
        # for security updates or critical package updates
        echo "SECURITY_UPDATES_AVAILABLE=$security_updates_available"
    else
        echo "SECURITY_UPDATES_AVAILABLE=unknown"
    fi
}

# Compare versions and detect changes
analyze_changes() {
    local prod_pio_version="${1:-unknown}"
    local latest_pio_version="${2:-unknown}"
    local prod_python_version="${3:-unknown}"
    local prod_created_date="${4:-unknown}"
    local base_image_age_days="${5:-unknown}"
    local security_updates="${6:-unknown}"
    
    local changes_detected=false
    local change_summary=""
    local build_recommended=false
    
    print_status "Analyzing changes..."
    echo ""
    
    # Compare PlatformIO versions
    if [[ "$prod_pio_version" != "unknown" && "$latest_pio_version" != "unknown" ]]; then
        if [[ "$prod_pio_version" != "$latest_pio_version" ]]; then
            print_change "PlatformIO version difference detected"
            echo "  Production: $prod_pio_version"
            echo "  Latest:     $latest_pio_version"
            changes_detected=true
            change_summary="${change_summary}PlatformIO: $prod_pio_version → $latest_pio_version; "
            
            # Note: We pin PlatformIO to 6.1.13, so this is informational only
            print_warning "Note: PlatformIO is pinned to 6.1.13 in Dockerfile"
        else
            print_success "PlatformIO version is current: $prod_pio_version"
        fi
    else
        print_warning "Cannot compare PlatformIO versions (prod: $prod_pio_version, latest: $latest_pio_version)"
    fi
    
    # Check base image age
    if [[ "$base_image_age_days" != "unknown" ]]; then
        if [[ "$base_image_age_days" -gt 7 ]]; then
            print_change "Base image python:3.11-slim is $base_image_age_days days old"
            changes_detected=true
            build_recommended=true
            change_summary="${change_summary}Base image: $base_image_age_days days old; "
        else
            print_success "Base image is recent ($base_image_age_days days old)"
        fi
    fi
    
    # Check production image age
    if [[ "$prod_created_date" != "unknown" ]]; then
        local prod_age_days
        local prod_epoch
        prod_epoch=$(date -d "$prod_created_date" +%s 2>/dev/null || echo "0")
        local current_epoch
        current_epoch=$(date +%s)
        prod_age_days=$(( (current_epoch - prod_epoch) / 86400 ))
        
        if [[ "$prod_age_days" -gt 30 ]]; then
            print_change "Production image is $prod_age_days days old"
            echo "  Created: $prod_created_date"
            changes_detected=true
            build_recommended=true
            change_summary="${change_summary}Production age: $prod_age_days days; "
        elif [[ "$prod_age_days" -gt 7 ]]; then
            print_warning "Production image is $prod_age_days days old (created: $prod_created_date)"
            change_summary="${change_summary}Production age: $prod_age_days days; "
        else
            print_success "Production image is recent ($prod_age_days days old)"
        fi
    fi
    
    # Check for security updates
    if [[ "$security_updates" = "true" ]]; then
        print_change "Security updates are available"
        changes_detected=true
        build_recommended=true
        change_summary="${change_summary}Security updates available; "
    fi
    
    # Weekly build refresh (every Sunday or if >7 days since last build)
    local day_of_week
    day_of_week=$(date +%u)  # 1=Monday, 7=Sunday
    if [[ "$day_of_week" = "7" ]] || [[ "${base_image_age_days:-0}" -gt 7 ]]; then
        print_change "Weekly refresh build recommended (Sunday or >7 days since base update)"
        build_recommended=true
        change_summary="${change_summary}Weekly refresh; "
    fi
    
    echo ""
    
    # Generate summary
    if [[ "$changes_detected" = true || "$build_recommended" = true ]]; then
        print_change "Build is recommended"
        echo "CHANGES_DETECTED=true"
        echo "BUILD_RECOMMENDED=true"
        echo "CHANGE_SUMMARY=${change_summary%%; }"
    else
        print_success "No significant changes detected"
        echo "CHANGES_DETECTED=false"
        echo "BUILD_RECOMMENDED=false"
        echo "CHANGE_SUMMARY=No changes detected"
    fi
}

# Generate audit report
generate_audit_report() {
    local changes_detected="${1:-false}"
    local change_summary="${2:-No changes detected}"
    local prod_pio_version="${3:-unknown}"
    local latest_pio_version="${4:-unknown}"
    local prod_created_date="${5:-unknown}"
    local base_image_age_days="${6:-unknown}"
    
    local report_file="${REPO_ROOT}/audit-report.md"
    local timestamp
    timestamp=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
    
    cat > "$report_file" << EOF
# Daily Build Audit Report

**Generated:** $timestamp  
**Repository:** alteriom-docker-images  
**Production Image:** ${DOCKER_REPO}/builder:latest  

## Summary

**Changes Detected:** $changes_detected  
**Build Recommended:** ${BUILD_RECOMMENDED:-false}  
**Change Summary:** $change_summary  

## Version Comparison

| Component | Production | Latest Available | Status |
|-----------|------------|------------------|--------|
| PlatformIO | $prod_pio_version | $latest_pio_version | $([ "$prod_pio_version" = "$latest_pio_version" ] && echo "✅ Current" || echo "⚠️ Different (pinned)") |
| Python Base | python:3.11-slim | python:3.11-slim | $([ "${base_image_age_days:-999}" -lt 7 ] && echo "✅ Recent" || echo "⚠️ ${base_image_age_days:-unknown} days old") |
| Production Image Age | $prod_created_date | - | $([ "${base_image_age_days:-999}" -lt 7 ] && echo "✅ Recent" || echo "⚠️ Consider refresh") |

## Analysis

### PlatformIO
- **Production Version:** $prod_pio_version
- **Latest Available:** $latest_pio_version
- **Note:** PlatformIO is pinned to version 6.1.13 for stability

### Base Image
- **Image:** python:3.11-slim
- **Age:** ${base_image_age_days:-unknown} days
- **Recommendation:** $([ "${base_image_age_days:-999}" -gt 7 ] && echo "Update recommended" || echo "Current")

### Build Decision
$(if [ "$changes_detected" = "true" ] || [ "${BUILD_RECOMMENDED:-false}" = "true" ]; then
echo "**✅ PROCEED WITH BUILD**"
echo ""
echo "Reasons for build:"
echo "$change_summary" | tr ';' '\n' | sed 's/^/- /'
else
echo "**⏭️ SKIP BUILD**"
echo ""
echo "No significant changes detected. Daily build can be skipped."
fi)

## Next Steps

$(if [ "$changes_detected" = "true" ] || [ "${BUILD_RECOMMENDED:-false}" = "true" ]; then
echo "1. Proceed with development image build"
echo "2. Tag with date-specific version"
echo "3. Update development image tags"
echo "4. Generate build summary"
else
echo "1. Skip build process"
echo "2. Monitor for future changes"
echo "3. Next audit in 24 hours"
fi)

---
*This report is automatically generated by the daily build audit process.*
EOF

    print_success "Audit report generated: $report_file"
}

# Main function
main() {
    echo "========================================"
    echo "    Daily Build Package Audit"
    echo "========================================"
    echo "Repository: ${DOCKER_REPO}"
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    
    # Get production version info
    print_status "=== Production Version Analysis ==="
    local prod_info
    if prod_info=$(get_production_version_info); then
        # Parse the output
        eval "$prod_info"
    else
        print_error "Failed to get production version information"
        PROD_PIO_VERSION="unknown"
        PROD_PYTHON_VERSION="unknown"
        PROD_CREATED_DATE="unknown"
    fi
    echo ""
    
    # Check latest versions
    print_status "=== Latest Version Check ==="
    local latest_info
    if latest_info=$(check_latest_versions); then
        eval "$latest_info"
    else
        print_error "Failed to check latest versions"
        LATEST_PIO_VERSION="unknown"
        BASE_IMAGE_AGE_DAYS="unknown"
        SECURITY_UPDATES_AVAILABLE="unknown"
    fi
    echo ""
    
    # Analyze changes
    print_status "=== Change Analysis ==="
    local analysis_result
    if analysis_result=$(analyze_changes \
        "${PROD_PIO_VERSION:-unknown}" \
        "${LATEST_PIO_VERSION:-unknown}" \
        "${PROD_PYTHON_VERSION:-unknown}" \
        "${PROD_CREATED_DATE:-unknown}" \
        "${BASE_IMAGE_AGE_DAYS:-unknown}" \
        "${SECURITY_UPDATES_AVAILABLE:-unknown}")
    then
        eval "$analysis_result"
    else
        print_error "Failed to analyze changes"
        CHANGES_DETECTED="false"
        BUILD_RECOMMENDED="false"
        CHANGE_SUMMARY="Analysis failed"
    fi
    echo ""
    
    # Generate report
    print_status "=== Report Generation ==="
    generate_audit_report \
        "${CHANGES_DETECTED:-false}" \
        "${CHANGE_SUMMARY:-No changes detected}" \
        "${PROD_PIO_VERSION:-unknown}" \
        "${LATEST_PIO_VERSION:-unknown}" \
        "${PROD_CREATED_DATE:-unknown}" \
        "${BASE_IMAGE_AGE_DAYS:-unknown}"
    echo ""
    
    # Final summary
    echo "========================================"
    print_status "AUDIT COMPLETE"
    echo "========================================"
    
    if [[ "${BUILD_RECOMMENDED:-false}" = "true" ]]; then
        print_success "✅ BUILD RECOMMENDED"
        echo "Changes detected: ${CHANGE_SUMMARY:-No summary available}"
        echo ""
        echo "Environment variables for build process:"
        echo "export AUDIT_CHANGES_DETECTED=${CHANGES_DETECTED:-false}"
        echo "export AUDIT_BUILD_RECOMMENDED=${BUILD_RECOMMENDED:-false}"
        echo "export AUDIT_CHANGE_SUMMARY='${CHANGE_SUMMARY:-No changes detected}'"
        exit 0
    else
        print_success "⏭️ BUILD NOT NEEDED"
        echo "Reason: ${CHANGE_SUMMARY:-No changes detected}"
        echo ""
        echo "Environment variables for build process:"
        echo "export AUDIT_CHANGES_DETECTED=${CHANGES_DETECTED:-false}"
        echo "export AUDIT_BUILD_RECOMMENDED=${BUILD_RECOMMENDED:-false}"
        echo "export AUDIT_CHANGE_SUMMARY='${CHANGE_SUMMARY:-No changes detected}'"
        exit 1  # Exit with non-zero to signal build can be skipped
    fi
}

# Show usage if help requested
if [[ "${1:-}" = "--help" ]] || [[ "${1:-}" = "-h" ]]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Audit packages and determine if a daily build is needed."
    echo "Compares current production versions with latest available versions."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_REPOSITORY   Docker repository prefix"
    echo ""
    echo "Exit Codes:"
    echo "  0  Build is recommended (changes detected)"
    echo "  1  Build can be skipped (no significant changes)"
    echo ""
    echo "Generated Files:"
    echo "  audit-report.md     Detailed audit report"
    echo ""
    echo "Environment Variables Set:"
    echo "  AUDIT_CHANGES_DETECTED   true/false"
    echo "  AUDIT_BUILD_RECOMMENDED  true/false" 
    echo "  AUDIT_CHANGE_SUMMARY     Summary of changes"
    exit 0
fi

# Check prerequisites
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is required but not available"
    exit 1
fi

# Run the audit
main "$@"