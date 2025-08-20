#!/usr/bin/env bash
# Test script to validate daily build optimization logic
# This script tests the new dev-only build mode without actually building Docker images

set -euo pipefail

echo "=== Testing Daily Build Optimization Logic ==="
echo ""

# Test setup
export DOCKER_REPOSITORY="test-repo"
export PLATFORMS="linux/amd64"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_passed=0
test_failed=0

run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    echo "Testing: $test_name"
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Found expected output '$expected'"
        test_passed=$((test_passed + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Expected '$expected'"
        echo "DEBUG: Actual output was:"
        echo "$actual" | head -20
        test_failed=$((test_failed + 1))
    fi
    echo ""
}

# Test 1: Dev-only mode with schedule event 
echo "Test 1: Dev-only mode with schedule event"
export GITHUB_EVENT_NAME="schedule"
echo "Running: timeout 5s ./scripts/build-images.sh dev-only"
if output=$(timeout 5s ./scripts/build-images.sh dev-only 2>&1); then
    echo "Command completed successfully"
else
    echo "Command timed out or failed (expected due to Docker build)"
fi
run_test "Dev-only with schedule creates dev version" "Creating development version:" "$output"
run_test "Dev-only builds development image only" "Building and pushing development image only" "$output"

# Test 2: Regular push mode (both images)
echo "Test 2: Regular push mode"
unset GITHUB_EVENT_NAME
echo "Running: timeout 5s ./scripts/build-images.sh push"
if output=$(timeout 5s ./scripts/build-images.sh push 2>&1); then
    echo "Command completed successfully"
else
    echo "Command timed out or failed (expected due to Docker build)"
fi
run_test "Push mode builds both images" "Building and pushing both images" "$output"

# Test 3: Local build mode
echo "Test 3: Local build mode"
echo "Running: timeout 5s ./scripts/build-images.sh"
if output=$(timeout 5s ./scripts/build-images.sh 2>&1); then
    echo "Command completed successfully"
else
    echo "Command timed out or failed (expected due to Docker build)"
fi
run_test "Local mode builds without pushing" "Building local (no push)" "$output"

# Summary
echo "=== Test Results ==="
echo -e "Tests passed: ${GREEN}$test_passed${NC}"
echo -e "Tests failed: ${RED}$test_failed${NC}"

if [ $test_failed -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Daily build optimization logic is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the implementation.${NC}"
    exit 1
fi