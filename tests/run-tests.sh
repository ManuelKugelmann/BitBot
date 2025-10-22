#!/usr/bin/env bash
#
# BitBot Test Runner
# Orchestrates all automated tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0

# Parse arguments
CLEAN=false
QUICK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN=true
            shift
            ;;
        --quick)
            QUICK=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--clean] [--quick]"
            echo "  --clean   Run clean-slate before tests"
            echo "  --quick   Skip slow integration tests"
            exit 1
            ;;
    esac
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       BitBot Test Suite Runner         ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo ""

# ============================================================================
# Clean Slate (Optional)
# ============================================================================

if [[ "$CLEAN" == "true" ]]; then
    echo -e "${YELLOW}[Preparation]${NC} Running clean-slate..."
    echo ""

    if [[ -f "${SCRIPT_DIR}/clean-slate.sh" ]]; then
        bash "${SCRIPT_DIR}/clean-slate.sh" --full
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓${NC} Clean slate completed"
        else
            echo -e "${RED}✗${NC} Clean slate failed"
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} clean-slate.sh not found"
        exit 1
    fi

    echo ""
fi

# ============================================================================
# Helper Functions
# ============================================================================

run_test() {
    local test_name="$1"
    local test_script="$2"
    local skip="${3:-false}"

    total_tests=$((total_tests + 1))

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}[Test $total_tests]${NC} $test_name"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ "$skip" == "true" ]]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC}: $test_name"
        skipped_tests=$((skipped_tests + 1))
        return 0
    fi

    if [[ ! -f "$test_script" ]]; then
        echo -e "${RED}✗ FAILED${NC}: Test script not found: $test_script"
        failed_tests=$((failed_tests + 1))
        return 1
    fi

    # Run the test
    if bash "$test_script"; then
        echo ""
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        echo ""
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

# ============================================================================
# Test Suite
# ============================================================================

echo -e "${CYAN}Starting test suite...${NC}"
echo ""

# Test 1: Prerequisites
run_test "Prerequisites Check" \
    "${SCRIPT_DIR}/test-prerequisites.sh"

# Test 2: Workspace Init
run_test "Workspace Initialization" \
    "${SCRIPT_DIR}/test-workspace-init.sh"

# Test 3: BitBot Commands
run_test "BitBot Commands" \
    "${SCRIPT_DIR}/test-bitbot-commands.sh"

# Test 4: Platform Detection
run_test "Platform Detection" \
    "${SCRIPT_DIR}/test-platform-detection.sh"

# Test 5: Filesystem Performance (WSL only, skipped in quick mode)
if [[ "$QUICK" == "true" ]]; then
    run_test "Filesystem Performance (WSL vs /mnt/c/)" \
        "${SCRIPT_DIR}/test-filesystem-performance.sh" \
        true  # skip=true
else
    run_test "Filesystem Performance (WSL vs /mnt/c/)" \
        "${SCRIPT_DIR}/test-filesystem-performance.sh"
fi

# Test 6: Integration tests (skipped in quick mode)
if [[ "$QUICK" == "true" ]]; then
    run_test "Full Integration Test" \
        "${SCRIPT_DIR}/test-integration.sh" \
        true  # skip=true
else
    if [[ -f "${SCRIPT_DIR}/test-integration.sh" ]]; then
        run_test "Full Integration Test" \
            "${SCRIPT_DIR}/test-integration.sh"
    fi
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Test Suite Summary            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total:   ${BLUE}${total_tests}${NC}"
echo -e "  Passed:  ${GREEN}${passed_tests}${NC}"
echo -e "  Failed:  ${RED}${failed_tests}${NC}"
echo -e "  Skipped: ${YELLOW}${skipped_tests}${NC}"
echo ""

# Calculate success rate
if [[ $total_tests -gt 0 ]]; then
    success_rate=$((passed_tests * 100 / (total_tests - skipped_tests)))
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
