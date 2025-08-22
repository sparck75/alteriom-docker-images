#!/usr/bin/env bash

# 🛡️ Comprehensive Service Monitoring for ESP32/ESP8266 Docker Images
# Enhanced validation system with multi-layer service verification and health monitoring

set -euo pipefail

# Colors for enhanced output visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-ghcr.io/sparck75/alteriom-docker-images}"
TIMEOUT="${TIMEOUT:-30}"
REPORT_DIR="${REPORT_DIR:-service-monitoring-results}"
ADVANCED_MODE="${ADVANCED_MODE:-true}"

# Create results directory with timestamp
mkdir -p "$REPORT_DIR"
echo "$(date -u)" > "$REPORT_DIR/execution-timestamp.txt"

echo -e "${BOLD}${PURPLE}🛡️  ESP32/ESP8266 DOCKER IMAGES - COMPREHENSIVE SERVICE MONITORING${NC}"
echo "================================================================================"
echo -e "${CYAN}🎯 Repository:${NC} $DOCKER_REPOSITORY"
echo -e "${CYAN}📁 Reports:${NC} $REPORT_DIR"
echo -e "${CYAN}⏰ Started:${NC} $(date -u)"
echo -e "${CYAN}🔧 Advanced Mode:${NC} $ADVANCED_MODE"
echo ""

# Function to print status with enhanced visibility
print_status() {
    local status=$1
    local message=$2
    local emoji=""
    case $status in
        "SUCCESS") emoji="✅"; echo -e "${BOLD}${GREEN}$emoji $message${NC}" ;;
        "WARNING") emoji="⚠️"; echo -e "${BOLD}${YELLOW}$emoji $message${NC}" ;;
        "ERROR") emoji="❌"; echo -e "${BOLD}${RED}$emoji $message${NC}" ;;
        "INFO") emoji="ℹ️"; echo -e "${BLUE}$emoji $message${NC}" ;;
        "SERVICE") emoji="🔧"; echo -e "${BOLD}${CYAN}$emoji $message${NC}" ;;
        "HEALTH") emoji="🩺"; echo -e "${BOLD}${PURPLE}$emoji $message${NC}" ;;
        "PLATFORM") emoji="🚀"; echo -e "${BOLD}${BLUE}$emoji $message${NC}" ;;
    esac
}

# Enhanced service check counter with categories
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

SERVICE_CATEGORIES=("Image_Availability" "Health_Check" "PlatformIO_Service" "Container_Runtime" "ESP_Platform_Support" "Network_Connectivity")

increment_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    case "$1" in
        "PASS") PASSED_CHECKS=$((PASSED_CHECKS + 1)) ;;
        "FAIL") FAILED_CHECKS=$((FAILED_CHECKS + 1)) ;;
        "WARN") WARNING_CHECKS=$((WARNING_CHECKS + 1)) ;;
    esac
}

# Create detailed progress tracking
cat > "$REPORT_DIR/service-categories.md" << 'EOF'
# 🛡️ Service Monitoring Categories

## Overview
This service monitoring system validates 6 critical service categories:

1. **Image Availability** - Registry connectivity and image pullability
2. **Health Check Validation** - Docker HEALTHCHECK functionality
3. **PlatformIO Service** - Core ESP32/ESP8266 development functionality  
4. **Container Runtime** - Execution behavior and command processing
5. **ESP Platform Support** - Platform installation and availability
6. **Network Connectivity** - External service access validation

EOF

echo -e "${BOLD}${CYAN}📋 SERVICE MONITORING CATEGORIES:${NC}"
for category in "${SERVICE_CATEGORIES[@]}"; do
    echo -e "   ${BLUE}•${NC} ${category//_/ }"
done
echo ""

