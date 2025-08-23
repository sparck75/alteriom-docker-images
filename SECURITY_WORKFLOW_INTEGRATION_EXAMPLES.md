# Example Security Workflow Integration

This file demonstrates how other repositories can integrate the reusable security workflows from this repository.

## Basic Integration Example

Create this file as `.github/workflows/security.yml` in your repository:

```yaml
name: Security Checks

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]
  schedule:
    # Run security scans weekly on Sundays at 2 AM
    - cron: '0 2 * * 0'

jobs:
  security-analysis:
    name: Security Analysis
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-security-checks.yml@main
    with:
      python-version: '3.11'
      node-version: '18'
      enable-dependency-check: true
      enable-secret-scan: true
      enable-code-analysis: true
    secrets: inherit

  docker-security:
    name: Docker Security Scan
    # Only run for repositories that contain Docker files
    if: hashFiles('**/Dockerfile*') != ''
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-docker-security.yml@main
    with:
      image-name: ${{ github.event.repository.name }}
      dockerfile-path: "./Dockerfile"
      enable-trivy-scan: true
      enable-hadolint: true
      enable-dockle: true
    secrets: inherit
```

## Advanced Integration Example

For repositories with multiple Docker images or specific requirements:

```yaml
name: Comprehensive Security Pipeline

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]
  schedule:
    - cron: '0 2 * * 0'

jobs:
  # Basic security analysis
  security-analysis:
    name: Security Analysis
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-security-checks.yml@main
    with:
      python-version: '3.11'
      enable-dependency-check: true
      enable-secret-scan: true
      enable-code-analysis: true
    secrets: inherit

  # Production Docker image security
  docker-security-prod:
    name: Production Image Security
    if: hashFiles('**/Dockerfile') != ''
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-docker-security.yml@main
    with:
      image-name: ${{ github.event.repository.name }}-prod
      dockerfile-path: "./Dockerfile"
      registry: "ghcr.io"
    secrets: inherit

  # Development Docker image security
  docker-security-dev:
    name: Development Image Security
    if: hashFiles('**/Dockerfile.dev') != ''
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-docker-security.yml@main
    with:
      image-name: ${{ github.event.repository.name }}-dev
      dockerfile-path: "./Dockerfile.dev"
      registry: "ghcr.io"
    secrets: inherit

  # Custom security checks
  custom-security:
    name: Custom Security Checks
    runs-on: ubuntu-latest
    needs: [security-analysis]
    if: always()
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Custom vulnerability assessment
        run: |
          echo "Running custom security checks..."
          # Add repository-specific security checks here
          
      - name: Security gate check
        run: |
          # Implement security gates based on your requirements
          # Example: Fail if critical vulnerabilities are found
          echo "Evaluating security scan results..."
```

## Integration with Existing CI/CD

If you already have CI/CD workflows, integrate security checks:

```yaml
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  # Your existing jobs
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Build application
        run: npm run build

  # Add security checks
  security:
    name: Security Checks
    needs: test  # Run security checks after tests pass
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-security-checks.yml@main
    secrets: inherit

  # Docker security (if applicable)
  docker-security:
    name: Docker Security
    needs: [test, security]  # Run after tests and security checks
    if: hashFiles('**/Dockerfile') != ''
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-docker-security.yml@main
    with:
      image-name: ${{ github.event.repository.name }}
      dockerfile-path: "./Dockerfile"
    secrets: inherit

  # Deploy only if all security checks pass
  deploy:
    runs-on: ubuntu-latest
    needs: [build, security, docker-security]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: echo "Deploying to production..."
```

## Organization-wide Template

For consistent organization-wide adoption, create this in your organization's `.github` repository:

```yaml
# .github/.github/workflows/security-template.yml
name: Organization Security Template

on:
  workflow_call:
    inputs:
      repository-name:
        required: true
        type: string
      has-docker:
        required: false
        type: boolean
        default: false
      python-version:
        required: false
        type: string
        default: '3.11'

jobs:
  security:
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-security-checks.yml@main
    with:
      python-version: ${{ inputs.python-version }}
    secrets: inherit

  docker-security:
    if: inputs.has-docker
    uses: sparck75/alteriom-docker-images/.github/workflows/reusable-docker-security.yml@main
    with:
      image-name: ${{ inputs.repository-name }}
    secrets: inherit
```

Then use it in individual repositories:

```yaml
# Individual repository workflow
name: Security
on: [push, pull_request]

jobs:
  security:
    uses: your-org/.github/.github/workflows/security-template.yml@main
    with:
      repository-name: ${{ github.event.repository.name }}
      has-docker: true
      python-version: '3.11'
    secrets: inherit
```

## Required Permissions

Ensure your repositories have the necessary permissions:

```yaml
# Add to repository settings or workflow
permissions:
  contents: read
  security-events: write
  actions: read
  pull-requests: write  # For PR comments
  issues: write        # For issue creation
```

## Environment Variables and Secrets

Some workflows may require these secrets (configure at organization level):

- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- `DOCKER_REGISTRY_TOKEN`: For private registry access (if needed)
- `SECURITY_EMAIL`: For security notifications (optional)

## Monitoring and Alerting

Set up notifications for security events:

```yaml
# Add to your workflow for notifications
- name: Security notification
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: '🚨 Security scan failed',
        body: 'Security scan failed in workflow: ${{ github.workflow }}\nRun: ${{ github.run_id }}',
        labels: ['security', 'urgent']
      })
```

This integration guide provides multiple patterns for adopting the centralized security workflows based on different organizational needs and existing CI/CD setups.