# .NET 10 SDK Dockerfile for CI/CD jobs
# Uses published base image from GHCR
FROM ci-cd-base

# Install .NET 10 SDK for build and test tooling
# Using .NET install script (more up-to-date than apt packages)
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
 && curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0 --install-dir /usr/share/dotnet \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm -rf /var/lib/apt/lists/*
USER runner

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify installation
RUN dotnet --version && dotnet --list-sdks