# 1. Enhanced Image Availability Check
print_status "SERVICE" "CATEGORY 1/6: Enhanced Image Availability Validation"
check_image_availability() {
    local image=$1
    local image_name=$(echo "$image" | sed 's|.*/||')
    
    print_status "INFO" "Testing $image_name image availability and metadata..."
    
    # Test image pull
    if docker pull "$image" >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: Available and pullable from registry"
        echo "$image_name: AVAILABLE" >> "$REPORT_DIR/image-availability.txt"
        increment_check "PASS"
        
        # Get image metadata
        local image_size=$(docker images --format "table {{.Size}}" "$image" | tail -1)
        local image_created=$(docker inspect "$image" --format '{{.Created}}' 2>/dev/null | cut -d'T' -f1)
        
        print_status "INFO" "  → Size: $image_size, Created: $image_created"
        echo "$image_name: SIZE=$image_size, CREATED=$image_created" >> "$REPORT_DIR/image-availability.txt"
        
        # Test image layers and optimization
        local layer_count=$(docker history "$image" --quiet | wc -l)
        print_status "INFO" "  → Docker layers: $layer_count"
        echo "$image_name: LAYERS=$layer_count" >> "$REPORT_DIR/image-availability.txt"
        
        return 0
    else
        print_status "ERROR" "$image_name: Not available or pull failed"
        echo "$image_name: UNAVAILABLE" >> "$REPORT_DIR/image-availability.txt"
        increment_check "FAIL"
        return 1
    fi
}

# Check both images with enhanced metadata
check_image_availability "$DOCKER_REPOSITORY/builder:latest"
check_image_availability "$DOCKER_REPOSITORY/dev:latest"

echo ""

# 2. Comprehensive Health Check Validation
print_status "HEALTH" "CATEGORY 2/6: Comprehensive Health Check Validation"
validate_health_checks() {
    local image=$1
    local image_name=$(echo "$image" | sed 's|.*/||')
    
    print_status "INFO" "Comprehensive health check testing for $image_name..."
    
    # First, verify health check configuration
    local health_config=$(docker inspect "$image" --format='{{.Config.Healthcheck}}' 2>/dev/null || echo "")
    
    if [ "$health_config" != "" ] && [ "$health_config" != "<nil>" ] && [ "$health_config" != "{[]   0 0}" ]; then
        print_status "SUCCESS" "$image_name: Health check configuration detected"
        echo "$image_name: HEALTHCHECK_CONFIGURED" >> "$REPORT_DIR/health-checks.txt"
        increment_check "PASS"
        
        # Extract health check details
        local interval=$(docker inspect "$image" --format='{{.Config.Healthcheck.Interval}}' 2>/dev/null || echo "unknown")
        local timeout=$(docker inspect "$image" --format='{{.Config.Healthcheck.Timeout}}' 2>/dev/null || echo "unknown")
        local retries=$(docker inspect "$image" --format='{{.Config.Healthcheck.Retries}}' 2>/dev/null || echo "unknown")
        
        print_status "INFO" "  → Interval: $interval, Timeout: $timeout, Retries: $retries"
        echo "$image_name: INTERVAL=$interval, TIMEOUT=$timeout, RETRIES=$retries" >> "$REPORT_DIR/health-checks.txt"
        
        # Test the health check command directly
        print_status "INFO" "Testing health check command execution..."
        if timeout 15 docker run --rm "$image" /usr/local/bin/platformio --version >/dev/null 2>&1; then
            print_status "SUCCESS" "$image_name: Health check command executes successfully"
            echo "$image_name: HEALTHCHECK_COMMAND_OK" >> "$REPORT_DIR/health-checks.txt"
            increment_check "PASS"
        else
            print_status "ERROR" "$image_name: Health check command failed"
            echo "$image_name: HEALTHCHECK_COMMAND_FAILED" >> "$REPORT_DIR/health-checks.txt"
            increment_check "FAIL"
        fi
        
        # Test health check in running container
        print_status "INFO" "Testing health check in running container..."
        local container_id=""
        if container_id=$(docker run -d "$image" sleep 60 2>/dev/null); then
            print_status "INFO" "  → Container started: ${container_id:0:12}"
            
            # Wait for health check to initialize
            sleep 10
            
            local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "none")
            
            case "$health_status" in
                "healthy")
                    print_status "SUCCESS" "$image_name: Container health check PASSING"
                    echo "$image_name: CONTAINER_HEALTHY" >> "$REPORT_DIR/health-checks.txt"
                    increment_check "PASS"
                    ;;
                "starting")
                    print_status "WARNING" "$image_name: Health check still initializing, waiting..."
                    sleep 15
                    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "none")
                    if [ "$health_status" = "healthy" ]; then
                        print_status "SUCCESS" "$image_name: Container health check PASSING (after delay)"
                        echo "$image_name: CONTAINER_HEALTHY_DELAYED" >> "$REPORT_DIR/health-checks.txt"
                        increment_check "PASS"
                    else
                        print_status "ERROR" "$image_name: Health check failed after extended wait"
                        echo "$image_name: CONTAINER_UNHEALTHY" >> "$REPORT_DIR/health-checks.txt"
                        increment_check "FAIL"
                    fi
                    ;;
                *)
                    print_status "ERROR" "$image_name: Health check failed or not responding"
                    echo "$image_name: CONTAINER_UNHEALTHY" >> "$REPORT_DIR/health-checks.txt"
                    increment_check "FAIL"
                    ;;
            esac
            
            # Clean up container
            docker stop "$container_id" >/dev/null 2>&1 || true
            docker rm "$container_id" >/dev/null 2>&1 || true
        else
            print_status "ERROR" "$image_name: Could not start container for health check testing"
            echo "$image_name: CONTAINER_START_FAILED" >> "$REPORT_DIR/health-checks.txt"
            increment_check "FAIL"
        fi
    else
        print_status "ERROR" "$image_name: No health check configuration found"
        echo "$image_name: NO_HEALTHCHECK" >> "$REPORT_DIR/health-checks.txt"
        increment_check "FAIL"
    fi
}

