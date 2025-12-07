# .NET 7 SDK Dockerfile for CI/CD jobs
# Uses published base image from GHCR
FROM ghcr.io/hutch79/ci-runner-images:base

# Install .NET 7 SDK for build and test tooling
# Using .NET install script for reliable, up-to-date installations
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
 && curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
 && chmod +x dotnet-install.sh \
 && ./dotnet-install.sh --channel 7.0 --install-dir /usr/share/dotnet \
 && rm dotnet-install.sh \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm -rf /var/lib/apt/lists/*
USER runner

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify installation
RUN echo "=== .NET Version Installed ===" \
 && dotnet --list-sdks \
 && echo "=== Default .NET Version ===" \
 && dotnet --version