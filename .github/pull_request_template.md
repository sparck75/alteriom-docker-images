# Pull Request

## Description
Brief description of changes made in this PR.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Docker configuration change
- [ ] Script/automation update
- [ ] CI/CD workflow change
- [ ] Security improvement
- [ ] Performance optimization
- [ ] Platform support addition

## Related Issues
- Closes # (issue number)
- Addresses # (issue number)
- Related to # (issue number)

## Changes Made
### Docker Images
- [ ] Production image (`production/Dockerfile`)
- [ ] Development image (`development/Dockerfile`)
- [ ] Base image updates
- [ ] Dependency changes
- [ ] Configuration changes

### Scripts and Automation
- [ ] Build scripts (`scripts/build-images.sh`)
- [ ] Validation scripts (`scripts/verify-images.sh`, `scripts/status-check.sh`)
- [ ] Test scripts
- [ ] Utility scripts
- [ ] Other: 

### CI/CD Pipeline
- [ ] GitHub Actions workflow
- [ ] Build process changes
- [ ] Test automation
- [ ] Deployment changes
- [ ] Security scanning updates

### Documentation
- [ ] README.md
- [ ] Technical documentation
- [ ] Copilot instructions
- [ ] Admin guides
- [ ] Code comments

## Testing Checklist
### Local Testing
- [ ] Built Docker images locally without errors
- [ ] Tested production image functionality
- [ ] Tested development image functionality
- [ ] Ran `./scripts/verify-images.sh` successfully
- [ ] Tested PlatformIO version command
- [ ] Verified container health checks pass

### Platform Testing
- [ ] Tested ESP32 platform support
- [ ] Tested ESP8266 platform support
- [ ] Tested new platforms (if applicable)
- [ ] Validated platform installation process
- [ ] Confirmed no regressions with existing platforms

### Integration Testing
- [ ] Tested with existing projects
- [ ] Verified compatibility with current workflows
- [ ] Tested CI/CD pipeline integration
- [ ] Validated script functionality
- [ ] Confirmed no breaking changes

### Security Testing
- [ ] Ran security scans on images
- [ ] Verified no new vulnerabilities introduced
- [ ] Tested with restricted network environment
- [ ] Validated user permissions and access
- [ ] Confirmed sensitive data protection

## Performance Impact
### Image Size
- **Production image size change**: +/- XX MB
- **Development image size change**: +/- XX MB
- **Justification for size increases**: 

### Build Time
- **Local build time impact**: +/- XX minutes
- **CI/CD build time impact**: +/- XX minutes
- **Optimization strategies applied**: 

## Breaking Changes
- [ ] No breaking changes
- [ ] Breaking changes with migration guide
- [ ] Breaking changes documented below

### Migration Guide (if applicable)
Describe what users need to do to migrate:

1. 
2. 
3. 

## Security Considerations
- [ ] No security implications
- [ ] Security improvements included
- [ ] Security review required
- [ ] Potential security concerns: 

## Deployment Strategy
- [ ] Can be deployed immediately
- [ ] Requires coordinated deployment
- [ ] Needs gradual rollout
- [ ] Special deployment considerations: 

## Validation Commands
```bash
# Commands reviewers can run to validate this PR
./scripts/verify-images.sh
./scripts/status-check.sh

# Test specific functionality
docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest
docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version
```

## Pre-merge Checklist
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version number updated (if needed)
- [ ] Changelog updated (if applicable)
- [ ] Security review completed (if needed)
- [ ] Performance impact assessed
- [ ] Breaking changes documented
- [ ] Migration guide provided (if needed)

## Post-merge Tasks
- [ ] Monitor CI/CD pipeline
- [ ] Verify image deployment
- [ ] Update dependent projects (if needed)
- [ ] Announce breaking changes (if applicable)
- [ ] Close related issues

## Additional Notes
Any additional context, screenshots, or information that reviewers should know.

## Review Focus Areas
Please pay special attention to:
- [ ] Security implications
- [ ] Performance impact
- [ ] Breaking changes
- [ ] Documentation accuracy
- [ ] Test coverage
- [ ] Other: 

---

**Reviewer Guidelines**: Please ensure all checklist items are completed before approval. Test the changes in your local environment when possible.