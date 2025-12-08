# Configuration Management

This project uses centralized configuration in `config.yml` for:

- Base images (Ubuntu and internal runner base)
- Container registry settings
- Image naming conventions
- GitHub Actions versions

## Configuration File

The `config.yml` file contains:

```yaml
registry:
  url: ghcr.io
  owner: hutch79
  repository: ci-runner-images

base_images:
  ubuntu: ubuntu:24.04           # Base for the 'base' image
  runner: ghcr.io/hutch79/ci-runner-images:base  # Base for all other images

naming:
  platform: ubuntu               # Used in image naming: <platform>-<content>

actions:
  checkout: v4                   # GitHub Actions versions
  setup-buildx: v3
  # ... etc
```

## Using Configuration in Scripts

### Bash Scripts

Use the config loader shell script directly:

```bash
#!/bin/bash

# Get registry path
REGISTRY=$(bash scripts/config-loader.sh registry-path)
# Returns: ghcr.io/hutch79/ci-runner-images

# Get configuration values
CHECKOUT_VERSION=$(bash scripts/config-loader.sh get actions.checkout)
# Returns: v4

# Get image name
IMAGE_NAME=$(bash scripts/config-loader.sh image-name "dotnet-8")
# Returns: ubuntu-dotnet-8

# Get full image tag
FULL_TAG=$(bash scripts/config-loader.sh full-tag "dotnet-8" "20251208")
# Returns: ghcr.io/hutch79/ci-runner-images:ubuntu-dotnet-8-20251208

# Get base images
UBUNTU_BASE=$(bash scripts/config-loader.sh base-ubuntu)
# Returns: ubuntu:24.04

RUNNER_BASE=$(bash scripts/config-loader.sh base-runner)
# Returns: ghcr.io/hutch79/ci-runner-images:base
```

Or source the configuration helper library:

```bash
#!/bin/bash
source "$(dirname "$0")/lib/config.sh"

# Get registry path
REGISTRY=$(config_registry_path)

# Get full image tag
IMAGE_TAG=$(config_full_tag "base" "20251208")

# Get action version
CHECKOUT_VERSION=$(config_action_version "checkout")
```

### GitHub Actions Workflows

Load configuration values in workflow steps using the shell script:

```yaml
- name: Load configuration
  id: config
  run: |
    echo "registry=$(bash scripts/config-loader.sh registry-path)" >> $GITHUB_OUTPUT
    echo "base_ubuntu=$(bash scripts/config-loader.sh base-ubuntu)" >> $GITHUB_OUTPUT
    echo "checkout_version=$(bash scripts/config-loader.sh get actions.checkout)" >> $GITHUB_OUTPUT

- name: Use configuration
  run: |
    echo "Registry: ${{ steps.config.outputs.registry }}"
    echo "Base: ${{ steps.config.outputs.base_ubuntu }}"
```

## Image Naming Convention

Images follow the pattern: `<platform>-<content>`

- **platform**: Operating system base (currently `ubuntu`)
- **content**: Folder name containing the Dockerfile

Examples:

- `base` → `base` (special case)
- `dotnet-8` → `ubuntu-dotnet-8`
- `node-20` → `ubuntu-node-20`

Full tags include the registry:

- `ghcr.io/hutch79/ci-runner-images:base`
- `ghcr.io/hutch79/ci-runner-images:ubuntu-dotnet-8`

## Updating Configuration

### Changing the Registry

Edit `config.yml`:

```yaml
registry:
  url: docker.io        # Changed from ghcr.io
  owner: mycompany
  repository: ci-images
```

All scripts and workflows will automatically use the new registry.

### Updating Base Images

```yaml
base_images:
  ubuntu: ubuntu:24.10  # Upgrade Ubuntu version
```

Rebuild all images to pick up the new base.

### Updating Action Versions

```yaml
actions:
  checkout: v5          # Upgrade action version
  trivy: "0.34.0"       # Update Trivy scanner
```

Update workflows to reference `config.yml` for action versions.
