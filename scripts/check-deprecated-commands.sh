#!/usr/bin/env bash
# Test script to verify that deprecated PlatformIO commands have been replaced
# This script checks for deprecated commands in the Dockerfiles

set -euo pipefail

echo "=== Checking for deprecated PlatformIO commands ==="

# Check for old deprecated commands in Dockerfiles only
deprecated_found=0

if find . -name "Dockerfile" -exec grep -l "pio platform install" {} \; 2>/dev/null | grep -q .; then
    echo "❌ Found deprecated 'pio platform install' commands in Dockerfiles"
    find . -name "Dockerfile" -exec grep -Hn "pio platform install" {} \; 2>/dev/null
    deprecated_found=1
fi

if find . -name "Dockerfile" -exec grep -l "pio lib install" {} \; 2>/dev/null | grep -q .; then
    echo "❌ Found deprecated 'pio lib install' commands in Dockerfiles"
    find . -name "Dockerfile" -exec grep -Hn "pio lib install" {} \; 2>/dev/null
    deprecated_found=1
fi

# Check that new commands are present in Dockerfiles
modern_found=0

if find . -name "Dockerfile" -exec grep -l "pio pkg install" {} \; 2>/dev/null | grep -q .; then
    echo "✅ Found modern 'pio pkg install' commands in Dockerfiles:"
    find . -name "Dockerfile" -exec grep -Hn "pio pkg install" {} \; 2>/dev/null
    modern_found=1
fi

echo ""
echo "=== Summary ==="

if [ $deprecated_found -eq 0 ] && [ $modern_found -eq 1 ]; then
    echo "✅ All checks passed: No deprecated commands found, modern commands present"
    exit 0
elif [ $deprecated_found -eq 1 ]; then
    echo "❌ Deprecated commands still present"
    exit 1
else
    echo "⚠️ No PlatformIO install commands found"
    exit 1
fi