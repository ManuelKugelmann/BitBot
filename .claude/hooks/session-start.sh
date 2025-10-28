#!/usr/bin/env bash
# session-start.sh - Create PID->SessionID map and display session ID
# Receives JSON via stdin with session_id field

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/session-utils.sh"

# Read JSON from stdin
INPUT=$(cat)

# Extract session_id using jq if available, otherwise use grep
if command -v jq &> /dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
    # Fallback to grep/sed if jq not available
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"\([^"]*\)"/\1/')
fi

if [ -n "$SESSION_ID" ]; then
    CLAUDE_PID=$(find_claude_pid || echo "")

    if [ -n "$CLAUDE_PID" ]; then
        MAP_DIR=$(get_session_map_dir)
        mkdir -p "$MAP_DIR"

        # Check if any other Claude instances are running
        # If not (only this one), clean up stale mapping files
        CLAUDE_COUNT=$(pgrep -c "^claude$" 2>/dev/null || echo "0")
        if [ "$CLAUDE_COUNT" -le 1 ]; then
            # Only this Claude instance running, clean up all old maps
            rm -f "$MAP_DIR"/*.txt 2>/dev/null || true
        fi

        # Write PID -> SessionID mapping for this instance
        echo "$SESSION_ID" > "$MAP_DIR/$CLAUDE_PID.txt"
    fi

    # Echo session ID and Claude PID for visibility
    echo "Session ID: $SESSION_ID"
    if [ -n "$CLAUDE_PID" ]; then
        echo "Claude PID: $CLAUDE_PID"
    fi
fi

exit 0
