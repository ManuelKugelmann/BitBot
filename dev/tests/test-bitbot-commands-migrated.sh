#!/usr/bin/env bash
#
# Test: BitBot Command Handling
# Tests bitbot help, version, and error handling
#
# MIGRATED TO USE: test-framework.sh helper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BITBOT="$BITBOT_ROOT/core/bitbot"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Command Tests"

# ============================================================================
# Test 1: bitbot help command
# ============================================================================

test_section "Test 1: bitbot help command"
output=$(bash "$BITBOT" help 2>&1)
if echo "$output" | grep -q "Usage:"; then
    test_pass "help command shows usage"
else
    test_fail "help command missing usage section"
fi

# ============================================================================
# Test 2: bitbot --help flag
# ============================================================================

test_section "Test 2: bitbot --help flag"
output=$(bash "$BITBOT" --help 2>&1)
if echo "$output" | grep -q "Usage:"; then
    test_pass "--help flag works"
else
    test_fail "--help flag doesn't work"
fi

# ============================================================================
# Test 3: bitbot -h flag
# ============================================================================

test_section "Test 3: bitbot -h flag"
output=$(bash "$BITBOT" -h 2>&1)
if echo "$output" | grep -q "Commands:"; then
    test_pass "-h flag works"
else
    test_fail "-h flag doesn't work"
fi

# ============================================================================
# Test 4: bitbot version command
# ============================================================================

test_section "Test 4: bitbot version command"
output=$(bash "$BITBOT" version 2>&1)
if echo "$output" | grep -q "BitBot version"; then
    test_pass "version command shows version"
else
    test_fail "version command missing version info"
fi

# ============================================================================
# Test 5: bitbot --version flag
# ============================================================================

test_section "Test 5: bitbot --version flag"
output=$(bash "$BITBOT" --version 2>&1)
if echo "$output" | grep -q "BitBot Dependency Status"; then
    test_pass "--version flag works"
else
    test_fail "--version flag doesn't work"
fi

# ============================================================================
# Test 6: bitbot -v flag
# ============================================================================

test_section "Test 6: bitbot -v flag"
output=$(bash "$BITBOT" -v 2>&1)
if echo "$output" | grep -q "Platform:"; then
    test_pass "-v flag works"
else
    test_fail "-v flag doesn't work"
fi

# ============================================================================
# Test 7: Unknown command handling (in workspace context)
# ============================================================================

test_section "Test 7: Invalid command handling"
# Run from /tmp to test workspace context behavior
output=$(cd /tmp && bash "$BITBOT" invalidcommand 2>&1 || true)
if echo "$output" | grep -qE "(Unknown command|Workspace not initialized)"; then
    test_pass "Invalid command shows appropriate error"
else
    test_fail "Invalid command error message missing"
fi

# ============================================================================
# Test 8: Help command shows all expected commands
# ============================================================================

test_section "Test 8: Help shows all commands"
output=$(bash "$BITBOT" help 2>&1)
commands_found=0

if echo "$output" | grep -q "init"; then
    commands_found=$((commands_found + 1))
fi
if echo "$output" | grep -q "work"; then
    commands_found=$((commands_found + 1))
fi
if echo "$output" | grep -q "config"; then
    commands_found=$((commands_found + 1))
fi
if echo "$output" | grep -q "version"; then
    commands_found=$((commands_found + 1))
fi
if echo "$output" | grep -q "help"; then
    commands_found=$((commands_found + 1))
fi

if [[ $commands_found -eq 5 ]]; then
    test_pass "All 5 commands listed in help"
else
    test_fail "Only $commands_found of 5 commands found in help"
fi

# ============================================================================
# Test 9: Version shows dependency status
# ============================================================================

test_section "Test 9: Version shows dependencies"
output=$(bash "$BITBOT" version 2>&1)
deps_found=0

if echo "$output" | grep -q "Docker"; then
    deps_found=$((deps_found + 1))
fi
if echo "$output" | grep -q "Git"; then
    deps_found=$((deps_found + 1))
fi
if echo "$output" | grep -q "Platform"; then
    deps_found=$((deps_found + 1))
fi

if [[ $deps_found -ge 3 ]]; then
    test_pass "Version shows dependency information"
else
    test_fail "Version missing dependency information"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
