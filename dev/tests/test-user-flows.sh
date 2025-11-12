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
# This script runs all user flow test suites:
#   - test-user-flow-init.sh: Global initialization flow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments to pass through to tests
TEST_ARGS=("$@")

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}BitBot User Flows - Master Test Suite${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

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
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if "$test_script" "${TEST_ARGS[@]}"; then
        echo ""
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        passed_suites=$((passed_suites + 1))
        return 0
    else
        echo ""
        echo -e "${RED}✗ $test_name FAILED${NC}"
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
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Master Test Suite Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total test suites: $total_suites"
echo -e "${GREEN}Passed: $passed_suites${NC}"
echo -e "${RED}Failed: $((total_suites - passed_suites))${NC}"
echo ""

if [[ ${#failed_suites[@]} -gt 0 ]]; then
    echo -e "${RED}Failed test suites:${NC}"
    for suite in "${failed_suites[@]}"; do
        echo -e "  ${RED}✗${NC} $suite"
    done
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Exit with appropriate code
if [[ $passed_suites -eq $total_suites ]]; then
    echo -e "${GREEN}✓ All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some test suites failed${NC}"
    exit 1
fi
