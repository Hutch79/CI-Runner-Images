# Minimal Dockerfile for CI/CD jobs (Ubuntu 24.04)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG NODE_MAJOR=20

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    unzip \
    zip \
    gnupg \
    xz-utils \
 && \
 # Install Node.js from NodeSource for a pinned major version (better control than distro package)
 curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Non-root user for safer CI execution
RUN useradd -m -u 1001 -s /bin/bash runner \
 && mkdir -p /workspace \
 && chown runner:runner /workspace \
 && mkdir -p /home/runner/.local/bin \
 && chown -R 1001:1001 /home/runner/.local

WORKDIR /workspace
USER runner

ENV PATH=/home/runner/.local/bin:$PATH

CMD ["/bin/bash"]