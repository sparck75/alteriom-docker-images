#!/usr/bin/env bash
# Test script for automated versioning logic
# Usage: ./test-version-automation.sh

set -euo pipefail

echo "🧪 Testing Automated Versioning Logic"
echo "======================================"

# Simulate version bump logic
test_version_bump() {
    local commit_msg="$1"
    local current_version="$2"
    
    # Parse version components
    IFS='.' read -r MAJOR MINOR PATCH <<< "$current_version"
    
    echo "Testing: '$commit_msg'"
    echo "Current version: $current_version"
    
    # Check commit messages for version bump indicators
    if echo "$commit_msg" | grep -qE "^(BREAKING CHANGE|feat!|fix!|perf!):"; then
        # Major version bump for breaking changes
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        echo "Result: 🚨 MAJOR version bump → ${MAJOR}.${MINOR}.${PATCH}"
    elif echo "$commit_msg" | grep -qE "^(feat|feature):"; then
        # Minor version bump for new features
        MINOR=$((MINOR + 1))
        PATCH=0
        echo "Result: ✨ MINOR version bump → ${MAJOR}.${MINOR}.${PATCH}"
    elif echo "$commit_msg" | grep -qE "^(fix|bug|patch|hotfix):"; then
        # Patch version bump for bug fixes
        PATCH=$((PATCH + 1))
        echo "Result: 🐛 PATCH version bump → ${MAJOR}.${MINOR}.${PATCH}"
    elif echo "$commit_msg" | grep -qE "Merge pull request"; then
        # Default patch bump for merged PRs
        PATCH=$((PATCH + 1))
        echo "Result: 🔀 PATCH version bump → ${MAJOR}.${MINOR}.${PATCH}"
    else
        echo "Result: ℹ️ No version bump → ${MAJOR}.${MINOR}.${PATCH}"
    fi
    
    echo ""
}

# Test various commit message patterns
echo "Testing commit message patterns:"
echo "--------------------------------"

test_version_bump "feat: add ESP32-S3 support" "1.5.1"
test_version_bump "fix: resolve Docker build timeout" "1.5.1" 
test_version_bump "feat!: breaking API changes" "1.5.1"
test_version_bump "BREAKING CHANGE: migrate to PlatformIO 7.0" "1.5.1"
test_version_bump "Merge pull request #30 from user/feature-branch" "1.5.1"
test_version_bump "docs: update README" "1.5.1"
test_version_bump "chore: update dependencies" "1.5.1"

echo "✅ All version bump tests completed!"
echo ""
echo "Current VERSION file content:"
cat VERSION
echo ""
echo "🔧 To test automation in actual workflow:"
echo "1. Create a branch: git checkout -b test-automation"
echo "2. Make a change and commit with semantic message"
echo "3. Create PR and merge to main"
echo "4. Check GitHub Actions for automated version bump"