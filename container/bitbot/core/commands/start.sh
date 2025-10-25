#!/bin/bash
# Container BitBot - Start Claude Session
# Launches Claude Code in tmux session with mode selection

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh"

# Show launch mode choice
show_launch_mode_choice() {
    echo -e "${BLUE}How would you like to launch Claude Code?${RESET}"
    echo ""
    echo "  1) Resume previous session    (--resume)"
    echo "  2) Interactive mode           (default)"
    echo "  3) Custom command"
    echo ""
    read -p "Choice (1-3) [2]: " choice

    case "$choice" in
        1) echo "resume" ;;
        2|"") echo "interactive" ;;
        3) echo "custom" ;;
        *) echo "interactive" ;;
    esac
}

# Prompt resume or new
prompt_resume_or_new() {
    echo -e "${BLUE}Would you like to:${RESET}"
    echo "  1) Resume existing session"
    echo "  2) Create new session"
    echo ""
    read -p "Choice (1-2) [1]: " choice

    case "$choice" in
        1|"") echo "resume" ;;
        *) echo "new" ;;
    esac
}

# Create new Claude session
create_new_claude_session() {
    local session_name="$(generate_session_name)"
    local mode="$(get_bitbot_mode)"
    local workspace="$(get_workspace)"

    echo ""
    info "Creating new Claude Code session..."
    echo ""

    # Show launch mode choice
    local launch_mode="$(show_launch_mode_choice)"
    local claude_cmd=""

    case "$launch_mode" in
        resume)
            claude_cmd="claude --resume"
            info "Launching: claude --resume"
            ;;
        interactive)
            claude_cmd="claude"
            info "Launching: claude (interactive)"
            ;;
        custom)
            echo ""
            read -p "Enter Claude command: " claude_cmd
            ;;
        *)
            claude_cmd="claude"
            ;;
    esac

    # Show workspace info
    echo ""
    info "Workspace: $workspace"
    info "Mode: $mode"
    info "Session: $session_name"
    echo ""

    # Create tmux session and launch Claude
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
}

# Main start function
main() {
    if ! tmux_available; then
        error "tmux is not available"
        echo ""
        echo "Please install tmux:"
        echo "  sudo apt-get install tmux"
        exit 1
    fi

    echo -e "${BLUE}BitBot - Claude Code Launcher${RESET}"
    echo ""

    # Check for existing sessions
    local sessions="$(list_tmux_sessions)"
    local session_count="$(echo "$sessions" | grep -c '^' || echo 0)"

    if [[ $session_count -gt 0 ]]; then
        info "Found existing tmux sessions:"
        while IFS= read -r session; do
            local session_info="$(get_session_info "$session")"
            echo "  • $session_info"
        done <<< "$sessions"
        echo ""

        # Offer to resume
        local choice="$(prompt_resume_or_new)"

        if [[ "$choice" == "resume" ]]; then
            exec "${SCRIPT_DIR}/resume.sh" "$@"
            return
        fi
    fi

    # No existing sessions or user wants new session
    create_new_claude_session "$@"
}

main "$@"
