# Admin Setup Requirements for GitHub Copilot Integration

This document outlines the specific administrative setup needed to ensure GitHub Copilot (AI assistant) can fully perform work on this repository without warnings or access limitations.

## Current Issues Preventing Full Testing

Based on the build pipeline warnings, the following admin actions are required:

## 1. Repository Access & Permissions

### Required Repository Settings
```yaml
Repository Settings:
  - Actions: Enabled
  - Packages: Enabled
  - Issues: Enabled
  - Pull Requests: Enabled
  - Discussions: Enabled (optional)
```

### Branch Protection Rules
The following branch protection should be configured for `main`:
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
- ✅ Include administrators in restrictions: **DISABLE** (critical for Copilot work)
- ✅ Allow force pushes: **DISABLE**
- ✅ Allow deletions: **DISABLE**

## 2. GitHub Actions Secrets & Variables

### Required Secrets
The following secrets need to be configured in Repository Settings > Secrets and variables > Actions:

```bash
# Docker Hub Access (for publish-mydocker.yml workflow)
DOCKERHUB_USERNAME=<your-docker-hub-username>
DOCKERHUB_TOKEN=<your-docker-hub-access-token>

# Optional: Custom Docker Repository
DOCKER_REPOSITORY=<custom-repo-url>  # Can be variable instead of secret
```

### Required Variables (Repository Settings > Secrets and variables > Actions > Variables)
```bash
# Optional: Override default repository
DOCKER_REPOSITORY=ghcr.io/sparck75/alteriom-docker-images
```

### Built-in Tokens (No setup required)
- `GITHUB_TOKEN` - Automatically available, provides access to:
  - Read repository contents
  - Write to GitHub Container Registry (ghcr.io)
  - Update PR status checks

## 3. Package Registry Permissions

### GitHub Container Registry (GHCR)
Ensure the following permissions are set:
- Repository has `packages: write` permission in workflows ✅ (already configured)
- Personal/Organization settings allow package creation
- No package deletion policies that would interfere with testing

### Verification Commands
```bash
# Test GHCR access
docker login ghcr.io -u $GITHUB_USERNAME -p $GITHUB_TOKEN
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
```

## 4. GitHub Copilot Specific Access

### Organization-Level Settings (if applicable)
If this repository belongs to an organization:

```yaml
Organization Settings > Copilot:
  - Copilot Business/Enterprise: Enabled
  - Repository Access: Include this repository
  - Content Exclusion: Configure sensitive paths
  - Audit Logs: Enabled for compliance
```

### User-Level Access
Ensure the Copilot service account has:
- Read access to repository
- Write access for creating PRs and commits
- Actions workflow access

## 5. API Rate Limits & Access

### GitHub API Limits
- Standard rate limits apply: 5,000 requests/hour for authenticated requests
- For heavy testing, consider GitHub Enterprise for higher limits
- Monitor usage in repository insights

### Required API Scopes
The integration requires these GitHub API scopes:
- `repo` - Full repository access
- `packages:write` - Package registry write access
- `actions:write` - Workflow management
- `pull_requests:write` - PR creation and updates

## 6. Environment Setup for Testing

### Development Environment
For local testing and validation:

```bash
# Required tools
- Docker Desktop or Docker Engine
- Git
- GitHub CLI (optional, but recommended)

# Environment variables for testing
export GITHUB_TOKEN="<your-personal-access-token>"
export DOCKER_REPOSITORY="ghcr.io/sparck75/alteriom-docker-images"
```

### CI/CD Environment Variables
The following are automatically available in GitHub Actions:
- `GITHUB_ACTOR` - Username of the actor
- `GITHUB_REPOSITORY` - Repository name
- `GITHUB_REF` - Branch or tag ref
- `GITHUB_SHA` - Commit SHA

## 7. Monitoring & Troubleshooting Access

### Required Access for Diagnostics
- GitHub Actions logs access
- Package registry logs access
- Repository insights access
- Security alerts access (if enabled)

### Webhook Verification (if applicable)
For external integrations:
- Webhook secret configuration
- SSL certificate validation
- Endpoint accessibility testing

## 8. Quick Setup Checklist

### Immediate Actions Required:
- [ ] Verify `DOCKERHUB_USERNAME` secret is set
- [ ] Verify `DOCKERHUB_TOKEN` secret is set and valid
- [ ] Check branch protection rules don't block admin access
- [ ] Ensure GitHub Actions are enabled
- [ ] Verify package registry permissions
- [ ] Test workflow trigger permissions

### Verification Script:
```bash
# Run this to verify setup
cd scripts/
./verify-admin-setup.sh
```

### Test Commands:
```bash
# Test Docker Hub access
docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_TOKEN

# Test GitHub Container Registry access
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# Test workflow permissions
gh workflow run "Build and Publish Docker Images" --repo sparck75/alteriom-docker-images
```

## 9. Security Considerations

### Secrets Management
- Use GitHub Secrets for sensitive data
- Rotate tokens regularly
- Use least-privilege access principles
- Monitor secret usage in audit logs

### Network Access
- Ensure CI/CD runners can access Docker registries
- Verify DNS resolution for external services
- Check firewall rules if using self-hosted runners

## 10. Troubleshooting Common Issues

### Build Pipeline Warnings
If you encounter warnings about access:
1. Check workflow permissions in `.github/workflows/`
2. Verify secrets are properly set and not expired
3. Ensure branch protection rules allow necessary operations
4. Check GitHub Actions quotas and limits

### Package Registry Issues
1. Verify registry authentication
2. Check package visibility settings
3. Ensure sufficient storage quotas
4. Verify multi-platform build capabilities

---

## Next Steps

After completing this setup:
1. Trigger a manual workflow run to test all permissions
2. Monitor the build logs for any remaining warnings
3. Verify published packages are accessible
4. Test the complete CI/CD pipeline end-to-end

For issues or questions about this setup, please create an issue in this repository with the "admin-setup" label.