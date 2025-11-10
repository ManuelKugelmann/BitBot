#!/usr/bin/env bash
#
# BitBot Global Initialization
#
# Component: Global BitBot Setup
# Purpose: First-time BitBot installation setup
#
# This script handles:
# - Global initialization detection
# - Prerequisites checking
# - PATH setup
# - BITBOT_HOME environment variable
# - config.json creation in install folder
#

set -euo pipefail

# Source utilities
# shellcheck source=../util/helpers.sh
source "${BITBOT_HOME}/core/util/helpers.sh"
# shellcheck source=../util/prerequisites.sh
source "${BITBOT_HOME}/core/util/prerequisites.sh"
# shellcheck source=../util/logo.sh
source "${BITBOT_HOME}/core/util/logo.sh"

# ============================================================================
# Global Init Detection
# ============================================================================

is_global_init_needed() {
    # Check if global initialization is needed
    # Returns: 0 if needed, 1 if already initialized

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local config_file="${bitbot_install}/config.json"

    if [[ ! -f "$config_file" ]]; then
        return 0  # No config → need global init
    fi

    return 1  # Config exists → already initialized
}

# ============================================================================
# Global Environment Validation
# ============================================================================

validate_global_environment() {
    # Validate PATH and BITBOT_HOME are set correctly
    # Handles portable installation - detects if folder was moved
    # Returns: 0 if OK, 1 if not configured

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local path_ok=false
    local env_ok=false
    local moved=false

    # Check if BitBot is in PATH
    local bitbot_in_path
    bitbot_in_path=$(command -v bitbot 2>/dev/null || echo "")
    if [[ -n "$bitbot_in_path" ]]; then
        # Resolve symlinks
        local resolved_path
        resolved_path=$(readlink -f "$bitbot_in_path" 2>/dev/null || realpath "$bitbot_in_path" 2>/dev/null || echo "$bitbot_in_path")
        local expected_path="${bitbot_install}/bitbot"

        if [[ "$resolved_path" == "$expected_path" ]]; then
            path_ok=true
        fi
    fi

    # Check BITBOT_HOME environment variable
    local bitbot_home_env="${BITBOT_HOME:-}"
    if [[ "$bitbot_home_env" == "$bitbot_install" ]]; then
        env_ok=true
    elif [[ -n "$bitbot_home_env" ]] && [[ "$bitbot_home_env" != "$bitbot_install" ]]; then
        # Installation was moved!
        moved=true
    fi

    # If both OK, return success
    if [[ "$path_ok" == "true" ]] && [[ "$env_ok" == "true" ]]; then
        return 0
    fi

    # Something is wrong - offer to fix
    echo ""

    if [[ "$moved" == "true" ]]; then
        print_warning "BitBot installation moved:"
        echo "    Was: $bitbot_home_env"
        echo "    Now: $bitbot_install"
        echo ""
    else
        print_warning "BitBot environment not configured correctly:"
        echo ""
    fi

    if [[ "$path_ok" != "true" ]]; then
        echo "  ✗ BitBot not in PATH (or wrong installation)"
    fi

    if [[ "$env_ok" != "true" ]]; then
        if [[ -z "$bitbot_home_env" ]]; then
            echo "  ✗ BITBOT_HOME not set"
        else
            echo "  ✗ BITBOT_HOME points to: $bitbot_home_env"
            echo "    Current location: $bitbot_install"
        fi
    fi

    echo ""
    local should_fix
    should_fix=$(prompt_yes_no "Update shell configuration now?" "yes")

    if [[ "$should_fix" == "yes" ]]; then
        add_to_path
        echo ""
        print_info "Please reload your shell: source ~/.bashrc (or ~/.zshrc)"
        echo ""
        return 0
    else
        echo ""
        print_warning "Environment not updated. Some commands may not work correctly."
        echo ""
        return 1
    fi
}

# ============================================================================
# Main Global Init (First-Run)
# ============================================================================

run_global_init() {
    # First-time setup
    # Creates config.json, sets up PATH/env

    show_welcome_banner

    # Step 1: Prerequisites check
    echo ""
    echo "[1/3] Checking prerequisites..."
    echo ""

    check_prerequisites_for_init

    # Step 2: Create config.json
    echo ""
    echo "[2/3] Creating configuration..."
    echo ""

    create_global_config

    # Step 3: Add to PATH
    echo ""
    echo "[3/3] Adding BitBot to PATH..."
    echo ""

    add_to_path

    # Done
    echo ""
    print_success "Global BitBot setup complete!"
    echo ""
    echo "Reload your shell to use 'bitbot' from anywhere:"
    echo "  \$ source ~/.bashrc  (or ~/.zshrc)"
    echo ""
    echo "Then initialize a workspace:"
    echo "  \$ cd ~/my-project"
    echo "  \$ bitbot init"
    echo ""
}

