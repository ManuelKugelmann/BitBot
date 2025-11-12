#!/bin/bash
# Container BitBot - tmux Utilities
# Helper functions for tmux session management

# Check if tmux is available
tmux_available() {
    command_exists tmux
}

# List tmux sessions
# Returns: Array of session names
list_tmux_sessions() {
    if ! tmux_available; then
        return 1
    fi

    tmux list-sessions -F "#{session_name}" 2>/dev/null || true
}

# Check if session exists
# Args: session_name
session_exists() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

# Count tmux sessions
count_sessions() {
    list_tmux_sessions | wc -l
}

# Get session info
# Args: session_name
# Returns: Formatted session info
get_session_info() {
    local session_name="$1"
    if session_exists "$session_name"; then
        tmux list-sessions -F "#{session_name}: #{session_windows} windows (created #{session_created})" \
            | grep "^${session_name}:" || true
    fi
}

# Create tmux session
# Args: session_name, command
create_session() {
    local session_name="$1"
    local command="${2:-bash}"

    if ! tmux_available; then
        error "tmux is not available"
        return 1
    fi

    tmux new-session -d -s "$session_name" "$command"
}

# Attach to session
# Args: session_name
attach_session() {
    local session_name="$1"

    if ! session_exists "$session_name"; then
        error "Session '$session_name' does not exist"
        return 1
    fi

    tmux attach-session -t "$session_name"
}

# Generate session name
# Returns: bitbot-YYYYMMDD-HHMM
generate_session_name() {
    echo "bitbot-$(date +%Y%m%d-%H%M)"
}
