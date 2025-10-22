#!/bin/bash
# vscode-devcontainer-utils.sh
# Utility functions for launching VS Code into devcontainers
#
# Usage:
#   source vscode-devcontainer-utils.sh
#   open_vscode_devcontainer "C:\Path\To\Workspace"

# Convert path to hex for VS Code URI
path_to_hex() {
    local path="$1"

    # Try xxd first (common on Linux/macOS)
    if command -v xxd &> /dev/null; then
        printf "%s" "$path" | xxd -p -c 256 | tr -d '\n'
    else
        # Fallback: use od (more universal, available in Alpine)
        printf "%s" "$path" | od -A n -t x1 | tr -d ' \n'
    fi
}

# Open VS Code in devcontainer using folder URI
open_vscode_devcontainer() {
    local workspace_path="$1"
    local container_path="${2:-/workspace}"
    local verify="${3:-false}"

    echo "[>] Launching VS Code in devcontainer..."
    echo "    Workspace: $workspace_path"

    # Convert to hex
    local hex_path=$(path_to_hex "$workspace_path")

    if [[ "$verify" == "true" ]]; then
        echo "    Hex: $hex_path"

        # Verify decoding (if xxd available)
        if command -v xxd &> /dev/null; then
            local decoded=$(echo "$hex_path" | xxd -r -p)
            if [[ "$decoded" != "$workspace_path" ]]; then
                echo "    [X] Path encoding verification failed!"
                echo "        Expected: $workspace_path"
                echo "        Got: $decoded"
                return 1
            fi
            echo "    [+] Path encoding verified"
        fi
    fi

    # Build devcontainer URI
    local uri="vscode-remote://dev-container+${hex_path}${container_path}"

    if [[ "$verify" == "true" ]]; then
        echo "    URI: $uri"
    fi

    # Launch VS Code (detect platform)
    if command -v code.exe &> /dev/null; then
        # WSL or Git Bash
        code.exe --folder-uri="$uri"
    elif command -v code &> /dev/null; then
        # Native Linux/macOS
        code --folder-uri="$uri"
    else
        echo "    [X] VS Code 'code' command not found"
        return 1
    fi

    echo "    [+] VS Code launched"
    return 0
}

# Export functions (bash doesn't really export functions from sourced scripts,
# but this documents what's available)
# Functions available after sourcing:
#   - path_to_hex <path>
#   - open_vscode_devcontainer <workspace_path> [container_path] [verify]
