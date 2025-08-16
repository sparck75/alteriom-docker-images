# alteriom-docker-images

Pre-built PlatformIO builder images for the Alteriom project (ESP32 / ESP8266).

This repository contains Dockerfiles and helper scripts to build and publish PlatformIO images that include the required PlatformIO platforms and build tools so CI systems and developers can build firmware without downloading platforms at build time.

Contents
- production/Dockerfile  — minimal builder image with PlatformIO and espressif platforms
- development/Dockerfile — development image with extra tools and debugging utilities
- scripts/build-images.sh — build and push helper script
- scripts/verify-images.sh — verify published images are available and working

Quick start

Pull the recommended builder image (replace `<your_user>` with the image owner):

```powershell
docker pull ghcr.io/<your_user>/alteriom-docker-images/builder:latest
```

Build firmware using the image:

```powershell
# mount your repository into /workspace and run PlatformIO inside the image
docker run --rm -v ${PWD}:/workspace ghcr.io/<your_user>/alteriom-docker-images/builder:latest pio run -e diag-esp32-c3
```

**Verify images are ready:**

```bash
# Check if images are published and working
./scripts/verify-images.sh
```

Build & publish (admin, one-time - run in an unrestricted network environment)

```powershell
# from the cloned Alteriom repo
# set GITHUB_TOKEN and DOCKER_REPOSITORY environment variables
./scripts/build-images.sh push
```

CI / Automated builds

This repository includes a GitHub Actions workflow (`.github/workflows/build-and-publish.yml`) that automatically builds and publishes the production and development images when PRs are merged to main, on a daily schedule, and on manual dispatch. The workflow tags images with `:latest` and a date tag (YYYYMMDD). 

**Setup required:** The workflow is pre-configured to use GitHub Container Registry (GHCR) and requires no additional secrets setup. The workflow uses the built-in `GITHUB_TOKEN` for authentication.

**Admin Notes:** 
- Repository has been tested and builds are working as of August 2025
- Docker builds use Python 3.11-slim base image (compatible with current package repositories)
- Both production and development images build successfully with multi-platform support

**Optional configuration:** If you want to use a different container registry, set the following repository variables:

- `DOCKER_REPOSITORY` - target repository (e.g. `ghcr.io/<your_user>/alteriom-docker-images`) - optional, defaults to `ghcr.io/<owner>/alteriom-docker-images`

The workflow runs:
- **Automatically** when PRs are merged to the main branch
- **Daily** at 02:00 UTC  
- **Manually** via workflow dispatch in the Actions tab

Contribution and maintenance

If you'd like me to help maintain the CI and update images regularly, I can:

- Review and refine the Dockerfiles for size and reproducibility
- Add automated smoke tests that run a quick `pio run -e diag-esp32-c3` inside the image
- Keep the daily build workflow and perform periodic reviews when PlatformIO releases major changes

Repository structure

```
alteriom-docker-images/
├── production/
│   └── Dockerfile
├── development/
│   └── Dockerfile
├── scripts/
│   └── build-images.sh
└── README.md
```

License
This repository is licensed under the MIT License. See `LICENSE` for details.
