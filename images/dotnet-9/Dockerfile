# .NET 9 SDK Dockerfile for CI/CD jobs
# Uses published base image from GHCR
FROM ghcr.io/hutch79/ci-cd-base:main

# Install .NET 9 SDK for build and test tooling
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
 && curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 9.0 --install-dir /usr/share/dotnet \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm -rf /var/lib/apt/lists/*
USER runner

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify installation
RUN dotnet --version && dotnet --list-sdks