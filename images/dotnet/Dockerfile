# Multi-Version .NET SDK Dockerfile for CI/CD jobs
# Contains .NET 8, 9, and 10 SDKs for flexible CI/CD pipelines
FROM ci-cd-base

# Install multiple .NET SDK versions for build and test tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    software-properties-common \
 && add-apt-repository ppa:dotnet/backports -y \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    dotnet-sdk-8.0 \
    dotnet-sdk-9.0 \
    dotnet-sdk-10.0 \
 && rm -rf /var/lib/apt/lists/*

# Set .NET environment variables
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Verify all installations
RUN echo "=== .NET Versions Installed ===" \
 && dotnet --list-sdks \
 && echo "=== Default .NET Version ===" \
 && dotnet --version