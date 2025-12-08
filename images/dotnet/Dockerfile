# Multi-Version .NET SDK Dockerfile for CI/CD jobs
# Contains .NET 8, 9, and 10 SDKs for flexible CI/CD pipelines
# Base image is configured in config.yml (base_images.runner)
ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base
FROM ${BASE_IMAGE}

# Install multiple .NET SDK versions for build and test tooling
# Using .NET install script for reliable, up-to-date installations
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
 && curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
 && chmod +x dotnet-install.sh \
 && ./dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
 && ./dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet \
 && ./dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet \
 && rm dotnet-install.sh \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm -rf /var/lib/apt/lists/*
USER runner

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify all installations
RUN echo "=== .NET Versions Installed ===" \
 && dotnet --list-sdks \
 && echo "=== Default .NET Version ===" \
 && dotnet --version