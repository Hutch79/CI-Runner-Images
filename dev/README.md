# Development Scripts

This directory contains utility scripts for local development and testing of CI/CD job runner images.

## Scripts

### `build-all.sh`

Builds all Docker images and runs tests locally, mimicking the GitHub Actions CI/CD pipeline behavior.

#### Usage

```bash
./dev/build-all.sh [options]
```

#### Options

- `--no-cache` - Don't use build cache (slower, but fresh builds)
- `--skip-tests` - Build only, don't run any tests
- `--skip-smoke` - Skip smoke tests (but run integration tests)
- `--skip-integration` - Skip integration tests (but run smoke tests)
- `--help` - Show help message

#### Examples

```bash
# Build all images with cache, run all tests
./dev/build-all.sh

# Build without cache
./dev/build-all.sh --no-cache

# Build only, skip tests
./dev/build-all.sh --skip-tests

# Build with smoke tests only
./dev/build-all.sh --skip-integration

# Build with integration tests only
./dev/build-all.sh --skip-smoke
```

#### Behavior

**Build Process:**
- Builds images in order: base, then all dependent images
- Uses configuration from `config.yml` for base images, naming, etc.
- If `base` image build fails → **immediately stops** (aborts all other builds)
- If any other image build fails → continues to next image
- Continues through all images even if some fail

**Testing:**
- Smoke tests: Basic functionality checks (tools installed, image runs, etc.)
- Integration tests: Runs project-specific test scripts if available
- Tests only run if all builds succeeded
- Test failures don't stop other tests (continues through all images)

**Exit Code:**
- `0` - All builds and tests passed
- `1` - Any build or test failed

#### Output

The script provides colored output:
- 🟢 **Green** (`✓`) - Success
- 🔴 **Red** (`✗`) - Failure
- 🟡 **Yellow** (`⚠`) - Warning
- 🔵 **Blue** (`→`) - Information

#### Example Output

```
================================================
CI/CD Job Runners - Build All Images
================================================

Configuration:
  Cache: enabled
  Tests: enabled
  Smoke tests: enabled
  Integration tests: enabled

→ Found 9 images to build

================================================
Building: base
================================================
→ Image directory: /path/to/images/base
→ Base image: ubuntu:24.04
→ Local tag: local-test-base:latest
✓ Built: base

[... more builds ...]

================================================
Building: dotnet-8
================================================
→ Image directory: /path/to/images/dotnet-8
→ Base image: ghcr.io/hutch79/ci-runner-images:base
→ Local tag: local-test-dotnet-8:latest
✓ Built: dotnet-8
→ Running tests for: dotnet-8
→ Running smoke tests...
✓ Smoke tests passed: dotnet-8
→ Running integration tests...
✓ Integration tests passed: dotnet-8
✓ Tests passed: dotnet-8

[... more tests ...]

================================================
Build Summary
================================================
Total builds: 9
Successful builds: 9
Failed builds: 0
Failed tests: 0
✓ All builds and tests passed!
```

## How It Works with Configuration

The script automatically uses configuration from `config.yml`:

- **Base images**: Gets Ubuntu base image and runner base image from config
- **Image naming**: Uses naming convention from config
- **Registry**: Uses registry configuration (for display purposes)

Configuration is loaded dynamically using `scripts/config-loader.sh` (pure bash, no dependencies).

## Requirements

- Linux/Unix system with bash
- Docker with buildx support
- Standard utilities: grep, sed, awk, find
- Python 3 (for config loader - optional if using shell config-loader.sh)

## What Gets Built

The script discovers and builds all images in the `images/` directory:

- `images/base` - Base Ubuntu image with common tools
- `images/dotnet` - .NET SDK (multiple versions)
- `images/dotnet-8` - .NET 8 SDK
- `images/dotnet-9` - .NET 9 SDK
- `images/dotnet-10` - .NET 10 SDK
- `images/node-20` - Node.js 20
- `images/node-22` - Node.js 22
- `images/node-24` - Node.js 24

## Testing

### Smoke Tests

Basic functionality checks run for all images:
- Image can be instantiated
- Common tools are installed (git, curl)
- Language-specific tools are installed (.NET, Node.js, npm)

### Integration Tests

Project-specific tests run if available:
- Looks for `tests/projects/<image-name>/test-build.sh`
- Runs the test script with the built image tag
- Tests verify the image can actually build/run projects

## Tips

1. **First run**: Use `--no-cache` to ensure fresh builds
2. **Development iteration**: Use `--skip-tests` for faster builds
3. **Quick validation**: Use `--skip-integration` to skip long-running tests
4. **Debug builds**: Docker runs with `--load` (not pushed to registry)

## Troubleshooting

- **"docker buildx build" not found**: Install Docker Buildx (`docker buildx create`)
- **Permission denied**: Run with `sudo` or ensure you're in the docker group
- **Out of disk space**: Clean up old images with `docker image prune`
- **Base image not found**: Check `config.yml` base image URLs are accessible

## Integration with Pipelines

This script mimics the GitHub Actions pipeline behavior:

| Aspect | Local Script | GitHub Actions |
|--------|--------------|-----------------|
| Base failure handling | Stop all builds | Stop all builds |
| Other failures | Continue | Continue |
| Test runs | After all builds | Parallel with builds |
| Cache support | ✓ Yes | ✓ Yes |
| Configuration | config.yml | config.yml |
| Build args | Applied | Applied |

Use this script to validate changes locally before pushing!
