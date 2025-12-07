# CI-CD-job-runners

Docker images for CI/CD job runners with different language/tooling support.

## Images

### Base Image
Minimal Ubuntu 24.04 image with essential CI/CD tools:
- Git, Node.js, curl, unzip, and other common utilities
- Non-root user setup for security
- Optimized for fast startup and small size

### .NET SDK Images
Extend the base image with .NET SDKs for build and test tooling:
- **Multi-Version .NET Image**: Contains .NET 8.0, 9.0, and 10.0 SDKs
- **.NET 10 SDK Image**: .NET 10.0 SDK for latest features
- **.NET 9 SDK Image**: .NET 9.0 SDK for current LTS
- **.NET 8 SDK Image**: .NET 8.0 SDK for stable LTS
- Includes build tools, test runners, and development utilities
- No deployment runtimes (optimized for CI/CD pipelines)

## Automated Publishing

The base image is automatically published to GitHub Container Registry (GHCR) when changes are made to the `images/base/` directory.

### Published Images
- **Base Image**: `ghcr.io/hutch79/ci-cd-base:latest`
- Tagged with branch names, PR numbers, and commit SHAs for traceability

### Using Published Images
```bash
# Pull and use the published base image
docker pull ghcr.io/hutch79/ci-cd-base:latest

# Or reference it directly in FROM statements
FROM ghcr.io/hutch79/ci-cd-base:latest
```

## Building Images

```bash
# Build base image
docker build -t ci-cd-base ./images/base

# Build .NET images (all require base image)
docker build -t ci-cd-dotnet ./images/dotnet          # Multi-version (8, 9, 10)
docker build -t ci-cd-dotnet-8 ./images/dotnet-8
docker build -t ci-cd-dotnet-9 ./images/dotnet-9
docker build -t ci-cd-dotnet-10 ./images/dotnet-10
```

## Usage

```bash
# Run base image
docker run -it --rm ci-cd-base

# Run .NET images
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet     # Multi-version
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet-8
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet-9
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet-10

# Switch .NET versions in multi-version image
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet \
  dotnet --version  # Shows default (latest)
docker run -it --rm -v $(pwd):/workspace ci-cd-dotnet \
  dotnet test --framework net8.0
```