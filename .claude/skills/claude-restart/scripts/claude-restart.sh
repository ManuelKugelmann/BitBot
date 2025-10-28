#!/usr/bin/env bash
# restart.sh - Restart Claude Code session via self-pkill
# Usage: restart.sh [mode]
#   Modes:
#     resume  - Quick restart with session resume (default)
#     compact - Exit for context compaction, then resume
#     clear   - Exit and start fresh (no resume)

set -euo pipefail

# Default mode is resume
MODE="${1:-resume}"

# Validate mode
case "$MODE" in
    resume|compact|clear)
        ;;
    *)
        echo "Error: Invalid mode '$MODE'"
        echo "Valid modes: resume, compact, clear"
        exit 1
        ;;
esac

# Get script directory and source utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../claude-get-session-info/scripts/get-session-info.sh"

# Validate Claude PID
if [ -z "$CLAUDE_PID" ]; then
    echo "Error: Could not find Claude process in parent chain"
    echo "Cannot safely restart"
    exit 1
fi

# Prepare restart command based on mode
case "$MODE" in
    resume)
        if [ -z "$SESSION_ID" ]; then
            echo "Error: Could not detect session ID"
            echo "Cannot resume without session ID"
            echo ""
            echo "Use 'clear' mode to start fresh: restart.sh clear"
            exit 1
        fi
        RESTART_CMD="claude --resume $SESSION_ID"
        ;;
    compact)
        if [ -z "$SESSION_ID" ]; then
            echo "Error: Could not detect session ID"
            echo "Cannot compact without session ID"
            echo ""
            echo "Use 'clear' mode to start fresh: restart.sh clear"
            exit 1
        fi
        RESTART_CMD="claude -p --resume $SESSION_ID"
        ;;
    clear)
        RESTART_CMD="claude"
        ;;
esac

# Display restart information
cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              Claude Code Restart                              ║
╚═══════════════════════════════════════════════════════════════╝

Mode: $MODE
Session ID: ${SESSION_ID:-<new session>}
Claude PID: $CLAUDE_PID

EOF

case "$MODE" in
    resume)
        echo "Restart:resume - Preserving conversation history"
        ;;
    compact)
        echo "Restart:compact - Context management mode"
        ;;
    clear)
        echo "Restart:clear - Fresh session start"
        ;;
esac

echo ""
echo "Forking restart process..."

# Get current TTY for terminal access
TTY=$(tty)

# Fork a detached background process to survive Claude termination
# Use setsid to create a new session, detaching from parent process tree
# Preserve terminal access by redirecting to actual TTY
setsid bash -c "
    # Kill Claude process
    kill -TERM $CLAUDE_PID 2>/dev/null || exit 1

    # Wait for Claude to fully exit
    sleep 2

    # Clear terminal
    clear

    # Execute restart command
    exec $RESTART_CMD
" <"$TTY" >"$TTY" 2>&1 &

# Exit immediately - the detached process will handle the restart
exit 0
