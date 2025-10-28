#!/usr/bin/env bash
# watchdog.sh - Monitor Claude process health and restart if stalled
#
# Monitors:
#   - Process existence and responsiveness
#   - CPU load (detect infinite loops or hangs - Type A)
#   - Session file activity (detect API stalls - Type B)
#   - I/O deadlock (detect uninterruptible sleep - Type C)
#
# Usage: watchdog.sh <claude-pid> <session-id>

set -euo pipefail

# Configuration
CHECK_INTERVAL=30           # Check every 30 seconds
CPU_THRESHOLD=95            # Alert if CPU > 95% for extended period
HIGH_CPU_DURATION=300       # 5 minutes of high CPU = likely stalled (Type A)
LOW_CPU_THRESHOLD=5         # Consider idle if CPU < 5%
NO_ACTIVITY_TIMEOUT=600     # 10 minutes no session activity = stalled
SESSION_UPDATE_TIMEOUT=300  # 5 minutes no session file update = stalled
IO_BLOCK_DURATION=60        # 60 seconds in D state = I/O deadlock (Type C)

# Arguments
CLAUDE_PID="${1:-}"
SESSION_ID="${2:-}"

if [ -z "$CLAUDE_PID" ]; then
    echo "Error: Claude PID required"
    echo "Usage: watchdog.sh <claude-pid> [session-id]"
    exit 1
fi

# Find project root
find_project_root() {
    local dir="$PWD"
    local max_depth=10
    local depth=0

    while [ $depth -lt $max_depth ]; do
        if [ -d "$dir/.bitbot" ]; then
            echo "$dir"
            return 0
        fi

        if [ "$dir" = "/" ]; then
            break
        fi

        dir="$(dirname "$dir")"
        depth=$((depth + 1))
    done

    echo "$PWD"
    return 1
}

PROJECT_ROOT=$(find_project_root)
PIPE="$PROJECT_ROOT/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.pipe"
SESSION_DIR="$HOME/.config/Claude/sessions"
WATCHDOG_STATE="$PROJECT_ROOT/.bitbot/wrapper/.watchdog-${CLAUDE_PID}.state"

# State tracking
HIGH_CPU_START=0
LAST_SESSION_MTIME=0
LAST_PIPE_CHECK=0
IO_BLOCK_START=0
LAST_BLKIO_TICKS=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WATCHDOG[$CLAUDE_PID]: $*" >&2
}

# Check if process exists and get CPU usage
check_process_health() {
    if ! kill -0 "$CLAUDE_PID" 2>/dev/null; then
        log "Process not found - Claude has exited"
        return 2  # Process dead
    fi

    # Get CPU usage (percentage)
    local cpu_usage=$(ps -p "$CLAUDE_PID" -o %cpu= 2>/dev/null | tr -d ' ' | cut -d. -f1)

    if [ -z "$cpu_usage" ]; then
        log "Cannot read CPU usage - process may have just exited"
        return 2
    fi

    echo "$cpu_usage"
    return 0
}

# Check session file activity
check_session_activity() {
    if [ -z "$SESSION_ID" ]; then
        return 0  # No session to check
    fi

    local session_file="$SESSION_DIR/$SESSION_ID"

    if [ ! -f "$session_file" ]; then
        log "Session file not found: $session_file"
        return 1
    fi

    # Get last modification time
    local mtime=$(stat -c %Y "$session_file" 2>/dev/null || stat -f %m "$session_file" 2>/dev/null)
    local now=$(date +%s)
    local age=$((now - mtime))

    echo "$age"
    return 0
}

# Check if wrapper pipe is responsive
check_pipe_health() {
    if [ ! -p "$PIPE" ]; then
        log "Control pipe missing: $PIPE"
        return 1
    fi

    # Try to check if pipe is readable (non-blocking)
    if timeout 1 test -p "$PIPE" 2>/dev/null; then
        return 0
    else
        log "Pipe appears to be blocked or unreadable"
        return 1
    fi
}

# Check for I/O deadlock (Type C stall)
check_io_deadlock() {
    # Check process state from /proc/PID/stat (field 3)
    local stat_data
    stat_data=$(cat /proc/$CLAUDE_PID/stat 2>/dev/null) || return 1

    local state=$(echo "$stat_data" | awk '{print $3}')

    # D state = uninterruptible sleep (usually I/O wait)
    if [ "$state" = "D" ]; then
        # Get wchan (wait channel) to see what kernel function is blocking
        local wchan=$(cat /proc/$CLAUDE_PID/wchan 2>/dev/null)

        # Get block I/O delay ticks (field 42)
        local blkio_ticks=$(echo "$stat_data" | awk '{print $42}')

        # Log details
        log "Process in D state (I/O wait), wchan: ${wchan:-unknown}, blkio_ticks: ${blkio_ticks:-0}"

        # Check for problematic wchan patterns
        case "$wchan" in
            *rpc_wait*|*io_schedule*|*wait_on_page*|*sync_buffer*)
                log "Detected problematic I/O wait pattern: $wchan"
                ;;
        esac

        # Track block I/O activity
        if [ "${LAST_BLKIO_TICKS:-0}" -gt 0 ]; then
            local blkio_delta=$((blkio_ticks - LAST_BLKIO_TICKS))
            if [ $blkio_delta -gt 100 ]; then
                log "Significant I/O delay: +${blkio_delta} ticks"
            fi
        fi
        LAST_BLKIO_TICKS=$blkio_ticks

        echo "D:$wchan"
        return 0
    else
        # Not in D state
        echo "$state"
        return 1
    fi
}

