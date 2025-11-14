#!/usr/bin/env bash
#
# VS Code Helper Functions
# Provides utilities for checking VS Code state, processes, and DevContainers
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/helpers/vscode-helper.sh"
#   vscode_is_running
#   vscode_get_workspace_hash "/path/to/workspace"
#   vscode_devcontainer_is_open "/path/to/workspace"
#

# ============================================================================
# VS Code Process Checking
# ============================================================================

# Check if VS Code is running
# Returns: 0 if running, 1 if not
vscode_is_running() {
    if command -v powershell.exe &>/dev/null; then
        # On WSL, use PowerShell to check Windows processes
        powershell.exe -NoProfile -Command "Get-Process Code -ErrorAction SilentlyContinue" &>/dev/null
        return $?
    else
        # On Linux, check local processes
        pgrep -x "code" &>/dev/null || pgrep -x "Code" &>/dev/null
        return $?
    fi
}

# Get VS Code process count
# Returns: Number of VS Code processes running
vscode_process_count() {
    if command -v powershell.exe &>/dev/null; then
        powershell.exe -NoProfile -Command "(Get-Process Code -ErrorAction SilentlyContinue).Count" 2>/dev/null | tr -d '\r'
    else
        pgrep -c "code" 2>/dev/null || echo "0"
    fi
}

# Wait for VS Code to start
# Usage: vscode_wait_for_start [timeout_seconds]
vscode_wait_for_start() {
    local timeout="${1:-30}"
    local elapsed=0

    while ! vscode_is_running; do
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    return 0
}

# ============================================================================
# VS Code Storage and State
# ============================================================================

# Get VS Code user data directory
# Returns: Path to VS Code user data directory
vscode_get_user_data_dir() {
    if [[ -n "${VSCODE_PORTABLE:-}" ]]; then
        echo "$VSCODE_PORTABLE/user-data"
    elif grep -qi microsoft /proc/version 2>/dev/null && command -v powershell.exe &>/dev/null; then
        # On WSL, VS Code data is stored in Windows
        local win_appdata
        win_appdata=$(powershell.exe -NoProfile -Command "Write-Host \$env:APPDATA" 2>/dev/null | tr -d '\r')
        if [[ -n "$win_appdata" ]]; then
            local wsl_path
            wsl_path=$(wslpath "$win_appdata/Code" 2>/dev/null)
            if [[ -d "$wsl_path" ]]; then
                echo "$wsl_path"
                return 0
            fi
        fi
        return 1
    elif [[ "$(uname -s)" == "Linux" ]] || [[ "$(uname -s)" =~ MINGW|MSYS|CYGWIN ]]; then
        if [[ -d "$HOME/.config/Code" ]]; then
            echo "$HOME/.config/Code"
        elif [[ -d "$HOME/.vscode" ]]; then
            echo "$HOME/.vscode"
        fi
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        echo "$HOME/Library/Application Support/Code"
    fi
}

# Get workspace storage directory
# Returns: Path to workspace storage directory
vscode_get_workspace_storage_dir() {
    local user_data_dir
    user_data_dir="$(vscode_get_user_data_dir)"

    if [[ -n "$user_data_dir" ]] && [[ -d "$user_data_dir/User/workspaceStorage" ]]; then
        echo "$user_data_dir/User/workspaceStorage"
    fi
}

# Get workspace hash for a given workspace path
# Usage: vscode_get_workspace_hash "/path/to/workspace"
# Returns: Workspace hash (directory name in workspaceStorage)
vscode_get_workspace_hash() {
    local workspace_path="$1"
    local storage_dir
    storage_dir="$(vscode_get_workspace_storage_dir)"

    if [[ -z "$storage_dir" ]] || [[ ! -d "$storage_dir" ]]; then
        return 1
    fi

    # Find workspace.json files containing the workspace path
    local hash
    hash=$(find "$storage_dir" -name "workspace.json" -type f -exec grep -l "\"folder\":\"file://$workspace_path\"" {} \; 2>/dev/null | head -1 | xargs dirname | xargs basename)

    if [[ -n "$hash" ]]; then
        echo "$hash"
        return 0
    fi

    return 1
}