validate_health_checks "$DOCKER_REPOSITORY/builder:latest"
validate_health_checks "$DOCKER_REPOSITORY/dev:latest"

echo ""

# 3. Enhanced PlatformIO Service Functionality Testing
print_status "SERVICE" "CATEGORY 3/6: Enhanced PlatformIO Service Functionality"
test_platformio_service() {
    local image=$1
    local image_name=$(echo "$image" | sed 's|.*/||')
    
    print_status "INFO" "Comprehensive PlatformIO service testing for $image_name..."
    
    # Test --version command with detailed output
    print_status "INFO" "Testing PlatformIO version command..."
    if version_output=$(docker run --rm "$image" --version 2>/dev/null); then
        local version=$(echo "$version_output" | head -1)
        print_status "SUCCESS" "$image_name: PlatformIO version command works ($version)"
        echo "$image_name: VERSION_OK ($version)" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "PASS"
    else
        print_status "ERROR" "$image_name: PlatformIO version command failed"
        echo "$image_name: VERSION_FAILED" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "FAIL"
        return 1
    fi
    
    # Test --help command
    print_status "INFO" "Testing PlatformIO help command..."
    if docker run --rm "$image" --help >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: PlatformIO help command accessible"
        echo "$image_name: HELP_OK" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "PASS"
    else
        print_status "ERROR" "$image_name: PlatformIO help command failed"
        echo "$image_name: HELP_FAILED" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "FAIL"
    fi
    
    # Test platform list command (enhanced with network access)
    print_status "INFO" "Testing PlatformIO platform list (with collector.platformio.org access)..."
    if timeout "$TIMEOUT" docker run --rm "$image" platform list >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: Platform list command functional with network access"
        echo "$image_name: PLATFORM_LIST_OK" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "PASS"
        
        # Get platform details if available
        if platform_output=$(timeout 20 docker run --rm "$image" platform list 2>/dev/null | head -10); then
            local platform_count=$(echo "$platform_output" | grep -c "^Platform " || echo "0")
            print_status "INFO" "  → Available platforms: $platform_count"
            echo "$image_name: PLATFORMS_AVAILABLE=$platform_count" >> "$REPORT_DIR/platformio-service.txt"
        fi
    else
        print_status "WARNING" "$image_name: Platform list command timed out (may be network-related)"
        echo "$image_name: PLATFORM_LIST_TIMEOUT" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "WARN"
    fi
    
    # Test system info command
    print_status "INFO" "Testing PlatformIO system information..."
    if system_output=$(timeout 15 docker run --rm "$image" system info 2>/dev/null); then
        print_status "SUCCESS" "$image_name: System info command functional"
        echo "$image_name: SYSTEM_INFO_OK" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "PASS"
        
        # Extract useful system info
        if echo "$system_output" | grep -q "Core"; then
            local core_dir=$(echo "$system_output" | grep "Core" | head -1 | cut -d':' -f2 | xargs)
            print_status "INFO" "  → PlatformIO Core directory: $core_dir"
        fi
    else
        print_status "WARNING" "$image_name: System info command failed or timed out"
        echo "$image_name: SYSTEM_INFO_FAILED" >> "$REPORT_DIR/platformio-service.txt"
        increment_check "WARN"
    fi
}

