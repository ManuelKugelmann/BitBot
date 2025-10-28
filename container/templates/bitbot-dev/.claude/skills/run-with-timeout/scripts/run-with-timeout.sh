#!/usr/bin/env bash
#
# run-with-timeout - Run a command with timeout and capture output
#
# Usage:
#   run-with-timeout <seconds> <command> [args...]
#
# Example:
#   run-with-timeout 10 ./test-prerequisites.sh
#   run-with-timeout 30 bash test-script.sh

set -uo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <seconds> <command> [args...]"
    echo "Example: $0 10 ./test-script.sh"
    exit 1
fi

TIMEOUT="$1"
shift

# Run command with timeout
timeout "$TIMEOUT" "$@"
EXIT_CODE=$?

# Check exit code
if [[ $EXIT_CODE -eq 124 ]]; then
    echo ""
    echo "⏱️  Command timed out after ${TIMEOUT}s"
    exit 124
elif [[ $EXIT_CODE -ne 0 ]]; then
    echo ""
    echo "❌ Command failed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
fi

exit 0
