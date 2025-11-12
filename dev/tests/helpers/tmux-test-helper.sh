#!/usr/bin/env bash
#
# Tmux Test Helper
# Provides utilities for testing interactive scripts using tmux
#

# Start a tmux test session
# Usage: tmux_test_start <session_name> <command>
tmux_test_start() {
    local session_name="$1"
    local command="$2"

    # Kill existing session if it exists
    tmux kill-session -t "$session_name" 2>/dev/null || true

    # Start new detached session
    tmux new-session -d -s "$session_name" "$command"

    # Wait a moment for session to start
    sleep 0.2
}

# Send keys to tmux session
# Usage: tmux_test_send_keys <session_name> <keys>
tmux_test_send_keys() {
    local session_name="$1"
    local keys="$2"

    tmux send-keys -t "$session_name" "$keys"

    # Wait for keys to be processed
    sleep 0.1
}

# Send Enter key
# Usage: tmux_test_send_enter <session_name>
tmux_test_send_enter() {
    local session_name="$1"
    tmux send-keys -t "$session_name" Enter
    sleep 0.1
}

# Capture pane content
# Usage: tmux_test_capture <session_name>
tmux_test_capture() {
    local session_name="$1"

    tmux capture-pane -t "$session_name" -p
}

# Wait for text to appear in pane
# Usage: tmux_test_wait_for <session_name> <text> [timeout_seconds]
tmux_test_wait_for() {
    local session_name="$1"
    local text="$2"
    local timeout="${3:-10}"
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if tmux_test_capture "$session_name" | grep -q "$text"; then
            return 0
        fi
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

    return 1
}

# Check if session is still running
# Usage: tmux_test_is_running <session_name>
tmux_test_is_running() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

# Wait for session to finish
# Usage: tmux_test_wait_finish <session_name> [timeout_seconds]
tmux_test_wait_finish() {
    local session_name="$1"
    local timeout="${2:-10}"
    local elapsed=0

    while tmux_test_is_running "$session_name"; do
        if [ $elapsed -ge $timeout ]; then
            return 1
        fi
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

    return 0
}

# Kill test session
# Usage: tmux_test_kill <session_name>
tmux_test_kill() {
    local session_name="$1"
    tmux kill-session -t "$session_name" 2>/dev/null || true
}

# Export functions for use in tests
export -f tmux_test_start
export -f tmux_test_send_keys
export -f tmux_test_send_enter
export -f tmux_test_capture
export -f tmux_test_wait_for
export -f tmux_test_is_running
export -f tmux_test_wait_finish
export -f tmux_test_kill
