#!/usr/bin/env bash
# donotstop - Enable the donotstop Stop hook for current session
# Usage: .claude/skills/do-not-stop/scripts/do-not-stop.sh [reason]
#
# Writes to session-specific file: DO-NOT-STOP-<session-id>.txt

set -euo pipefail

# Get Claude PID and Session ID
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../.claude/tools/get-session-info.sh"

if [ -z "$SESSION_ID" ]; then
    echo "Error: Could not detect session ID"
    echo "Cannot enable do-not-stop without session ID"
    exit 1
fi

# Use /workspace for BitBot containers, fallback to project dir
if [ -d "/workspace" ]; then
    DONOTSTOP_DIR="/workspace/.bitbot"
else
    DONOTSTOP_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot"
fi

# Create directory if it doesn't exist
mkdir -p "$DONOTSTOP_DIR"

DO_NOT_STOP_FILE="$DONOTSTOP_DIR/DO-NOT-STOP-$SESSION_ID.txt"

# Use provided reason or default
if [ $# -gt 0 ]; then
    REASON="$*"
else
    REASON="Resume work!"
fi

# Write reason to file
echo "$REASON" > "$DO_NOT_STOP_FILE"

cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              DONOTSTOP Hook Enabled                           ║
╚═══════════════════════════════════════════════════════════════╝

Session: $SESSION_ID

The Stop hook will now block completion and continue with:

$(cat "$DO_NOT_STOP_FILE")

File: $DO_NOT_STOP_FILE

To disable: /allow-stop
To change reason: Edit $DO_NOT_STOP_FILE or run this tool again
EOF

exit 0
