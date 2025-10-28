#!/bin/bash
# Test script for container BitBot start/resume commands
# Tests session management functionality

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test helper functions
run_test() {
    local test_name="$1"
    echo -e "\n${BLUE}Testing: ${test_name}${RESET}"
    ((TOTAL_TESTS++))
}

test_passed() {
    echo -e "${GREEN}✓ PASS${RESET}"
    ((PASSED_TESTS++))
}

test_failed() {
    local reason="$1"
    echo -e "${RED}✗ FAIL: ${reason}${RESET}"
    ((FAILED_TESTS++))
}

# Cleanup function
cleanup() {
    echo -e "\n${BLUE}Cleaning up test environment...${RESET}"
    # Kill any test tmux sessions
    tmux kill-session -t test-session 2>/dev/null || true
    tmux kill-session -t test-claude-session 2>/dev/null || true
}

# Set up test environment
setup() {
    echo -e "${BLUE}Setting up test environment...${RESET}"
    cleanup
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

echo "=========================================="
echo "Container BitBot Start/Resume Test Suite"
echo "=========================================="

setup

# Test 1: Check bash syntax
run_test "Bash syntax check for main bitbot"
if bash -n container/bitbot/bitbot; then
    test_passed
else
    test_failed "Syntax errors in bitbot"
fi

run_test "Bash syntax check for default.sh"
if bash -n container/bitbot/core/commands/default.sh; then
    test_passed
else
    test_failed "Syntax errors in default.sh"
fi

run_test "Bash syntax check for start.sh"
if bash -n container/bitbot/core/commands/start.sh; then
    test_passed
else
    test_failed "Syntax errors in start.sh"
fi

run_test "Bash syntax check for resume.sh"
if bash -n container/bitbot/core/commands/resume.sh; then
    test_passed
else
    test_failed "Syntax errors in resume.sh"
fi

run_test "Bash syntax check for tmux-utils.sh"
if bash -n container/bitbot/core/util/tmux-utils.sh; then
    test_passed
else
    test_failed "Syntax errors in tmux-utils.sh"
fi

# Test 2: Source utilities without errors
run_test "Source helpers.sh"
if source container/bitbot/core/util/helpers.sh 2>/dev/null; then
    test_passed
else
    test_failed "Failed to source helpers.sh"
fi

run_test "Source tmux-utils.sh"
if source container/bitbot/core/util/tmux-utils.sh 2>/dev/null; then
    test_passed
else
    test_failed "Failed to source tmux-utils.sh"
fi

# Test 3: Test tmux utility functions
run_test "tmux_available function"
if command -v tmux &>/dev/null; then
    if tmux_available; then
        test_passed
    else
        test_failed "tmux_available returned false but tmux is installed"
    fi
else
    echo "  (Skipped: tmux not installed)"
    ((TOTAL_TESTS--))
fi

run_test "list_tmux_sessions function"
sessions=$(list_tmux_sessions)
if [[ $? -eq 0 ]] || [[ $? -eq 1 ]]; then
    test_passed
else
    test_failed "list_tmux_sessions returned unexpected exit code"
fi

run_test "generate_session_name function"
session_name=$(generate_session_name)
if [[ "$session_name" =~ ^bitbot-[0-9]{8}-[0-9]{4}$ ]]; then
    test_passed
else
    test_failed "Session name format incorrect: $session_name"
fi

# Test 4: Test session creation
if command -v tmux &>/dev/null; then
    run_test "Create test tmux session"
    if tmux new-session -d -s test-session bash; then
        test_passed
    else
        test_failed "Failed to create test session"
    fi

    run_test "session_exists function"
    if session_exists test-session; then
        test_passed
    else
        test_failed "session_exists failed for existing session"
    fi

    run_test "get_session_info function"
    info=$(get_session_info test-session)
    if [[ -n "$info" ]] && [[ "$info" =~ test-session ]]; then
        test_passed
    else
        test_failed "get_session_info returned invalid info: $info"
    fi

    run_test "count_sessions function"
    count=$(count_sessions)
    if [[ "$count" -ge 1 ]]; then
        test_passed
    else
        test_failed "count_sessions returned $count, expected >= 1"
    fi

    run_test "Kill test session"
    if tmux kill-session -t test-session; then
        test_passed
    else
        test_failed "Failed to kill test session"
    fi
fi

# Test 5: Check file permissions
run_test "start.sh is executable"
if [[ -x container/bitbot/core/commands/start.sh ]]; then
    test_passed
else
    test_failed "start.sh is not executable"
fi

run_test "resume.sh is executable"
if [[ -x container/bitbot/core/commands/resume.sh ]]; then
    test_passed
else
    test_failed "resume.sh is not executable"
fi

# Test 6: Check helper functions exist
run_test "Helper functions defined"
if declare -f command_exists &>/dev/null && \
   declare -f get_workspace &>/dev/null && \
   declare -f get_bitbot_mode &>/dev/null; then
    test_passed
else
    test_failed "Required helper functions not defined"
fi

# Test 7: Check global tmux config exists
run_test "Global tmux config exists"
if [[ -f container/home/.tmux.conf ]]; then
    test_passed
else
    test_failed "tmux.conf not found in container/home/"
fi

run_test "Global tmux config has required settings"
if grep -q "set -g mouse on" container/home/.tmux.conf && \
   grep -q "set -g status on" container/home/.tmux.conf && \
   grep -q "set -g history-limit 10000" container/home/.tmux.conf && \
   grep -q "BITBOT_PROJECT_PATH" container/home/.tmux.conf; then
    test_passed
else
    test_failed "container/home/.tmux.conf missing required settings"
fi

# Test 8: Check Dockerfiles DON'T bake tmux config (uses global mount instead)
run_test "Base Dockerfile doesn't bake tmux config"
if ! grep -q "tmux.conf" container/templates/bitbot-base/Dockerfile; then
    test_passed
else
    test_failed "Base Dockerfile shouldn't bake tmux.conf (uses global mount)"
fi

run_test "Config Dockerfile doesn't bake tmux config"
if ! grep -q "tmux.conf" container/templates/bitbot-config/Dockerfile; then
    test_passed
else
    test_failed "Config Dockerfile shouldn't bake tmux.conf (uses global mount)"
fi

# Test 9: Check command behavior
run_test "Default command (no args) routes to default.sh"
if grep -q 'core/commands/default.sh' container/bitbot/bitbot; then
    test_passed
else
    test_failed "Default command doesn't route to default.sh"
fi

run_test "default.sh has smart session detection"
if grep -q "prompt_resume_or_new\|show_launch_mode_choice" container/bitbot/core/commands/default.sh; then
    test_passed
else
    test_failed "default.sh missing resume/launch mode prompts"
fi

run_test "Start command creates fresh session (no prompts)"
if ! grep -q "prompt_resume_or_new\|show_launch_mode_choice" container/bitbot/core/commands/start.sh; then
    test_passed
else
    test_failed "start.sh still contains resume/launch mode prompts"
fi

run_test "default.sh is executable"
if [[ -x container/bitbot/core/commands/default.sh ]]; then
    test_passed
else
    test_failed "default.sh is not executable"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
else
    echo "Failed:       $FAILED_TESTS"
fi
echo "=========================================="

# Exit code
if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}Some tests failed!${RESET}"
    exit 1
fi
