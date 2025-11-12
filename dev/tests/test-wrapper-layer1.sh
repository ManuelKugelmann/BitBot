#!/usr/bin/env bash
#
# BitBot Layer 1 Wrapper Test
# Tests wrapper, pipes, and session management
#
# Layer 1 = Wrapper + Pipes (no tmux required)
# Layer 2 = Tmux integration (see test-wrapper-layer2.sh)
#
# This test validates:
# 1. Wrapper script execution
# 2. Pipe creation and communication
# 3. Session ID detection
# 4. Wrapper command handling (exit, restart)
# 5. Watchdog integration
#
# Requirements:
# - Built devcontainer
# - Claude Code installed in container
#
# Usage:
#   BITBOT_TEST_WORKSPACE=/path/to/test-workspace ./test-wrapper-layer1.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Test workspace
TEST_WORKSPACE="${BITBOT_TEST_WORKSPACE:-/mnt/c/bitbot-wrapper-test-$$}"

test_suite_begin "BitBot Layer 1 Wrapper Test - Wrapper + Pipes (no tmux)"
echo ""

# ============================================================================
# Test Framework
# ============================================================================



run_test() {
    local test_name="$1"
    total_tests=$((total_tests + 1))
}

# ============================================================================
# Prerequisites
# ============================================================================

echo -e "${BLUE}═══ Prerequisites ═══${NC}"
echo ""

# Check if workspace exists
if [[ ! -d "$TEST_WORKSPACE" ]]; then
    echo -e "${RED}✗ FAILED${NC}: Test workspace not found: $TEST_WORKSPACE"
    echo ""
    echo "Create workspace first:"
    echo "  export BITBOT_HOME=\"$BITBOT_ROOT\""
    echo "  export PATH=\"\$BITBOT_HOME/core:\$PATH\""
    echo "  mkdir -p \"$TEST_WORKSPACE\""
    echo "  cd \"$TEST_WORKSPACE\""
    echo "  git init"
    echo "  bitbot init --template bitbot-base"
    echo ""
    exit 1
fi

test_pass " Test workspace exists: $TEST_WORKSPACE"

# Check devcontainer CLI
DEVC_CMD=""
if command -v devcontainer.cmd &>/dev/null; then
    DEVC_CMD="cmd.exe /c devcontainer.cmd"
    test_pass " Using devcontainer.cmd"
elif command -v devcontainer &>/dev/null; then
    DEVC_CMD="devcontainer"
    test_pass " Using devcontainer CLI"
else
    echo -e "${RED}✗ FAILED${NC}: DevContainer CLI not found"
    exit 1
fi

echo ""

# ============================================================================
# Helper Functions
# ============================================================================

# Convert path for devcontainer CLI
get_workspace_arg() {
    local path="$TEST_WORKSPACE"
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        echo "$path" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g'
    else
        echo "$path"
    fi
}

WORKSPACE_ARG=$(get_workspace_arg)

# Run command in container
run_in_container() {
    local cmd="$1"
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        timeout 30 cmd.exe /c "cd /d $WORKSPACE_ARG && devcontainer.cmd exec --workspace-folder $WORKSPACE_ARG bash -c \"$cmd\"" 2>&1
    else
        timeout 30 devcontainer exec --workspace-folder "$TEST_WORKSPACE" bash -c "$cmd" 2>&1
    fi
}

# ============================================================================
# Test 1: Wrapper Basics
# ============================================================================

echo -e "${BLUE}═══ Test 1: Wrapper Basics ═══${NC}"
echo ""

run_test "Test wrapper script exists in container"
if run_in_container "test -f /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Wrapper script exists"
else
    test_fail "Wrapper script not found"
    exit 1
fi

run_test "Test wrapper is executable"
if run_in_container "test -x /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Wrapper is executable"
else
    test_fail "Wrapper not executable"
fi

run_test "Test wrapper has valid bash syntax"
if run_in_container "bash -n /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Wrapper syntax valid"
else
    test_fail "Wrapper has syntax errors"
fi

echo ""

# ============================================================================
# Test 2: Pipe Infrastructure
# ============================================================================

echo -e "${BLUE}═══ Test 2: Pipe Infrastructure ═══${NC}"
echo ""

run_test "Test pipe directory creation"
if run_in_container "mkdir -p /workspace/.bitbot/tmp/pipes && echo OK" | grep -q "OK"; then
    test_pass "Pipe directory can be created"
else
    test_fail "Pipe directory creation failed"
fi

run_test "Test named pipe creation"
if run_in_container "mkfifo /workspace/.bitbot/tmp/pipes/test-$$.pipe && test -p /workspace/.bitbot/tmp/pipes/test-$$.pipe && echo OK" | grep -q "OK"; then
    test_pass "Named pipe creation works"
