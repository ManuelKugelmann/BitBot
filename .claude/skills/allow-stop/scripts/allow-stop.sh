#!/usr/bin/env bash
# allowstop - Disable the donotstop Stop hook for current session
# Usage: .claude/skills/allow-stop/scripts/allow-stop.sh
#
# Removes session-specific file: DO-NOT-STOP-<session-id>.txt

set -euo pipefail

# Get Claude PID and Session ID
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../.claude/tools/get-session-info.sh"

if [ -z "$SESSION_ID" ]; then
    echo "Error: Could not detect session ID"
    echo "Cannot disable do-not-stop without session ID"
    exit 1
fi

# Use /workspace for BitBot containers, fallback to project dir
if [ -d "/workspace" ]; then
    DONOTSTOP_DIR="/workspace/.bitbot"
else
    DONOTSTOP_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot"
fi

SESSION_FILE="$DONOTSTOP_DIR/DO-NOT-STOP-$SESSION_ID.txt"

if [ -f "$SESSION_FILE" ]; then
    rm "$SESSION_FILE"
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              DONOTSTOP Hook Disabled                          ║
╚═══════════════════════════════════════════════════════════════╝

Session: $SESSION_ID

The Stop hook will now allow normal completion.

Claude will stop after finishing responses.

To re-enable: /do-not-stop [reason]
EOF
else
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║           DONOTSTOP Hook Already Disabled                     ║
╚═══════════════════════════════════════════════════════════════╝

Session: $SESSION_ID

No DO-NOT-STOP file found for this session.

To enable: /do-not-stop [reason]
EOF
fi

exit 0
