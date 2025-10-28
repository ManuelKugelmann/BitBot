#!/usr/bin/env bash
# restart.sh - Restart Claude Code session with various modes
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

# Detect current session ID - try multiple methods
detect_session_id() {
    local session_id=""

    # Method 1: Read from SessionStart hook file (most reliable)
    local session_file
    if [ -d "/workspace" ]; then
        session_file="/workspace/.bitbot/CURRENT_SESSION.txt"
    else
        session_file="${CLAUDE_PROJECT_DIR:-.}/.bitbot/CURRENT_SESSION.txt"
    fi

    if [ -f "$session_file" ]; then
        session_id=$(cat "$session_file" 2>/dev/null || true)
    fi

    # Method 2: Fallback to most recent session-env directory
    if [ -z "$session_id" ]; then
        local session_dir="$HOME/.claude/session-env"
        if [ -d "$session_dir" ]; then
            session_id=$(ls -t "$session_dir" 2>/dev/null | head -1 || true)
        fi
    fi

    if [ -z "$session_id" ]; then
        echo "Error: Cannot detect session ID" >&2
        return 1
    fi

    echo "$session_id"
}

# Check if running in tmux
in_tmux() {
    [ -n "${TMUX:-}" ]
}

# Get Claude PID (for pkill method)
get_claude_pid() {
    # Find the main Claude process (not agents)
    pgrep -f "^claude$" | head -1 || true
}

# Main logic
main() {
    local session_id=""

    # Detect session ID for resume modes
    if [ "$MODE" != "clear" ]; then
        session_id=$(detect_session_id) || {
            echo "Warning: Could not detect session ID. Falling back to 'clear' mode."
            MODE="clear"
        }
    fi

    # Prepare restart command based on mode
    local restart_cmd=""
    local message=""

    case "$MODE" in
        resume)
            restart_cmd="claude --resume $session_id"
            message="Will restart Claude and resume session $session_id"
            ;;
        compact)
            restart_cmd="claude -p"
            message="Will restart Claude in print mode for context management.
After compacting or clearing, run:
  claude --resume $session_id"
            ;;
        clear)
            restart_cmd="claude"
            message="Will restart Claude with a fresh session"
            ;;
    esac

    # Display restart information
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║              Claude Code Restart                              ║
╚═══════════════════════════════════════════════════════════════╝

Mode: $MODE
Session ID: ${session_id:-<new session>}

$message

EOF

    # Choose restart method based on environment
    if in_tmux; then
        echo "✓ Using tmux automation"
        echo ""

        # Use tmux run-shell to schedule restart after Claude exits
        # The -b flag runs it in background, so it won't block this script
        tmux run-shell -b "sleep 3 && tmux send-keys -t '$TMUX_PANE' '$restart_cmd' Enter" 2>/dev/null || {
            echo "Warning: Could not schedule tmux restart"
            echo "Manually run: $restart_cmd"
        }

        echo "Claude will exit and restart automatically in 3 seconds..."
        sleep 1

        # Exit Claude cleanly
        # The tmux command queued above will execute after we exit
        exit 0

    else
        # Not in tmux - try pkill method as fallback
        echo "⚠ Not in tmux - using pkill method"
        echo ""

        local claude_pid=$(get_claude_pid)
        if [ -n "$claude_pid" ]; then
            echo "Found Claude PID: $claude_pid"
            echo "Will kill Claude and provide restart command"
            echo ""
            echo "After Claude exits, run:"
            echo "  $restart_cmd"
            echo ""
            echo "Press Enter to continue..."
            read -r

            # Kill Claude process gracefully (SIGTERM)
            kill -TERM "$claude_pid" 2>/dev/null || {
                echo "Could not kill Claude process"
                exit 1
            }

            # The session will end here
            exit 0
        else
            # Can't find PID - just provide instructions
            echo "Could not find Claude process"
            echo ""
            echo "To restart, run this command after Claude exits:"
            echo "  $restart_cmd"
            echo ""
            echo "Press Enter to exit Claude..."
            read -r
            exit 0
        fi
    fi
}

main
