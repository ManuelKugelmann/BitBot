#!/usr/bin/env bash
# session-utils.sh - Shared utilities for session hooks
# Source this file in other hooks

# Find Claude PID by walking up the process tree
find_claude_pid() {
    local pid=$$
    local max_depth=10
    local depth=0

    while [ $depth -lt $max_depth ] && [ $pid -gt 1 ]; do
        local ppid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
        if [ -z "$ppid" ] || [ "$ppid" -eq 1 ]; then
            break
        fi

        local pname=$(ps -p "$ppid" -o comm= 2>/dev/null | tr -d ' ')
        if [ "$pname" = "claude" ]; then
            echo "$ppid"
            return 0
        fi

        pid=$ppid
        depth=$((depth + 1))
    done

    return 1
}

# Get session map directory
get_session_map_dir() {
    if [ -d "/workspace" ]; then
        echo "/workspace/.bitbot/session-map"
    else
        echo "${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-map"
    fi
}

# Clean up stale session maps if no other Claude instances running
cleanup_stale_maps() {
    local map_dir=$(get_session_map_dir)

    if [ ! -d "$map_dir" ]; then
        return 0
    fi

    # Count running Claude instances
    local claude_count=$(pgrep -c "^claude$" 2>/dev/null || echo "0")

    if [ "$claude_count" -eq 0 ]; then
        # No Claude instances running, clean up all maps
        rm -f "$map_dir"/*.txt 2>/dev/null || true
    fi
}
