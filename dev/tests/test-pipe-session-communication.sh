#!/usr/bin/env bash
# Comprehensive test suite for pipe-based session communication
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

total_tests=0
passed_tests=0

run_test() {
    local test_name="$1"
    local test_script="$2"

    total_tests=$((total_tests + 1))

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test $total_tests: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if bash "$test_script"; then
        passed_tests=$((passed_tests + 1))
        echo -e "${GREEN}✓ PASSED${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
    fi
}

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        Pipe-Based Session Communication Test Suite           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Testing the new pipe-based IPC (no state files)"
echo ""

# Run all tests
run_test "Pipe IPC Mechanism" "$SCRIPT_DIR/test-pipe-session-ipc.sh"
run_test "Session Hook Without Wrapper" "$SCRIPT_DIR/test-session-hook-no-wrapper.sh"
run_test "Session Hook With Wrapper Pipe" "$SCRIPT_DIR/test-session-hook-with-wrapper.sh"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED ($passed_tests/$total_tests)${NC}"
    echo ""
    echo "The pipe-based session communication is working correctly:"
    echo "  • No state files are created"
    echo "  • Session ID sent via pipe when wrapper is active"
    echo "  • Hook works correctly without wrapper"
    echo "  • Environment variables exported properly"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED ($passed_tests/$total_tests passed)${NC}"
    echo ""
    exit 1
fi
