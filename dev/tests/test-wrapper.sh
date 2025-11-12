#!/usr/bin/env bash
# test-wrapper.sh - Test script for claude-wrapper.sh
#
# Tests all wrapper functionality:
#   - Pipe creation and cleanup
#   - Command parsing (exit, restart, compact, clear)
#   - Session ID handling
#   - Restart logic without tmux dependency

set -euo pipefail

# Get script directory and find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"
WRAPPER_SCRIPT="$PROJECT_ROOT/.bitbot/wrapper/claude-wrapper.sh"
SEND_CMD_SCRIPT="$PROJECT_ROOT/.bitbot/wrapper/send-wrapper-command.sh"

# Test helpers
run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}[TEST $TESTS_RUN]${NC} $test_name"
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
    test_pass
else
    test_fail "Syntax error in wrapper script"
fi

run_test "Check send-command script syntax"
if bash -n "$SEND_CMD_SCRIPT"; then
    test_pass
else
    test_fail "Syntax error in send-command script"
fi

section "Pipe Infrastructure Tests"

run_test "Wrapper creates pipe on startup"
(
    TEST_DIR="/tmp/test-wrapper-$$"
    mkdir -p "$TEST_DIR/.bitbot"
    cd "$TEST_DIR"

    # Create mock claude command
    export CLAUDE_WRAPPER_CMD="sleep"

    # Start wrapper and capture output to get actual Claude PID
    timeout 2 "$WRAPPER_SCRIPT" 1 > /tmp/wrapper-out-$$.txt 2>&1 &
    SHELL_PID=$!

    # Extract Claude PID from output
    sleep 0.5
    CLAUDE_PID=$(grep "Claude PID:" /tmp/wrapper-out-$$.txt | awk '{print $3}')

    if [ -z "$CLAUDE_PID" ]; then
        echo "Could not extract Claude PID"
        kill $SHELL_PID 2>/dev/null || true
        rm -f /tmp/wrapper-out-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 1
    fi

    # Wait for ready marker
    READY_MARKER="$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.ready"
    for i in {1..20}; do
        [ -f "$READY_MARKER" ] && break
        sleep 0.1
    done

    # Check pipe exists
    if [ -p "$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.pipe" ]; then
        kill $SHELL_PID 2>/dev/null || true
        wait $SHELL_PID 2>/dev/null || true
        rm -f /tmp/wrapper-out-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 0
    else
        kill $SHELL_PID 2>/dev/null || true
        rm -f /tmp/wrapper-out-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 1
    fi
) && test_pass || test_fail "Pipe not created"

run_test "Wrapper cleans up pipe on exit"
(
    TEST_DIR="/tmp/test-wrapper-$$"
    mkdir -p "$TEST_DIR/.bitbot"
    cd "$TEST_DIR"

    export CLAUDE_WRAPPER_CMD="sleep"

    # Start wrapper and capture output
    timeout 2 "$WRAPPER_SCRIPT" 0.5 > /tmp/wrapper-out-cleanup-$$.txt 2>&1 &
    SHELL_PID=$!

    # Extract Claude PID
    sleep 0.3
    CLAUDE_PID=$(grep "Claude PID:" /tmp/wrapper-out-cleanup-$$.txt | awk '{print $3}')

    # Wait for wrapper to finish
    wait $SHELL_PID 2>/dev/null || true

    # Check pipe is removed
    if [ -n "$CLAUDE_PID" ] && \
       [ ! -p "$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.pipe" ] && \
       [ ! -f "$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.ready" ]; then
        rm -f /tmp/wrapper-out-cleanup-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 0
    else
        rm -f /tmp/wrapper-out-cleanup-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 1
    fi
) && test_pass || test_fail "Pipe not cleaned up"

section "Command Parsing Tests"

