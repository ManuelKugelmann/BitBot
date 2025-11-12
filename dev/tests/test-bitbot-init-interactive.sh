#!/usr/bin/env bash
#
# BitBot Init Interactive Test
# Tests the interactive prompt for config mode using tmux
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BITBOT_CMD="${BITBOT_ROOT}/core/bitbot"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source tmux test helper
source "${SCRIPT_DIR}/helpers/tmux-test-helper.sh"

test_suite_begin "BitBot Init Interactive Test"

# Check if tmux is available
if ! command -v tmux &>/dev/null; then
    test_skip "All tests" "tmux not available"
    test_suite_end
fi

# Create test workspace
TEST_WORKSPACE="/tmp/bitbot-interactive-test-$$"
echo -e "${BLUE}[Setup]${NC} Creating test workspace: $TEST_WORKSPACE"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
git init -q
echo "test" > README.md

# Set BITBOT_HOME for tests
export BITBOT_HOME="$BITBOT_ROOT"

# Unset CI variables to enable interactive prompt
unset CI
unset GITHUB_ACTIONS

# ============================================================================
# Test 1: User declines config mode (answer 'n')
# ============================================================================

echo ""
echo -e "${BLUE}[Test 1]${NC} User declines config mode prompt"

SESSION_NAME="bitbot-test-decline-$$"

# Start bitbot init in tmux
tmux_test_start "$SESSION_NAME" "bash $BITBOT_CMD init"

# Wait for prompt
if tmux_test_wait_for "$SESSION_NAME" "Launch config mode?" 5; then
    test_pass "Interactive prompt appeared"

    # Send 'n' to decline
    tmux_test_send_keys "$SESSION_NAME" "n"
    tmux_test_send_enter "$SESSION_NAME"

    # Wait for completion
    if tmux_test_wait_finish "$SESSION_NAME" 5; then
        test_pass "Command completed after declining"

        # Check workspace was created
        if [[ -f ".devcontainer/devcontainer.json" ]]; then
            test_pass "Workspace structure created"
        else
            test_fail "Workspace structure not created"
        fi
    else
        test_fail "Command did not complete"
    fi
else
    test_fail "Interactive prompt did not appear"
fi

tmux_test_kill "$SESSION_NAME"

# Clean up test workspace
cd /tmp
rm -rf "$TEST_WORKSPACE"

# ============================================================================
# Test 2: User accepts config mode (answer 'y')
# ============================================================================

echo ""
echo -e "${BLUE}[Test 2]${NC} User accepts config mode prompt"

TEST_WORKSPACE="/tmp/bitbot-interactive-test-accept-$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
git init -q
echo "test" > README.md

SESSION_NAME="bitbot-test-accept-$$"

# Start bitbot init in tmux
tmux_test_start "$SESSION_NAME" "bash $BITBOT_CMD init"

# Wait for prompt
if tmux_test_wait_for "$SESSION_NAME" "Launch config mode?" 5; then
    test_pass "Interactive prompt appeared"

    # Send 'y' to accept
    tmux_test_send_keys "$SESSION_NAME" "y"
    tmux_test_send_enter "$SESSION_NAME"

    # Wait a moment for config mode to attempt to start
    sleep 2

    # Capture output
    output=$(tmux_test_capture "$SESSION_NAME")

    # Check if config mode was attempted
    if echo "$output" | grep -q "Launching config mode\|Building and starting config"; then
        test_pass "Config mode launch attempted"
    else
        test_fail "Config mode launch not attempted"
    fi

    # Workspace should still be created
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        test_pass "Workspace structure created"
    else
        test_fail "Workspace structure not created"
    fi
else
    test_fail "Interactive prompt did not appear"
fi

tmux_test_kill "$SESSION_NAME"

# Clean up
cd /tmp
rm -rf "$TEST_WORKSPACE"

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
