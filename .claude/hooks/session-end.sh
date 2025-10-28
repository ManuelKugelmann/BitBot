#!/usr/bin/env bash
# session-end.sh - Cleanup PID->SessionID map on session end
# Receives JSON via stdin

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/session-utils.sh"

# Read JSON from stdin (required even if we don't use it)
INPUT=$(cat)

CLAUDE_PID=$(find_claude_pid || echo "")

if [ -n "$CLAUDE_PID" ]; then
    MAP_DIR=$(get_session_map_dir)

    # Remove PID mapping file if it exists
    MAP_FILE="$MAP_DIR/$CLAUDE_PID.txt"
    if [ -f "$MAP_FILE" ]; then
        rm "$MAP_FILE"
    fi
fi

# Clean up stale maps if no other Claude instances running
cleanup_stale_maps

exit 0
