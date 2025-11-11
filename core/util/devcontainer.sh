#!/usr/bin/env bash
#
# BitBot DevContainer Launch Utilities
#
# Component: DevContainer CLI Wrapper
# Purpose: Launch work or config devcontainers with different configurations
#
# Usage: source this file from other scripts
#

# Source helpers (if not already sourced)
if [[ -z "${BITBOT_HELPERS_LOADED:-}" ]]; then
    # shellcheck source=./helpers.sh disable=SC2153
    source "${BITBOT_HOME}/core/util/helpers.sh"
    BITBOT_HELPERS_LOADED=1
fi

# Source prerequisites for platform detection
if [[ -z "${BITBOT_PREREQUISITES_LOADED:-}" ]]; then
    # shellcheck source=./prerequisites.sh
    source "${BITBOT_HOME}/core/util/prerequisites.sh"
    BITBOT_PREREQUISITES_LOADED=1
fi

# ============================================================================
# DevContainer Binary Detection
# ============================================================================

get_devcontainer_bin() {
    # Get the appropriate devcontainer binary for this platform
    # Returns: devcontainer command to use
    #
    # WSL: Uses devcontainer.cmd with Methods 3 & 4 (bash-centric wrappers)
    # - Method 3 (cmd.exe): For /mnt/c/ paths (Windows mounts)
    # - Method 4 (PowerShell): For WSL native paths (better performance)
    # Other platforms: Use native devcontainer CLI

    local platform
    platform=$(detect_platform)

    if [[ "$platform" == "wsl" ]] && command -v devcontainer.cmd &>/dev/null; then
        # WSL with VS Code's devcontainer.cmd available
        echo "devcontainer.cmd"
    else
        # Native devcontainer CLI (macOS, Linux, or WSL without VS Code)
        echo "devcontainer"
    fi
}

# ============================================================================
# DevContainer Command Execution (Methods 3 & 4)
# ============================================================================

