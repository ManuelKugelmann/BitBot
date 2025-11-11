#!/usr/bin/env bash
#
# BitBot Init Interactive Test
# Tests the interactive prompt for config mode using tmux
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BITBOT_CMD="${BITBOT_ROOT}/core/bitbot"

# Source tmux test helper
source "${SCRIPT_DIR}/helpers/tmux-test-helper.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0

test_passed() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} ${test_name}"
    passed_tests=$((passed_tests + 1))
    total_tests=$((total_tests + 1))
}

test_failed() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason: ${reason}${NC}"
    fi
    failed_tests=$((failed_tests + 1))
    total_tests=$((total_tests + 1))
}

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   BitBot Init Interactive Test        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if tmux is available
if ! command -v tmux &>/dev/null; then
    echo -e "${YELLOW}⚠ tmux not available, skipping interactive tests${NC}"
    exit 0
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
    test_passed "Interactive prompt appeared"

    # Send 'n' to decline
    tmux_test_send_keys "$SESSION_NAME" "n"
    tmux_test_send_enter "$SESSION_NAME"

    # Wait for completion
    if tmux_test_wait_finish "$SESSION_NAME" 5; then
        test_passed "Command completed after declining"

        # Check workspace was created
        if [[ -f ".devcontainer/devcontainer.json" ]]; then
            test_passed "Workspace structure created"
        else
            test_failed "Workspace structure not created"
        fi
    else
        test_failed "Command did not complete"
    fi
else
    test_failed "Interactive prompt did not appear"
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
    test_passed "Interactive prompt appeared"

    # Send 'y' to accept
    tmux_test_send_keys "$SESSION_NAME" "y"
    tmux_test_send_enter "$SESSION_NAME"

    # Wait a moment for config mode to attempt to start
    sleep 2

    # Capture output
    output=$(tmux_test_capture "$SESSION_NAME")

    # Check if config mode was attempted
    if echo "$output" | grep -q "Launching config mode\|Building and starting config"; then
        test_passed "Config mode launch attempted"
    else
        test_failed "Config mode launch not attempted"
    fi

    # Workspace should still be created
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        test_passed "Workspace structure created"
    else
        test_failed "Workspace structure not created"
    fi
else
    test_failed "Interactive prompt did not appear"
fi

tmux_test_kill "$SESSION_NAME"

# Clean up
cd /tmp
rm -rf "$TEST_WORKSPACE"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Test Suite Summary            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total:   ${BLUE}${total_tests}${NC}"
echo -e "  Passed:  ${GREEN}${passed_tests}${NC}"
echo -e "  Failed:  ${RED}${failed_tests}${NC}"
echo ""

# Final result
if [[ $failed_tests -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ALL TESTS PASSED! ✓                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     SOME TESTS FAILED ✗                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