# ============================================================================
# Welcome Banner
# ============================================================================

show_welcome_banner() {
    # Display logo with version
    print_logo "${BITBOT_HOME}"

    echo "  ${GREY}Secure Development Environment for AI-Assisted Coding${RESET}"
    echo ""
    echo "  This is your first run. Let's set up BitBot..."
    echo ""
}

# ============================================================================
# Prerequisites Check (for init)
# ============================================================================

check_prerequisites_for_init() {
    # Check prerequisites for global init
    # Shows status but doesn't block (Docker optional for init)

    # Docker
    echo "Checking Docker..."
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null | head -n 1)
        echo "  ✓ $docker_version"

        if docker ps &>/dev/null; then
            echo "  ✓ Docker is running"
        else
            echo "  ℹ Docker is not running (can start later)"
        fi
    else
        echo "  ℹ Docker not installed (install before using 'bitbot work')"
        echo "    https://www.docker.com/products/docker-desktop"
    fi

    echo ""

    # Docker Compose
    echo "Checking Docker Compose..."
    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version 2>/dev/null)
        echo "  ✓ $compose_version"
    else
        echo "  ℹ Docker Compose v2 not found (usually bundled with Docker Desktop)"
    fi

    echo ""

    # DevContainer CLI
    echo "Checking DevContainer CLI..."
    local cli_status
    cli_status=$(check_devcontainer_cli)
    case "$cli_status" in
        builtin)
            echo "  ✓ DevContainer CLI (VS Code builtin)"
            ;;
        standalone)
            echo "  ✓ DevContainer CLI (standalone)"
            ;;
        vscode-only)
            echo "  ℹ VS Code found, but Dev Containers extension missing"
            echo "    Install: ms-vscode-remote.remote-containers"
            ;;
        none)
            echo "  ℹ DevContainer CLI not found (install before using 'bitbot work')"
            echo "    Option 1: VS Code + Dev Containers extension"
            echo "    Option 2: npm install -g @devcontainers/cli"
            ;;
    esac

    echo ""

    # Git (optional)
    echo "Checking Git..."
    if command_exists git; then
        local git_version
        git_version=$(git --version 2>/dev/null)
        echo "  ✓ $git_version"
    else
        echo "  ℹ Git not installed (optional, recommended)"
    fi

    echo ""
    print_success "All prerequisites checked"
}

# ============================================================================
# Config Creation
# ============================================================================

create_global_config() {
    # Create config.json in BitBot install folder

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local config_file="${bitbot_install}/config.json"

    # Check if VS Code is installed
    local has_vscode=false
    if command_exists code || command_exists code.exe; then
        has_vscode=true
    fi

    local default_mode="terminal"

    if [[ "$has_vscode" == "true" ]]; then
        # VS Code installed - offer choice
        echo "Choose default launch mode for BitBot workspaces:"
        echo "  • Terminal: Faster, lightweight, tmux-based (good for servers, CLI workflows)"
        echo "  • VS Code: Full IDE experience with GUI (good for local development)"
        echo ""

        local choice
        choice=$(prompt_choice "Select default launch mode:" 1 "Terminal" "VS Code")
        echo ""

        if [[ $choice -eq 1 ]]; then
            default_mode="vscode"
        else
            default_mode="terminal"
        fi
    else
        # No VS Code
        print_info "VS Code not detected on this system"
        echo "    Default launch mode will be set to: Terminal"
        echo ""
        echo "    To use VS Code integration later:"
        echo "      1. Install VS Code: https://code.visualstudio.com/"
        echo "      2. Edit ${bitbot_install}/config.json"
        echo "      3. Set \"launch_mode\": \"vscode\""
        echo ""
        default_mode="terminal"
    fi

    # Create config.json
    local timestamp
    timestamp=$(current_timestamp)

    create_config_json "$config_file" \
        "version" "0.1.0" \
        "launch_mode" "$default_mode" \
        "created_at" "$timestamp"

    print_success "Created config.json"
    echo "  ✓ Default mode: $default_mode"
}

# ============================================================================
# PATH Setup
# ============================================================================

