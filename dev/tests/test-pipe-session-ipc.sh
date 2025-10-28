#!/usr/bin/env bash
# Test pipe-based session IPC between session-start hook and wrapper
set -euo pipefail

echo "=== Testing Pipe-Based Session IPC ==="
echo ""

# Test setup
TEST_DIR="/tmp/bitbot-pipe-test-$$"
mkdir -p "$TEST_DIR"
PROJECT_ROOT="$TEST_DIR"
RUNTIME_DIR="$TEST_DIR/.bitbot/tmp"
mkdir -p "$RUNTIME_DIR/pipes"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Simulate wrapper creating pipe
MOCK_PID=12345
PIPE="$RUNTIME_DIR/pipes/claude-${MOCK_PID}.pipe"
mkfifo "$PIPE"

echo "✓ Created test pipe: $PIPE"
echo ""

# Start pipe reader in background (simulates wrapper)
(
    echo "Pipe reader: Waiting for messages..."
    while IFS= read -r line < "$PIPE"; do
        read -r cmd session_id <<< "$line"
        echo "Pipe reader: Received command='$cmd' session_id='$session_id'"

        if [ "$cmd" = "session" ]; then
            echo "✓ SUCCESS: Received session ID via pipe: $session_id"
            exit 0
        fi
    done
) &
READER_PID=$!

sleep 0.5

# Simulate session-start hook sending session ID
echo "Session hook: Sending session ID via pipe..."
TEST_SESSION_ID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

if [ -p "$PIPE" ]; then
    echo "session $TEST_SESSION_ID" > "$PIPE"
    echo "✓ Sent 'session $TEST_SESSION_ID' to pipe"
else
    echo "✗ FAIL: Pipe doesn't exist"
    exit 1
fi

# Wait for reader to process
sleep 1

# Check if reader got the message
if kill -0 $READER_PID 2>/dev/null; then
    echo "✗ FAIL: Pipe reader still running (didn't receive message)"
    kill $READER_PID 2>/dev/null || true
    exit 1
fi

wait $READER_PID
READER_EXIT=$?

echo ""
if [ $READER_EXIT -eq 0 ]; then
    echo "=== TEST PASSED ==="
    echo "Session ID successfully communicated via pipe (no state files needed)"
else
    echo "=== TEST FAILED ==="
    exit 1
fi
