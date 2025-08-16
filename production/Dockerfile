# Optimized Production builder image for Alteriom
# Minimal image with PlatformIO for ESP32/ESP8266 builds
# Platforms are installed at runtime for smaller base image

FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install essential dependencies only, removing build tools after PlatformIO install
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    gcc \
    g++ \
    make \
    libffi-dev \
    libssl-dev \
    && pip3 install --no-cache-dir -U pip \
    && pip3 install --no-cache-dir "platformio==6.1.13" \
    && apt-get remove -y gcc g++ make libffi-dev libssl-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and workspace directory for safer builds
RUN useradd --create-home --shell /bin/false builder \
    && mkdir -p /workspace \
    && chown -R builder:builder /workspace

USER builder

WORKDIR /workspace

# Default entrypoint: run platformio if arguments provided
ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
