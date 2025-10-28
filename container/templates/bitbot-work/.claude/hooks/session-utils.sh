#!/usr/bin/env bash
# session-utils.sh - Shared utilities for session hooks
# Source this file in other hooks

# Find project root by looking for .claude directory
find_project_root() {
    local dir="$PWD"
    local max_depth=10
    local depth=0

    while [ $depth -lt $max_depth ]; do
        if [ -d "$dir/.claude" ]; then
            echo "$dir"
            return 0
        fi

        # Reached filesystem root
        if [ "$dir" = "/" ]; then
            break
        fi

        dir=$(dirname "$dir")
        depth=$((depth + 1))
    done

    # Fallback to current directory
    echo "$PWD"
    return 1
}

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
