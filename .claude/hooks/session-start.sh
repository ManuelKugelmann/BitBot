#!/usr/bin/env bash
# session-start.sh - Create PID->SessionID map and display session ID
# Receives JSON via stdin with session_id field
#
# NOTE: This hook is NOT standalone - it must be run by Claude Code
# which provides the CLAUDE_ENV_FILE environment variable.

set -euo pipefail

# Verify this is being run by Claude Code, not standalone
if [ -z "${CLAUDE_ENV_FILE:-}" ]; then
    echo "ERROR: CLAUDE_ENV_FILE not set." >&2
    echo "This hook must be run by Claude Code SessionStart, not standalone." >&2
    exit 1
fi

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

    # Check if this is a resume (session already exists)
    IS_RESUME=$(echo "$INPUT" | grep -q '"is_resume":true' && echo "resume" || echo "start")

    # Export environment variables for the session
    PROJECT_ROOT=$(find_project_root)
    echo "export CLAUDE_SESSION_ID='$SESSION_ID'" >> "$CLAUDE_ENV_FILE"
    echo "export CLAUDE_PROJECT_DIR='$PROJECT_ROOT'" >> "$CLAUDE_ENV_FILE"
    if [ -n "$CLAUDE_PID" ]; then
        echo "export CLAUDE_PID='$CLAUDE_PID'" >> "$CLAUDE_ENV_FILE"
    fi

    # Echo session info in one line
    if [ -n "$CLAUDE_PID" ]; then
        echo "SessionStart:$IS_RESUME - Session: $SESSION_ID, PID: $CLAUDE_PID"
    else
        echo "SessionStart:$IS_RESUME - Session: $SESSION_ID"
    fi
fi

exit 0
