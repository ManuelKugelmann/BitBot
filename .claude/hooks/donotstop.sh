#!/usr/bin/env bash
# donotstop.sh - Stop hook that blocks completion with custom reason
# Reads reason from /workspace/.bitbot/DONOTSTOP.txt

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Parse stop_hook_active flag to prevent infinite loops
# Simple bash parsing - look for "stop_hook_active": true
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

# Check if DONOTSTOP.txt exists and is not empty
# Try /workspace first (for BitBot containers), fallback to project dir
if [ -d "/workspace" ]; then
    DONOTSTOP_FILE="/workspace/.bitbot/DONOTSTOP.txt"
else
    DONOTSTOP_FILE="${CLAUDE_PROJECT_DIR}/.bitbot/DONOTSTOP.txt"
fi

if [ -f "$DONOTSTOP_FILE" ] && [ -s "$DONOTSTOP_FILE" ]; then
    # Read the entire file content (multiline)
    REASON=$(cat "$DONOTSTOP_FILE")

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
