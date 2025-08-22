---
name: Docker Build Issue
about: Report issues with Docker image building or CI/CD pipeline
title: '[BUILD] '
labels: build, ci-cd
assignees: ''

---

## Build Issue Description
A clear description of the build problem.

## Build Context
- **Build Type**: [ ] Local Build [ ] GitHub Actions [ ] Manual Pipeline
- **Target Image**: [ ] Production [ ] Development [ ] Both
- **Build Command**: 
- **Environment**: [ ] Restricted Network [ ] Unrestricted Network [ ] Corporate Firewall

## Build Output/Logs
```
Paste build logs here (include error messages)
```

## GitHub Actions Information (if applicable)
- **Workflow Run URL**: 
- **Failed Job**: 
- **Error Step**: 

## Validation Checklist
- [ ] Checked GitHub Actions status
- [ ] Verified Docker daemon is running
- [ ] Confirmed network connectivity
- [ ] Ran `./scripts/validate-workflows.sh`
- [ ] Checked available disk space
- [ ] Verified base image availability
- [ ] Tested with clean Docker environment

## Network/Firewall Issues
- [ ] Corporate firewall restrictions
- [ ] SSL certificate issues
- [ ] PyPI access blocked
- [ ] GitHub Container Registry access issues
- [ ] Other network restrictions: 

## Build Commands Attempted
```bash
# Paste the exact commands you tried
```

## System Information
- **Docker Version**: 
- **Operating System**: 
- **Available Memory**: 
- **Available Disk Space**: 
- **Network Environment**: 

## Expected Behavior
What should have happened during the build.

## Proposed Solution
If you have ideas on how to fix this build issue.

## Additional Context
Any other context about the build environment, restrictions, or specific requirements.