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

# ============================================================================
# Core Unit Tests (Fast - Always Run)
# ============================================================================

# Test 1: Prerequisites
run_test "Prerequisites Check" \
    "${SCRIPT_DIR}/test-prerequisites.sh"

# Test 2: Platform Detection
run_test "Platform Detection" \
    "${SCRIPT_DIR}/test-platform-detection.sh"

# Test 3: Helper Functions
run_test "Helper Functions" \
    "${SCRIPT_DIR}/test-helpers.sh"

# Test 4: BitBot Commands (Migrated Framework)
run_test "BitBot Commands (Migrated)" \
    "${SCRIPT_DIR}/test-bitbot-commands-migrated.sh"

# ============================================================================
# Workspace Tests (Fast - Always Run)
# ============================================================================

# Test 5: Workspace Init
run_test "Workspace Initialization" \
    "${SCRIPT_DIR}/test-workspace-init.sh"

# Test 6: BitBot Init (Non-Interactive)
run_test "BitBot Init (Non-Interactive)" \
    "${SCRIPT_DIR}/test-bitbot-init-non-interactive.sh"

# ============================================================================
# Container Tests (Fast - Always Run)
# ============================================================================

# Test 7: Container BitBot
run_test "Container BitBot" \
    "${SCRIPT_DIR}/test-container-bitbot.sh"

# Test 8: Container BitBot Start/Resume
run_test "Container BitBot Start/Resume" \
    "${SCRIPT_DIR}/test-container-bitbot-start.sh"

# ============================================================================
# Infrastructure Tests (Fast - Always Run)
# ============================================================================

# Test 9: Infrastructure Sync
run_test "Infrastructure Sync" \
    "${SCRIPT_DIR}/test-infrastructure-sync.sh"

# Test 10: Merge DevContainer
run_test "Merge DevContainer" \
    "${SCRIPT_DIR}/test-merge-devcontainer.sh"

# ============================================================================
# Session/Wrapper Tests (Fast - Always Run)
# ============================================================================

# Test 11: Wrapper Layer 1
run_test "Wrapper Layer 1" \
    "${SCRIPT_DIR}/test-wrapper-layer1.sh"

# Test 12: Wrapper Full
run_test "Wrapper Full" \
    "${SCRIPT_DIR}/test-wrapper.sh"

# Test 13: Session Management
run_test "Session Management" \
    "${SCRIPT_DIR}/test-session-management.sh"

# Test 14: Session Hook (No Wrapper)
run_test "Session Hook (No Wrapper)" \
    "${SCRIPT_DIR}/test-session-hook-no-wrapper.sh"

# Test 15: Session Hook (With Wrapper)
run_test "Session Hook (With Wrapper)" \
    "${SCRIPT_DIR}/test-session-hook-with-wrapper.sh"

# ============================================================================
# Pipe/IPC Tests (Fast - Always Run)
# ============================================================================

# Test 16: Pipe Session Communication
run_test "Pipe Session Communication" \
    "${SCRIPT_DIR}/test-pipe-session-communication.sh"

# Test 17: Pipe Session IPC
run_test "Pipe Session IPC" \
    "${SCRIPT_DIR}/test-pipe-session-ipc.sh"

# ============================================================================
# User Flow Tests (Medium - Skip in Quick Mode)
# ============================================================================

if [[ "$QUICK" == "false" ]]; then
    # Test 18: User Flow - Init
    run_test "User Flow: Init" \
        "${SCRIPT_DIR}/test-user-flow-init.sh"

    # Test 19: User Flow - Workspace Init
    run_test "User Flow: Workspace Init" \
        "${SCRIPT_DIR}/test-user-flow-workspace-init.sh"

    # Test 20: User Flow - Context Switch
    run_test "User Flow: Context Switch" \
        "${SCRIPT_DIR}/test-user-flow-context-switch.sh"

    # Test 21: User Flow - Moved
    run_test "User Flow: Moved" \
        "${SCRIPT_DIR}/test-user-flow-moved.sh"

    # Test 22: User Flow - Container Commands
    run_test "User Flow: Container Commands" \
        "${SCRIPT_DIR}/test-user-flow-container-commands.sh"

    # Test 23: User Flow - Container Interactive
    run_test "User Flow: Container Interactive" \
        "${SCRIPT_DIR}/test-user-flow-container-interactive.sh"

    # Test 24: User Flows (Combined)
    run_test "User Flows (Combined)" \
        "${SCRIPT_DIR}/test-user-flows.sh"
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: 7 User Flow Tests (--quick mode)"
    skipped_tests=$((skipped_tests + 7))
    total_tests=$((total_tests + 7))
