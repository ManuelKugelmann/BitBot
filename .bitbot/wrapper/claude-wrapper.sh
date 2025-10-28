#!/usr/bin/env bash
# claude-wrapper.sh - Wrapper for Claude Code with pipe-based control
#
# Creates a named pipe for receiving control commands from within Claude:
#   - exit     : Gracefully exit Claude
#   - restart  : Kill and restart Claude (resume mode)
#   - compact  : Kill, compact context, and restart Claude
#   - clear    : Kill and restart Claude (fresh session)
#
# Usage: claude-wrapper.sh [claude-args...]
#
# The wrapper creates a pipe at: .bitbot/wrapper/pipes/claude-<PID>.pipe
# Tools within Claude can send commands to this pipe.

set -euo pipefail

# Find project root (look for .bitbot/ marker)
find_project_root() {
    local dir="$PWD"
    local max_depth=10
    local depth=0

    while [ $depth -lt $max_depth ]; do
        if [ -d "$dir/.bitbot" ]; then
            echo "$dir"
            return 0
        fi

        # Stop at filesystem root
        if [ "$dir" = "/" ]; then
            break
        fi

        dir="$(dirname "$dir")"
        depth=$((depth + 1))
    done

    # Fallback to current directory
    echo "$PWD"
    return 1
}

# Determine project directory
PROJECT_DIR=$(find_project_root)

# Setup pipe infrastructure (use wrapper-runtime in workspace)
RUNTIME_DIR="$PROJECT_DIR/.bitbot/wrapper-runtime"
PIPE_DIR="$RUNTIME_DIR/pipes"
WRAPPER_PID=$$

# Create runtime directories if needed
mkdir -p "$PIPE_DIR"

# Cleanup function
cleanup() {
    local exit_code=$?

    # Kill background reader if still running
    if [ -n "${READER_PID:-}" ]; then
        kill "$READER_PID" 2>/dev/null || true
    fi

    # Remove ready marker
    rm -f "${READY_MARKER:-}" 2>/dev/null || true

    # Remove pipe
    rm -f "${PIPE:-}" 2>/dev/null || true

    # Cleanup empty pipe directory
    rmdir "$PIPE_DIR" 2>/dev/null || true

    exit $exit_code
}

trap cleanup EXIT INT TERM

# Create pipe directory
mkdir -p "$PIPE_DIR"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Claude Code Wrapper                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Wrapper PID: $WRAPPER_PID"
echo "Launching wrapped process..."
echo ""

# Handle commands from pipe
handle_command() {
    local cmd="$1"
    local session_id="${2:-}"

    case "$cmd" in
        exit)
            echo ""
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║ Exit command received via pipe                                ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            if [ -n "${CLAUDE_PID:-}" ]; then
                kill -TERM "$CLAUDE_PID" 2>/dev/null || true
            fi
            exit 0
            ;;

        restart)
            echo ""
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║ Restart command received via pipe                             ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Mode: resume"
            echo "Session ID: ${session_id:-<auto-detect>}"
            echo ""

            if [ -n "${CLAUDE_PID:-}" ]; then
                do_restart "resume" "$session_id"
            fi
            ;;

        compact)
            echo ""
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║ Compact command received via pipe                             ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Mode: compact"
            echo "Session ID: ${session_id:-<required>}"
            echo ""

            if [ -z "$session_id" ]; then
                echo "Error: Session ID required for compact mode"
                return 1
            fi

            if [ -n "${CLAUDE_PID:-}" ]; then
                do_restart "compact" "$session_id"
            fi
            ;;

        clear)
            echo ""
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║ Clear command received via pipe                               ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Mode: clear (fresh session)"
            echo ""

            if [ -n "${CLAUDE_PID:-}" ]; then
                do_restart "clear" ""
            fi
            ;;

        *)
            echo "Warning: Unknown command received via pipe: $cmd" >&2
            ;;
    esac
}

# Perform restart operation
do_restart() {
    local mode="$1"
    local session_id="$2"

    echo "Killing Claude (PID: $CLAUDE_PID)..."
    kill -TERM "$CLAUDE_PID" 2>/dev/null || true

    # Wait for Claude to exit
    local wait_count=0
    while kill -0 "$CLAUDE_PID" 2>/dev/null && [ $wait_count -lt 10 ]; do
        sleep 0.5
        wait_count=$((wait_count + 1))
    done

    # Force kill if still alive
    if kill -0 "$CLAUDE_PID" 2>/dev/null; then
        echo "Force killing Claude..."
        kill -9 "$CLAUDE_PID" 2>/dev/null || true
        sleep 0.5
    fi

    echo "Claude stopped."
    echo ""

    # Determine restart command
    case "$mode" in
        resume)
            if [ -n "$session_id" ]; then
                echo "Restarting with session resume: $session_id"
                RESTART_ARGS=("--resume" "$session_id")
            else
                echo "Restarting (will auto-detect latest session)..."
                RESTART_ARGS=()
            fi
            ;;

        compact)
            echo "Running context compaction..."
            run_compaction "$session_id"

            echo "Restarting with session resume: $session_id"
            RESTART_ARGS=("--resume" "$session_id")
            ;;

        clear)
            echo "Restarting with fresh session..."
            RESTART_ARGS=()
            ;;
    esac

    echo ""
    echo "─────────────────────────────────────────────────────────────────"
    echo ""

    # Exec into new Claude instance (replaces wrapper process)
    exec claude "${RESTART_ARGS[@]}" "$@"
}

