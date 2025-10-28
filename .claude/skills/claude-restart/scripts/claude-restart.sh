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

# Check if running in tmux
if [ -z "$TMUX" ]; then
    echo "Error: Restart requires tmux"
    echo "Please run Claude inside a tmux session"
    exit 1
fi

# Get tmux session target
TMUX_TARGET=$(tmux display-message -p '#S:#I.#P')
echo "Detected tmux session: $TMUX_TARGET"
echo "Forking restart process..."

# Fork detached process to kill Claude and send restart command to tmux
setsid bash <<EOF &
    # Kill Claude process
    kill -TERM $CLAUDE_PID 2>/dev/null || exit 1

    # Wait for Claude to fully exit
    sleep 3

    # Send restart command to tmux pane
    tmux send-keys -t '$TMUX_TARGET' '$RESTART_CMD' C-m
EOF

# Give fork time to start
sleep 1

# Exit immediately - detached process will handle restart
exit 0
