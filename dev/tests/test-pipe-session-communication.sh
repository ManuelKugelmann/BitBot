#!/usr/bin/env bash
# Comprehensive test suite for pipe-based session communication
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

run_test() {
    local test_name="$1"
    local test_script="$2"

    test_section "$test_name"

    if bash "$test_script" >/dev/null 2>&1; then
        test_pass "$test_name"
    else
        test_fail "$test_name"
    fi
}

test_suite_begin "Pipe-Based Session Communication Test Suite"

echo "Testing the new pipe-based IPC (no state files)"
echo ""

# Run all tests
run_test "Pipe IPC Mechanism" "$SCRIPT_DIR/test-pipe-session-ipc.sh"
run_test "Session Hook Without Wrapper" "$SCRIPT_DIR/test-session-hook-no-wrapper.sh"
run_test "Session Hook With Wrapper Pipe" "$SCRIPT_DIR/test-session-hook-with-wrapper.sh"

# Test suite complete
echo ""
echo "The pipe-based session communication features tested:"
echo "  • No state files are created"
echo "  • Session ID sent via pipe when wrapper is active"
echo "  • Hook works correctly without wrapper"
echo "  • Environment variables exported properly"
echo ""

test_suite_end