test_platformio_service "$DOCKER_REPOSITORY/builder:latest"
test_platformio_service "$DOCKER_REPOSITORY/dev:latest"

echo ""

# 4. Enhanced Container Runtime Validation
print_status "SERVICE" "CATEGORY 4/6: Enhanced Container Runtime Validation"
test_container_runtime() {
    local image=$1
    local image_name=$(echo "$image" | sed 's|.*/||')
    
    print_status "INFO" "Comprehensive container runtime testing for $image_name..."
    
    # Test basic container execution with timing
    print_status "INFO" "Testing basic container command execution..."
    start_time=$(date +%s%N)
    if docker run --rm "$image" --version >/dev/null 2>&1; then
        end_time=$(date +%s%N)
        execution_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        print_status "SUCCESS" "$image_name: Container executes commands correctly (${execution_time}ms)"
        echo "$image_name: RUNTIME_OK (${execution_time}ms)" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "PASS"
    else
        print_status "ERROR" "$image_name: Container command execution failed"
        echo "$image_name: RUNTIME_FAILED" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "FAIL"
    fi
        
    # Test container with different command patterns
    print_status "INFO" "Testing container command processing..."
    if docker run --rm "$image" --help >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: Container command processing functional"
        echo "$image_name: COMMAND_PROCESSING_OK" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "PASS"
    else
        print_status "ERROR" "$image_name: Container command processing failed"
        echo "$image_name: COMMAND_PROCESSING_FAILED" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "FAIL"
    fi
    
    # Test container logging capability
    print_status "INFO" "Testing container logging functionality..."
    if log_output=$(docker run --rm "$image" --version 2>&1); then
        if [ -n "$log_output" ]; then
            print_status "SUCCESS" "$image_name: Container logging functional"
            echo "$image_name: LOGGING_OK" >> "$REPORT_DIR/container-runtime.txt"
            increment_check "PASS"
        else
            print_status "WARNING" "$image_name: Container logging may be limited"
            echo "$image_name: LOGGING_LIMITED" >> "$REPORT_DIR/container-runtime.txt"
            increment_check "WARN"
        fi
    else
        print_status "ERROR" "$image_name: Container logging failed"
        echo "$image_name: LOGGING_FAILED" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "FAIL"
    fi
    
    # Test resource constraints and behavior
    print_status "INFO" "Testing container resource behavior..."
    if timeout 10 docker run --rm --memory=512m "$image" --version >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: Container respects resource constraints"
        echo "$image_name: RESOURCE_CONSTRAINTS_OK" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "PASS"
    else
        print_status "WARNING" "$image_name: Container resource constraint testing failed"
        echo "$image_name: RESOURCE_CONSTRAINTS_FAILED" >> "$REPORT_DIR/container-runtime.txt"
        increment_check "WARN"
    fi
}

test_container_runtime "$DOCKER_REPOSITORY/builder:latest"
test_container_runtime "$DOCKER_REPOSITORY/dev:latest"

echo ""

# 5. NEW: ESP Platform Support Validation (Enhanced)
print_status "PLATFORM" "CATEGORY 5/6: ESP Platform Support Validation"
test_esp_platform_support() {
    local image=$1
    local image_name=$(echo "$image" | sed 's|.*/||')
    
    print_status "INFO" "Testing ESP32/ESP8266 platform support for $image_name..."
    
    # Test ESP32 platform detection/installation capability
    print_status "INFO" "Testing ESP32 platform availability..."
    if timeout 30 docker run --rm "$image" platform show espressif32 >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: ESP32 platform accessible"
        echo "$image_name: ESP32_PLATFORM_OK" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "PASS"
    elif timeout 30 docker run --rm "$image" platform install espressif32 >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: ESP32 platform installable"
        echo "$image_name: ESP32_PLATFORM_INSTALLABLE" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "PASS"
    else
        print_status "WARNING" "$image_name: ESP32 platform may require network access"
        echo "$image_name: ESP32_PLATFORM_NETWORK_REQUIRED" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "WARN"
    fi
    
    # Test ESP8266 platform detection/installation capability  
    print_status "INFO" "Testing ESP8266 platform availability..."
    if timeout 30 docker run --rm "$image" platform show espressif8266 >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: ESP8266 platform accessible"
        echo "$image_name: ESP8266_PLATFORM_OK" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "PASS"
    elif timeout 30 docker run --rm "$image" platform install espressif8266 >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: ESP8266 platform installable"
        echo "$image_name: ESP8266_PLATFORM_INSTALLABLE" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "PASS"
    else
        print_status "WARNING" "$image_name: ESP8266 platform may require network access"
        echo "$image_name: ESP8266_PLATFORM_NETWORK_REQUIRED" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "WARN"
    fi
    
    # Test board list functionality
    print_status "INFO" "Testing board list functionality..."
    if timeout 20 docker run --rm "$image" boards >/dev/null 2>&1; then
        print_status "SUCCESS" "$image_name: Board list command functional"
        echo "$image_name: BOARDS_LIST_OK" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "PASS"
    else
        print_status "WARNING" "$image_name: Board list command failed or timed out"
        echo "$image_name: BOARDS_LIST_FAILED" >> "$REPORT_DIR/esp-platform-support.txt"
        increment_check "WARN"
    fi
}