run_devcontainer_cmd() {
    # Execute devcontainer command with correct wrapper for path type
    # Usage: run_devcontainer_cmd <workspace_path> <devcontainer_args...>
    #
    # Automatically selects:
    # - Method 3 (cmd.exe): For /mnt/c/ paths -> C:\ labels
    # - Method 4 (PowerShell): For WSL native paths -> \\wsl.localhost labels
    # - Direct execution: For non-WSL platforms

    local workspace_path="$1"
    shift  # Remove workspace_path, rest are devcontainer arguments

    local devcontainer_bin
    devcontainer_bin=$(get_devcontainer_bin)

    local platform
    platform=$(detect_platform)

    if [[ "$platform" == "wsl" ]] && [[ "$devcontainer_bin" == "devcontainer.cmd" ]]; then
        # WSL with devcontainer.cmd - use Methods 3 & 4
        local win_path
        win_path=$(convert_wsl_to_windows_path "$workspace_path")

        # Build command arguments string for shell execution
        local args=""
        for arg in "$@"; do
            # Escape quotes and spaces for shell
            arg="${arg//\"/\\\"}"
            args="$args \"$arg\""
        done

        if [[ "$workspace_path" == /mnt/* ]]; then
            # Method 3: cmd.exe wrapper for Windows mounts
            # Use cd trick to avoid UNC path limitations
            cmd.exe /c "cd /d \"$win_path\" && devcontainer.cmd --workspace-folder . $args"
        else
            # Method 4: PowerShell wrapper for WSL native paths
            powershell.exe -NoProfile -Command "devcontainer.cmd --workspace-folder '$win_path' $args"
        fi
    else
        # Native devcontainer CLI (direct execution)
        "$devcontainer_bin" --workspace-folder "$workspace_path" "$@"
    fi
}

# ============================================================================
# Mode Detection
# ============================================================================

detect_current_mode() {
    # Detect current mode from environment or container name
    # Returns: "work" | "config" | ""

    # Check environment variable (inside container)
    if [[ -n "${BITBOT_MODE:-}" ]]; then
        echo "$BITBOT_MODE"
        return 0
    fi

    # Check from container name (on host)
    local hostname
    hostname=$(hostname 2>/dev/null || echo "")

    if [[ "$hostname" == *"bitbot-work"* ]]; then
        echo "work"
    elif [[ "$hostname" == *"bitbot-config"* ]]; then
        echo "config"
    else
        echo ""
    fi
}

# ============================================================================
# Launch Work Devcontainer
# ============================================================================

launch_work_devcontainer() {
    # Launch workspace's devcontainer with RO .devcontainer mount
    local workspace_path="$1"
    local use_vscode="${2:-false}"

    local devcontainer_path="${workspace_path}/.devcontainer"

    if [[ ! -d "$devcontainer_path" ]]; then
        print_error "No .devcontainer found. Run 'bitbot init' first."
        return 4
    fi

    print_step "Launching work mode..."

    if [[ "$use_vscode" == "true" ]]; then
        launch_work_via_vscode "$workspace_path"
    else
        launch_work_via_devcontainer_cli "$workspace_path"
    fi
}

launch_work_via_devcontainer_cli() {
    # Use devcontainer CLI to launch work container
    # Automatically uses Methods 3 & 4 on WSL for correct path labels
    local workspace_path="$1"

    print_step "Building and starting devcontainer..."

    # Launch using devcontainer CLI with correct wrapper
    # The .devcontainer/devcontainer.json should include RO mount:
    # "mounts": ["source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"]

    if ! run_devcontainer_cmd "$workspace_path" up --remove-existing-container; then
        print_error "Failed to launch devcontainer"
        return 1
    fi

    print_success "Work container launched successfully"

    # Attach to container with tmux
    print_step "Entering devcontainer with tmux session 'work'..."
    run_devcontainer_cmd "$workspace_path" exec tmux new-session -A -s work
}

launch_work_via_vscode() {
    # Launch VS Code, let devcontainer extension handle container
    local workspace_path="$1"
    local platform
    platform=$(detect_platform)

    print_step "Launching VS Code..."

    # VS Code will detect .devcontainer and launch container automatically
    if command_exists code; then
        code "$workspace_path"
    elif command_exists code.exe; then
        # On WSL, convert path to Windows format for code.exe
        if [[ "$platform" == "wsl" ]]; then
            local windows_path
            windows_path=$(convert_wsl_to_windows_path "$workspace_path")
            code.exe "$windows_path"
        else
            code.exe "$workspace_path"
        fi
    else
        print_error "VS Code 'code' command not found"
        return 1
    fi

    print_success "VS Code launched"
}

# ============================================================================
# Launch Config Devcontainer
# ============================================================================

launch_config_devcontainer() {
    # Launch config devcontainer for workspace
    local workspace_path="$1"
    local use_vscode="${2:-false}"

    local workspace_config_devcontainer="${workspace_path}/.bitbot/internal/.devcontainer/devcontainer.json"

    # Verify workspace config devcontainer exists (created during init)
    if [[ ! -f "$workspace_config_devcontainer" ]]; then
        print_error "Config devcontainer.json not found in .bitbot/internal/.devcontainer/"
        echo "This should have been created during 'bitbot init'"
        echo "Try re-initializing: bitbot init"
        return 1
    fi

    print_step "Launching config mode..."

    if [[ "$use_vscode" == "true" ]]; then
        launch_config_via_vscode "$workspace_path"
    else
        launch_config_via_devcontainer_cli "$workspace_path"
    fi
}

launch_config_via_devcontainer_cli() {
    # Launch config devcontainer using workspace-specific config
    # Automatically uses Methods 3 & 4 on WSL for correct path labels
    local workspace_path="$1"
    local config_dir="${workspace_path}/.bitbot/internal/.devcontainer"
    local config_file="${config_dir}/devcontainer.json"
    local config_dir_relative=".bitbot/internal/.devcontainer"  # Relative to workspace

    print_step "Building and starting config devcontainer..."

    # Debug: Show what config we're using
    print_info "Config directory: $config_dir"
    print_info "Config directory (relative): $config_dir_relative"

    # Verify config file exists
    if [[ ! -f "$config_file" ]]; then
        print_error "Config devcontainer.json not found: $config_file"
        echo "Directory contents:"
        ls -la "$config_dir" 2>&1 || echo "  (directory doesn't exist)"
        return 1
    fi

    print_info "Using config file: $config_file"

    # Validate config file
    local file_size
    file_size=$(stat -c%s "$config_file" 2>/dev/null || stat -f%z "$config_file" 2>/dev/null || echo "0")

    if [[ "$file_size" -eq 0 ]]; then
        print_error "Config file is empty!"
        return 1
    fi

    # Check JSON validity
    if command -v jq &>/dev/null; then
        if ! jq empty "$config_file" 2>/dev/null; then
            print_error "Config file has invalid JSON syntax"
            echo "File contents:"
            head -20 "$config_file"
            return 1
        fi
    fi

    print_info "Config file validated (size: $file_size bytes)"

    # Launch using workspace-specific devcontainer.json in .bitbot/internal/
    # Use relative path from workspace folder
    if ! run_devcontainer_cmd "$workspace_path" up \
        --config "$config_dir_relative" \
        --remove-existing-container; then
        print_error "Failed to launch config devcontainer"
        echo ""
        echo "Debug information:"
        echo "  Workspace: $workspace_path"
        echo "  Config dir (absolute): $config_dir"
        echo "  Config dir (relative): $config_dir_relative"
        echo "  Config file: $config_file"
        echo "  File exists: $(test -f "$config_file" && echo "yes" || echo "no")"
        echo "  File size: $file_size bytes"
        echo "  File permissions: $(stat -c '%A' "$config_file" 2>/dev/null || stat -f '%Sp' "$config_file" 2>/dev/null)"
        echo ""
        echo "Directory listing:"
        ls -la "$config_dir"
        echo ""
        echo "File contents (first 30 lines):"
        head -30 "$config_file"
        return 1
    fi

    print_success "Config devcontainer launched successfully"

    # Attach to container with tmux
    print_step "Entering devcontainer with tmux session 'config'..."
    run_devcontainer_cmd "$workspace_path" exec \
        --config "$config_dir_relative" \
        tmux new-session -A -s config
}

launch_config_via_vscode() {
    # Launch VS Code with config devcontainer
    local workspace_path="$1"
    local platform
    platform=$(detect_platform)

    print_step "Launching VS Code in config mode..."
    print_info "Note: VS Code config mode support is limited in MVP"

    # For MVP, just launch VS Code normally
    # Future: Use devcontainer.json override or specific config
    if command_exists code; then
        code "$workspace_path"
    elif command_exists code.exe; then
        # On WSL, convert path to Windows format for code.exe
        if [[ "$platform" == "wsl" ]]; then
            local windows_path
            windows_path=$(convert_wsl_to_windows_path "$workspace_path")
            code.exe "$windows_path"
        else
            code.exe "$workspace_path"
        fi
    else
        print_error "VS Code 'code' command not found"
        return 1
    fi

    print_success "VS Code launched"
    print_info "You may need to manually select config devcontainer"
}

# ============================================================================
# Git Safety Checks (wrapper)
# ============================================================================

check_git_uncommitted() {
    # Check for uncommitted changes (non-blocking warning)
    local workspace_path="$1"

    if ! command_exists git; then
        return 1  # No git repo
    fi

    if [[ ! -d "${workspace_path}/.git" ]]; then
        return 1  # No git repo
    fi

    # Check for uncommitted changes
    if ! git -C "$workspace_path" diff-index --quiet HEAD -- 2>/dev/null; then
        return 0  # Has uncommitted changes
    fi

    return 1  # Clean
}

count_uncommitted_files() {
    # Count uncommitted files for user feedback
    local workspace_path="${1:-.}"

    if ! command_exists git; then
        echo "0"
        return
    fi

    local count
    count=$(git -C "$workspace_path" status --porcelain 2>/dev/null | wc -l)
    echo "$count"
}
