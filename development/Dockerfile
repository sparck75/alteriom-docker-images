# Development builder image — extends production with dev tools

FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install build deps. On some Debian releases (e.g. trixie) the distutils package
# is provided as python3.11-distutils instead of python3-distutils. Try the
# generic package name first and fall back to the versioned name if needed.
RUN apt-get update \
     && apt-get install -y --no-install-recommends \
         build-essential git ca-certificates curl unzip wget pkg-config git-core \
         libffi-dev libssl-dev gcc g++ make cmake vim less sudo htop \
     && rm -rf /var/lib/apt/lists/*

# Install a pinned PlatformIO to avoid upstream surprises
RUN pip3 install --no-cache-dir -U pip setuptools wheel \
    && pip3 install --no-cache-dir "platformio==6.1.13"

# Optional: install other helpful tools or inspectors
RUN pip3 install --no-cache-dir twine

# Create non-root user and workspace directory for safer builds
RUN useradd --create-home --shell /bin/false builder \
    && mkdir -p /workspace \
    && chown -R builder:builder /workspace

USER builder

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