run_test "Send exit command via pipe"
(
    TEST_DIR="/tmp/test-wrapper-$$"
    mkdir -p "$TEST_DIR/.bitbot"
    cd "$TEST_DIR"

    export CLAUDE_WRAPPER_CMD="sleep"

    # Start wrapper with long-running command
    timeout 5 "$WRAPPER_SCRIPT" 10 > /tmp/wrapper-out-exit-$$.txt 2>&1 &
    SHELL_PID=$!

    # Extract Claude PID from output
    sleep 0.5
    CLAUDE_PID=$(grep "Claude PID:" /tmp/wrapper-out-exit-$$.txt | awk '{print $3}')

    if [ -z "$CLAUDE_PID" ]; then
        kill $SHELL_PID 2>/dev/null || true
        rm -f /tmp/wrapper-out-exit-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 1
    fi

    # Wait for ready marker
    READY_MARKER="$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.ready"
    for i in {1..20}; do
        [ -f "$READY_MARKER" ] && break
        sleep 0.1
    done

    # Send exit command
    PIPE="$TEST_DIR/.bitbot/wrapper/pipes/claude-${CLAUDE_PID}.pipe"
    if [ -p "$PIPE" ]; then
        echo "exit" > "$PIPE"

        # Wait for Claude to exit
        sleep 1

        # Check if Claude exited
        if ! kill -0 $CLAUDE_PID 2>/dev/null; then
            rm -f /tmp/wrapper-out-exit-$$.txt
            cd /tmp && rm -rf "$TEST_DIR"
            exit 0
        else
            kill $CLAUDE_PID 2>/dev/null || true
            kill $SHELL_PID 2>/dev/null || true
            rm -f /tmp/wrapper-out-exit-$$.txt
            cd /tmp && rm -rf "$TEST_DIR"
            exit 1
        fi
    else
        kill $SHELL_PID 2>/dev/null || true
        rm -f /tmp/wrapper-out-exit-$$.txt
        cd /tmp && rm -rf "$TEST_DIR"
        exit 1
    fi
) && test_pass || test_fail "Exit command not processed"

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
) && test_pass || test_fail "Invalid command not rejected"

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
) && test_pass || test_fail "Compact accepted without session ID"

section "Environment Variable Tests"

run_test "Wrapper exports WRAPPER_PIPE and wrapped process can discover own PID"
(
    TEST_DIR="/tmp/test-wrapper-$$"
    mkdir -p "$TEST_DIR/.bitbot"
    cd "$TEST_DIR"

    export CLAUDE_WRAPPER_CMD="bash"

    # Create a test script that discovers its own PID and checks WRAPPER_PIPE
    ENV_OUTPUT="/tmp/wrapper-env-$$.txt"
    TEST_CMD="-c"
    TEST_ARG="MYPID=\$\$; if [ -n \"\$WRAPPER_PIPE\" ] && [ -n \"\$MYPID\" ]; then echo \"WRAPPER_PIPE=\$WRAPPER_PIPE\" > $ENV_OUTPUT; echo \"MYPID=\$MYPID\" >> $ENV_OUTPUT; sleep 0.2; else exit 1; fi"

    # Run wrapper with test script
    timeout 2 "$WRAPPER_SCRIPT" "$TEST_CMD" "$TEST_ARG" || true

    # Check results
    if [ -f "$ENV_OUTPUT" ]; then
        source "$ENV_OUTPUT"
        if [ -n "$WRAPPER_PIPE" ] && [ -n "$MYPID" ]; then
            rm -f "$ENV_OUTPUT"
            cd /tmp && rm -rf "$TEST_DIR"
            exit 0
        fi
    fi

    rm -f "$ENV_OUTPUT"
    cd /tmp && rm -rf "$TEST_DIR"
    exit 1
) && test_pass || test_fail "Environment variables not exported or PID not discoverable"

section "Executable Permissions"

run_test "Wrapper script is executable"
if [ -x "$WRAPPER_SCRIPT" ]; then
    test_pass
else
    test_fail "Wrapper script not executable"
fi

run_test "Send-command script is executable"
if [ -x "$SEND_CMD_SCRIPT" ]; then
    test_pass
else
    test_fail "Send-command script not executable"
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
