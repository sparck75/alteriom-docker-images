# Production builder image for Alteriom
# Lightweight image with PlatformIO and required platforms

FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential git ca-certificates curl unzip wget pkg-config git-core \
       libffi-dev libssl-dev gcc g++ make cmake \
    && rm -rf /var/lib/apt/lists/*

# Install PlatformIO
RUN pip3 install --no-cache-dir -U pip setuptools wheel \
    && pip3 install --no-cache-dir platformio

# Pre-install commonly used PlatformIO platforms and frameworks (attempt)
# These may fail in restricted networks when building; the admin should build in an unrestricted environment.
RUN pio platform install espressif32 || echo "espressif32 install failed"
RUN pio platform install espressif8266 || echo "espressif8266 install failed"

# Create workspace dir
WORKDIR /workspace

# Default entrypoint: run platformio if arguments provided
ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
