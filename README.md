# alteriom-docker-images

Pre-built PlatformIO builder images for the Alteriom project (ESP32 / ESP8266).

This repository contains Dockerfiles and helper scripts to build and publish PlatformIO images that include the required PlatformIO platforms and build tools so CI systems and developers can build firmware without downloading platforms at build time.

Contents
- production/Dockerfile  — minimal builder image with PlatformIO and espressif platforms
- development/Dockerfile — development image with extra tools and debugging utilities
- scripts/build-images.sh — build and push helper script

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

Build & publish (admin, one-time - run in an unrestricted network environment)

```powershell
# from the cloned Alteriom repo
# set GITHUB_TOKEN and DOCKER_REPOSITORY environment variables
./scripts/build_docker_images.sh push
```

CI / Automated builds

This repository includes a GitHub Actions workflow that builds and publishes the production and development images on-demand and on a daily schedule. The workflow tags images with `:latest` and a date tag (YYYYMMDD). Set the following repository secrets before enabling the workflow:

- `REGISTRY_USERNAME` - username for the container registry (or leave blank when using GHCR with a personal token)
- `REGISTRY_TOKEN` - token with package:write (or equivalent) permissions
- `DOCKER_REPOSITORY` - target repository (e.g. `ghcr.io/<your_user>/alteriom-docker-images`)

Maintain a regular cadence: the workflow is configured to run daily (02:00 UTC) and on manual dispatch.

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
