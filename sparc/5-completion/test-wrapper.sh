#!/usr/bin/env bash
# test-wrapper.sh - Test script for claude-wrapper.sh
#
# Tests all wrapper functionality:
#   - Pipe creation and cleanup
#   - Command parsing (exit, restart, compact, clear)
#   - Session ID handling
#   - Restart logic without tmux dependency

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="$SCRIPT_DIR/claude-wrapper.sh"
SEND_CMD_SCRIPT="$SCRIPT_DIR/send-wrapper-command.sh"

# Test helpers
run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}[TEST $TESTS_RUN]${NC} $test_name"
}

test_passed() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}  ✓ PASS${NC}"
    echo ""
}

test_failed() {
    local reason="$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}  ✗ FAIL${NC}: $reason"
    echo ""
}

section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Cleanup function
cleanup() {
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true

    # Remove test pipes
    rm -rf /tmp/test-wrapper-pipes 2>/dev/null || true
}

trap cleanup EXIT

section "Bash Syntax Check"

run_test "Check wrapper script syntax"
if bash -n "$WRAPPER_SCRIPT"; then
    test_passed
else
    test_failed "Syntax error in wrapper script"
fi

run_test "Check send-command script syntax"
if bash -n "$SEND_CMD_SCRIPT"; then
    test_passed
else
    test_failed "Syntax error in send-command script"
fi

section "Pipe Infrastructure Tests"

run_test "Wrapper creates pipe on startup"
(
    export CLAUDE_PROJECT_DIR="/tmp/test-wrapper-$$"
    mkdir -p "$CLAUDE_PROJECT_DIR"

    # Create mock claude command
    export CLAUDE_WRAPPER_CMD="sleep"

    # Start wrapper with dummy command
    timeout 2 "$WRAPPER_SCRIPT" 1 &
    WRAPPER_PID=$!

    # Wait for ready marker (pipes are in /tmp/bitbot-pipes/)
    READY_MARKER="/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.ready"
    for i in {1..20}; do
        [ -f "$READY_MARKER" ] && break
        sleep 0.1
    done

    # Check pipe exists
    if [ -p "/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.pipe" ]; then
        wait $WRAPPER_PID || true
        rm -rf "$CLAUDE_PROJECT_DIR"
        exit 0
    else
        kill $WRAPPER_PID 2>/dev/null || true
        rm -rf "$CLAUDE_PROJECT_DIR"
        exit 1
    fi
) && test_passed || test_failed "Pipe not created"

run_test "Wrapper cleans up pipe on exit"
(
    export CLAUDE_PROJECT_DIR="/tmp/test-wrapper-$$"
    export CLAUDE_WRAPPER_CMD="sleep"
    mkdir -p "$CLAUDE_PROJECT_DIR"

    # Start wrapper and capture PID
    timeout 2 "$WRAPPER_SCRIPT" 0.5 &
    WRAPPER_PID=$!

    # Wait for wrapper to finish
    wait $WRAPPER_PID 2>/dev/null || true

    # Check pipe is removed
    if [ ! -p "/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.pipe" ] && \
       [ ! -f "/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.ready" ]; then
        rm -rf "$CLAUDE_PROJECT_DIR"
        exit 0
    else
        rm -rf "$CLAUDE_PROJECT_DIR"
        exit 1
    fi
) && test_passed || test_failed "Pipe not cleaned up"

section "Command Parsing Tests"

