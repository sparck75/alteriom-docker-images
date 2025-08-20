# VERSION CONTROL GUIDE

## Current Version Management System

This repository uses **automated semantic versioning** controlled by the CI/CD workflow with manual override capability.

### Current Version: 1.5.1

### Version History
- **1.5.1** (2025-08-17): 
  - **AUTOMATED VERSIONING IMPLEMENTED** - Full CI/CD automation for version management
  - ESP32-C3 support added to test suite and documentation (PR #28)
  - Fixed VERSION file format and implemented automated version bumping
  
- **1.5.0** (2025-08-17): 
  - Added comprehensive ESP platform build testing with CI/CD integration (PR #22)
  - Significantly enhanced Copilot instructions with comprehensive development guide (PR #24)
  - Total: 736+ lines of improvements to documentation and testing infrastructure

- **1.4.0** (2025-08-17): Previous release

### How Automated Versioning Works

1. **Trigger**: PR merges to main branch automatically trigger version analysis
2. **Analysis**: Commit messages are analyzed for semantic versioning keywords
3. **Increment**: Version is automatically bumped according to semantic rules:
   - `BREAKING CHANGE:`, `feat!:` → **MAJOR** bump (x.0.0)
   - `feat:`, `feature:` → **MINOR** bump (1.x.0)  
   - `fix:`, `bug:`, `patch:` → **PATCH** bump (1.5.x)
   - `Merge pull request` → **PATCH** bump (default)
4. **Commit**: New version is committed to VERSION file
5. **Release**: GitHub release is automatically created with generated notes
6. **Build**: Docker images are built and published with new version tags

### When to Use Manual Override

Manual version updates are still supported for special cases:

- **Emergency releases**: Critical security fixes requiring immediate release
- **Correcting mistakes**: If automated versioning makes an error
- **Major milestones**: When you want specific version numbers (e.g., 2.0.0)

### Manual Version Update Process

1. **Assess Changes**: Review commits since last version bump
2. **Update VERSION File**: Edit `VERSION` file with new semantic version
3. **Commit with [skip ci]**: Include `[skip ci]` to prevent automated bump
4. **Trigger Build**: Push to main branch triggers automated build and release

Example:
```bash
echo "2.0.0" > VERSION
git add VERSION
git commit -m "chore: bump to version 2.0.0 for major release [skip ci]"
git push
```

### Automation Status

**Current**: ✅ **FULLY AUTOMATED** versioning system
- ✅ Automatic version bumping based on semantic commit messages
- ✅ Automatic GitHub release creation with generated release notes
- ✅ Automatic Docker image building and publishing
- ✅ Manual override capability maintained for special cases

**Benefits**:
- Consistent semantic versioning
- Reduced manual errors
- Automatic release notes generation
- Faster release cycles
- Better traceability between commits and versions

### Quick Commands

```bash
# Check current version
cat VERSION

# Update version manually (with automation skip)
echo "1.6.0" > VERSION
git commit -m "chore: bump version to 1.6.0 [skip ci]"

# Verify automation is working
cat .github/workflows/build-and-publish.yml | grep -A 10 "Bump Version"

# Check latest workflow run
./scripts/verify-images.sh
```

### Next Build

The next push to main branch will:
1. Analyze commit messages for version bump requirements
2. Automatically increment VERSION file if needed
3. Build Docker images with tags:
   - `:latest`
   - `:1.5.1` (or incremented version)
   - `:20250817` (date tag)
4. Create GitHub release v1.5.1 (or incremented version) with auto-generated notes
5. Publish to GitHub Container Registry

### For Future Agents

See [AUTOMATED_VERSIONING.md](AUTOMATED_VERSIONING.md) for comprehensive instructions on:
- Using semantic commit message conventions
- Troubleshooting automated versioning
- Manual override procedures
- Emergency release processes

---

*This guide now documents the automated versioning system that addresses issue #29: "Release number automation and documentation updates"*