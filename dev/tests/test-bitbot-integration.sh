#!/usr/bin/env bash
#
# BitBot Integration Test - CI Focused
# Tests actual bitbot command workflows
#
# This test validates:
# 1. bitbot init workflow
# 2. bitbot help/version commands
# 3. Workspace setup and configuration
# 4. DevContainer configuration generation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BITBOT_CMD="${BITBOT_ROOT}/core/bitbot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0

test_passed() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} ${test_name}"
    passed_tests=$((passed_tests + 1))
    total_tests=$((total_tests + 1))
}

test_failed() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason: ${reason}${NC}"
    fi
    failed_tests=$((failed_tests + 1))
    total_tests=$((total_tests + 1))
}

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   BitBot Integration Test (CI)        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Create test workspace
TEST_WORKSPACE="/tmp/bitbot-ci-integration-test-$$"
echo -e "${BLUE}[Setup]${NC} Creating test workspace: $TEST_WORKSPACE"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
git init -q

# Set BITBOT_HOME for tests
export BITBOT_HOME="$BITBOT_ROOT"

# ============================================================================
# Test 1: bitbot help command
# ============================================================================

echo ""
echo -e "${BLUE}[Test 1]${NC} bitbot help command"

if bash "$BITBOT_CMD" help &>/dev/null; then
    test_passed "bitbot help executes successfully"
else
    test_failed "bitbot help failed to execute"
fi

help_output=$(bash "$BITBOT_CMD" help 2>&1)
if echo "$help_output" | grep -q "Usage:"; then
    test_passed "bitbot help shows usage information"
else
    test_failed "bitbot help missing usage information"
fi

# ============================================================================
# Test 2: bitbot version command
# ============================================================================

echo ""
echo -e "${BLUE}[Test 2]${NC} bitbot version command"

if bash "$BITBOT_CMD" version &>/dev/null; then
    test_passed "bitbot version executes successfully"
else
    test_failed "bitbot version failed to execute"
fi

version_output=$(bash "$BITBOT_CMD" version 2>&1)
if echo "$version_output" | grep -q "BitBot"; then
    test_passed "bitbot version shows BitBot info"
else
    test_failed "bitbot version missing BitBot info"
fi

# ============================================================================
# Test 3: bitbot init command (non-interactive)
# ============================================================================

echo ""
echo -e "${BLUE}[Test 3]${NC} bitbot init command"

# Create minimal test environment for init
echo "test" > README.md

# Run bitbot init non-interactively
# Note: In CI, we need to handle interactive prompts
# The init may fail when trying to launch devcontainer (expected in CI)
# but should succeed in creating the workspace structure
timeout 10 bash "$BITBOT_CMD" init <<EOF 2>&1 | tee /tmp/bitbot-init-test.log
bitbot-base
EOF
init_exit_code=$?

# Check if workspace was created successfully (even if container launch failed)
if [[ -d ".devcontainer" ]] && [[ -f ".devcontainer/devcontainer.json" ]]; then
    test_passed "bitbot init created workspace structure"
    if [[ $init_exit_code -eq 0 ]]; then
        test_passed "bitbot init completed fully"
    elif grep -q "devcontainer: command not found\|Failed to launch" /tmp/bitbot-init-test.log 2>/dev/null; then
        test_passed "bitbot init succeeded (container launch skipped - expected in CI)"
    fi
else
    if [[ $init_exit_code -eq 124 ]]; then
        test_failed "bitbot init timed out (may require interactive input)"
    else
        test_failed "bitbot init failed to create workspace structure"
    fi
fi

# ============================================================================
# Test 4: Workspace structure after init
# ============================================================================

echo ""
echo -e "${BLUE}[Test 4]${NC} Workspace structure validation"

if [[ -d ".devcontainer" ]]; then
    test_passed ".devcontainer directory created"

    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        test_passed "devcontainer.json created"
    else
        test_failed "devcontainer.json not created"
    fi

    if [[ -f ".devcontainer/Dockerfile" ]]; then
        test_passed "Dockerfile created"
    else
        test_failed "Dockerfile not created"
    fi

    if [[ -d ".devcontainer/bitbot" ]]; then
        test_passed "BitBot container scripts copied"

        if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
            test_passed "Container bitbot script present"
        else
            test_failed "Container bitbot script missing"
        fi
    else
        test_failed "BitBot container scripts not copied"
    fi
else
    test_failed ".devcontainer directory not created"
    test_failed "devcontainer.json not created (skipped)"
    test_failed "Dockerfile not created (skipped)"
    test_failed "BitBot container scripts not copied (skipped)"
    test_failed "Container bitbot script present (skipped)"
fi

# ============================================================================
# Test 5: DevContainer configuration validation
# ============================================================================

echo ""
echo -e "${BLUE}[Test 5]${NC} DevContainer configuration validation"

if [[ -f ".devcontainer/devcontainer.json" ]]; then
    # Validate JSON syntax
    if command -v jq &>/dev/null; then
        if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
            test_passed "devcontainer.json has valid JSON syntax"
        else
            test_failed "devcontainer.json has invalid JSON syntax"
        fi

        # Check for required fields
        if jq -e '.name' .devcontainer/devcontainer.json &>/dev/null; then
            test_passed "devcontainer.json has 'name' field"
        else
            test_failed "devcontainer.json missing 'name' field"
        fi

        if jq -e '.dockerFile' .devcontainer/devcontainer.json &>/dev/null; then
            test_passed "devcontainer.json has 'dockerFile' field"
        else
            test_failed "devcontainer.json missing 'dockerFile' field"
        fi

        if jq -e '.workspaceFolder' .devcontainer/devcontainer.json &>/dev/null; then
            test_passed "devcontainer.json has 'workspaceFolder' field"
        else
            test_failed "devcontainer.json missing 'workspaceFolder' field"
        fi

        # Check for resource limits
        if jq -e '.runArgs' .devcontainer/devcontainer.json &>/dev/null; then
            test_passed "devcontainer.json has resource limits (runArgs)"
        else
            test_failed "devcontainer.json missing resource limits"
        fi
    else
        test_failed "jq not available, cannot validate JSON (skipped)"
    fi
else
    test_failed "devcontainer.json validation skipped (file not created)"
fi

# ============================================================================
# Test 6: Container scripts validation
# ============================================================================

echo ""
echo -e "${BLUE}[Test 6]${NC} Container scripts validation"

if [[ -d ".devcontainer/bitbot" ]]; then
    # Check if scripts have proper permissions
    if [[ -x ".devcontainer/bitbot/bitbot" ]]; then
        test_passed "Container bitbot script is executable"
    else
        test_failed "Container bitbot script not executable"
    fi

    # Validate bash syntax of main script
    if bash -n .devcontainer/bitbot/bitbot 2>/dev/null; then
        test_passed "Container bitbot script has valid bash syntax"
    else
        test_failed "Container bitbot script has syntax errors"
    fi

    # Check for core utilities
    if [[ -d ".devcontainer/bitbot/core" ]]; then
        test_passed "Container bitbot core utilities present"
    else
        test_failed "Container bitbot core utilities missing"
    fi
else
    test_failed "Container scripts validation skipped (directory not created)"
fi

# ============================================================================
# Cleanup
# ============================================================================

echo ""
echo -e "${BLUE}[Cleanup]${NC} Removing test workspace"
cd /tmp
rm -rf "$TEST_WORKSPACE"

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
