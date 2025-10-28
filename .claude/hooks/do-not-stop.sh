#!/usr/bin/env bash
# do-not-stop.sh - Stop hook that blocks completion with custom reason
# Reads reason from /workspace/.bitbot/DO-NOT-STOP.txt

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Parse stop_hook_active flag to prevent infinite loops
# Simple bash parsing - look for "stop_hook_active": true
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

# Check if DO-NOT-STOP.txt exists and is not empty
# Try /workspace first (for BitBot containers), fallback to project dir
if [ -d "/workspace" ]; then
    DO_NOT_STOP_FILE="/workspace/.claude/DO-NOT-STOP.txt"
else
    DO_NOT_STOP_FILE="${CLAUDE_PROJECT_DIR}/.claude/DO-NOT-STOP.txt"
fi

if [ -f "$DO_NOT_STOP_FILE" ] && [ -s "$DO_NOT_STOP_FILE" ]; then
    # Read the entire file content (multiline)
    REASON=$(cat "$DO_NOT_STOP_FILE")

    # Escape special characters for JSON
    REASON_ESCAPED=$(echo "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    # Block completion and inject the reason
    cat <<EOF
{
  "decision": "block",
  "reason": "$REASON_ESCAPED"
}
EOF
else
    # File doesn't exist or is empty, allow normal completion
    exit 0
fi
