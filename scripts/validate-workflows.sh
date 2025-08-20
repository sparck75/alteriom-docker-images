#!/bin/bash

# Validate Workflows Script
# Ensures only one workflow file exists to prevent duplicate builds

set -e

echo "🔍 Validating workflow configuration..."
echo ""

# Check local workflow files
echo "📁 Local workflow files:"
WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | sed 's/^/  - /'

echo ""
echo "📊 Local workflow count: $WORKFLOW_COUNT"

if [ "$WORKFLOW_COUNT" -eq 1 ]; then
    echo "✅ Local validation: PASSED - Only one workflow file exists"
    LOCAL_STATUS="PASS"
else
    echo "❌ Local validation: FAILED - Multiple workflow files detected"
    echo "⚠️  This will cause duplicate builds and cost overruns!"
    LOCAL_STATUS="FAIL"
fi

echo ""

# Check GitHub repository workflows if gh CLI is available
if command -v gh >/dev/null 2>&1; then
    echo "🌐 Checking GitHub repository workflows..."
    
    # Get workflows from GitHub API
    GITHUB_WORKFLOWS=$(gh api repos/sparck75/alteriom-docker-images/actions/workflows --jq '.workflows[] | select(.state == "active") | .name' 2>/dev/null || echo "")
    
    if [ -n "$GITHUB_WORKFLOWS" ]; then
        echo "📋 Active GitHub workflows:"
        echo "$GITHUB_WORKFLOWS" | sed 's/^/  - /'
        
        GITHUB_COUNT=$(echo "$GITHUB_WORKFLOWS" | grep -v "^$" | wc -l)
        echo ""
        echo "📊 GitHub workflow count: $GITHUB_COUNT"
        
        # Filter out the Copilot dynamic workflow as it's not a build workflow
        BUILD_WORKFLOWS=$(echo "$GITHUB_WORKFLOWS" | grep -v "^Copilot$" || echo "")
        BUILD_COUNT=$(echo "$BUILD_WORKFLOWS" | grep -v "^$" | wc -l)
        
        echo "📊 Build workflow count (excluding Copilot): $BUILD_COUNT"
        
        if [ "$BUILD_COUNT" -eq 1 ]; then
            echo "✅ GitHub validation: PASSED - Only one build workflow exists"
            GITHUB_STATUS="PASS"
        else
            echo "❌ GitHub validation: FAILED - Multiple build workflows detected"
            echo "⚠️  Build workflows found:"
            echo "$BUILD_WORKFLOWS" | grep -v "^$" | sed 's/^/     - /'
            echo "⚠️  This WILL cause duplicate builds and cost overruns!"
            GITHUB_STATUS="FAIL"
        fi
    else
        echo "⚠️  Could not fetch GitHub workflows (may require authentication)"
        GITHUB_STATUS="UNKNOWN"
    fi
else
    echo "ℹ️  GitHub CLI not available - cannot check remote workflows"
    GITHUB_STATUS="UNKNOWN"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VALIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Local workflows:  $LOCAL_STATUS ($WORKFLOW_COUNT files)"
echo "GitHub workflows: $GITHUB_STATUS"

if [ "$LOCAL_STATUS" = "PASS" ] && ([ "$GITHUB_STATUS" = "PASS" ] || [ "$GITHUB_STATUS" = "UNKNOWN" ]); then
    echo ""
    echo "🎉 OVERALL STATUS: ✅ VALIDATION PASSED"
    echo "   No duplicate workflows detected - builds will run only once!"
    exit 0
else
    echo ""
    echo "🚨 OVERALL STATUS: ❌ VALIDATION FAILED"
    echo "   Duplicate workflows will cause redundant builds and cost overruns!"
    echo ""
    echo "🔧 REMEDIATION STEPS:"
    echo "   1. Remove duplicate workflow files from .github/workflows/"
    echo "   2. Ensure only build-and-publish.yml remains"
    echo "   3. Commit and push changes to update GitHub repository"
    echo "   4. Re-run this script to verify fix"
    exit 1
fi