fi

# ============================================================================
# Interactive Tests (Slow - Skip in Quick Mode)
# ============================================================================

if [[ "$QUICK" == "false" ]]; then
    # Test 25: BitBot Init (Interactive with tmux)
    run_test "BitBot Init (Interactive)" \
        "${SCRIPT_DIR}/test-bitbot-init-interactive.sh"
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: BitBot Init (Interactive) (--quick mode)"
    skipped_tests=$((skipped_tests + 1))
    total_tests=$((total_tests + 1))
fi

# ============================================================================
# Performance Tests (Slow - Skip in Quick Mode)
# ============================================================================

if [[ "$QUICK" == "false" ]]; then
    # Test 26: Filesystem Performance
    run_test "Filesystem Performance (WSL vs /mnt/c/)" \
        "${SCRIPT_DIR}/test-filesystem-performance.sh"

    # Test 27: DevContainer Filesystem Performance
    if [[ -f "${SCRIPT_DIR}/test-devcontainer-filesystem-performance.sh" ]]; then
        run_test "DevContainer Filesystem Performance" \
            "${SCRIPT_DIR}/test-devcontainer-filesystem-performance.sh"
    fi
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: 2 Performance Tests (--quick mode)"
    skipped_tests=$((skipped_tests + 2))
    total_tests=$((total_tests + 2))
fi

# ============================================================================
# DevContainer Tests (Very Slow - Skip in Quick Mode)
# ============================================================================

if [[ "$QUICK" == "false" ]]; then
    # Test 28: DevContainer Locations
    if [[ -f "${SCRIPT_DIR}/test-devcontainer-locations.sh" ]]; then
        run_test "DevContainer Functionality (WSL home and /mnt/c/)" \
            "${SCRIPT_DIR}/test-devcontainer-locations.sh"
    fi
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: DevContainer Locations Test (--quick mode)"
    skipped_tests=$((skipped_tests + 1))
    total_tests=$((total_tests + 1))
fi

# ============================================================================
# Integration Tests (Very Slow - Skip in Quick Mode)
# ============================================================================

if [[ "$QUICK" == "false" ]]; then
    # Test 29: BitBot Integration
    if [[ -f "${SCRIPT_DIR}/test-bitbot-integration.sh" ]]; then
        run_test "BitBot Integration" \
            "${SCRIPT_DIR}/test-bitbot-integration.sh"
    fi

    # Test 30: Full Integration Test
    if [[ -f "${SCRIPT_DIR}/test-integration.sh" ]]; then
        run_test "Full Integration Test" \
            "${SCRIPT_DIR}/test-integration.sh"
    fi
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: 2 Integration Tests (--quick mode)"
    skipped_tests=$((skipped_tests + 2))
    total_tests=$((total_tests + 2))
fi

# ============================================================================
# Quality Tests (Fast - Always Run)
# ============================================================================

# Test 31: Shellcheck (if available)
if command -v shellcheck >/dev/null 2>&1; then
    run_test "Shellcheck" \
        "${SCRIPT_DIR}/test-shellcheck.sh"
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: Shellcheck (shellcheck not installed)"
    skipped_tests=$((skipped_tests + 1))
    total_tests=$((total_tests + 1))
fi

# ============================================================================
# Cloud Environment Tests (Skip if not in Codespaces)
# ============================================================================

if [[ -n "${CODESPACES}" ]]; then
    # Test 32: Codespaces
    run_test "GitHub Codespaces" \
        "${SCRIPT_DIR}/test-codespaces.sh"
else
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: Codespaces Test (not running in GitHub Codespaces)"
    skipped_tests=$((skipped_tests + 1))
    total_tests=$((total_tests + 1))
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