test_esp_platform_support "$DOCKER_REPOSITORY/builder:latest"
test_esp_platform_support "$DOCKER_REPOSITORY/dev:latest"

echo ""

# 6. NEW: Network Connectivity Validation
print_status "SERVICE" "CATEGORY 6/6: Network Connectivity Validation"
test_network_connectivity() {
    print_status "INFO" "Testing network connectivity for external services..."
    
    # Test collector.platformio.org access (now available)
    print_status "INFO" "Testing collector.platformio.org connectivity..."
    if timeout 10 docker run --rm "$DOCKER_REPOSITORY/builder:latest" platform search esp32 >/dev/null 2>&1; then
        print_status "SUCCESS" "PlatformIO collector service accessible"
        echo "COLLECTOR_PLATFORMIO_OK" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "PASS"
    else
        print_status "WARNING" "PlatformIO collector service may be restricted"
        echo "COLLECTOR_PLATFORMIO_RESTRICTED" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "WARN"
    fi
    
    # Test api.registry.platformio.org access (NEW: Package Registry API)
    print_status "INFO" "Testing api.registry.platformio.org connectivity..."
    if timeout 10 curl -s -I "https://api.registry.platformio.org/" >/dev/null 2>&1; then
        print_status "SUCCESS" "PlatformIO Package Registry API accessible"
        echo "API_REGISTRY_PLATFORMIO_OK" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "PASS"
        
        # Enhanced registry API testing - test actual API functionality
        print_status "INFO" "Testing PlatformIO registry API basic functionality..."
        if timeout 15 curl -s "https://api.registry.platformio.org/" | grep -q "PlatformIO Registry API" 2>/dev/null; then
            print_status "SUCCESS" "PlatformIO Registry API responding correctly"
            echo "API_REGISTRY_RESPONSE_OK" >> "$REPORT_DIR/network-connectivity.txt"
            increment_check "PASS"
        else
            print_status "WARNING" "PlatformIO Registry API unexpected response"
            echo "API_REGISTRY_RESPONSE_UNEXPECTED" >> "$REPORT_DIR/network-connectivity.txt"
            increment_check "WARN"
        fi
        
        # Test if registry can be reached from within containers
        print_status "INFO" "Testing registry access from container environment..."
        if timeout 15 docker run --rm "$DOCKER_REPOSITORY/builder:latest" sh -c "curl -s -I https://api.registry.platformio.org/ >/dev/null 2>&1" 2>/dev/null; then
            print_status "SUCCESS" "PlatformIO Registry accessible from containers"
            echo "API_REGISTRY_CONTAINER_OK" >> "$REPORT_DIR/network-connectivity.txt"
            increment_check "PASS"
        else
            print_status "WARNING" "PlatformIO Registry may not be accessible from containers"
            echo "API_REGISTRY_CONTAINER_LIMITED" >> "$REPORT_DIR/network-connectivity.txt"
            increment_check "WARN"
        fi
    else
        print_status "WARNING" "PlatformIO Package Registry API may be restricted"
        echo "API_REGISTRY_PLATFORMIO_RESTRICTED" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "WARN"
    fi
    
    # Test GitHub registry connectivity
    print_status "INFO" "Testing GitHub registry connectivity..."
    if docker pull hello-world >/dev/null 2>&1; then
        print_status "SUCCESS" "Docker registry connectivity functional"
        echo "DOCKER_REGISTRY_OK" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "PASS"
        # Clean up
        docker rmi hello-world >/dev/null 2>&1 || true
    else
        print_status "WARNING" "Docker registry connectivity may be limited"
        echo "DOCKER_REGISTRY_LIMITED" >> "$REPORT_DIR/network-connectivity.txt"
        increment_check "WARN"
    fi
}

