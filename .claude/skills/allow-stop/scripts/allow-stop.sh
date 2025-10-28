#!/usr/bin/env bash
# allowstop - Disable the donotstop Stop hook
# Usage: .claude/skills/allow-stop/scripts/allow-stop.sh
#
# Removes the DO-NOT-STOP.txt file to allow normal completion

set -euo pipefail

# Use /workspace for BitBot containers, fallback to project dir
if [ -d "/workspace" ]; then
    DO_NOT_STOP_FILE="/workspace/.bitbot/DO-NOT-STOP.txt"
else
    DO_NOT_STOP_FILE="${CLAUDE_PROJECT_DIR:-.}/.bitbot/DO-NOT-STOP.txt"
fi

if [ -f "$DO_NOT_STOP_FILE" ]; then
    rm "$DO_NOT_STOP_FILE"
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              DONOTSTOP Hook Disabled                          ║
╚═══════════════════════════════════════════════════════════════╝

The Stop hook will now allow normal completion.

Claude will stop after finishing responses.

To re-enable: /do-not-stop [reason]
EOF
else
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║           DONOTSTOP Hook Already Disabled                     ║
╚═══════════════════════════════════════════════════════════════╝

File not found: $DO_NOT_STOP_FILE

To enable: /do-not-stop [reason]
EOF
fi

exit 0
