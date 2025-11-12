#!/usr/bin/env bash
# Test session-start hook when NOT running under wrapper
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/test-framework.sh"

test_suite_begin "Session Hook Without Wrapper"

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

if [ $EXIT_CODE -eq 0 ]; then
    test_pass "Hook executed successfully"

    # Check that environment was exported
    if grep -q "CLAUDE_SESSION_ID='test-session-12345'" "$CLAUDE_ENV_FILE"; then
        test_pass "Session ID exported to CLAUDE_ENV_FILE"
    else
        test_fail "Session ID exported to CLAUDE_ENV_FILE"
    fi

    # Verify no state files created
    if [ -d "$PROJECT_ROOT/.bitbot/tmp" ]; then
        STATE_FILES=$(find "$PROJECT_ROOT/.bitbot/tmp" -name ".wrapper-session-*.state" 2>/dev/null || true)
        if [ -n "$STATE_FILES" ]; then
            test_fail "No state files created (should use pipe, not state files)"
        else
            test_pass "No state files created (correct - using pipe or no wrapper)"
        fi
    else
        test_pass "No .bitbot/tmp directory created (correct for non-wrapper session)"
    fi
else
    test_fail "Hook execution" "Exit code: $EXIT_CODE"
fi

test_suite_end
