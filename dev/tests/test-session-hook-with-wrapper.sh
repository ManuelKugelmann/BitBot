#!/usr/bin/env bash
# Test session-start hook WITH wrapper pipe
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/test-framework.sh"

test_suite_begin "Session Hook With Wrapper Pipe"

# Setup mock environment
TEST_DIR="/tmp/bitbot-wrapper-test-$$"
mkdir -p "$TEST_DIR/.bitbot/tmp/pipes"

export CLAUDE_ENV_FILE="$TEST_DIR/claude-env"
export PROJECT_ROOT="$TEST_DIR"

MOCK_PID=99999
PIPE="$TEST_DIR/.bitbot/tmp/pipes/claude-${MOCK_PID}.pipe"
mkfifo "$PIPE"
export WRAPPER_PIPE="$PIPE"

# Cleanup
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo "Created wrapper pipe: $PIPE"
echo ""

# Start pipe reader (simulates wrapper)
(
    if IFS= read -r line < "$PIPE"; then
        read -r cmd session_id <<< "$line"
        echo "Wrapper: Received command='$cmd' session_id='$session_id'"

        if [ "$cmd" = "session" ] && [ "$session_id" = "test-session-67890" ]; then
            echo "Wrapper received correct session ID via pipe"
            exit 0
        else
            echo "Wrapper received unexpected data"
            exit 1
        fi
    fi
) &
READER_PID=$!

sleep 0.5

# Run hook WITH WRAPPER_PIPE set
echo "Running hook with WRAPPER_PIPE set..."
MOCK_JSON='{"session_id":"test-session-67890","is_resume":true}'
echo "$MOCK_JSON" | .bitbot/hooks/session-start.sh

echo ""

# Wait for reader
wait $READER_PID
READER_EXIT=$?

# Verify environment export
if grep -q "CLAUDE_SESSION_ID='test-session-67890'" "$CLAUDE_ENV_FILE"; then
    test_pass "Session ID exported to CLAUDE_ENV_FILE"
else
    test_fail "Session ID exported to CLAUDE_ENV_FILE"
fi

# Verify no state files created
STATE_FILES=$(find "$TEST_DIR" -name ".wrapper-session-*.state" 2>/dev/null || true)
if [ -n "$STATE_FILES" ]; then
    test_fail "No state files created (should only use pipe)"
else
    test_pass "No state files created (correct - using pipe instead)"
fi

if [ $READER_EXIT -eq 0 ]; then
    test_pass "Wrapper received session ID via pipe"
else
    test_fail "Wrapper received session ID via pipe"
fi

test_suite_end
