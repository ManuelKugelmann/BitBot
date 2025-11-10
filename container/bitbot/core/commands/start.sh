#!/bin/bash
# Container BitBot - Start Claude Session
# Creates new tmux session and launches Claude via wrapper

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh"

# Main start function
main() {
    local wrapper_script="/usr/local/bitbot/wrapper/claude-wrapper.sh"
    local session_name
    session_name="bitbot-$(date +%Y%m%d-%H%M%S)"
    local mode
    mode="$(get_bitbot_mode)"
    local workspace
    workspace="$(get_workspace)"

    echo -e "${BLUE}BitBot - Start New Session${RESET}"
    echo ""

    # Check if wrapper is available
    if [[ ! -f "$wrapper_script" ]] || [[ ! -x "$wrapper_script" ]]; then
        error "Wrapper not found or not executable"
        echo ""
        echo "Expected location: $wrapper_script"
        echo ""
        echo "The wrapper must be copied to container during build."
        echo "Check your Dockerfile includes:"
        echo ""
        echo '  COPY container/bitbot/wrapper/ /usr/local/bitbot/wrapper/'
        echo '  RUN chmod +x /usr/local/bitbot/wrapper/*.sh'
        echo ""
        exit 1
    fi

    # Check if tmux is available
    if ! command_exists tmux; then
        error "tmux is not available"
        echo ""
        echo "Please install tmux:"
        echo "  apt-get update && apt-get install -y tmux"
        echo ""
        exit 1
    fi

    info "Creating new tmux session: $session_name"
    info "Workspace: $workspace"
    info "Mode: $mode"
    echo ""

    # Create tmux session and exec wrapper directly
    # No tmux send-keys - exec wrapper as the session command
    exec tmux new-session -s "$session_name" "$wrapper_script claude $*"
}

main "$@"
