# Admin Setup Guide for Automated Deployment

This document provides specific instructions for administrators to ensure the automated deployment system works properly.

## Current Status ✅

The repository is **fully configured** for automated deployment with the following features:

### Automatic Triggers
- ✅ **PR Merges**: Builds both images automatically when PRs are merged to main branch
- ✅ **Daily Builds**: Runs daily at 02:00 UTC (development image only - optimized for cost)
- ✅ **Manual Dispatch**: Can be triggered manually from GitHub Actions tab (both images)

### Registry & Authentication
- ✅ **GitHub Container Registry (GHCR)**: Pre-configured to use `ghcr.io/sparck75/alteriom-docker-images`
- ✅ **Authentication**: Uses built-in `GITHUB_TOKEN` - no secrets setup required
- ✅ **Multi-platform**: Builds for linux/amd64 and linux/arm64

## Admin Actions Required: NONE

The system is ready to use with no additional admin configuration needed.

## How to Force a New Build Now

### Option 1: Manual Dispatch (Recommended)
1. Go to the [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions)
2. Click on "Build and Publish Docker Images" workflow
3. Click "Run workflow" button
4. Select branch (usually `main`) and click "Run workflow"

### Option 2: Merge This PR
Merging this PR will automatically trigger a new build and test the fixed Docker configuration.

## Published Images Location

Once builds succeed, images will be available at:
- **Production**: `ghcr.io/sparck75/alteriom-docker-images/builder:latest`
- **Development**: `ghcr.io/sparck75/alteriom-docker-images/dev:latest`
- **Dated tags**: Images also get tagged with YYYYMMDD format

## Verification Commands

**Quick verification script:**
```bash
# Run the automated verification script
./scripts/verify-images.sh
```

**Manual verification:**
Test the published images:
```bash
# Pull and test production image
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version

# Pull and test development image  
docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version
```

## Repository Permissions

The workflow has the correct permissions:
- ✅ `contents: read` - to checkout code
- ✅ `packages: write` - to publish to GHCR

## Issues Fixed

- ✅ **Build failures** due to deprecated `python3-distutils` package resolved
- ✅ **Authentication** properly configured for GitHub Container Registry
- ✅ **Multi-platform builds** working correctly

## Support

If you encounter issues:
1. Check the [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions) for build logs
2. Verify the workflow is enabled in repository settings
3. Ensure the main branch is not protected in a way that blocks automation