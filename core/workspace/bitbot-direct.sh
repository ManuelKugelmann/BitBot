#!/usr/bin/env bash
#
# BitBot Direct Mode
#
# Component: Direct Mode (Containerless)
# Purpose: Launch AI assistant directly on host without containers
#
# This mode runs the container-bitbot scripts directly on the host,
# providing a lightweight alternative that doesn't require Docker.
#

set -euo pipefail

# Source utilities
# shellcheck source=../util/helpers.sh
source "${BITBOT_HOME}/core/util/helpers.sh"

# ============================================================================
# Direct Mode
# ============================================================================

bitbot_direct() {
    # Launch BitBot in direct mode (no containers)
    # Runs container-bitbot scripts directly on host
    # Usage: bitbot_direct <workspace_path>
    local workspace_path="$1"

    echo ""
    print_info "BitBot Direct Mode (Containerless)"
    echo ""
    echo "Running AI assistant directly on host without containers."
    echo "Workspace: $workspace_path"
    echo ""

    # Check if container/bitbot scripts exist
    local container_bitbot_dir="${BITBOT_HOME}/container/bitbot"
    if [[ ! -d "$container_bitbot_dir" ]]; then
        print_error "container/bitbot directory not found"
        echo "Expected location: $container_bitbot_dir"
        return 1
    fi

    if [[ ! -f "${container_bitbot_dir}/bitbot" ]]; then
        print_error "container/bitbot/bitbot script not found"
        return 1
    fi

    # Set environment variables for container/bitbot scripts
    export WORKSPACE="$workspace_path"
    export BITBOT_CONTAINER_HOME="$container_bitbot_dir"

    # Check if Claude Code is available
    if ! command_exists claude; then
        print_warning "Claude Code not found in PATH"
        echo ""
        echo "Direct mode requires Claude Code to be installed on the host."
        echo ""
        echo "Install Claude Code:"
        echo "  npm install -g @anthropic-ai/claude-code"
        echo ""

        local choice
        choice=$(prompt_yes_no "Continue anyway?" "no")
        if [[ "$choice" != "yes" ]]; then
            echo "Cancelled."
            return 1
        fi
        echo ""
    fi

    # Display direct mode info
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Direct Mode Active"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Benefits:"
    echo "  ✓ No Docker required"
    echo "  ✓ Faster startup"
    echo "  ✓ Direct access to host tools"
    echo ""
    echo "Limitations:"
    echo "  ⚠ No isolation from host"
    echo "  ⚠ Shares host environment"
    echo "  ⚠ Infrastructure files NOT protected"
    echo ""
    echo "Use Cases:"
    echo "  • Quick tasks without containers"
    echo "  • Codespaces-like workflows"
    echo "  • Environments where Docker unavailable"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Prompt to continue
    local continue_choice
    continue_choice=$(prompt_yes_no "Launch AI assistant in direct mode?" "yes")
    if [[ "$continue_choice" != "yes" ]]; then
        echo "Cancelled."
        return 0
    fi

    echo ""
    print_success "Launching container-bitbot in direct mode..."
    echo ""

    # Change to workspace directory
    cd "$workspace_path"

    # Execute container-bitbot directly
    # This runs the same script that would run inside containers
    exec "${container_bitbot_dir}/bitbot" "$@"
}

# Export function for use by main script
export -f bitbot_direct
