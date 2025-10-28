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
    # Find Claude PID for display purposes
    CLAUDE_PID=$(find_claude_pid || echo "")

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

    # Post session ID to wrapper if running under wrapper
    if [ -n "$CLAUDE_PID" ]; then
        WRAPPER_STATE="$PROJECT_ROOT/.bitbot/wrapper-runtime/.wrapper-session-${CLAUDE_PID}.state"
        if mkdir -p "$PROJECT_ROOT/.bitbot/wrapper-runtime" 2>/dev/null; then
            echo "SESSION_ID=$SESSION_ID" > "$WRAPPER_STATE"
            echo "IS_RESUME=$IS_RESUME" >> "$WRAPPER_STATE"
            echo "START_TIME=$(date +%s)" >> "$WRAPPER_STATE"
        fi
    fi
fi

exit 0
