#!/usr/bin/env bash
# get-session-info.sh - Utility to get Claude PID and Session ID
# Source this file in other scripts to access:
#   - CLAUDE_PID variable
#   - SESSION_ID variable

# Find Claude PID by walking up the process tree
_find_claude_pid() {
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
_get_session_map_dir() {
    if [ -d "/workspace" ]; then
        echo "/workspace/.bitbot/session-map"
    else
        echo "${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-map"
    fi
}

# Get Claude PID
CLAUDE_PID=$(_find_claude_pid || echo "")

# Get Session ID from PID map
SESSION_ID=""
if [ -n "$CLAUDE_PID" ]; then
    MAP_DIR=$(_get_session_map_dir)
    MAP_FILE="$MAP_DIR/$CLAUDE_PID.txt"

    if [ -f "$MAP_FILE" ]; then
        SESSION_ID=$(cat "$MAP_FILE" 2>/dev/null || echo "")
    fi
fi

# Export variables for use by sourcing script
export CLAUDE_PID
export SESSION_ID