# Run context compaction
run_compaction() {
    local session_id="$1"

    # Create temp file for compaction output
    local temp_output=$(mktemp)
    trap "rm -f $temp_output" RETURN

    echo ""

    # Run compaction in background
    (
        echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"/compact"}]}}'
        echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Concise summary:"}]}}'
    ) | timeout 300 claude -p --output-format=stream-json --input-format=stream-json --resume "$session_id" > "$temp_output" 2>&1 &

    local compact_pid=$!

    # Show progress timer on single line
    SECONDS=0
    while kill -0 $compact_pid 2>/dev/null; do
        printf "\rCompacting session... %02d:%02d" $((SECONDS/60)) $((SECONDS%60))
        sleep 1
    done

    # Check exit code
    set +e
    wait $compact_pid
    local exit_code=$?
    set -e

    printf "\r\033[K"  # Clear the progress line

    # Handle compaction errors
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "Warning: Compaction failed (exit code: $exit_code)"

        # Show error output if available
        if [ -s "$temp_output" ]; then
            echo ""
            echo "Error details:"
            cat "$temp_output"
        fi

        echo ""
        echo "Continuing with restart anyway..."
    else
        echo "Compaction complete."
    fi

    echo ""

    # Brief delay
    sleep 0.5
}

# Store original arguments for potential restart
ORIGINAL_ARGS=("$@")

# Determine claude command (allow override for testing)
CLAUDE_CMD="${CLAUDE_WRAPPER_CMD:-claude}"

# Run Claude with env vars set inline, capture its PID
# We use a subshell to get PID first, then set WRAPPER_PIPE in child env
(
    # Get our PID (this is Claude's PID)
    MYPID=$$
    PIPE="$PIPE_DIR/claude-${MYPID}.pipe"

    # Export for child process
    export WRAPPER_PIPE="$PIPE"
    export WRAPPER_PID="$MYPID"
    export CLAUDE_PID="$MYPID"

    # Execute the command
    exec $CLAUDE_CMD "$@"
) &

CLAUDE_PID=$!

# Create pipe and ready marker based on Claude PID
PIPE="$PIPE_DIR/claude-${CLAUDE_PID}.pipe"
READY_MARKER="$PIPE_DIR/claude-${CLAUDE_PID}.ready"

# Create the named pipe
mkfifo "$PIPE"

# Display info now that we have Claude PID
echo "Claude PID: $CLAUDE_PID"
echo "Control pipe: $PIPE"
echo "Commands: exit, restart, compact, clear"
echo ""

# Start pipe reader in background
(
    # Signal that reader is ready
    touch "$READY_MARKER"

    while true; do
        if [ -p "$PIPE" ]; then
            # Read command from pipe (format: "command [session_id]")
            if IFS= read -r line < "$PIPE"; then
                # Parse command and optional session ID
                read -r cmd session_id <<< "$line"
                handle_command "$cmd" "$session_id"
            fi
        else
            # Pipe was removed, exit reader
            break
        fi
    done
) &

READER_PID=$!

# Create session map directory and file
MAP_DIR="$PROJECT_DIR/.bitbot/.pid-session-map"
mkdir -p "$MAP_DIR"

# Wait for Claude to potentially create session map and start session
sleep 0.5

# Try to detect session ID from wrapper state file
# Note: session-start hook writes SESSION_ID to this file when Claude starts
# Format: SESSION_ID=<uuid>\nIS_RESUME=start|resume\nSTART_TIME=<timestamp>
WRAPPER_STATE="$RUNTIME_DIR/.wrapper-session-${CLAUDE_PID}.state"
SESSION_ID=""

# Wait up to 5 seconds for session state to be posted
for i in {1..10}; do
    if [ -f "$WRAPPER_STATE" ]; then
        source "$WRAPPER_STATE" 2>/dev/null || true
        if [ -n "${SESSION_ID:-}" ]; then
            echo "Detected session: $SESSION_ID"
            break
        fi
    fi
    sleep 0.5
done

# Start watchdog if enabled and session detected
if [ "${BITBOT_WATCHDOG:-true}" = "true" ] && [ -n "$SESSION_ID" ]; then
    # Watchdog script is in same directory as wrapper (mounted)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WATCHDOG_SCRIPT="$SCRIPT_DIR/watchdog.sh"
    if [ -x "$WATCHDOG_SCRIPT" ]; then
        echo "Starting watchdog monitor..."
        "$WATCHDOG_SCRIPT" "$CLAUDE_PID" "$SESSION_ID" &
        WATCHDOG_PID=$!
        echo ""
    fi
fi

# Wait for Claude to finish
wait $CLAUDE_PID
CLAUDE_EXIT=$?

# Stop watchdog if running
if [ -n "${WATCHDOG_PID:-}" ]; then
    kill "$WATCHDOG_PID" 2>/dev/null || true
fi

# Cleanup session map and state
rm -f "$MAP_DIR/$CLAUDE_PID.txt" 2>/dev/null || true
rm -f "$WRAPPER_STATE" 2>/dev/null || true

exit $CLAUDE_EXIT
