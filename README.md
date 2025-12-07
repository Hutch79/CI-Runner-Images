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

### Weekly Builds
All images are automatically built and published weekly on **Mondays at 00:00 UTC** via GitHub Actions.

**Published to**: `ghcr.io/hutch79/ci-runner-images:<folder-name>-<date>`

**Examples**:
- `ghcr.io/hutch79/ci-runner-images:base-20251207`
- `ghcr.io/hutch79/ci-runner-images:dotnet-10-20251207`
- `ghcr.io/hutch79/ci-runner-images:dotnet-20251207`

### Release Tags
Weekly builds also create release tags **without dates** for stable references:
- `ghcr.io/hutch79/ci-runner-images:base`
- `ghcr.io/hutch79/ci-runner-images:dotnet-10`
- `ghcr.io/hutch79/ci-runner-images:dotnet`

### Base Image Publishing
The base image is also published when changes are made to `images/base/` with tags like:
- `ghcr.io/hutch79/ci-cd-base:main` (branch-based)
- `ghcr.io/hutch79/ci-cd-base:latest` (default branch)

### Manual Triggers
You can manually trigger the weekly build workflow from the GitHub Actions tab.

## Building Images

### Local Development
For local development and testing:

```bash
# Build base image
docker build -t ci-cd-base ./images/base

# Build .NET images (use published base image from GHCR)
docker build -t ci-cd-dotnet ./images/dotnet
docker build -t ci-cd-dotnet-8 ./images/dotnet-8
docker build -t ci-cd-dotnet-9 ./images/dotnet-9
docker build -t ci-cd-dotnet-10 ./images/dotnet-10
```

### Automated Weekly Builds
All images are automatically built and published **weekly on Mondays at 00:00 UTC**. Use the published images for production CI/CD pipelines.

### Using Published Images
All images are available on GitHub Container Registry with weekly automated builds:
- **Base**: `ghcr.io/hutch79/ci-runner-images:base-YYYYMMDD`
- **Multi .NET**: `ghcr.io/hutch79/ci-runner-images:dotnet-YYYYMMDD`
- **.NET 8**: `ghcr.io/hutch79/ci-runner-images:dotnet-8-YYYYMMDD`
- **.NET 9**: `ghcr.io/hutch79/ci-runner-images:dotnet-9-YYYYMMDD`
- **.NET 10**: `ghcr.io/hutch79/ci-runner-images:dotnet-10-YYYYMMDD`

**Release tags** (without dates) are also available for stable references.

## Usage

```bash
# Use latest weekly builds (recommended for stability)
docker run -it --rm ghcr.io/hutch79/ci-runner-images:base
docker run -it --rm ghcr.io/hutch79/ci-runner-images:dotnet-10

# Use specific dated versions
docker run -it --rm ghcr.io/hutch79/ci-runner-images:base-20251207
docker run -it --rm ghcr.io/hutch79/ci-runner-images:dotnet-10-20251207

# Use in CI/CD pipelines
FROM ghcr.io/hutch79/ci-runner-images:dotnet-10:latest
```