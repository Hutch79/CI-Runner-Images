# .NET 8 SDK Dockerfile for CI/CD jobs
# Uses published base image from GHCR
FROM ghcr.io/hutch79/ci-cd-base:main

# Install .NET 8 SDK for build and test tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    software-properties-common \
 && add-apt-repository ppa:dotnet/backports -y \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    dotnet-sdk-8.0 \
 && rm -rf /var/lib/apt/lists/*

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify installation
RUN dotnet --version && dotnet --list-sdks