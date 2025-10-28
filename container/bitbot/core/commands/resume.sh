#!/bin/bash
# Container BitBot - Resume Session
# Intelligent resume: tmux sessions or Claude --resume

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh"

# Check if Claude is running in tmux session
check_claude_running() {
    local session_name="$1"

    # Get PIDs in tmux session
    local pids="$(tmux list-panes -t "$session_name" -F '#{pane_pid}' 2>/dev/null || echo "")"

    if [[ -z "$pids" ]]; then
        return 1
    fi

    # Check if any process tree contains 'claude'
    for pid in $pids; do
        if ps -o command= -p "$pid" 2>/dev/null | grep -q "claude"; then
            return 0
        fi
        # Check child processes
        if pgrep -P "$pid" 2>/dev/null | xargs -r ps -o command= 2>/dev/null | grep -q "claude"; then
            return 0
        fi
    done

    return 1
}

# Resume tmux session with Claude check
resume_tmux_session() {
    local session_name="$1"

    info "Attaching to session '$session_name'..."
    echo ""

    # Check if Claude is still running
    if ! check_claude_running "$session_name"; then
        warning "Note: Claude Code appears to have exited in this session"
        echo ""
        echo "  To resume your Claude session:"
        echo "    claude --resume"
        echo ""
    fi

    attach_session "$session_name"
}

# Create new tmux with Claude --resume
create_tmux_with_resume() {
    local session_name="$(generate_session_name)"
    local mode="$(get_bitbot_mode)"
    local workspace="$(get_workspace)"

    echo ""
    info "Creating new tmux session with Claude --resume..."
    echo ""
    info "Claude will show its available sessions for you to select"
    echo ""

    # Show workspace info
    info "Workspace: $workspace"
    info "Mode: $mode"
    info "Session: $session_name"
    echo ""

    # Create tmux session and launch Claude with --resume
    if ! tmux new-session -d -s "$session_name"; then
        error "Failed to create tmux session"
        return 1
    fi

    # Send Claude --resume command
    tmux send-keys -t "$session_name" "claude --resume" C-m

    # Wait a moment for session to start
    sleep 1

    # Attach to session
    success "Session created successfully"
    echo ""
    info "Attaching to session '$session_name'..."
    echo ""
    attach_session "$session_name"
}

# Show session menu
show_session_menu() {
    local sessions=("$@")
    local count=${#sessions[@]}

    echo -e "${BLUE}Select tmux session to resume:${RESET}"
    echo ""

    local index=1
    for session in "${sessions[@]}"; do
        local session_info="$(get_session_info "$session")"
        echo "  $index) $session_info"
        ((index++))
    done

    echo "  0) Cancel"
    echo ""
    read -p "Choice: " choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return 1
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        echo "${sessions[$((choice - 1))]}"
        return 0
    else
        error "Invalid choice"
        return 1
    fi
}

# Main resume function
main() {
    local session_name="${1:-}"

    if ! tmux_available; then
        error "tmux is not available"
        echo ""
        echo "Please install tmux:"
        echo "  sudo apt-get install tmux"
        exit 1
    fi

    echo -e "${BLUE}BitBot - Resume Session${RESET}"
    echo ""

    # Get list of sessions
    local sessions="$(list_tmux_sessions)"
    local session_count="$(echo "$sessions" | grep -c '^' || echo 0)"

    # No tmux sessions - create new tmux with claude --resume
    if [[ $session_count -eq 0 ]]; then
        info "No tmux sessions found"
        echo ""
        create_tmux_with_resume
        return
    fi

    # Session name provided - try to attach directly
    if [[ -n "$session_name" ]]; then
        if session_exists "$session_name"; then
            resume_tmux_session "$session_name"
            return
        else
            error "Session '$session_name' not found"
            echo ""
            echo "Available sessions:"
            while IFS= read -r session; do
                echo "  • $session"
            done <<< "$sessions"
            return 1
        fi
    fi

    # Convert sessions to array
    local session_array=()
    while IFS= read -r session; do
        [[ -n "$session" ]] && session_array+=("$session")
    done <<< "$sessions"

    # Single session - auto-attach
    if [[ ${#session_array[@]} -eq 1 ]]; then
        local single_session="${session_array[0]}"
        info "Found one session: $single_session"
        echo ""
        resume_tmux_session "$single_session"
        return
    fi

    # Multiple sessions - show menu
    local selected
    if selected="$(show_session_menu "${session_array[@]}")"; then
        echo ""
        resume_tmux_session "$selected"
    else
        info "Cancelled"
        exit 0
    fi
}

main "$@"
