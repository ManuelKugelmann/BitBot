#!/usr/bin/env bash
# send-wrapper-command.sh - Send control commands to claude-wrapper.sh
#
# Usage: send-wrapper-command.sh <command> [args...]
#
# Commands:
#   exit                         - Exit Claude gracefully
#   restart [session-id]         - Restart Claude (resume mode)
#   compact <session-id> [prompt] - Compact context and restart (with optional prompt)
#   clear                        - Restart Claude with fresh session
#
# Examples:
#   send-wrapper-command.sh exit
#   send-wrapper-command.sh restart
#   send-wrapper-command.sh restart abc-123
#   send-wrapper-command.sh compact abc-123
#   send-wrapper-command.sh compact abc-123 "Preserve TODO state and decisions"
#   send-wrapper-command.sh clear

set -euo pipefail

# Validate arguments
if [ $# -lt 1 ]; then
    echo "Error: Command required"
    echo "Usage: send-wrapper-command.sh <command> [args...]"
    echo ""
    echo "Commands: exit, restart, compact, clear"
    exit 1
fi

COMMAND="$1"
shift  # Remove command from $@, leaving only args

# Validate command
case "$COMMAND" in
    exit|restart|compact|clear)
        ;;
    *)
        echo "Error: Invalid command '$COMMAND'"
        echo "Valid commands: exit, restart, compact, clear"
        exit 1
        ;;
esac

# Validate session ID for compact command
if [ "$COMMAND" = "compact" ] && [ $# -lt 1 ]; then
    echo "Error: Session ID required for compact command"
    echo "Usage: send-wrapper-command.sh compact <session-id> [prompt]"
    exit 1
fi

# Check if wrapper pipe exists
if [ -z "${WRAPPER_PIPE:-}" ]; then
    echo "Error: WRAPPER_PIPE environment variable not set"
    echo "This script must be run from within claude-wrapper.sh"
    exit 1
fi

if [ ! -p "$WRAPPER_PIPE" ]; then
    echo "Error: Wrapper pipe does not exist: $WRAPPER_PIPE"
    echo "Wrapper may have exited"
    exit 1
fi

# Send command with all arguments to wrapper (newline-separated)
# Format: command arg1 arg2 arg3...
echo "$COMMAND $*" > "$WRAPPER_PIPE"

# Small delay to allow wrapper to process
sleep 0.1

exit 0