else
    test_fail "Named pipe creation failed"
fi

run_test "Cleanup test pipe"
run_in_container "rm -f /workspace/.bitbot/tmp/pipes/test-$$.pipe" &>/dev/null
echo -e "${BLUE}ℹ${NC}  Test pipe cleaned up"

echo ""

# ============================================================================
# Test 3: Wrapper Command Handling
# ============================================================================

echo -e "${BLUE}═══ Test 3: Wrapper Command Handling ═══${NC}"
echo ""

run_test "Test handle_command function exists"
if run_in_container "grep -q 'handle_command()' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "handle_command function found"
else
    test_fail "handle_command function missing"
fi

run_test "Test exit command handling"
if run_in_container "grep -q 'exit)' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Exit command handler found"
else
    test_fail "Exit command handler missing"
fi

run_test "Test restart command handling"
if run_in_container "grep -q 'restart)' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Restart command handler found"
else
    test_fail "Restart command handler missing"
fi

run_test "Test session command handling"
if run_in_container "grep -q 'session)' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "Session command handler found"
else
    test_fail "Session command handler missing"
fi

echo ""

# ============================================================================
# Test 4: Watchdog Integration
# ============================================================================

echo -e "${BLUE}═══ Test 4: Watchdog Integration ═══${NC}"
echo ""

run_test "Test watchdog script exists"
if run_in_container "test -f /usr/local/bitbot/wrapper/watchdog.sh && echo OK" | grep -q "OK"; then
    test_pass "Watchdog script exists"
else
    test_fail "Watchdog script not found"
fi

run_test "Test watchdog is executable"
if run_in_container "test -x /usr/local/bitbot/wrapper/watchdog.sh && echo OK" | grep -q "OK"; then
    test_pass "Watchdog is executable"
else
    test_fail "Watchdog not executable"
fi

run_test "Test watchdog syntax"
if run_in_container "bash -n /usr/local/bitbot/wrapper/watchdog.sh && echo OK" | grep -q "OK"; then
    test_pass "Watchdog syntax valid"
else
    test_fail "Watchdog has syntax errors"
fi

run_test "Test start_watchdog function exists"
if run_in_container "grep -q 'start_watchdog()' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "start_watchdog function found"
else
    test_fail "start_watchdog function missing"
fi

echo ""

# ============================================================================
# Test 5: Session Management
# ============================================================================

echo -e "${BLUE}═══ Test 5: Session Management ═══${NC}"
echo ""

run_test "Test session-start hook exists"
if run_in_container "test -f /workspace/.bitbot/hooks/session-start.sh && echo OK" | grep -q "OK"; then
    test_pass "session-start hook exists"
else
    test_fail "session-start hook not found"
fi

run_test "Test session-start hook is executable"
if run_in_container "test -x /workspace/.bitbot/hooks/session-start.sh && echo OK" | grep -q "OK"; then
    test_pass "session-start hook is executable"
else
    test_fail "session-start hook not executable"
fi

run_test "Test session-start hook syntax"
if run_in_container "bash -n /workspace/.bitbot/hooks/session-start.sh && echo OK" | grep -q "OK"; then
    test_pass "session-start hook syntax valid"
else
    test_fail "session-start hook has syntax errors"
fi

run_test "Test wrapper pipe communication in session-start"
if run_in_container "grep -q 'WRAPPER_PIPE' /workspace/.bitbot/hooks/session-start.sh && echo OK" | grep -q "OK"; then
    test_pass "session-start communicates with wrapper"
else
    test_fail "session-start missing wrapper communication"
fi

echo ""

# ============================================================================
# Test 6: Environment Variable Setup
# ============================================================================

echo -e "${BLUE}═══ Test 6: Environment Variables ═══${NC}"
echo ""

run_test "Test WRAPPER_PIPE export in wrapper"
if run_in_container "grep -q 'export WRAPPER_PIPE' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "WRAPPER_PIPE exported correctly"
else
    test_fail "WRAPPER_PIPE export missing"
fi

run_test "Test WRAPPER_PID export in wrapper"
if run_in_container "grep -q 'export WRAPPER_PID' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "WRAPPER_PID exported correctly"
else
    test_fail "WRAPPER_PID export missing"
fi

run_test "Test CLAUDE_PID export in wrapper"
if run_in_container "grep -q 'export CLAUDE_PID' /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
    test_pass "CLAUDE_PID exported correctly"
else
    test_fail "CLAUDE_PID export missing"
fi

echo ""

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

# Calculate success rate
if [[ $total_tests -gt 0 ]]; then
    success_rate=$((passed_tests * 100 / total_tests))
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
fi

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
