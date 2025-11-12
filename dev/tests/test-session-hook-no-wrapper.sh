#!/usr/bin/env bash
# Test session-start hook when NOT running under wrapper
set -euo pipefail

echo "=== Testing Session Hook Without Wrapper ==="
echo ""

# Setup mock environment
export CLAUDE_ENV_FILE="/tmp/test-claude-env-$$"
export PROJECT_ROOT="/tmp/test-project-$$"
mkdir -p "$PROJECT_ROOT"

# Cleanup
cleanup() {
    rm -f "$CLAUDE_ENV_FILE"
    rm -rf "$PROJECT_ROOT"
}
trap cleanup EXIT

# Simulate hook input (session-start JSON)
MOCK_JSON='{"session_id":"test-session-12345","is_resume":false}'

# Run hook WITHOUT WRAPPER_PIPE set
echo "Running hook without WRAPPER_PIPE (simulates direct Claude session)..."
echo "$MOCK_JSON" | .bitbot/hooks/session-start.sh

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Hook executed successfully"

    # Check that environment was exported
    if grep -q "CLAUDE_SESSION_ID='test-session-12345'" "$CLAUDE_ENV_FILE"; then
        echo "✓ Session ID exported to CLAUDE_ENV_FILE"
    else
        echo "✗ Session ID NOT exported"
        exit 1
    fi

    # Verify no state files created
    if [ -d "$PROJECT_ROOT/.bitbot/tmp" ]; then
        STATE_FILES=$(find "$PROJECT_ROOT/.bitbot/tmp" -name ".wrapper-session-*.state" 2>/dev/null || true)
        if [ -n "$STATE_FILES" ]; then
            echo "✗ FAIL: State files were created (should use pipe instead)"
            exit 1
        else
            echo "✓ No state files created (correct - using pipe or no wrapper)"
        fi
    else
        echo "✓ No .bitbot/tmp directory created (correct for non-wrapper session)"
    fi

    echo ""
    echo "=== TEST PASSED ==="
else
    echo "✗ Hook failed with exit code: $EXIT_CODE"
    exit 1
fi
