#!/bin/bash
# Admin Setup Verification Script
# This script helps verify that all required permissions and access are properly configured

set -e

echo "🔍 GitHub Copilot Admin Setup Verification"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "1. Checking GitHub CLI access..."
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        check_pass "GitHub CLI authenticated"
        GITHUB_USER=$(gh api user --jq '.login')
        echo "   Authenticated as: $GITHUB_USER"
    else
        check_fail "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
else
    check_warn "GitHub CLI not installed. Some checks will be skipped."
fi

echo ""
echo "2. Checking repository access..."
REPO="sparck75/alteriom-docker-images"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    if gh repo view "$REPO" &> /dev/null; then
        check_pass "Repository access verified"
        
        # Check if user has admin access
        PERMISSION=$(gh api "repos/$REPO/collaborators/$GITHUB_USER/permission" --jq '.permission' 2>/dev/null || echo "unknown")
        if [[ "$PERMISSION" == "admin" ]]; then
            check_pass "Admin permissions confirmed"
        else
            check_warn "Permission level: $PERMISSION (admin recommended for full setup)"
        fi
    else
        check_fail "Cannot access repository: $REPO"
        exit 1
    fi
fi

echo ""
echo "3. Checking GitHub Actions..."
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    ACTIONS_ENABLED=$(gh api "repos/$REPO" --jq '.has_actions' 2>/dev/null || echo "unknown")
    if [[ "$ACTIONS_ENABLED" == "true" ]]; then
        check_pass "GitHub Actions enabled"
    else
        check_fail "GitHub Actions not enabled"
    fi
fi

echo ""
echo "4. Checking required secrets..."
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    SECRETS=$(gh api "repos/$REPO/actions/secrets" --jq '.secrets[].name' 2>/dev/null || echo "")
    
    # Check for required secrets
    REQUIRED_SECRETS=("DOCKERHUB_USERNAME" "DOCKERHUB_TOKEN")
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if echo "$SECRETS" | grep -q "^$secret$"; then
            check_pass "Secret $secret is configured"
        else
            check_warn "Secret $secret is missing (required for Docker Hub publishing)"
        fi
    done
fi

echo ""
echo "5. Checking Docker access..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        check_pass "Docker daemon accessible"
        
        # Test GitHub Container Registry access
        if [[ -n "$GITHUB_TOKEN" ]]; then
            if echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin &> /dev/null; then
                check_pass "GitHub Container Registry access verified"
                docker logout ghcr.io &> /dev/null
            else
                check_warn "GitHub Container Registry access failed (GITHUB_TOKEN may be invalid)"
            fi
        else
            check_warn "GITHUB_TOKEN not set - cannot test GHCR access"
        fi
        
        # Test Docker Hub access
        if [[ -n "$DOCKERHUB_USERNAME" && -n "$DOCKERHUB_TOKEN" ]]; then
            if echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin &> /dev/null; then
                check_pass "Docker Hub access verified"
                docker logout &> /dev/null
            else
                check_warn "Docker Hub access failed (credentials may be invalid)"
            fi
        else
            check_warn "DOCKERHUB_USERNAME/DOCKERHUB_TOKEN not set - cannot test Docker Hub access"
        fi
    else
        check_fail "Docker daemon not accessible"
    fi
else
    check_warn "Docker not installed - cannot verify registry access"
fi

echo ""
echo "6. Checking workflow files..."
WORKFLOW_DIR=".github/workflows"
if [[ -d "$WORKFLOW_DIR" ]]; then
    check_pass "Workflows directory exists"
    
    # Check for main workflow file
    if [[ -f "$WORKFLOW_DIR/build-and-publish.yml" ]]; then
        check_pass "Main build workflow found"
        
        # Check workflow permissions
        if grep -q "packages: write" "$WORKFLOW_DIR/build-and-publish.yml"; then
            check_pass "Package write permissions configured"
        else
            check_warn "Package write permissions may be missing"
        fi
    else
        check_warn "Main build workflow not found"
    fi
else
    check_fail "Workflows directory not found"
fi

echo ""
echo "7. Testing API rate limits..."
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    RATE_LIMIT=$(gh api rate_limit --jq '.rate.remaining' 2>/dev/null || echo "unknown")
    if [[ "$RATE_LIMIT" != "unknown" && "$RATE_LIMIT" -gt 100 ]]; then
        check_pass "API rate limit OK ($RATE_LIMIT remaining)"
    else
        check_warn "API rate limit low ($RATE_LIMIT remaining)"
    fi
fi

echo ""
echo "📋 Setup Summary"
echo "=================="
echo "To complete the setup, ensure the following:"
echo ""
echo "Required Secrets (Repository Settings > Secrets and variables > Actions):"
echo "  • DOCKERHUB_USERNAME - Your Docker Hub username"
echo "  • DOCKERHUB_TOKEN - Your Docker Hub access token"
echo ""
echo "Required Permissions:"
echo "  • Repository admin access (for branch protection rules)"
echo "  • GitHub Actions enabled"
echo "  • Packages enabled (for GitHub Container Registry)"
echo ""
echo "Optional Environment Variables for Local Testing:"
echo "  export GITHUB_TOKEN=\"your-personal-access-token\""
echo "  export DOCKERHUB_USERNAME=\"your-dockerhub-username\""
echo "  export DOCKERHUB_TOKEN=\"your-dockerhub-token\""
echo ""
echo "🚀 Once setup is complete, trigger a manual workflow run to test everything:"
echo "   gh workflow run \"Build and Publish Docker Images\" --repo $REPO"
echo ""
echo "For detailed setup instructions, see: COPILOT_ADMIN_SETUP.md"