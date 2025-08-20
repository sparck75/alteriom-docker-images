# Automated Versioning Guide

## Overview

This repository now uses **fully automated semantic versioning** that triggers on PR merges to the main branch. Version numbers are automatically incremented based on commit message conventions and PR content.

## How It Works

### Automatic Version Bumping

When PRs are merged to main branch, the CI/CD workflow automatically:

1. **Analyzes commit messages** for semantic versioning keywords
2. **Increments version** according to semantic versioning rules
3. **Commits the new version** to the VERSION file
4. **Creates a GitHub release** with auto-generated release notes
5. **Builds and publishes** Docker images with the new version tags

### Version Increment Rules

| Commit Message Pattern | Version Bump | Example |
|------------------------|-------------|---------|
| `BREAKING CHANGE:`, `feat!:`, `fix!:` | **MAJOR** (x.0.0) | Breaking API changes |
| `feat:`, `feature:` | **MINOR** (1.x.0) | New features, enhancements |
| `fix:`, `bug:`, `patch:`, `hotfix:` | **PATCH** (1.5.x) | Bug fixes, small improvements |
| `Merge pull request` | **PATCH** (1.5.x) | Default for any PR merge |

### Current Version: 1.6.1

**Development Badge System**: The repository now includes an automated development badge that shows:
- Current development version with build numbers (e.g., "1.6.1+ (build 20241201)")
- Automatic updates when development images are built
- Links to GHCR development package for easy access

## Instructions for Future Agents

### For Regular Development Work

1. **Use semantic commit messages** for automatic version bumping:
   ```bash
   # New feature
   git commit -m "feat: add ESP32-S3 support to build system"
   
   # Bug fix
   git commit -m "fix: resolve Docker build timeout issues"
   
   # Breaking change
   git commit -m "feat!: migrate to PlatformIO 7.0 with breaking changes"
   ```

2. **PR titles should follow the same pattern** for clarity:
   ```
   feat: Add automated version management system
   fix: Correct VERSION file format validation
   docs: Update development guide with new workflows
   ```

### When Version Automation Fails

If the automated versioning doesn't work as expected:

1. **Check GitHub Actions logs**:
   ```bash
   # Go to: https://github.com/sparck75/alteriom-docker-images/actions
   # Look for "Build and Publish Docker Images" workflow
   # Check the "Bump Version" step for errors
   ```

2. **Manually fix VERSION file** if needed:
   ```bash
   # Update VERSION file to correct semantic version
   echo "1.6.0" > VERSION
   git add VERSION
   git commit -m "chore: fix version to 1.6.0 [skip ci]"
   git push
   ```

3. **Force a new release** manually:
   ```bash
   # Trigger manual workflow dispatch
   # Go to Actions tab → "Build and Publish Docker Images" → "Run workflow"
   ```

### Version Management Commands

```bash
# Check current version
cat VERSION

# Verify version will be used in build
cat .github/workflows/build-and-publish.yml | grep -A 10 "Bump Version"

# Test version bumping logic locally
COMMIT_MSG="feat: add new feature"
if echo "$COMMIT_MSG" | grep -qE "^(feat|feature):"; then
    echo "This would trigger a MINOR version bump"
fi
```

### Workflow Permissions

The automated versioning requires these permissions (already configured):
- ✅ `contents: write` - to commit version bumps and create releases
- ✅ `packages: write` - to publish Docker images
- ✅ Built-in `GITHUB_TOKEN` - no additional secrets needed

### Troubleshooting Common Issues

#### Version Not Incrementing
- **Check commit message format** - must match semantic patterns
- **Verify workflow permissions** - needs write access to repository
- **Look for [skip ci] flag** - prevents infinite loops

#### Release Not Created
- **Check for existing release** with same version tag
- **Verify GitHub token permissions** - needs release creation rights
- **Check for workflow failures** in Actions tab

#### Docker Images Not Updated
- **Verify DOCKER_REPOSITORY** environment variable
- **Check registry authentication** - should use GITHUB_TOKEN
- **Monitor build logs** for Docker buildx errors

### Emergency Procedures

#### Rollback Version
```bash
# If automated version bump goes wrong
git revert HEAD  # Revert the version bump commit
git push

# Or manually set correct version
echo "1.5.0" > VERSION
git add VERSION
git commit -m "chore: rollback to version 1.5.0 [skip ci]"
git push
```

#### Skip Automated Versioning
```bash
# Use [skip ci] in commit message to prevent version bump
git commit -m "docs: update README [skip ci]"
```

#### Force Specific Version
```bash
# Manually set version and trigger build
echo "2.0.0" > VERSION
git add VERSION
git commit -m "chore: bump to version 2.0.0 for major release [skip ci]"
git push

# Then trigger manual workflow to build and release
```

## Integration with Existing Documentation

### Updated Files
- ✅ **VERSION_CONTROL.md** - Now documents automated system
- ✅ **ADMIN_SETUP.md** - Updated with automated workflow info
- ✅ **README.md** - CI/CD section updated with automated versioning
- ✅ **.github/workflows/build-and-publish.yml** - Implements auto-versioning

### Verification Commands
```bash
# Comprehensive system check
./scripts/verify-images.sh

# Check if automation is working
./scripts/status-check.sh

# Test ESP builds with latest version
./scripts/test-esp-builds.sh
```

## Benefits of Automation

1. **Consistency** - No more manual version management mistakes
2. **Traceability** - Clear link between commits and version increments
3. **Efficiency** - Automatic releases with generated release notes
4. **Standards** - Enforces semantic versioning conventions
5. **Reliability** - Reduces human error in release process

## Migration Notes

### Previous System (Manual)
- VERSION file manually updated
- Releases manually created
- Version increments based on developer judgment

### New System (Automated)
- VERSION file automatically updated on PR merge
- Releases automatically created with generated notes
- Version increments based on semantic commit conventions
- Backward compatible with manual overrides when needed

---

*This automated versioning system addresses issue #29 and provides a fully automated CI/CD pipeline for version management.*