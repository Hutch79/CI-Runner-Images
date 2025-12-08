#!/bin/bash
# Bash helper functions for accessing centralized configuration
# Sources configuration from config.yml using the Python config loader

# Get the repository root directory
get_repo_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

# Path to the Python config loader
CONFIG_LOADER="$(get_repo_root)/scripts/config-loader.py"

# Ensure config loader is executable
if [ ! -x "$CONFIG_LOADER" ]; then
    chmod +x "$CONFIG_LOADER" 2>/dev/null || true
fi

# Get a configuration value by key path
# Usage: config_get "registry.url"
config_get() {
    local key="$1"
    local default="${2:-}"
    
    if [ -z "$key" ]; then
        echo "Error: config_get requires a key path" >&2
        return 1
    fi
    
    if [ -n "$default" ]; then
        python3 "$CONFIG_LOADER" get "$key" "$default" 2>/dev/null || echo "$default"
    else
        python3 "$CONFIG_LOADER" get "$key" 2>/dev/null
    fi
}

# Get full registry path (without tag)
# Returns: ghcr.io/hutch79/ci-runner-images
config_registry_path() {
    python3 "$CONFIG_LOADER" registry-path 2>/dev/null
}

# Get image name for a folder (applies naming convention)
# Usage: config_image_name "dotnet-8" -> "ubuntu-dotnet-8"
#        config_image_name "base" -> "base"
config_image_name() {
    local folder_name="$1"
    python3 "$CONFIG_LOADER" image-name "$folder_name" 2>/dev/null
}

# Get full image tag
# Usage: config_full_tag "base"           -> ghcr.io/hutch79/ci-runner-images:base
#        config_full_tag "base" "20251208" -> ghcr.io/hutch79/ci-runner-images:base-20251208
config_full_tag() {
    local folder_name="$1"
    local tag="${2:-latest}"
    python3 "$CONFIG_LOADER" full-tag "$folder_name" "$tag" 2>/dev/null
}

# Get base Ubuntu image
# Returns: ubuntu:24.04
config_base_ubuntu() {
    python3 "$CONFIG_LOADER" base-ubuntu 2>/dev/null
}

# Get runner base image (internal base)
# Returns: ghcr.io/hutch79/ci-runner-images:base
config_base_runner() {
    python3 "$CONFIG_LOADER" base-runner 2>/dev/null
}

# Get GitHub Actions version
# Usage: config_action_version "checkout" -> "v4"
config_action_version() {
    local action="$1"
    config_get "actions.${action}"
}

# Validate that configuration is accessible
config_validate() {
    if [ ! -f "$CONFIG_LOADER" ]; then
        echo "Error: Config loader not found at $CONFIG_LOADER" >&2
        return 1
    fi
    
    if ! python3 "$CONFIG_LOADER" get "registry.url" >/dev/null 2>&1; then
        echo "Error: Cannot read configuration. Check config.yml" >&2
        return 1
    fi
    
    return 0
}
