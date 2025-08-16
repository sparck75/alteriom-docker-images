# alteriom-docker-images Development Instructions

Always follow these instructions precisely and only fall back to additional search and context gathering if the information in the instructions is incomplete or found to be in error.

Pre-built PlatformIO builder images for the Alteriom project (ESP32 / ESP8266). Contains production and development Docker images with PlatformIO and required build tools.

## Working Effectively

### Bootstrap and Verification
- Check image availability and status:
  - `./scripts/verify-images.sh` -- comprehensive verification with GitHub Actions workflow status (takes 30-60 seconds)
  - `./scripts/status-check.sh` -- quick status check (takes 10-15 seconds)
- ALWAYS verify images are published and working before using them in development
- Both scripts require Docker to be installed and available

### Docker Image Usage
- Pull and use production builder:
  - `docker pull ghcr.io/sparck75/alteriom-docker-images/builder:latest`
  - `docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest --version`
- Pull and use development image:
  - `docker pull ghcr.io/sparck75/alteriom-docker-images/dev:latest`
  - `docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/dev:latest --version`
- Build firmware (example command):
  - `docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev`

### Local Building (Admin/Development)
- **CRITICAL**: Local builds often fail due to SSL certificate issues in restricted network environments
- Set up environment:
  - `export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images`
- Build locally without push:
  - `./scripts/build-images.sh` -- takes 15-45 minutes depending on network. NEVER CANCEL. Set timeout to 60+ minutes.
- Build and push to registry:
  - `./scripts/build-images.sh push` -- takes 20-60 minutes depending on network and registry. NEVER CANCEL. Set timeout to 90+ minutes.
- **Known issue**: Docker builds may fail with SSL certificate errors in restricted environments. Run builds in unrestricted network environment when possible.

### CI/CD Operations
- GitHub Actions workflow triggers automatically:
  - **PR merges** to main branch
  - **Daily builds** at 02:00 UTC
  - **Manual dispatch** via GitHub Actions tab
- Force new build manually:
  1. Go to [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions)
  2. Click "Build and Publish Docker Images" workflow
  3. Click "Run workflow" button
  4. Select branch (usually `main`) and click "Run workflow"
- Workflow builds take 15-30 minutes typically. NEVER CANCEL builds. Set timeout to 45+ minutes.

## Validation

### Mandatory Validation Steps
- ALWAYS test image functionality after making changes:
  - `docker run --rm ghcr.io/sparck75/alteriom-docker-images/builder:latest --version` -- should output "PlatformIO Core, version 6.1.13"
  - `docker run --rm ghcr.io/sparck75/alteriom-docker-images/dev:latest --version` -- should output "PlatformIO Core, version 6.1.13"
- ALWAYS run verification after CI builds complete:
  - `./scripts/verify-images.sh` -- must show "ALL SYSTEMS GO!" for complete success
- You cannot interact with GUI applications, but you can test command-line PlatformIO functionality

### Complete User Scenario Testing
- Create test PlatformIO project:
  ```bash
  mkdir /tmp/test-platformio && cd /tmp/test-platformio
  echo '[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino' > platformio.ini
  mkdir src
  echo '#include <Arduino.h>
void setup() { Serial.begin(115200); }
void loop() { delay(1000); }' > src/main.cpp
  ```
- Test with Docker image (may fail in restricted networks but validates command structure):
  - `docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev`
- Expected behavior: Command should attempt to build, may fail due to network restrictions but validates image functionality
- ALWAYS test both production and development images after making changes to Dockerfiles

### Build Timing Expectations
- **NEVER CANCEL** any build or long-running command
- Local Docker builds: 15-45 minutes (set timeout to 60+ minutes)
- GitHub Actions builds: 15-30 minutes (set timeout to 45+ minutes)  
- Image pulls: 1-5 minutes depending on connection
- Verification scripts: 30-60 seconds

## Common Tasks

### Repository Structure
```
alteriom-docker-images/
├── .github/
│   └── workflows/
│       └── build-and-publish.yml    # CI/CD automation
├── production/
│   └── Dockerfile                   # Minimal PlatformIO builder
├── development/
│   └── Dockerfile                   # Development tools + PlatformIO
├── scripts/
│   ├── build-images.sh             # Build and push helper
│   ├── verify-images.sh            # Comprehensive verification
│   └── status-check.sh             # Quick status check
├── ADMIN_SETUP.md                  # Admin configuration guide
└── README.md                       # Usage documentation
```

### Key Files to Check After Changes
- Always check GitHub Actions logs after workflow changes: [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions)
- Always verify `production/Dockerfile` and `development/Dockerfile` build successfully
- Always test both images with `--version` command after Dockerfile changes

### Environment Requirements
- **Docker**: Required for all build and test operations
- **Bash**: Required for running helper scripts  
- **Unrestricted network**: Required for reliable building (PyPI access for pip installs)
- **GitHub Actions**: Pre-configured for automated builds and publishing
- **DOCKER_REPOSITORY environment variable**: Required for local builds (`export DOCKER_REPOSITORY=ghcr.io/your_user/alteriom-docker-images`)

### Image Registry Information
- **Registry**: GitHub Container Registry (GHCR)
- **Production image**: `ghcr.io/sparck75/alteriom-docker-images/builder:latest`
- **Development image**: `ghcr.io/sparck75/alteriom-docker-images/dev:latest`
- **Authentication**: Uses GitHub token, no additional secrets required
- **Multi-platform**: Builds for linux/amd64 and linux/arm64

### Troubleshooting Common Issues
- **SSL certificate errors**: Normal in restricted environments. Build in unrestricted network or use pre-published images.
- **Image not found**: Run `./scripts/verify-images.sh` to check publication status and build progress.
- **Permission denied in container**: Ensure mounted workspace has correct ownership (`chown -R 1000:1000` if needed).
- **Workflow failures**: Check [Actions tab](https://github.com/sparck75/alteriom-docker-images/actions) for detailed logs.

## Development Notes
- PlatformIO version pinned to 6.1.13 for stability
- Base image: python:3.11-slim (compatible with current package repositories)
- Images include pre-installed espressif32 and espressif8266 platforms when built in unrestricted environment
- Non-root user 'builder' (UID 1000) for security
- Working directory: `/workspace` for mounted project files