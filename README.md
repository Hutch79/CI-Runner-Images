# CI-Runner Images

Docker images for CI/CD job runners with different language/tooling support.

## Image Overview

| Image | Purpose | Key Features | Example Tag |
|-------|---------|--------------|-------------|
| **Base** | Minimal CI/CD foundation | Ubuntu 24.04, Git, Node.js, curl, unzip, non-root user | `ghcr.io/hutch79/ci-runner-images:base` |
| **.NET Multi** | All supported .NET versions | .NET 8.0, 9.0, 10.0 SDKs | `ghcr.io/hutch79/ci-runner-images:dotnet` |
| **.NET 10** | Current LTS | .NET 10.0 SDK | `ghcr.io/hutch79/ci-runner-images:dotnet-10` |
| **.NET 9** | Current STS | .NET 9.0 SDK | `ghcr.io/hutch79/ci-runner-images:dotnet-9` |
| **.NET 8** | Old LTS | .NET 8.0 SDK | `ghcr.io/hutch79/ci-runner-images:dotnet-8` |

**Note**: All images include dated tags for explicit references, e.g., `ghcr.io/hutch79/ci-runner-images:base-20251208`

## Images

### Base Image
Minimal Ubuntu 24.04 image with essential CI/CD tools:
- Git, Node.js, curl, unzip, and other common utilities
- Non-root user setup for security
- Optimized for fast startup and small size

## Automated Publishing

### Weekly Builds
All images are automatically built and published weekly on **Mondays at 00:00 UTC** via GitHub Actions.

### Tagging Strategy
- **Release tags** (without dates) for stable references: `ghcr.io/hutch79/ci-runner-images:{image-name}`
- **Dated tags** for pinning to specific versions: `ghcr.io/hutch79/ci-runner-images:{image-name}-{YYYYMMDD}`
