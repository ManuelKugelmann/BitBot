#!/bin/bash
# Container BitBot - Start Claude Session
# Launches Claude Code in tmux session with mode selection

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh"

# Create new Claude session
create_new_claude_session() {
    local session_name="$(generate_session_name)"
    local mode="$(get_bitbot_mode)"
    local workspace="$(get_workspace)"

    echo ""
    info "Creating fresh Claude Code session..."
    echo ""

    # Check if wrapper is available (mounted from $BITBOT_HOME)
    local wrapper_script="/opt/bitbot/wrapper/claude-wrapper.sh"
    local use_wrapper=false

    if [[ -f "$wrapper_script" ]] && [[ -x "$wrapper_script" ]]; then
        use_wrapper=true
        info "Using wrapper (pipe-based IPC + watchdog)"
    else
        info "Wrapper not mounted, using tmux fallback"
    fi

    # Always use fresh interactive Claude (no --resume)
    local claude_cmd="claude"

    # Show workspace info
    info "Workspace: $workspace"
    info "Mode: $mode"
    info "Session: $session_name"
    echo ""

    if [[ "$use_wrapper" == "true" ]]; then
        # Launch via wrapper (no tmux required)
        success "Launching Claude via wrapper..."
        echo ""
        exec "$wrapper_script" "$claude_cmd"
    else
        # Fallback: Create tmux session and launch Claude
        if ! tmux new-session -d -s "$session_name"; then
            error "Failed to create tmux session"
            return 1
        fi

        # Send Claude command to session
        tmux send-keys -t "$session_name" "$claude_cmd" C-m

        # Wait a moment for session to start
        sleep 1

        # Attach to session
        success "Session created successfully"
        echo ""
        info "Attaching to session '$session_name'..."
        echo ""
        tmux attach-session -t "$session_name"
    fi
}

# Main start function
main() {
    local wrapper_script="/opt/bitbot/wrapper/claude-wrapper.sh"

    # Check if wrapper is available (makes tmux optional)
    if [[ -f "$wrapper_script" ]] && [[ -x "$wrapper_script" ]]; then
        # Wrapper available - tmux not required
        :
    else
        # No wrapper - require tmux
        if ! tmux_available; then
            error "tmux is not available"
            echo ""
            echo "Please install tmux:"
            echo "  sudo apt-get install tmux"
            echo ""
            echo "Alternatively, wrapper can be mounted from \$BITBOT_HOME:"
            echo "  (Check devcontainer.json mounts)"
            exit 1
        fi
    fi

    echo -e "${BLUE}BitBot - Claude Code Launcher${RESET}"
    echo ""

    # Always create fresh session (use 'bitbot resume' to resume existing)
    create_new_claude_session "$@"
}

main "$@"