# Send restart command to wrapper
trigger_restart() {
    local reason="$1"

    log "STALL DETECTED: $reason"
    log "Triggering restart via pipe..."

    if [ -p "$PIPE" ]; then
        if [ -n "$SESSION_ID" ]; then
            echo "restart $SESSION_ID" > "$PIPE" 2>/dev/null || {
                log "Failed to write to pipe - wrapper may be dead"
                return 1
            }
        else
            echo "restart" > "$PIPE" 2>/dev/null || {
                log "Failed to write to pipe - wrapper may be dead"
                return 1
            }
        fi
        log "Restart command sent successfully"
        return 0
    else
        log "Control pipe not available - cannot restart"
        return 1
    fi
}

# Main monitoring loop
monitor() {
    log "Starting watchdog for Claude PID $CLAUDE_PID"
    if [ -n "$SESSION_ID" ]; then
        log "Monitoring session: $SESSION_ID"
    fi
    log "Check interval: ${CHECK_INTERVAL}s"

    while true; do
        sleep "$CHECK_INTERVAL"

        # Check 1: Process health and CPU
        cpu_usage=$(check_process_health)
        process_status=$?

        if [ $process_status -eq 2 ]; then
            log "Claude process has exited - stopping watchdog"
            rm -f "$WATCHDOG_STATE"
            exit 0
        fi

        # Detect sustained high CPU (possible infinite loop)
        local now=$(date +%s)
        if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
            if [ $HIGH_CPU_START -eq 0 ]; then
                HIGH_CPU_START=$now
                log "High CPU detected: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
            else
                local high_cpu_duration=$((now - HIGH_CPU_START))
                if [ $high_cpu_duration -gt $HIGH_CPU_DURATION ]; then
                    trigger_restart "Sustained high CPU (${cpu_usage}%) for ${high_cpu_duration}s"
                    exit 0
                fi
            fi
        else
            if [ $HIGH_CPU_START -ne 0 ]; then
                log "CPU usage normalized: ${cpu_usage}%"
            fi
            HIGH_CPU_START=0
        fi

        # Check 2: Session activity (if session ID provided)
        if [ -n "$SESSION_ID" ]; then
            session_age=$(check_session_activity)
            if [ $? -eq 0 ] && [ "$session_age" -gt "$SESSION_UPDATE_TIMEOUT" ]; then
                log "Session file not updated for ${session_age}s (threshold: ${SESSION_UPDATE_TIMEOUT}s)"
                # This is a warning, not necessarily a stall
                # Claude might be thinking or waiting for user input
            fi
        fi

        # Check 3: I/O deadlock detection (Type C)
        io_state=$(check_io_deadlock)
        io_check_status=$?

        if [ $io_check_status -eq 0 ]; then
            # Process is in D state
            if [ $IO_BLOCK_START -eq 0 ]; then
                IO_BLOCK_START=$now
                log "I/O block detected: $io_state"
            else
                local io_block_duration=$((now - IO_BLOCK_START))
                if [ $io_block_duration -gt $IO_BLOCK_DURATION ]; then
                    trigger_restart "I/O deadlock detected (D state for ${io_block_duration}s): $io_state"
                    exit 0
                fi
            fi
        else
            # Not in D state anymore
            if [ $IO_BLOCK_START -ne 0 ]; then
                log "I/O block cleared"
            fi
            IO_BLOCK_START=0
        fi

        # Check 4: Pipe health (every 5 checks)
        LAST_PIPE_CHECK=$((LAST_PIPE_CHECK + 1))
        if [ $((LAST_PIPE_CHECK % 5)) -eq 0 ]; then
            if ! check_pipe_health; then
                log "Warning: Pipe health check failed"
            fi
        fi

        # Save state
        echo "last_check=$now" > "$WATCHDOG_STATE"
        echo "cpu_usage=$cpu_usage" >> "$WATCHDOG_STATE"
        echo "high_cpu_start=$HIGH_CPU_START" >> "$WATCHDOG_STATE"
        echo "io_block_start=$IO_BLOCK_START" >> "$WATCHDOG_STATE"
        echo "last_blkio_ticks=$LAST_BLKIO_TICKS" >> "$WATCHDOG_STATE"
    done
}

# Cleanup on exit
cleanup() {
    log "Watchdog stopping"
    rm -f "$WATCHDOG_STATE"
}

trap cleanup EXIT INT TERM

# Start monitoring
monitor
