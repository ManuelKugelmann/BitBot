#!/usr/bin/env bash
#
# Test: BitBot User Flows - Master Test Runner
# Runs all user flow tests in sequence
#
# Usage:
#   test-user-flows.sh [--dev] [--no-cleanup]
#
# Options:
#   --dev:       Run in dev mode (requires clean git state)
#   --no-cleanup: Skip cleanup (leave changes for inspection)
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Parse arguments to pass through to tests
TEST_ARGS=("$@")

test_suite_begin "BitBot User Flows - Master Test Suite"

# Track overall results
total_suites=0
passed_suites=0
failed_suites=()

# Function to run a test suite
run_test_suite() {
    local test_name="$1"
    local test_script="$2"

    total_suites=$((total_suites + 1))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Running: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if "$test_script" "${TEST_ARGS[@]}"; then
        echo ""
        test_pass " $test_name PASSED"
        passed_suites=$((passed_suites + 1))
        return 0
    else
        echo ""
        test_fail " $test_name FAILED"
        failed_suites+=("$test_name")
        return 1
    fi
}

# ============================================================================
# Run Test Suites
# ============================================================================

# Test 1: Global Initialization Flow
run_test_suite \
    "Global Initialization Flow" \
    "$SCRIPT_DIR/test-user-flow-init.sh" \
    || true  # Continue even if this suite fails

# Test 2: Moved Installation
run_test_suite \
    "Moved Installation" \
    "$SCRIPT_DIR/test-user-flow-moved.sh" \
    || true  # Continue even if this suite fails

# Test 3: Workspace Initialization
run_test_suite \
    "Workspace Initialization" \
    "$SCRIPT_DIR/test-user-flow-workspace-init.sh" \
    || true  # Continue even if this suite fails

# Test 4: Context Switching
run_test_suite \
    "Context Switching (Global ↔ Workspace)" \
    "$SCRIPT_DIR/test-user-flow-context-switch.sh" \
    || true  # Continue even if this suite fails

# Test 5: Container Commands (script-based)
run_test_suite \
    "In-Container Commands" \
    "$SCRIPT_DIR/test-user-flow-container-commands.sh" \
    || true  # Continue even if this suite fails

# Test 6: Container Interactive (expect-based)
# Only run if expect is available
if command -v expect &> /dev/null; then
    run_test_suite \
        "In-Container Interactive (Expect)" \
        "$SCRIPT_DIR/test-user-flow-container-interactive.sh" \
        || true  # Continue even if this suite fails
else
    echo ""
    echo -e "${YELLOW}⚠ SKIP${NC}: In-Container Interactive test (expect not installed)"
    echo ""
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}Master Test Suite Summary"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total test suites: $total_suites"
echo -e "${GREEN}Passed: $passed_suites"
echo -e "${RED}Failed: $((total_suites - passed_suites))"
echo ""

if [[ ${#failed_suites[@]} -gt 0 ]]; then
    echo -e "${RED}Failed test suites:"
    for suite in "${failed_suites[@]}"; do
        echo -e "  ${RED}✗${NC} $suite"
    done
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Exit with appropriate code
if [[ $passed_suites -eq $total_suites ]]; then
    test_pass " All test suites passed!"
    exit 0
else
    test_fail " Some test suites failed"
    exit 1
fi
