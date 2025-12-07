# Minimal Dockerfile for CI/CD jobs (Ubuntu 24.04)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only the minimal runtime tools required by common CI steps
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    nodejs \
    openssh-client \
    unzip \
    zip \
    gnupg \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Non-root user for safer CI execution
RUN useradd -m -u 1000 -s /bin/bash runner \
 && mkdir -p /workspace \
 && chown runner:runner /workspace

WORKDIR /workspace
USER runner

ENV PATH=/home/runner/.local/bin:$PATH

CMD ["/bin/bash"]