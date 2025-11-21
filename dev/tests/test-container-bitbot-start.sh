#!/bin/bash
# Test script for container BitBot start/resume commands
# Tests session management functionality
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Set BITBOT_HOME for tests
export BITBOT_HOME="$PROJECT_ROOT"

source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Test helper functions
run_test() {
    local test_name="$1"
    test_section "$test_name"
}

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up test environment..."
    # Kill any test tmux sessions
    tmux kill-session -t test-session 2>/dev/null || true
    tmux kill-session -t test-claude-session 2>/dev/null || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

test_suite_begin "Container BitBot Start/Resume Test Suite"

echo "Setting up test environment..."
cleanup
echo ""

# Test 1: Check bash syntax
run_test "Bash syntax check for main bitbot"
if bash -n "$PROJECT_ROOT/container/bitbot/bitbot"; then
    test_pass "Test passed"
else
    test_fail "Test" "Syntax errors in bitbot"
fi

run_test "Bash syntax check for default.sh"
if bash -n "$PROJECT_ROOT/container/bitbot/core/commands/default.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "Syntax errors in default.sh"
fi

run_test "Bash syntax check for start.sh"
if bash -n "$PROJECT_ROOT/container/bitbot/core/commands/start.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "Syntax errors in start.sh"
fi

run_test "Bash syntax check for resume.sh"
if bash -n "$PROJECT_ROOT/container/bitbot/core/commands/resume.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "Syntax errors in resume.sh"
fi

run_test "Bash syntax check for tmux-utils.sh"
if bash -n "$PROJECT_ROOT/container/bitbot/core/util/tmux-utils.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "Syntax errors in tmux-utils.sh"
fi

# Test 2: Source utilities without errors
run_test "Source helpers.sh"
if source "$PROJECT_ROOT/container/bitbot/core/util/helpers.sh" 2>/dev/null; then
    test_pass "Test passed"
else
    test_fail "Test" "Failed to source helpers.sh"
fi

run_test "Source tmux-utils.sh"
if source "$PROJECT_ROOT/container/bitbot/core/util/tmux-utils.sh" 2>/dev/null; then
    test_pass "Test passed"
else
    test_fail "Test" "Failed to source tmux-utils.sh"
fi

# Test 3: Test tmux utility functions
run_test "tmux_available function"
if command -v tmux &>/dev/null; then
    if tmux_available; then
        test_pass "Test passed"
    else
        test_fail "Test" "tmux_available returned false but tmux is installed"
    fi
else
    echo "  (Skipped: tmux not installed)"
    ((TOTAL_TESTS--))
fi

run_test "list_tmux_sessions function"
sessions=$(list_tmux_sessions)
if [[ $? -eq 0 ]] || [[ $? -eq 1 ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "list_tmux_sessions returned unexpected exit code"
fi

run_test "generate_session_name function"
session_name=$(generate_session_name)
if [[ "$session_name" =~ ^bitbot-[0-9]{8}-[0-9]{4}$ ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "Session name format incorrect: $session_name"
fi

# Test 4: Test session creation
if command -v tmux &>/dev/null; then
    run_test "Create test tmux session"
    if tmux new-session -d -s test-session bash; then
        test_pass "Test passed"
    else
        test_fail "Test" "Failed to create test session"
    fi

    run_test "session_exists function"
    if session_exists test-session; then
        test_pass "Test passed"
    else
        test_fail "Test" "session_exists failed for existing session"
    fi

    run_test "get_session_info function"
    info=$(get_session_info test-session)
    if [[ -n "$info" ]] && [[ "$info" =~ test-session ]]; then
        test_pass "Test passed"
    else
        test_fail "Test" "get_session_info returned invalid info: $info"
    fi

    run_test "count_sessions function"
    count=$(count_sessions)
    if [[ "$count" -ge 1 ]]; then
        test_pass "Test passed"
    else
        test_fail "Test" "count_sessions returned $count, expected >= 1"
    fi

    run_test "Kill test session"
    if tmux kill-session -t test-session; then
        test_pass "Test passed"
    else
        test_fail "Test" "Failed to kill test session"
    fi
fi

# Test 5: Check file permissions
run_test "start.sh is executable"
if [[ -x "$PROJECT_ROOT/container/bitbot/core/commands/start.sh" ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "start.sh is not executable"
fi

run_test "resume.sh is executable"
if [[ -x "$PROJECT_ROOT/container/bitbot/core/commands/resume.sh" ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "resume.sh is not executable"
fi

# Test 6: Check helper functions exist
run_test "Helper functions defined"
if declare -f command_exists &>/dev/null && \
   declare -f get_workspace &>/dev/null && \
   declare -f get_bitbot_mode &>/dev/null; then
    test_pass "Test passed"
else
    test_fail "Test" "Required helper functions not defined"
fi

# Test 7: Check global tmux config exists
run_test "Global tmux config exists"
if [[ -f "$PROJECT_ROOT/container/templates/bitbot-base/home/.tmux.conf" ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "tmux.conf not found in container/templates/bitbot-base/home/"
fi

run_test "Global tmux config has required settings"
if grep -q "set -g mouse on" "$PROJECT_ROOT/container/templates/bitbot-base/home/.tmux.conf" && \
   grep -q "set -g status on" "$PROJECT_ROOT/container/templates/bitbot-base/home/.tmux.conf" && \
   grep -q "set -g history-limit 10000" "$PROJECT_ROOT/container/templates/bitbot-base/home/.tmux.conf" && \
   grep -q "BITBOT_PROJECT_PATH" "$PROJECT_ROOT/container/templates/bitbot-base/home/.tmux.conf"; then
    test_pass "Test passed"
else
    test_fail "Test" "container/templates/bitbot-base/home/.tmux.conf missing required settings"
fi

# Test 8: Check Dockerfiles DON'T bake tmux config (uses global mount instead)
run_test "Base Dockerfile doesn't bake tmux config"
if ! grep -q "tmux.conf" container/templates/bitbot-base/.devcontainer/Dockerfile; then
    test_pass "Test passed"
else
    test_fail "Test" "Base Dockerfile shouldn't bake tmux.conf (uses global mount)"
fi

run_test "Config Dockerfile doesn't bake tmux config"
if ! grep -q "tmux.conf" container/templates/bitbot-config/.devcontainer/Dockerfile; then
    test_pass "Test passed"
else
    test_fail "Test" "Config Dockerfile shouldn't bake tmux.conf (uses global mount)"
fi

# Test 9: Check command behavior
run_test "Default command (no args) routes to default.sh"
if grep -q 'core/commands/default.sh' "$PROJECT_ROOT/container/bitbot/bitbot"; then
    test_pass "Test passed"
else
    test_fail "Test" "Default command doesn't route to default.sh"
fi

run_test "default.sh has smart session detection"
if grep -q "prompt_resume_or_new\|show_launch_mode_choice" "$PROJECT_ROOT/container/bitbot/core/commands/default.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "default.sh missing resume/launch mode prompts"
fi

run_test "Start command creates fresh session (no prompts)"
if ! grep -q "prompt_resume_or_new\|show_launch_mode_choice" "$PROJECT_ROOT/container/bitbot/core/commands/start.sh"; then
    test_pass "Test passed"
else
    test_fail "Test" "start.sh still contains resume/launch mode prompts"
fi

run_test "default.sh is executable"
if [[ -x "$PROJECT_ROOT/container/bitbot/core/commands/default.sh" ]]; then
    test_pass "Test passed"
else
    test_fail "Test" "default.sh is not executable"
fi

# Test Suite Complete
test_suite_end
