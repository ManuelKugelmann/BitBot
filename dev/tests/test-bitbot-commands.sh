#!/usr/bin/env bash
#
# Test: BitBot Command Handling
# Tests bitbot help, version, and error handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BITBOT="$BITBOT_ROOT/bitbot"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    pass_count=$((pass_count + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    fail_count=$((fail_count + 1))
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

echo ""
echo "=== BitBot Command Tests ==="
echo ""

# ============================================================================
# Test 1: bitbot help command
# ============================================================================

echo "[Test 1] bitbot help command..."
output=$(bash "$BITBOT" help 2>&1)
if echo "$output" | grep -q "Usage:"; then
    test_pass "help command shows usage"
else
    test_fail "help command missing usage section"
fi

# ============================================================================
# Test 2: bitbot --help flag
# ============================================================================

echo "[Test 2] bitbot --help flag..."
output=$(bash "$BITBOT" --help 2>&1)
if echo "$output" | grep -q "Usage:"; then
    test_pass "--help flag works"
else
    test_fail "--help flag doesn't work"
fi

# ============================================================================
# Test 3: bitbot -h flag
# ============================================================================

echo "[Test 3] bitbot -h flag..."
output=$(bash "$BITBOT" -h 2>&1)
if echo "$output" | grep -q "Commands:"; then
    test_pass "-h flag works"
else
    test_fail "-h flag doesn't work"
fi

# ============================================================================
# Test 4: bitbot version command
# ============================================================================

echo "[Test 4] bitbot version command..."
output=$(bash "$BITBOT" version 2>&1)
if echo "$output" | grep -q "BitBot version"; then
    test_pass "version command shows version"
else
    test_fail "version command missing version info"
fi

# ============================================================================
# Test 5: bitbot --version flag
# ============================================================================

echo "[Test 5] bitbot --version flag..."
output=$(bash "$BITBOT" --version 2>&1)
if echo "$output" | grep -q "BitBot Dependency Status"; then
    test_pass "--version flag works"
else
    test_fail "--version flag doesn't work"
fi

# ============================================================================
# Test 6: bitbot -v flag
# ============================================================================

echo "[Test 6] bitbot -v flag..."
output=$(bash "$BITBOT" -v 2>&1)
if echo "$output" | grep -q "Platform:"; then
    test_pass "-v flag works"
else
    test_fail "-v flag doesn't work"
fi

# ============================================================================
# Test 7: Unknown command handling (in workspace context)
# ============================================================================

echo "[Test 7] Invalid command handling..."
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

echo "[Test 8] Help shows all commands..."
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

echo "[Test 9] Version shows dependencies..."
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
# Summary
# ============================================================================

echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