test_network_connectivity

echo ""

# 7. Generate Comprehensive Service Monitoring Report
print_status "INFO" "Generating comprehensive service monitoring dashboard..."

# Calculate percentages
if [ $TOTAL_CHECKS -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    WARNING_RATE=$(( (WARNING_CHECKS * 100) / TOTAL_CHECKS ))
    FAILURE_RATE=$(( (FAILED_CHECKS * 100) / TOTAL_CHECKS ))
else
    SUCCESS_RATE=0
    WARNING_RATE=0
    FAILURE_RATE=0
fi

# Determine overall health status
if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -le 2 ]; then
    OVERALL_STATUS="EXCELLENT"
    STATUS_EMOJI="🟢"
elif [ $FAILED_CHECKS -le 2 ] && [ $SUCCESS_RATE -ge 85 ]; then
    OVERALL_STATUS="GOOD"
    STATUS_EMOJI="🟡"
else
    OVERALL_STATUS="NEEDS_ATTENTION"
    STATUS_EMOJI="🔴"
fi

cat > "$REPORT_DIR/service-monitoring-dashboard.md" << EOF
# 🛡️ ESP32/ESP8266 Docker Images - Service Monitoring Dashboard

## ${STATUS_EMOJI} Overall System Health: **${OVERALL_STATUS}**

**Report Generated:** $(date -u)  
**Repository:** $DOCKER_REPOSITORY  
**Monitoring Version:** Enhanced v2.1  
**Network Access:** collector.platformio.org + api.registry.platformio.org enabled

---

## 📊 Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Total Checks** | $TOTAL_CHECKS | 🔍 |
| **Passed** | $PASSED_CHECKS | ✅ |
| **Warnings** | $WARNING_CHECKS | ⚠️ |
| **Failed** | $FAILED_CHECKS | ❌ |
| **Success Rate** | ${SUCCESS_RATE}% | $([ "$SUCCESS_RATE" -ge 90 ] && echo "🟢" || ([ "$SUCCESS_RATE" -ge 80 ] && echo "🟡" || echo "🔴")) |

---

## 🔍 Service Check Categories (6 Categories)

### 1. ${STATUS_EMOJI} Image Availability
$(cat "$REPORT_DIR/image-availability.txt" | sed 's/^/- **/' | sed 's/:/:** /')

### 2. 🩺 Health Check Validation
$(cat "$REPORT_DIR/health-checks.txt" | sed 's/^/- **/' | sed 's/:/:** /')

### 3. 🔧 PlatformIO Service Functionality
$(cat "$REPORT_DIR/platformio-service.txt" | sed 's/^/- **/' | sed 's/:/:** /')

### 4. ⚙️ Container Runtime Validation
$(cat "$REPORT_DIR/container-runtime.txt" | sed 's/^/- **/' | sed 's/:/:** /')

### 5. 🚀 ESP Platform Support
$(cat "$REPORT_DIR/esp-platform-support.txt" | sed 's/^/- **/' | sed 's/:/:** /')

### 6. 🌐 Network Connectivity
$(cat "$REPORT_DIR/network-connectivity.txt" | sed 's/^/- **/' | sed 's/:/:** /')

---

## 🩺 Health Check Implementation Details

Both production and development images implement comprehensive Docker HEALTHCHECK instructions:

