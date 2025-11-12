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
# MIGRATED TO USE: test-framework.sh, workspace-helper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BITBOT_CMD="${BITBOT_ROOT}/core/bitbot"

# Source test helpers
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"

# Set BITBOT_HOME for tests
export BITBOT_HOME="$BITBOT_ROOT"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Integration Test (CI)"

# Create test workspace
TEST_WORKSPACE=$(create_test_workspace "ci-integration")
echo "  Created test workspace: $TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
git init -q

# Set up cleanup
trap 'cleanup_test_workspace "$TEST_WORKSPACE"' EXIT INT TERM

# ============================================================================
# Test 1: bitbot help command
# ============================================================================

echo ""
test_section "Test 1: bitbot help command"

if bash "$BITBOT_CMD" help &>/dev/null; then
    test_pass "bitbot help executes successfully"
else
    test_fail "bitbot help failed to execute"
fi

help_output=$(bash "$BITBOT_CMD" help 2>&1)
if echo "$help_output" | grep -q "Usage:"; then
    test_pass "bitbot help shows usage information"
else
    test_fail "bitbot help missing usage information"
fi

# ============================================================================
# Test 2: bitbot version command
# ============================================================================

echo ""
test_section "Test 2: bitbot version command"

if bash "$BITBOT_CMD" version &>/dev/null; then
    test_pass "bitbot version executes successfully"
else
    test_fail "bitbot version failed to execute"
fi

version_output=$(bash "$BITBOT_CMD" version 2>&1)
if echo "$version_output" | grep -q "BitBot"; then
    test_pass "bitbot version shows BitBot info"
else
    test_fail "bitbot version missing BitBot info"
fi

# ============================================================================
# Test 3: bitbot init command (non-interactive)
# ============================================================================

echo ""
test_section "Test 3: bitbot init command"

# Create minimal test environment for init
echo "test" > README.md

# Run bitbot init with --no-config flag (non-interactive)
# The init may fail when trying to launch devcontainer (expected in CI)
# but should succeed in creating the workspace structure
init_output=$(timeout 10 bash "$BITBOT_CMD" init --no-config 2>&1)
init_exit_code=$?
echo "$init_output"

# Check if workspace was created successfully (even if container launch failed)
if [[ -d ".devcontainer" ]] && [[ -f ".devcontainer/devcontainer.json" ]]; then
    test_pass "bitbot init created workspace structure"
    if [[ $init_exit_code -eq 0 ]]; then
        test_pass "bitbot init completed fully"
    elif [[ $init_exit_code -eq 124 ]]; then
        test_pass "bitbot init succeeded (container build timed out - expected in CI)"
    elif echo "$init_output" | grep -q "devcontainer: command not found\|Failed to launch"; then
        test_pass "bitbot init succeeded (container launch skipped - expected in CI)"
    fi
else
    if [[ $init_exit_code -eq 124 ]]; then
        test_fail "bitbot init timed out before creating workspace structure"
    else
        test_fail "bitbot init failed to create workspace structure"
    fi
fi

# ============================================================================
# Test 4: Workspace structure after init
# ============================================================================

echo ""
test_section "Test 4: Workspace structure validation"

if [[ -d ".devcontainer" ]]; then
    test_pass ".devcontainer directory created"

    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        test_pass "devcontainer.json created"
    else
        test_fail "devcontainer.json not created"
    fi

    if [[ -f ".devcontainer/Dockerfile" ]]; then
        test_pass "Dockerfile created"
    else
        test_fail "Dockerfile not created"
    fi

    if [[ -d ".devcontainer/bitbot" ]]; then
        test_pass "BitBot container scripts copied"

        if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
            test_pass "Container bitbot script present"
        else
            test_fail "Container bitbot script missing"
        fi
    else
        test_fail "BitBot container scripts not copied"
    fi
else
    test_fail ".devcontainer directory not created"
    test_fail "devcontainer.json not created (skipped)"
    test_fail "Dockerfile not created (skipped)"
    test_fail "BitBot container scripts not copied (skipped)"
    test_fail "Container bitbot script present (skipped)"
fi

# ============================================================================
# Test 5: DevContainer configuration validation
# ============================================================================

echo ""
test_section "Test 5: DevContainer configuration validation"

if [[ -f ".devcontainer/devcontainer.json" ]]; then
    # Validate JSON syntax
    if command -v jq &>/dev/null; then
        if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
            test_pass "devcontainer.json has valid JSON syntax"
        else
            test_fail "devcontainer.json has invalid JSON syntax"
        fi

        # Check for required fields
        if jq -e '.name' .devcontainer/devcontainer.json &>/dev/null; then
            test_pass "devcontainer.json has 'name' field"
        else
            test_fail "devcontainer.json missing 'name' field"
        fi

        if jq -e '.dockerFile' .devcontainer/devcontainer.json &>/dev/null; then
            test_pass "devcontainer.json has 'dockerFile' field"
        else
            test_fail "devcontainer.json missing 'dockerFile' field"
        fi

        if jq -e '.workspaceFolder' .devcontainer/devcontainer.json &>/dev/null; then
            test_pass "devcontainer.json has 'workspaceFolder' field"
        else
            test_fail "devcontainer.json missing 'workspaceFolder' field"
        fi

        # Check for resource limits
        if jq -e '.runArgs' .devcontainer/devcontainer.json &>/dev/null; then
            test_pass "devcontainer.json has resource limits (runArgs)"
        else
            test_fail "devcontainer.json missing resource limits"
        fi
    else
        test_fail "jq not available, cannot validate JSON (skipped)"
    fi
else
    test_fail "devcontainer.json validation skipped (file not created)"
fi

# ============================================================================
# Test 6: Container scripts validation
# ============================================================================

echo ""
test_section "Test 6: Container scripts validation"

if [[ -d ".devcontainer/bitbot" ]]; then
    # Check if scripts have proper permissions
    if [[ -x ".devcontainer/bitbot/bitbot" ]]; then
        test_pass "Container bitbot script is executable"
    else
        test_fail "Container bitbot script not executable"
    fi

    # Validate bash syntax of main script
    if bash -n .devcontainer/bitbot/bitbot 2>/dev/null; then
        test_pass "Container bitbot script has valid bash syntax"
    else
        test_fail "Container bitbot script has syntax errors"
    fi

    # Check for core utilities
    if [[ -d ".devcontainer/bitbot/core" ]]; then
        test_pass "Container bitbot core utilities present"
    else
        test_fail "Container bitbot core utilities missing"
    fi
else
    test_fail "Container scripts validation skipped (directory not created)"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

echo ""
echo "  ℹ Test workspace will be auto-cleaned by trap"
echo ""

test_suite_end