# Check if workspace state database exists
# Usage: vscode_workspace_state_exists "/path/to/workspace"
vscode_workspace_state_exists() {
    local workspace_path="$1"
    local hash
    hash="$(vscode_get_workspace_hash "$workspace_path")"

    if [[ -z "$hash" ]]; then
        return 1
    fi

    local storage_dir
    storage_dir="$(vscode_get_workspace_storage_dir)"
    local state_db="$storage_dir/$hash/state.vscdb"

    [[ -f "$state_db" ]]
}

# ============================================================================
# DevContainer Checking
# ============================================================================

# Check if a DevContainer is running for a workspace
# Usage: vscode_devcontainer_is_running "/path/to/workspace"
vscode_devcontainer_is_running() {
    local workspace_path="$1"

    if ! command -v docker &>/dev/null; then
        return 1
    fi

    # Check for containers with VS Code remote labels
    docker ps --filter="label=vsch.quality" --format="{{.Labels}}" 2>/dev/null | grep -q "devcontainer.local_folder" && return 0

    # Check for containers matching workspace path (if provided)
    if [[ -n "$workspace_path" ]]; then
        # Convert to WSL path if needed
        local search_path="$workspace_path"
        if [[ "$workspace_path" =~ ^/mnt/[a-z]/ ]]; then
            search_path="$workspace_path"
        fi

        docker ps --filter="label=vsch.quality" --format="{{.Label \"devcontainer.local_folder\"}}" 2>/dev/null | grep -qF "$search_path" && return 0
    fi

    return 1
}

# Get list of running DevContainers
# Returns: List of container IDs
vscode_list_devcontainers() {
    if ! command -v docker &>/dev/null; then
        return 1
    fi

    docker ps --filter="label=vsch.quality" --format="{{.ID}}" 2>/dev/null
}

# Get DevContainer info for workspace
# Usage: vscode_get_devcontainer_info "/path/to/workspace"
# Returns: Container ID if found
vscode_get_devcontainer_info() {
    local workspace_path="$1"

    if ! command -v docker &>/dev/null; then
        return 1
    fi

    # Find container with matching workspace path
    local container_id
    container_id=$(docker ps --filter="label=vsch.quality" --format="{{.ID}}\t{{.Label \"devcontainer.local_folder\"}}" 2>/dev/null | grep "$workspace_path" | cut -f1)

    if [[ -n "$container_id" ]]; then
        echo "$container_id"
        return 0
    fi

    return 1
}

# ============================================================================
# VS Code CLI Commands
# ============================================================================

# Execute VS Code with status command
# Returns: VS Code status output
vscode_get_status() {
    if command -v code &>/dev/null; then
        code --status 2>/dev/null
        return $?
    fi

    return 1
}

# Check if VS Code CLI is available
vscode_cli_available() {
    command -v code &>/dev/null
}

# ============================================================================
# Workspace Opening
# ============================================================================

# Open workspace in VS Code (non-blocking)
# Usage: vscode_open_workspace "/path/to/workspace"
vscode_open_workspace() {
    local workspace_path="$1"

    if ! vscode_cli_available; then
        return 1
    fi

    # Open workspace (non-blocking)
    code "$workspace_path" &>/dev/null &

    return 0
}

# Open workspace in DevContainer
# Usage: vscode_open_devcontainer "/path/to/workspace"
vscode_open_devcontainer() {
    local workspace_path="$1"

    if ! vscode_cli_available; then
        return 1
    fi

    # Open in container using remote-containers extension
    code --folder-uri "vscode-remote://dev-container+${workspace_path}" &>/dev/null &

    return 0
}

# ============================================================================
# Wait Functions
# ============================================================================

# Wait for DevContainer to be ready
# Usage: vscode_wait_for_devcontainer "/path/to/workspace" [timeout_seconds]
vscode_wait_for_devcontainer() {
    local workspace_path="$1"
    local timeout="${2:-120}"
    local elapsed=0

    while ! vscode_devcontainer_is_running "$workspace_path"; do
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    # Give it a few more seconds to fully initialize
    sleep 3

    return 0
}

# Export functions
export -f vscode_is_running
export -f vscode_process_count
export -f vscode_wait_for_start
export -f vscode_get_user_data_dir
export -f vscode_get_workspace_storage_dir
export -f vscode_get_workspace_hash
export -f vscode_workspace_state_exists
export -f vscode_devcontainer_is_running
export -f vscode_list_devcontainers
export -f vscode_get_devcontainer_info
export -f vscode_get_status
export -f vscode_cli_available
export -f vscode_open_workspace
export -f vscode_open_devcontainer
export -f vscode_wait_for_devcontainer
