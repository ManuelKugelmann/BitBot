#!/bin/bash
# bitbot-core.sh - Cross-platform BitBot core logic

set -e

# Detect platform
detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

# Get Windows username for WSL paths
get_windows_user() {
    # Try to get from environment or fallback
    if [[ -n "$WSLUSER" ]]; then
        echo "$WSLUSER"
    else
        # Extract from /mnt/c/Users/ (only directories, not files like desktop.ini)
        local user=$(ls -d /mnt/c/Users/*/ 2>/dev/null | sed 's|/mnt/c/Users/||g' | sed 's|/||g' | grep -v "Public\|Default\|All Users" | head -n1)
        echo "$user"
    fi
}

# Get VS Code's devcontainer CLI path (all platforms)
get_devcontainer_cli() {
    local platform=$(detect_platform)

    case "$platform" in
        wsl)
            # Use VS Code's bundled Windows CLI via interop
            local winuser=$(get_windows_user)
            local vscode_cli="/mnt/c/Users/$winuser/AppData/Roaming/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer.cmd"

            if [[ -f "$vscode_cli" ]]; then
                echo "$vscode_cli"
            else
                echo "ERROR: VS Code devcontainer CLI not found" >&2
                echo "Expected: $vscode_cli" >&2
                echo "Install VS Code and Dev Containers extension" >&2
                return 1
            fi
            ;;

        macos)
            # Use VS Code's bundled macOS CLI
            # TODO: Verify exact path on macOS
            local vscode_cli="$HOME/Library/Application Support/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer"

            if [[ -f "$vscode_cli" ]]; then
                echo "$vscode_cli"
            else
                echo "ERROR: VS Code devcontainer CLI not found" >&2
                echo "Expected: $vscode_cli" >&2
                echo "Install VS Code and Dev Containers extension" >&2
                return 1
            fi
            ;;

        linux)
            # Use VS Code's bundled Linux CLI
            # TODO: Verify exact path on Linux
            local vscode_cli="$HOME/.vscode/extensions/ms-vscode-remote.remote-containers-*/dev-containers-user-cli/cli"

            # Expand glob
            vscode_cli=$(echo $vscode_cli)

            if [[ -f "$vscode_cli" ]]; then
                echo "$vscode_cli"
            else
                echo "ERROR: VS Code devcontainer CLI not found" >&2
                echo "Expected: $vscode_cli" >&2
                echo "Install VS Code and Dev Containers extension" >&2
                echo "" >&2
                echo "TODO: Later support standalone @devcontainers/cli" >&2
                return 1
            fi
            ;;
    esac
}

# Convert path based on platform
convert_workspace_path() {
    local input_path="$1"
    local platform=$(detect_platform)

    case "$platform" in
        wsl)
            # If Windows path (C:\...), convert to WSL path
            if [[ "$input_path" =~ ^[A-Za-z]:\\ ]]; then
                wslpath "$input_path"
            else
                echo "$input_path"
            fi
            ;;
        *)
            # Native paths, no conversion needed
            echo "$input_path"
            ;;
    esac
}

# Convert path to hex for VS Code dev container URI
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

# Main BitBot command
bitbot_vscode() {
    local workspace_path=$(convert_workspace_path "$1")
    local platform=$(detect_platform)

    echo "[BitBot] Platform: $platform"
    echo "[BitBot] Workspace: $workspace_path"
    echo "[BitBot] Opening VS Code directly in dev container..."
    echo ""

    # Open VS Code (platform-specific with dev container URI)
    case "$platform" in
        wsl)
            # Convert to Windows path
            local windows_workspace=$(wslpath -w "$workspace_path")
            # Convert to hex for URI
            local hex_path=$(path_to_hex "$windows_workspace")
            local container_path="/workspace"
            local uri="vscode-remote://dev-container+${hex_path}${container_path}"

            echo "[BitBot] URI: $uri"

            # Use Windows VS Code via interop
            if command -v code.exe &> /dev/null; then
                code.exe --folder-uri="$uri"
            else
                # Fallback: common VS Code installation paths
                /mnt/c/Program\ Files/Microsoft\ VS\ Code/Code.exe --folder-uri="$uri" 2>/dev/null || \
                /mnt/c/Users/$(get_windows_user)/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe --folder-uri="$uri"
            fi
            ;;
        *)
            # Native VS Code (macOS/Linux)
            local hex_path=$(path_to_hex "$workspace_path")
            local uri="vscode-remote://dev-container+${hex_path}/workspace"
            code --folder-uri="$uri"
            ;;
    esac

    echo ""
    echo "============================================"
    echo " BitBot: VS Code Opening in Dev Container"
    echo "============================================"
    echo ""
    echo "VS Code will open directly in the container!"
    echo "No 'Reopen in Container' popup needed!"
    echo ""
}

# Entry point
case "$1" in
    vscode)
        bitbot_vscode "$2"
        ;;
    *)
        echo "Usage: $0 {vscode} <workspace-path>"
        exit 1
        ;;
esac