add_to_path() {
    # Add BitBot to PATH and set BITBOT_HOME

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)

    echo "BitBot install location: $bitbot_install"
    echo ""

    # Detect shell
    local shell_name="bash"
    if [[ -n "${SHELL:-}" ]]; then
        shell_name=$(basename "$SHELL")
    fi

    local platform
    platform=$(detect_platform)

    echo "Detected shell: $shell_name"
    echo "Detected platform: $platform"

    # Determine shell config file
    local shell_config
    case "$shell_name" in
        zsh)
            shell_config="$HOME/.zshrc"
            echo "Shell config: ~/.zshrc"
            ;;
        *)
            shell_config="$HOME/.bashrc"
            echo "Shell config: ~/.bashrc"
            ;;
    esac

    echo ""
    local should_add
    should_add=$(prompt_yes_no "Add BitBot to your PATH?" "yes")

    if [[ "$should_add" != "yes" ]]; then
        echo ""
        echo "Skipped PATH addition."
        echo ""
        echo "To use BitBot, run from the install directory:"
        echo "  ${bitbot_install}/core/bitbot"
        echo ""
        echo "Or add to PATH manually:"
        echo "  export PATH=\"\$PATH:${bitbot_install}/core\""
        echo "  export BITBOT_HOME=\"${bitbot_install}\""
        return 0
    fi

    # Remove old BitBot entries (if any)
    if [[ -f "$shell_config" ]]; then
        # Create backup
        cp "$shell_config" "${shell_config}.bitbot.bak"

        # Remove old entries
        sed -i '/# BitBot PATH/d' "$shell_config"
        sed -i '/BITBOT_HOME/d' "$shell_config"
        sed -i '/bitbot/d' "$shell_config"
    fi

    # Add new entries
    {
        echo ""
        echo "# BitBot PATH"
        echo "export PATH=\"${bitbot_install}/core:\$PATH\""
        echo "export BITBOT_HOME=\"${bitbot_install}\""
    } >> "$shell_config"

    print_success "Added to $shell_config"

    # WSL: Also update Windows environment
    if [[ "$platform" == "wsl" ]]; then
        update_windows_environment "$bitbot_install"
    fi

    echo ""
    print_info "Restart your shell or run: source $shell_config"
}

update_windows_environment() {
    # Update Windows environment variables (WSL only)
    local bitbot_install="$1"

    echo ""
    print_step "Updating Windows environment variables..."

    # Convert WSL path to Windows path
    local windows_path
    if command_exists wslpath; then
        windows_path=$(wslpath -w "$bitbot_install")
    else
        # Fallback: Use bash parameter expansion instead of sed (SC2001)
        if [[ "$bitbot_install" =~ ^/mnt/([a-z])/(.*)$ ]]; then
            local drive="${BASH_REMATCH[1]}"
            local path="${BASH_REMATCH[2]}"
            windows_path="${drive^^}:/${path}"
        else
            # Fallback to sed if regex doesn't match
            windows_path=$(printf '%s' "$bitbot_install" | sed 's|^/mnt/\([a-z]\)/|\U\1:/|')
        fi
    fi

    # Try to update via PowerShell
    # Use proper parameter passing to avoid injection
    # Escape single quotes in the path for PowerShell
    local escaped_windows_path
    escaped_windows_path=$(printf '%s' "$windows_path" | sed "s/'/''/g")

    if powershell.exe -Command "[Environment]::SetEnvironmentVariable('BITBOT_HOME', '$escaped_windows_path', 'User')" 2>/dev/null; then
        print_success "Set BITBOT_HOME in Windows: $windows_path"

        # Update PATH with proper escaping
        if powershell.exe -Command "\$path = [Environment]::GetEnvironmentVariable('Path', 'User'); \$bitbot = '$escaped_windows_path'; if (\$path -notlike ('*' + \$bitbot + '*')) { [Environment]::SetEnvironmentVariable('Path', \$bitbot + ';' + \$path, 'User') }" 2>/dev/null; then
            print_success "Updated Windows PATH"
        fi
    else
        # PowerShell not accessible
        print_warning "Cannot access PowerShell from WSL"
        echo ""
        echo "Manual Windows setup required (run in PowerShell as Admin):"
        echo "  [Environment]::SetEnvironmentVariable('BITBOT_HOME', '$escaped_windows_path', 'User')"
        echo "  \$path = [Environment]::GetEnvironmentVariable('Path', 'User')"
        echo "  [Environment]::SetEnvironmentVariable('Path', '$escaped_windows_path;' + \$path, 'User')"
    fi
}

# Export functions for use by main script
export -f is_global_init_needed
export -f validate_global_environment
export -f run_global_init
