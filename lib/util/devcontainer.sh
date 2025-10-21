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
    # shellcheck source=./helpers.sh
    source "${BITBOT_HOME}/lib/util/helpers.sh"
    BITBOT_HELPERS_LOADED=1
fi

# Source prerequisites for platform detection
if [[ -z "${BITBOT_PREREQUISITES_LOADED:-}" ]]; then
    # shellcheck source=./prerequisites.sh
    source "${BITBOT_HOME}/lib/util/prerequisites.sh"
    BITBOT_PREREQUISITES_LOADED=1
fi

# ============================================================================
# DevContainer Binary Detection
# ============================================================================

get_devcontainer_bin() {
    # Get the appropriate devcontainer binary for this platform
    # Returns: devcontainer command to use

    local platform
    platform=$(detect_platform)

    if [[ "$platform" == "wsl" ]]; then
        # Windows/WSL: Use .cmd wrapper
        echo "devcontainer.cmd"
    else
        # Linux/macOS: Use native binary
        echo "devcontainer"
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
    # Use @devcontainers/cli to launch work container
    local workspace_path="$1"

    local devcontainer_bin
    devcontainer_bin=$(get_devcontainer_bin)

    print_step "Building and starting devcontainer..."

    # Launch using devcontainer CLI
    # The .devcontainer/devcontainer.json should include RO mount:
    # "mounts": ["source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"]

    if ! "$devcontainer_bin" up --workspace-folder "$workspace_path" --remove-existing-container; then
        print_error "Failed to launch devcontainer"
        return 1
    fi

    print_success "Work container launched successfully"

    # Attach to container with tmux
    print_step "Entering devcontainer with tmux session 'work'..."
    "$devcontainer_bin" exec --workspace-folder "$workspace_path" tmux new-session -A -s work
}

launch_work_via_vscode() {
    # Launch VS Code, let devcontainer extension handle container
    local workspace_path="$1"

    print_step "Launching VS Code..."

    # VS Code will detect .devcontainer and launch container automatically
    if command_exists code; then
        code "$workspace_path"
    elif command_exists code.exe; then
        code.exe "$workspace_path"
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

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local workspace_config_devcontainer="${workspace_path}/.bitbot/internal/devcontainer.json"

    # Verify workspace config devcontainer exists (created during init)
    if [[ ! -f "$workspace_config_devcontainer" ]]; then
        print_error "Config devcontainer.json not found in .bitbot/internal/"
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
    local workspace_path="$1"

    local devcontainer_bin
    devcontainer_bin=$(get_devcontainer_bin)

    print_step "Building and starting config devcontainer..."

    # Launch using workspace-specific devcontainer.json in .bitbot/internal/
    if ! "$devcontainer_bin" up \
        --workspace-folder "$workspace_path" \
        --config "${workspace_path}/.bitbot/internal" \
        --remove-existing-container; then
        print_error "Failed to launch config devcontainer"
        return 1
    fi

    print_success "Config devcontainer launched successfully"

    # Attach to container with tmux
    print_step "Entering devcontainer with tmux session 'config'..."
    "$devcontainer_bin" exec \
        --workspace-folder "$workspace_path" \
        --config "${workspace_path}/.bitbot/internal" \
        tmux new-session -A -s config
}

launch_config_via_vscode() {
    # Launch VS Code with config devcontainer
    local workspace_path="$1"

    print_step "Launching VS Code in config mode..."
    print_info "Note: VS Code config mode support is limited in MVP"

    # For MVP, just launch VS Code normally
    # Future: Use devcontainer.json override or specific config
    if command_exists code; then
        code "$workspace_path"
    elif command_exists code.exe; then
        code.exe "$workspace_path"
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
