#!/usr/bin/env bash
# claude-compact-resume.sh - Run compaction with progress indicator, then resume
# Usage: claude-compact-resume.sh <session-id>
# Called by claude-restart.sh via tmux send-keys

set -euo pipefail

# Validate session ID parameter
if [ $# -ne 1 ]; then
    echo "Error: Session ID required"
    echo "Usage: claude-compact-resume.sh <session-id>"
    exit 1
fi

SESSION_ID="$1"

# Clear screen
clear

# Create temp file for compaction output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Run compaction in background
(
    echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"/compact"}]}}'
    echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Concise summary:"}]}}'
) | timeout 300 claude -p --output-format=stream-json --input-format=stream-json --resume "$SESSION_ID" > "$TEMP_OUTPUT" 2>&1 &

COMPACT_PID=$!

# Show progress timer on single line
echo ""
SECONDS=0
while kill -0 $COMPACT_PID 2>/dev/null; do
    printf "\rCompacting session... %02d:%02d" $((SECONDS/60)) $((SECONDS%60))
    sleep 1
done

# Check exit code
set +e
wait $COMPACT_PID
EXIT_CODE=$?
set -e

printf "\r\033[K"  # Clear the progress line

# Handle compaction errors
if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "Error: Compaction failed (exit code: $EXIT_CODE)"
    echo ""

    # Show error output if available
    if [ -s "$TEMP_OUTPUT" ]; then
        echo "Error details:"
        cat "$TEMP_OUTPUT"
        echo ""
    fi

    echo "Resuming without compaction in 10 seconds..."
    echo "(Press Enter to resume immediately)"
    echo ""

    # Wait 10s or until user presses Enter
    read -t 10 -r || true
fi

# Brief delay before resume
sleep 0.5

# Restart Claude interactively
exec claude --resume "$SESSION_ID"