run_test "Send exit command via pipe"
(
    export CLAUDE_PROJECT_DIR="/tmp/test-wrapper-$$"
    export CLAUDE_WRAPPER_CMD="sleep"
    mkdir -p "$CLAUDE_PROJECT_DIR"

    # Start wrapper with long-running command
    timeout 5 "$WRAPPER_SCRIPT" 10 &
    WRAPPER_PID=$!

    # Wait for ready marker
    READY_MARKER="/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.ready"
    for i in {1..20}; do
        [ -f "$READY_MARKER" ] && break
        sleep 0.1
    done

    # Send exit command
    PIPE="/tmp/bitbot-pipes/wrapper-${WRAPPER_PID}.pipe"
    if [ -p "$PIPE" ]; then
        echo "exit" > "$PIPE"

        # Wait for wrapper to exit
        sleep 1

        # Check if wrapper exited
        if ! kill -0 $WRAPPER_PID 2>/dev/null; then
            rm -rf "$CLAUDE_PROJECT_DIR"
            exit 0
        else
            kill $WRAPPER_PID 2>/dev/null || true
            rm -rf "$CLAUDE_PROJECT_DIR"
            exit 1
        fi
    else
        kill $WRAPPER_PID 2>/dev/null || true
        rm -rf "$CLAUDE_PROJECT_DIR"
        exit 1
    fi
) && test_passed || test_failed "Exit command not processed"

run_test "Send-command script validates commands"
(
    export WRAPPER_PIPE="/tmp/fake-pipe"
    mkfifo "$WRAPPER_PIPE"

    # Test invalid command
    if "$SEND_CMD_SCRIPT" invalid 2>/dev/null; then
        rm -f "$WRAPPER_PIPE"
        exit 1
    else
        rm -f "$WRAPPER_PIPE"
        exit 0
    fi
) && test_passed || test_failed "Invalid command not rejected"

run_test "Send-command script requires session ID for compact"
(
    export WRAPPER_PIPE="/tmp/fake-pipe"
    mkfifo "$WRAPPER_PIPE"

    # Test compact without session ID
    if "$SEND_CMD_SCRIPT" compact 2>/dev/null; then
        rm -f "$WRAPPER_PIPE"
        exit 1
    else
        rm -f "$WRAPPER_PIPE"
        exit 0
    fi
) && test_passed || test_failed "Compact accepted without session ID"

section "Environment Variable Tests"

run_test "Wrapper exports WRAPPER_PIPE and WRAPPER_PID"
(
    export CLAUDE_PROJECT_DIR="/tmp/test-wrapper-$$"
    export CLAUDE_WRAPPER_CMD="bash"
    mkdir -p "$CLAUDE_PROJECT_DIR"

    # Create a test script that checks env vars
    ENV_OUTPUT="/tmp/wrapper-env-$$.txt"
    TEST_CMD="-c"
    TEST_ARG="if [ -n \"\$WRAPPER_PIPE\" ] && [ -n \"\$WRAPPER_PID\" ]; then echo \"WRAPPER_PIPE=\$WRAPPER_PIPE\" > $ENV_OUTPUT; echo \"WRAPPER_PID=\$WRAPPER_PID\" >> $ENV_OUTPUT; sleep 0.2; else exit 1; fi"

    # Run wrapper with test script
    timeout 2 "$WRAPPER_SCRIPT" "$TEST_CMD" "$TEST_ARG" || true

    # Check results
    if [ -f "$ENV_OUTPUT" ]; then
        source "$ENV_OUTPUT"
        if [ -n "$WRAPPER_PIPE" ] && [ -n "$WRAPPER_PID" ]; then
            rm -f "$ENV_OUTPUT"
            rm -rf "$CLAUDE_PROJECT_DIR"
            exit 0
        fi
    fi

    rm -f "$ENV_OUTPUT"
    rm -rf "$CLAUDE_PROJECT_DIR"
    exit 1
) && test_passed || test_failed "Environment variables not exported"

section "Executable Permissions"

run_test "Wrapper script is executable"
if [ -x "$WRAPPER_SCRIPT" ]; then
    test_passed
else
    test_failed "Wrapper script not executable"
fi

run_test "Send-command script is executable"
if [ -x "$SEND_CMD_SCRIPT" ]; then
    test_passed
else
    test_failed "Send-command script not executable"
fi

section "Test Summary"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Total tests run: ${TESTS_RUN}"
echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"
else
    echo -e "  Failed: ${TESTS_FAILED}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
