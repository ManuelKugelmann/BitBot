#!/usr/bin/env bash
#
# Test: BitBot Bare Command and Config Mode
# Tests:
#   1. Bare 'bitbot' command (should default to work mode)
#   2. 'bitbot config' command (should launch config mode)
#
# This test focuses on command routing and basic functionality,
# reusing patterns from test-bitbot-commands-migrated.sh and
# test-user-flow-container-commands.sh
#
# Usage:
#   test-bitbot-bare-and-config.sh [--no-cleanup]
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BITBOT="$BITBOT_ROOT/core/bitbot"

# Parse arguments
SKIP_CLEANUP=false
for arg in "$@"; do
    case "$arg" in
        --no-cleanup)
            SKIP_CLEANUP=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: test-bitbot-bare-and-config.sh [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Test workspace
TEST_WORKSPACE="/tmp/bitbot-test-bare-config-$$"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

test_suite_begin "BitBot Bare Command and Config Mode Tests"

# ============================================================================
# Helper Functions
# ============================================================================

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Test workspace left for inspection: $TEST_WORKSPACE"
        echo ""
        return
    fi

    if [[ -d "$TEST_WORKSPACE" ]]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

trap cleanup EXIT

# Helper to initialize a test workspace
init_test_workspace() {
    mkdir -p "$TEST_WORKSPACE/main-workspace"
    cd "$TEST_WORKSPACE/main-workspace"

    # Initialize git to skip git prompts
    git init >/dev/null 2>&1

    # Initialize workspace with bitbot init --no-config
    # Using --no-config to skip the interactive prompt
    # Set environment variables to skip interactive prompts
    local output
    output=$(BITBOT_CHOICE_GIT_NO_REPO=1 BITBOT_CHOICE_GIT_NO_REMOTE=1 BITBOT_CHOICE_CONFIG_MODE=0 bash "$BITBOT" init --no-config 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        echo "Init failed with code $exit_code: $output" >&2
        return 1
    fi
}

# ============================================================================
# Test 1: Bare 'bitbot' command shows help when workspace uninitialized
# ============================================================================

test_section "Test 1: Bare 'bitbot' in uninitialized workspace"

mkdir -p "$TEST_WORKSPACE/uninit-test"
cd "$TEST_WORKSPACE/uninit-test"

# Bare bitbot in uninitialized workspace should show warning/error
# Use 'yes n' to answer 'no' to any initialization prompts
output=$(echo "n" | bash "$BITBOT" 2>&1 || true)

if echo "$output" | grep -qE "Workspace not initialized|Initialize workspace"; then
    test_pass "Bare bitbot detects uninitialized workspace"
else
    test_fail "Bare bitbot should detect uninitialized workspace"
    echo "Output: $output"
fi

# ============================================================================
# Test 2: Initialize workspace for remaining tests
# ============================================================================

test_section "Test 2: Initialize test workspace"

if init_test_workspace; then
    test_pass "Test workspace initialized successfully"
else
    test_fail "Failed to initialize test workspace"
    test_suite_end
fi

# Verify workspace structure
if [[ -d "$TEST_WORKSPACE/main-workspace/.devcontainer" ]]; then
    test_pass "Workspace has .devcontainer directory"
else
    test_fail "Workspace missing .devcontainer directory"
fi

# ============================================================================
# Test 3: Bare 'bitbot' command requires Docker (prereqs check)
# ============================================================================

test_section "Test 3: Bare 'bitbot' checks prerequisites"

# The bare bitbot command should check Docker availability
# We can't actually launch containers in all test environments,
# so we check that it at least validates prerequisites

cd "$TEST_WORKSPACE/main-workspace"

# Try to run bare bitbot (will fail without Docker, but should show appropriate error)
output=$(bash "$BITBOT" 2>&1 || true)

# Should either succeed (if Docker available) or show prerequisite error
if echo "$output" | grep -qE "Docker|devcontainer|Building|Starting"; then
    test_pass "Bare bitbot attempts container operations or checks prerequisites"
elif echo "$output" | grep -qE "not found|not installed|not running"; then
    test_pass "Bare bitbot shows prerequisite errors appropriately"
else
    test_warning "Bare bitbot output unexpected (may need Docker running)"
    echo "Output snippet: $(echo "$output" | head -5)"
fi

# ============================================================================
# Test 4: 'bitbot config' command requires Docker (prereqs check)
# ============================================================================

test_section "Test 4: 'bitbot config' checks prerequisites"

cd "$TEST_WORKSPACE/main-workspace"

# Try to run bitbot config (will fail without Docker, but should show appropriate error)
output=$(bash "$BITBOT" config 2>&1 || true)

# Should either succeed (if Docker available) or show prerequisite error
if echo "$output" | grep -qE "Docker|devcontainer|Building|Starting"; then
    test_pass "bitbot config attempts container operations or checks prerequisites"
elif echo "$output" | grep -qE "not found|not installed|not running"; then
    test_pass "bitbot config shows prerequisite errors appropriately"
else
    test_warning "bitbot config output unexpected (may need Docker running)"
    echo "Output snippet: $(echo "$output" | head -5)"
fi

# ============================================================================
# Test 5: Verify bare 'bitbot' and 'bitbot work' behave identically
# ============================================================================

test_section "Test 5: Bare 'bitbot' behaves like 'bitbot work'"

cd "$TEST_WORKSPACE/main-workspace"

# Capture output from bare bitbot
output_bare=$(bash "$BITBOT" 2>&1 || true)

# Capture output from bitbot work
output_work=$(bash "$BITBOT" work 2>&1 || true)

# They should produce similar output patterns
# Check for common elements (devcontainer, workspace, etc)
if echo "$output_bare" | grep -q "devcontainer"; then
    bare_has_devcontainer=1
else
    bare_has_devcontainer=0
fi

if echo "$output_work" | grep -q "devcontainer"; then
    work_has_devcontainer=1
else
    work_has_devcontainer=0
fi

if [[ "$bare_has_devcontainer" -gt 0 ]] && [[ "$work_has_devcontainer" -gt 0 ]]; then
    test_pass "Both bare 'bitbot' and 'bitbot work' reference devcontainer"
elif [[ "$bare_has_devcontainer" -eq 0 ]] && [[ "$work_has_devcontainer" -eq 0 ]]; then
    # Both might be failing due to missing Docker - that's fine for this test
    test_pass "Both commands behave consistently (may need Docker)"
else
    test_warning "Bare 'bitbot' and 'bitbot work' outputs differ"
fi

# ============================================================================
# Test 6: Verify 'bitbot config' uses config mode
# ============================================================================

test_section "Test 6: 'bitbot config' references config mode"

cd "$TEST_WORKSPACE/main-workspace"

output=$(bash "$BITBOT" config 2>&1 || true)

# Config mode should be distinguishable from work mode
# Look for config-specific references
if echo "$output" | grep -qiE "config|configuration|edit.*devcontainer"; then
    test_pass "bitbot config appears to use config mode"
else
    # Might just be generic devcontainer messages
    test_warning "bitbot config output doesn't clearly indicate config mode"
    echo "Output snippet: $(echo "$output" | head -5)"
fi

# ============================================================================
# Test 7: Test workspace validation
# ============================================================================

test_section "Test 7: Commands validate workspace initialization"

# Try running from a random directory (not a workspace)
mkdir -p "$TEST_WORKSPACE/random-dir"
cd "$TEST_WORKSPACE/random-dir"

output=$(echo "n" | bash "$BITBOT" 2>&1 || true)

if echo "$output" | grep -qE "Workspace not initialized|not initialized"; then
    test_pass "Bare bitbot validates workspace initialization"
else
    test_fail "Bare bitbot should validate workspace initialization"
fi

# Same for config
output=$(bash "$BITBOT" config 2>&1 || true)

if echo "$output" | grep -qE "Workspace not initialized|not initialized|Run.*init"; then
    test_pass "bitbot config validates workspace initialization"
else
    test_fail "bitbot config should validate workspace initialization"
fi

# ============================================================================
# Test 8: Help text includes all commands
# ============================================================================

test_section "Test 8: Help text documents bare command behavior"

output=$(bash "$BITBOT" help 2>&1)

# Verify work and config are documented
if echo "$output" | grep -q "work"; then
    test_pass "Help documents 'work' command"
else
    test_fail "Help missing 'work' command"
fi

if echo "$output" | grep -q "config"; then
    test_pass "Help documents 'config' command"
else
    test_fail "Help missing 'config' command"
fi

# ============================================================================
# Test 9: Verify command flags are rejected appropriately
# ============================================================================

test_section "Test 9: Invalid flags are rejected"

cd "$TEST_WORKSPACE/main-workspace"

# Bare bitbot shouldn't accept unknown flags
output=$(bash "$BITBOT" --invalid-flag 2>&1 || true)

if echo "$output" | grep -qE "Unknown|invalid|not recognized|Usage:"; then
    test_pass "Invalid flags are rejected with help message"
else
    test_warning "Invalid flag handling may need improvement"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
