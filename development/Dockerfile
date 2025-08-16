# Optimized Development builder image — extends production with dev tools

FROM python:3.11-slim

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
    && pip3 install --no-cache-dir "platformio==6.1.13" twine \
    && apt-get remove -y gcc g++ make libffi-dev libssl-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and workspace directory for safer builds
RUN useradd --create-home --shell /bin/false builder \
    && mkdir -p /workspace \
    && chown -R builder:builder /workspace

USER builder

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