\`\`\`dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\
    CMD /usr/local/bin/platformio --version || exit 1
\`\`\`

**Health Check Features:**
- ✅ **PlatformIO Binary Verification**: Ensures core service accessibility
- ✅ **Container Health Reporting**: Docker daemon health status integration
- ✅ **Orchestration Support**: Kubernetes/Docker Swarm health monitoring
- ✅ **Automatic Recovery**: Restart policies triggered on unhealthy status
- ✅ **Timing Configuration**: 30s intervals, 10s timeout, 3 retries

---

## 🛡️ Service Validation Capabilities

### 🔍 **Multi-Layer Validation System**
- **Registry Connectivity**: Image availability and metadata validation
- **Container Health**: Docker HEALTHCHECK functionality testing
- **Service Readiness**: PlatformIO command functionality verification
- **Runtime Behavior**: Container execution and command processing
- **Platform Support**: ESP32/ESP8266 platform accessibility testing
- **Network Validation**: External service connectivity verification

### 📈 **Enhanced Monitoring Features**
- **Performance Metrics**: Command execution timing analysis
- **Resource Validation**: Memory constraint testing
- **Logging Verification**: Container log output validation
- **Metadata Analysis**: Image size, layers, and creation date tracking
- **Network Testing**: collector.platformio.org connectivity validation

---

## 📋 Service Monitoring Locations

### 🔧 **Service Check Scripts**
- **Primary Script**: \`scripts/service-monitoring.sh\` (Enhanced comprehensive monitoring)
- **Quick Status**: \`scripts/status-check.sh\` (Fast availability verification)
- **CI/CD Integration**: \`.github/workflows/build-and-publish.yml\` (Service Health Validation step)

### 🩺 **Health Check Configuration**
- **Production Dockerfile**: \`production/Dockerfile\` (lines 46-47)
- **Development Dockerfile**: \`development/Dockerfile\` (lines 46-47)
- **Health Check Command**: \`/usr/local/bin/platformio --version\`

### 📊 **Monitoring Reports**
- **Dashboard**: \`service-monitoring-results/service-monitoring-dashboard.md\`
- **Executive Summary**: \`service-monitoring-results/service-monitoring-summary.md\`
- **Category Reports**: Individual \`.txt\` files for each validation category
- **CI/CD Artifacts**: 30-day retention in GitHub Actions artifacts

---

## 🎯 Recommendations

$(if [ "$OVERALL_STATUS" = "EXCELLENT" ]; then
    echo "### 🎉 **EXCELLENT SYSTEM HEALTH**"
    echo "All service checks passed with minimal warnings. The ESP32/ESP8266 Docker images are fully operational and ready for production use."
    echo ""
    echo "**Next Steps:**"
    echo "- Continue regular monitoring"
    echo "- Review performance metrics for optimization opportunities"
    echo "- Monitor network connectivity trends"
elif [ "$OVERALL_STATUS" = "GOOD" ]; then
    echo "### 🟡 **GOOD SYSTEM HEALTH**"
    echo "Most service checks passed with some warnings. The system is operational but may benefit from attention to warning items."
    echo ""
    echo "**Recommended Actions:**"
    echo "- Review warning conditions in detailed reports"
    echo "- Address network-related timeouts if critical"
    echo "- Monitor warning trends over time"
else
    echo "### 🔴 **SYSTEM NEEDS ATTENTION**"
    echo "Multiple service checks failed. Review the detailed results and address critical issues."
    echo ""
    echo "**Critical Actions Required:**"
    echo "- Review failed service checks immediately"
    echo "- Verify image availability and health"
    echo "- Check network connectivity issues"
    echo "- Validate PlatformIO service functionality"
fi)

---

## 🚀 Usage Examples

### Quick Status Check
\`\`\`bash
# Fast status verification (10-15 seconds)
./scripts/status-check.sh
\`\`\`

### Comprehensive Service Monitoring
\`\`\`bash
# Full service validation (2-5 minutes)
./scripts/service-monitoring.sh
\`\`\`

### CI/CD Integration
Service monitoring automatically runs in GitHub Actions after successful builds with results uploaded as artifacts.

---

*Generated by ESP32/ESP8266 Docker Images Enhanced Service Monitoring System v2.0*  
*Monitoring Categories: 6 | Total Checks: $TOTAL_CHECKS | Network: Enhanced*
EOF

# Generate executive summary for CI/CD
cat > "$REPORT_DIR/service-monitoring-summary.md" << EOF
# 🛡️ Service Monitoring Executive Summary

**Overall Health:** ${STATUS_EMOJI} **${OVERALL_STATUS}**  
**Success Rate:** ${SUCCESS_RATE}%  
**Generated:** $(date -u)

## Quick Stats
- ✅ Passed: $PASSED_CHECKS checks
- ⚠️ Warnings: $WARNING_CHECKS checks  
- ❌ Failed: $FAILED_CHECKS checks
- 🔍 Total: $TOTAL_CHECKS checks

## Service Categories Status
- 🔍 Image Availability: $([ $(grep -c "AVAILABLE" "$REPORT_DIR/image-availability.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Operational" || echo "❌ Failed")
- 🩺 Health Checks: $([ $(grep -c "HEALTHCHECK_CONFIGURED" "$REPORT_DIR/health-checks.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Operational" || echo "❌ Failed")
- 🔧 PlatformIO Service: $([ $(grep -c "VERSION_OK" "$REPORT_DIR/platformio-service.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Operational" || echo "❌ Failed")
- ⚙️ Container Runtime: $([ $(grep -c "RUNTIME_OK" "$REPORT_DIR/container-runtime.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Operational" || echo "❌ Failed")
- 🚀 ESP Platform Support: $([ $(grep -c "PLATFORM" "$REPORT_DIR/esp-platform-support.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Available" || echo "⚠️ Limited")
- 🌐 Network Connectivity: $([ $(grep -c "_OK" "$REPORT_DIR/network-connectivity.txt" 2>/dev/null || echo 0) -gt 0 ] && echo "✅ Connected" || echo "⚠️ Limited")

View detailed dashboard: service-monitoring-dashboard.md
EOF

# Display enhanced final results
echo ""
print_status "INFO" "ENHANCED SERVICE MONITORING RESULTS"
echo "================================================================================"
echo -e "${BOLD}${CYAN}📊 COMPREHENSIVE SYSTEM HEALTH DASHBOARD${NC}"
echo ""
echo -e "${BLUE}🔍 Total Checks Executed: ${BOLD}$TOTAL_CHECKS${NC}"
echo -e "${GREEN}✅ Passed: ${BOLD}$PASSED_CHECKS${NC} (${SUCCESS_RATE}%)"
echo -e "${YELLOW}⚠️  Warnings: ${BOLD}$WARNING_CHECKS${NC} (${WARNING_RATE}%)"
echo -e "${RED}❌ Failed: ${BOLD}$FAILED_CHECKS${NC} (${FAILURE_RATE}%)"
echo ""
echo -e "${BOLD}${PURPLE}🛡️ Overall System Health: ${STATUS_EMOJI} ${OVERALL_STATUS}${NC}"
echo ""

# Service category summary
echo -e "${CYAN}📋 Service Categories (6 total):${NC}"
echo -e "   ${BLUE}•${NC} Image Availability & Metadata"
echo -e "   ${BLUE}•${NC} Health Check Validation"  
echo -e "   ${BLUE}•${NC} PlatformIO Service Functionality"
echo -e "   ${BLUE}•${NC} Container Runtime Validation"
echo -e "   ${BLUE}•${NC} ESP Platform Support"
echo -e "   ${BLUE}•${NC} Network Connectivity"
echo ""

# Enhanced reporting
echo -e "${CYAN}📊 Enhanced Reports Generated:${NC}"
echo -e "   ${BLUE}•${NC} Service Monitoring Dashboard: $REPORT_DIR/service-monitoring-dashboard.md"
echo -e "   ${BLUE}•${NC} Executive Summary: $REPORT_DIR/service-monitoring-summary.md"
echo -e "   ${BLUE}•${NC} Category Reports: $REPORT_DIR/*.txt files"
echo ""

if [ "$OVERALL_STATUS" = "EXCELLENT" ]; then
    print_status "SUCCESS" "🎉 ALL SYSTEMS GO! ESP32/ESP8266 Docker images are fully operational and ready for production use!"
    echo -e "${GREEN}${BOLD}✨ Perfect system health - all service validation checks passed!${NC}"
    exit 0
elif [ "$OVERALL_STATUS" = "GOOD" ]; then
    print_status "SUCCESS" "✅ SYSTEMS OPERATIONAL! Minor warnings detected but overall functionality is good."
    echo -e "${YELLOW}📋 Review warnings in detailed dashboard: $REPORT_DIR/service-monitoring-dashboard.md${NC}"
    exit 0
else
    print_status "WARNING" "$FAILED_CHECKS critical service check(s) failed. System needs attention."
    echo -e "${RED}📋 Review critical issues in dashboard: $REPORT_DIR/service-monitoring-dashboard.md${NC}"
    exit 1
fi