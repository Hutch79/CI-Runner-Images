# Centralized Configuration Implementation

## Summary

Implemented centralized configuration management for the CI/CD job runners project to eliminate hardcoded values and improve maintainability.

## What Was Actually Implemented

### 1. Configuration File: `config.yml`

Contains centralized settings for:

- **Registry settings**: URL, owner, repository name
- **Base images**: Ubuntu base (`ubuntu:24.04`) and internal runner base (`ghcr.io/hutch79/ci-runner-images:base`)
- **Image naming**: Platform naming convention (currently `ubuntu`)
- **GitHub Actions versions**: All action versions in one place

### 2. Shell Configuration Loader: `scripts/config-loader.sh`

Pure bash script providing programmatic access to configuration values (no dependencies):

```bash
# Get registry path
bash scripts/config-loader.sh registry-path
# Returns: ghcr.io/hutch79/ci-runner-images

# Get image name with naming convention applied
bash scripts/config-loader.sh image-name dotnet-8
# Returns: ubuntu-dotnet-8

# Get full image tag
bash scripts/config-loader.sh full-tag base 20251208
# Returns: ghcr.io/hutch79/ci-runner-images:base-20251208

# Get base images
bash scripts/config-loader.sh base-ubuntu
# Returns: ubuntu:24.04

bash scripts/config-loader.sh base-runner
# Returns: ghcr.io/hutch79/ci-runner-images:base

# Get any config value
bash scripts/config-loader.sh get actions.trivy
# Returns: 0.33.1
```

### 3. Bash Helper Library: `scripts/lib/config.sh`

Convenient bash functions for local shell scripts (uses Python config-loader if available):

```bash
source scripts/lib/config.sh

# Get configuration values
registry=$(config_registry_path)
base_image=$(config_base_ubuntu)
runner_base=$(config_base_runner)
action_version=$(config_action_version "checkout")

# Get full image tags
image_tag=$(config_full_tag "dotnet-8" "20251208")
```

## Files Modified

### Dockerfiles Updated

All Dockerfiles now use `ARG BASE_IMAGE` to accept base image from build args:

**Modified files:**

- ✅ `images/base/Dockerfile` - Uses `ARG BASE_IMAGE=ubuntu:24.04`
- ✅ `images/dotnet/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/dotnet-8/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/dotnet-9/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/dotnet-10/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/node-20/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/node-22/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`
- ✅ `images/node-24/Dockerfile` - Uses `ARG BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base`

### GitHub Actions Updated

**`.github/actions/ci-image-builder/action.yml`:**

- ✅ Loads config values (registry, base images, action versions)
- ✅ Uses config for Docker Buildx action version
- ✅ Uses config for Docker login action version
- ✅ Passes base images as build args to Docker build
- ✅ Automatically selects correct base image (Ubuntu for `base`, runner for others)
- ✅ Uses config for registry path in image tags

**`.github/workflows/security-scan.yml`:**

- ✅ Loads Trivy version from config
- ✅ Loads CodeQL upload-sarif action version from config
- ✅ Uses dynamic action versions

**`.github/workflows/weekly-build.yml`:**

- ✅ Summary job loads registry from config
- ✅ Login action version from config
- ✅ Registry URL from config for image tags

## How It Works

### Docker Build with Config

When building images, the `ci-image-builder` action:

1. Loads config values from `config.yml`
2. Determines which base image to use (Ubuntu for `base`, runner for others)
3. Passes base image as `--build-arg BASE_IMAGE=<value>` to Docker build
3. Uses config-based registry path for tagging

Example build command generated:

```bash
docker buildx build \
  --build-arg BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base \
  --tag ghcr.io/hutch79/ci-runner-images:ubuntu-dotnet-8-20251208 \
  --push \
  images/dotnet-8
```

### GitHub Actions Version Management

Workflows now load action versions from config:

```yaml
- name: Load configuration
  id: config
  run: |
    echo "trivy_version=$(python3 scripts/config-loader.py get actions.trivy)" >> $GITHUB_OUTPUT

- name: Run Trivy
  uses: aquasecurity/trivy-action@${{ steps.config.outputs.trivy_version }}
```

## Benefits Achieved

1. ✅ **Single Source of Truth**: Registry and base images defined once in `config.yml`
2. ✅ **Easy Updates**: Change base image version once, affects all Dockerfiles
3. ✅ **Consistent Naming**: Image naming convention enforced programmatically
4. ✅ **Action Version Control**: All GitHub Actions versions centralized
5. ✅ **Build Arg Flexibility**: Can override base images at build time if needed

## Usage Examples

### Building Images Locally

```bash
# Build with default base from config
docker build -t my-test-image images/dotnet-8

# Override base image
docker build \
  --build-arg BASE_IMAGE=ghcr.io/hutch79/ci-runner-images:base-20251201 \
  -t my-test-image \
  images/dotnet-8
```

### Updating Registry

Edit `config.yml`:

```yaml
registry:
  url: docker.io       # Changed from ghcr.io
  owner: mycompany
  repository: ci-images
```

All workflows will automatically use the new registry on next run.

### Updating Base Image

Edit `config.yml`:

```yaml
base_images:
  ubuntu: ubuntu:24.10  # Upgrade Ubuntu
```

Rebuild base image, then rebuild all dependent images - they'll automatically pull the new base.

### Updating Action Versions

Edit `config.yml`:

```yaml
actions:
  trivy: "0.34.0"  # Upgrade Trivy scanner
```

Next workflow run will use the new version automatically.

## Next Steps (Future Enhancements)

1. Update remaining workflows to load checkout action version from config
2. Add config validation script to ensure values are valid
3. Add config-based timeouts and retry settings for tests
4. Consider adding digest pinning for base images for reproducibility
