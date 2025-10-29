#!/usr/bin/env bash
# session-end.sh - SessionEnd hook
# Receives JSON via stdin with session_id
#
# Cleanup tasks:
# - Remove ALL session env files (aggressive cleanup)
#
# Why: Status line wrapper recreates files on every update (~1-2 seconds)
# So it's safe to delete all files - active sessions will recreate theirs
# This prevents accumulation of stale files from crashed sessions

set -euo pipefail

# Read JSON from stdin (required by hook protocol)
INPUT=$(cat)

# Clean up ALL session env files (aggressive)
ENV_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-env"

if [ -d "$ENV_DIR" ]; then
    # Remove all .env files
    rm -f "$ENV_DIR"/*.env 2>/dev/null || true

    # Remove empty directory
    if [ -z "$(ls -A "$ENV_DIR" 2>/dev/null)" ]; then
        rmdir "$ENV_DIR" 2>/dev/null || true
    fi
fi

exit 0
