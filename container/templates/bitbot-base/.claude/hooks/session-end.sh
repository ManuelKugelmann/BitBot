#!/usr/bin/env bash
# session-end.sh - SessionEnd hook
# Receives JSON via stdin with session_id
#
# Cleanup tasks:
# - Remove session-specific env file from ccstatusline wrapper

set -euo pipefail

# Read JSON from stdin (required by hook protocol)
INPUT=$(cat)

# Extract session_id using jq if available, otherwise use grep
if command -v jq &> /dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
    # Fallback to grep/sed if jq not available
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"\([^"]*\)"/\1/')
fi

# Clean up session env file if it exists
if [ -n "$SESSION_ID" ]; then
    ENV_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-env"
    ENV_FILE="$ENV_DIR/${SESSION_ID}.env"

    if [ -f "$ENV_FILE" ]; then
        rm -f "$ENV_FILE"
    fi

    # Clean up empty directory
    if [ -d "$ENV_DIR" ] && [ -z "$(ls -A "$ENV_DIR")" ]; then
        rmdir "$ENV_DIR"
    fi
fi

exit 0
