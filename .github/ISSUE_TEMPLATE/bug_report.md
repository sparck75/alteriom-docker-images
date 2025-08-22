---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''

---

## Bug Description
A clear and concise description of what the bug is.

## Environment
- **Docker Image**: [ ] Production (`builder:latest`) [ ] Development (`dev:latest`)
- **Platform**: [ ] ESP32 [ ] ESP8266 [ ] ESP32-S3 [ ] ESP32-C3
- **OS**: [ ] Windows [ ] macOS [ ] Linux [ ] WSL2
- **Docker Version**: 
- **Image Version/Tag**: 

## Steps to Reproduce
1. 
2. 
3. 
4. 

## Expected Behavior
A clear and concise description of what you expected to happen.

## Actual Behavior
A clear and concise description of what actually happened.

## Error Messages/Logs
```
Paste any error messages or relevant logs here
```

## Validation Checklist
- [ ] Verified issue exists with latest image version
- [ ] Checked if issue exists in both production and development images
- [ ] Ran `./scripts/verify-images.sh` to confirm image availability
- [ ] Tested with clean Docker environment (`docker system prune`)
- [ ] Reviewed existing issues for duplicates
- [ ] Included complete error messages/stack traces

## Docker Commands Used
```bash
# Paste the exact Docker commands that reproduce the issue
```

## Additional Context
Add any other context about the problem here (screenshots, network restrictions, firewall settings, etc.).

## Proposed Solution (if any)
If you have ideas on how to fix this, please describe them here.