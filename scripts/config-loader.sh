#!/bin/bash
##############################################################################
# Configuration loader utility for CI/CD job runners.
# Reads values from config.yml for base images, registry, and action versions.
#
# Usage:
#   config-loader.sh get <key.path> [default]
#   config-loader.sh registry-path
#   config-loader.sh image-name <folder_name>
#   config-loader.sh full-tag <folder_name> [tag]
#   config-loader.sh base-ubuntu
#   config-loader.sh base-runner
##############################################################################

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Default config path
CONFIG_FILE="${REPO_ROOT}/config.yml"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Error: Configuration file not found: ${CONFIG_FILE}" >&2
    exit 1
fi

##############################################################################
# Helper function to get YAML values using grep and sed
# Handles nested keys with dot notation (e.g., "registry.url")
##############################################################################
get_yaml_value() {
    local key_path="$1"
    local default="${2:-}"
    local config_file="$3"
    
    # Convert dot notation to YAML path
    # e.g., "registry.url" becomes "registry:" then "url:"
    local current_indent=""
    local current_value=""
    local parts=()
    
    # Split by dots
    IFS='.' read -ra parts <<< "$key_path"
    
    local content=$(cat "$config_file")
    local current_indent=0
    
    for part in "${parts[@]}"; do
        # Find the line with the key at the current indentation
        local pattern="^$(printf ' %.0s' $(seq 1 $((current_indent * 2))))[^ #]*${part}:[^#]*"
        local line=$(echo "$content" | grep -E "^$(printf ' %.0s' $(seq 1 $((current_indent * 2))))${part}:" | head -1 || true)
        
        if [[ -z "$line" ]]; then
            if [[ -n "$default" ]]; then
                echo "$default"
            fi
            return 1
        fi
        
        # Extract the value from the line (after the colon, trimmed)
        local value=$(echo "$line" | sed "s/^[[:space:]]*${part}:[[:space:]]*//")
        
        # If value is empty, this is a parent key, so get its children
        if [[ -z "$value" ]]; then
            current_indent=$((current_indent + 1))
        else
            # Found the value
            echo "$value"
            return 0
        fi
    done
    
    if [[ -n "$default" ]]; then
        echo "$default"
    fi
    return 1
}

##############################################################################
# More robust YAML parser using awk
##############################################################################
get_yaml_value() {
    local key_path="$1"
    local default="${2:-}"
    local config_file="$3"
    
    # Use awk to parse YAML
    # This is a simple parser that handles our config.yml structure
    awk -v key="$key_path" -v default="$default" '
    BEGIN {
        FS = ":"
        split(key, keys, ".")
        target_depth = length(keys)
        depth = 0
        in_section = 0
    }
    
    /^[^ #]/ && NF > 1 {
        # Top-level key
        depth = 0
        current_key = $1
        gsub(/[[:space:]]/, "", current_key)
        
        if (depth + 1 == target_depth && current_key == keys[1]) {
            in_section = 1
            depth = 1
        } else {
            in_section = 0
        }
    }
    
    in_section && /^  [^ #]/ && NF > 1 {
        # Second-level key
        key_part = $1
        gsub(/^[[:space:]]+/, "", key_part)
        gsub(/[[:space:]]+$/, "", key_part)
        
        if (depth + 1 == target_depth && key_part == keys[2]) {
            # Found the value
            value = $2
            gsub(/^[[:space:]]+/, "", value)
            gsub(/[[:space:]]*#.*$/, "", value)
            print value
            exit 0
        }
    }
    
    END {
        if (default != "") {
            print default
        }
    }
    ' "$config_file"
}

##############################################################################
# Simplified YAML getter for our simple config structure
##############################################################################
get_yaml_value() {
    local key_path="$1"
    local default="${2:-}"
    local config_file="$3"
    
    # Split the key path into parts
    local IFS='.'
    local parts=($key_path)
    
    if [[ ${#parts[@]} -eq 1 ]]; then
        # Top-level key - find line like "key: value"
        grep "^${parts[0]}:" "$config_file" | sed "s/^${parts[0]}:[[:space:]]*//;s/[[:space:]]*#.*$//" || echo "$default"
    elif [[ ${#parts[@]} -eq 2 ]]; then
        # Second-level key - find section then key within it
        # Get content between "section:" and next top-level key
        sed -n "/^${parts[0]}:/,/^[^ ]/p" "$config_file" | \
            grep "^  ${parts[1]}:" | \
            head -1 | \
            sed "s/^[[:space:]]*${parts[1]}:[[:space:]]*//;s/[[:space:]]*#.*$//" || echo "$default"
    else
        echo "$default"
    fi
}

##############################################################################
# Get full registry path
##############################################################################
get_registry_path() {
    local url=$(get_yaml_value "registry.url" "ghcr.io" "$CONFIG_FILE")
    local owner=$(get_yaml_value "registry.owner" "hutch79" "$CONFIG_FILE")
    local repo=$(get_yaml_value "registry.repository" "ci-runner-images" "$CONFIG_FILE")
    echo "${url}/${owner}/${repo}"
}

##############################################################################
# Get image name based on folder
##############################################################################
get_image_name() {
    local folder_name="$1"
    
    if [[ "$folder_name" == "base" ]]; then
        echo "base"
    else
        local platform=$(get_yaml_value "naming.platform" "ubuntu" "$CONFIG_FILE")
        echo "${platform}-${folder_name}"
    fi
}

##############################################################################
# Get full image tag
##############################################################################
get_full_image_tag() {
    local folder_name="$1"
    local tag="${2:-latest}"
    
    local registry_path=$(get_registry_path)
    local image_name=$(get_image_name "$folder_name")
    
    if [[ "$tag" == "latest" ]]; then
        echo "${registry_path}:${image_name}"
    else
        echo "${registry_path}:${image_name}-${tag}"
    fi
}

##############################################################################
# Main command dispatcher
##############################################################################
main() {
    local action="${1:-help}"
    
    case "$action" in
        get)
            if [[ -z "${2:-}" ]]; then
                echo "Error: 'get' action requires a key path" >&2
                exit 1
            fi
            local value=$(get_yaml_value "$2" "${3:-}" "$CONFIG_FILE")
            if [[ -n "$value" ]]; then
                echo "$value"
            else
                exit 1
            fi
            ;;
        
        registry-path)
            get_registry_path
            ;;
        
        image-name)
            if [[ -z "${2:-}" ]]; then
                echo "Error: 'image-name' requires folder name" >&2
                exit 1
            fi
            get_image_name "$2"
            ;;
        
        full-tag)
            if [[ -z "${2:-}" ]]; then
                echo "Error: 'full-tag' requires folder name" >&2
                exit 1
            fi
            get_full_image_tag "$2" "${3:-latest}"
            ;;
        
        base-ubuntu)
            get_yaml_value "base_images.ubuntu" "ubuntu:24.04" "$CONFIG_FILE"
            ;;
        
        base-runner)
            get_yaml_value "base_images.runner" "ghcr.io/hutch79/ci-runner-images:base" "$CONFIG_FILE"
            ;;
        
        *)
            echo "Configuration loader utility for CI/CD job runners" >&2
            echo "" >&2
            echo "Usage:" >&2
            echo "  $(basename "$0") get <key.path> [default]" >&2
            echo "  $(basename "$0") registry-path" >&2
            echo "  $(basename "$0") image-name <folder_name>" >&2
            echo "  $(basename "$0") full-tag <folder_name> [tag]" >&2
            echo "  $(basename "$0") base-ubuntu" >&2
            echo "  $(basename "$0") base-runner" >&2
            exit 1
            ;;
    esac
}

main "$@"
