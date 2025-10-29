#!/usr/bin/env bash
# cleanup-old-sessions.sh - Remove old session env files
#
# SessionEnd hook should clean up automatically, but this provides
# a manual cleanup option for:
# - Sessions that crashed without proper shutdown
# - Old sessions after system restart
# - General maintenance
#
# Usage:
#   cleanup-old-sessions.sh [--older-than-days N]
#
# Default: Remove files older than 7 days

set -euo pipefail

# Parse arguments
DAYS_OLD=7
if [ $# -ge 2 ] && [ "$1" = "--older-than-days" ]; then
    DAYS_OLD="$2"
fi

ENV_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-env"

if [ ! -d "$ENV_DIR" ]; then
    echo "No session env directory found: $ENV_DIR"
    exit 0
fi

echo "Cleaning up session env files older than $DAYS_OLD days..."
echo "Directory: $ENV_DIR"
echo ""

# Find and remove old files
FOUND=0
REMOVED=0

while IFS= read -r -d '' file; do
    FOUND=$((FOUND + 1))
    SESSION_ID=$(basename "$file" .env)
    FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)) / 86400 ))

    if [ "$FILE_AGE" -ge "$DAYS_OLD" ]; then
        echo "  Removing: $SESSION_ID (${FILE_AGE} days old)"
        rm -f "$file"
        REMOVED=$((REMOVED + 1))
    fi
done < <(find "$ENV_DIR" -name "*.env" -type f -print0 2>/dev/null)

echo ""
echo "Found: $FOUND session files"
echo "Removed: $REMOVED old files"

# Clean up empty directory
if [ -d "$ENV_DIR" ] && [ -z "$(ls -A "$ENV_DIR")" ]; then
    rmdir "$ENV_DIR"
    echo "Removed empty directory: $ENV_DIR"
fi

exit 0
