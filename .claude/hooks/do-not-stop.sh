#!/usr/bin/env bash
# do-not-stop.sh - Stop hook that blocks completion with custom reason
# Checks session-specific file first, then global fallback:
#   1. DO-NOT-STOP-<session-id>.txt (per-session)
#   2. DO-NOT-STOP.txt (all sessions)

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Parse stop_hook_active flag to prevent infinite loops
# Simple bash parsing - look for "stop_hook_active": true
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

# Extract session_id from JSON input
if command -v jq &> /dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
    # Fallback to grep/sed if jq not available
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"\([^"]*\)"/\1/' || echo "")
fi

# Determine base directory
# Try /workspace first (for BitBot containers), fallback to project dir
if [ -d "/workspace" ]; then
    BASE_DIR="/workspace/.bitbot"
else
    BASE_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot"
fi

# Check for session-specific file first, then global fallback
DO_NOT_STOP_FILE=""
if [ -n "$SESSION_ID" ] && [ -f "$BASE_DIR/DO-NOT-STOP-$SESSION_ID.txt" ] && [ -s "$BASE_DIR/DO-NOT-STOP-$SESSION_ID.txt" ]; then
    DO_NOT_STOP_FILE="$BASE_DIR/DO-NOT-STOP-$SESSION_ID.txt"
elif [ -f "$BASE_DIR/DO-NOT-STOP.txt" ] && [ -s "$BASE_DIR/DO-NOT-STOP.txt" ]; then
    DO_NOT_STOP_FILE="$BASE_DIR/DO-NOT-STOP.txt"
fi

if [ -n "$DO_NOT_STOP_FILE" ]; then
    # Read the entire file content (multiline)
    REASON=$(cat "$DO_NOT_STOP_FILE")

    # Escape special characters for JSON
    REASON_ESCAPED=$(echo "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    # Block stopping and inject the reason for continuing
    cat <<EOF
{
  "decision": "block",
  "reason": "$REASON_ESCAPED"
}
EOF
else
    # File doesn't exist or is empty, allow normal stopping
    cat <<EOF
{
  "systemMessage": "Allowed to stop working."
}
EOF
fi
