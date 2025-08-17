# VERSION CONTROL GUIDE

## Current Version Management System

This repository uses **manual semantic versioning** controlled by the `VERSION` file.

### Current Version: 1.5.0

### Version History
- **1.5.0** (2025-08-17): 
  - Added comprehensive ESP platform build testing with CI/CD integration (PR #22)
  - Significantly enhanced Copilot instructions with comprehensive development guide (PR #24)
  - Total: 736+ lines of improvements to documentation and testing infrastructure

- **1.4.0** (2025-08-17): Previous release

### How Versioning Works

1. **VERSION File**: Contains the current version number (e.g., "1.5.0")
2. **Build Process**: GitHub Actions reads from `VERSION` file and uses it for:
   - Docker image tags (`:latest`, `:1.5.0`, `:20250817`)
   - GitHub releases (v1.5.0)
   - Build labels and metadata

3. **Manual Updates**: Version must be manually updated in `VERSION` file when significant changes are made

### When to Update Version

Use semantic versioning principles:

- **MAJOR** (x.0.0): Breaking changes to Docker images, CI/CD, or core functionality
- **MINOR** (1.x.0): New features, enhancements, significant documentation updates
- **PATCH** (1.5.x): Bug fixes, minor improvements, security patches

### Version Update Process

1. **Assess Changes**: Review commits since last version bump
2. **Update VERSION File**: Edit `VERSION` file with new semantic version
3. **Commit Changes**: Include version bump in commit message
4. **Trigger Build**: Push to main branch triggers automated build and release

### Automation Status

**Current**: Manual versioning system
**Future Consideration**: Could implement automated version bumping based on:
- Conventional commit messages
- PR labels
- Automated semantic analysis

### Recent Issue Resolution

**Problem**: VERSION file contained 1.4.0 but significant commits were made after v1.4.0 release without version bump.

**Solution**: Updated VERSION to 1.5.0 to reflect:
- ESP platform build testing infrastructure
- Comprehensive development guide (736 lines of documentation improvements)

**Prevention**: This documentation and clearer version management process.

### Quick Commands

```bash
# Check current version
cat VERSION

# Update version (example)
echo "1.6.0" > VERSION

# Verify build will use new version
cat .github/workflows/build-and-publish.yml | grep -A 10 "Read Version"
```

### Next Build

The next push to main branch will:
1. Read VERSION file (1.5.0)
2. Build Docker images with tags:
   - `:latest`
   - `:1.5.0` 
   - `:20250817` (date tag)
3. Create GitHub release v1.5.0
4. Publish to GitHub Container Registry

---

*This guide addresses issue #25: "Wondering why the version number is still the same even though we had several commit to the main branch today"*