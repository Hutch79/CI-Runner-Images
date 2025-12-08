# Node.js 22 Dockerfile for CI/CD jobs
# Uses published base image from GHCR
FROM ghcr.io/hutch79/ci-runner-images:base

# Remove existing Node.js installation and install Node.js 22
USER root
RUN apt-get update \
 && apt-get remove -y nodejs npm \
 && apt-get autoremove -y \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g npm@latest \
 && rm -rf /var/lib/apt/lists/*
USER runner

# Verify installation
RUN node --version && npm --version