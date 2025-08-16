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
