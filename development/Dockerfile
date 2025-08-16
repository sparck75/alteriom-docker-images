# Development builder image — extends production with dev tools

FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential git ca-certificates curl unzip wget pkg-config git-core \
       libffi-dev libssl-dev gcc g++ make cmake vim less sudo htop python3-distutils \
    && rm -rf /var/lib/apt/lists/*

# Install PlatformIO
RUN pip3 install --no-cache-dir -U pip setuptools wheel \
    && pip3 install --no-cache-dir platformio

# Optional: install other helpful tools or inspectors
RUN pip3 install --no-cache-dir twine

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/platformio"]
CMD ["--help"]
