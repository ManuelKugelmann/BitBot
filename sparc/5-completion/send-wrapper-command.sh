#!/usr/bin/env bash
# send-wrapper-command.sh - Send control commands to claude-wrapper.sh
#
# Usage: send-wrapper-command.sh <command> [session-id]
#
# Commands:
#   exit     - Exit Claude gracefully
#   restart  - Restart Claude (resume mode)
#   compact  - Compact context and restart Claude (requires session-id)
#   clear    - Restart Claude with fresh session
#
# Examples:
#   send-wrapper-command.sh exit
#   send-wrapper-command.sh restart
#   send-wrapper-command.sh restart 3e963c73-bb1d-45df-a97b-a3f4880038f1
#   send-wrapper-command.sh compact 3e963c73-bb1d-45df-a97b-a3f4880038f1
#   send-wrapper-command.sh clear

set -euo pipefail

# Validate arguments
if [ $# -lt 1 ]; then
    echo "Error: Command required"
    echo "Usage: send-wrapper-command.sh <command> [session-id]"
    echo ""
    echo "Commands: exit, restart, compact, clear"
    exit 1
fi

COMMAND="$1"
SESSION_ID="${2:-}"

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
if [ "$COMMAND" = "compact" ] && [ -z "$SESSION_ID" ]; then
    echo "Error: Session ID required for compact command"
    echo "Usage: send-wrapper-command.sh compact <session-id>"
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

# Send command to wrapper
echo "$COMMAND $SESSION_ID" > "$WRAPPER_PIPE"

# Small delay to allow wrapper to process
sleep 0.1

exit 0
