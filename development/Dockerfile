# Optimized Development builder image — extends production with dev tools

FROM python:3.11-slim

# Add version labels for tracking
ARG VERSION=1.4.0
LABEL org.opencontainers.image.title="Alteriom Development Builder"
LABEL org.opencontainers.image.description="PlatformIO builder with development tools for ESP32/ESP8266 development"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.vendor="Alteriom"
LABEL org.opencontainers.image.source="https://github.com/sparck75/alteriom-docker-images"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="sparck75 <dominic.lavoie@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies including dev tools, removing build-only packages after
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    gcc \
    g++ \
    make \
    libffi-dev \
    libssl-dev \
    vim \
    less \
    htop \
    && pip3 install --no-cache-dir -U pip \
    && pip3 install --no-cache-dir -U "setuptools>=70.0.0" \
    && pip3 install --no-cache-dir "platformio==6.1.13" twine \
    && pip3 install --no-cache-dir -U "starlette>=0.40.0" \
    && apt-get remove -y gcc g++ make libffi-dev libssl-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and workspace directory for safer builds
RUN useradd --create-home --shell /bin/false builder \
    && mkdir -p /workspace \
    && chown -R builder:builder /workspace

USER builder

WORKDIR /workspace

# Add healthcheck to ensure PlatformIO is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/platformio --version || exit 1

ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
