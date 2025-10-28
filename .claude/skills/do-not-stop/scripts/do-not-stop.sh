#!/usr/bin/env bash
# donotstop - Enable the donotstop Stop hook
# Usage: .claude/skills/do-not-stop/scripts/do-not-stop.sh [reason]
#
# If reason is provided as argument, it will be written to DO-NOT-STOP.txt
# Otherwise, a default message is used

set -euo pipefail

# Use /workspace for BitBot containers, fallback to project dir
if [ -d "/workspace" ]; then
    DONOTSTOP_DIR="/workspace/.bitbot"
else
    DONOTSTOP_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot"
fi
DO_NOT_STOP_FILE="$DONOTSTOP_DIR/DO-NOT-STOP.txt"

# Create directory if it doesn't exist
mkdir -p "$DONOTSTOP_DIR"

# Use provided reason or default
if [ $# -gt 0 ]; then
    # Use all arguments as the reason
    REASON="$*"
else
    # Default reason
    REASON="Continue working. Check TODO list and implement the next pending task."
fi

# Write reason to file
echo "$REASON" > "$DO_NOT_STOP_FILE"

cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              DONOTSTOP Hook Enabled                           ║
╚═══════════════════════════════════════════════════════════════╝

The Stop hook will now block completion and continue with:

$(cat "$DO_NOT_STOP_FILE")

File: $DO_NOT_STOP_FILE

To disable: /allow-stop
To change reason: Edit $DO_NOT_STOP_FILE or run this tool again
EOF

exit 0
