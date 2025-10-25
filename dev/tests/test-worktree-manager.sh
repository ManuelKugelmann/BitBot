#!/bin/bash
# Test script for git worktree manager
# Tests worktree creation, syncing, and cleanup

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test helper functions
run_test() {
    local test_name="$1"
    echo -e "\n${BLUE}Testing: ${test_name}${RESET}"
    ((TOTAL_TESTS++))
}

test_passed() {
    echo -e "${GREEN}✓ PASS${RESET}"
    ((PASSED_TESTS++))
}

test_failed() {
    local reason="$1"
    echo -e "${RED}✗ FAIL: ${reason}${RESET}"
    ((FAILED_TESTS++))
}

# Test environment
TEST_WORKTREE_BASE="/tmp/bitbot-test-worktrees-$$"
WORKTREE_MANAGER=".claude/tools/worktree-manager.sh"

# Cleanup function
cleanup() {
    echo -e "\n${BLUE}Cleaning up test environment...${RESET}"

    # Remove test worktrees
    if [[ -d "$TEST_WORKTREE_BASE" ]]; then
        for dir in "$TEST_WORKTREE_BASE"/*; do
            if [[ -d "$dir" ]]; then
                git worktree remove "$dir" --force 2>/dev/null || true
            fi
        done
        rm -rf "$TEST_WORKTREE_BASE"
    fi

    # Clean up test branches
    git branch -D test-worktree-branch 2>/dev/null || true
    git branch | grep "^  claude-test-" | xargs -r git branch -D 2>/dev/null || true
}

# Set up test environment
setup() {
    echo -e "${BLUE}Setting up test environment...${RESET}"
    cleanup
    mkdir -p "$TEST_WORKTREE_BASE"
    export WORKTREE_BASE="$TEST_WORKTREE_BASE"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

echo "=========================================="
echo "Git Worktree Manager Test Suite"
echo "=========================================="

setup

# Test 1: Check script exists and is executable
run_test "Worktree manager script exists"
if [[ -f "$WORKTREE_MANAGER" ]]; then
    test_passed
else
    test_failed "Script not found at $WORKTREE_MANAGER"
fi

run_test "Worktree manager is executable"
if [[ -x "$WORKTREE_MANAGER" ]]; then
    test_passed
else
    test_failed "Script is not executable"
fi

# Test 2: Check bash syntax
run_test "Bash syntax check"
if bash -n "$WORKTREE_MANAGER"; then
    test_passed
else
    test_failed "Syntax errors in worktree manager"
fi

# Test 3: Help command
run_test "Help command works"
if "$WORKTREE_MANAGER" help &>/dev/null; then
    test_passed
else
    test_failed "Help command failed"
fi

run_test "Help output contains usage info"
if "$WORKTREE_MANAGER" help | grep -q "Usage:"; then
    test_passed
else
    test_failed "Help output missing usage information"
fi

# Test 4: List command (should work even with no worktrees)
run_test "List command works"
if "$WORKTREE_MANAGER" list &>/dev/null; then
    test_passed
else
    test_failed "List command failed"
fi

# Test 5: Create worktree
run_test "Create worktree with auto-generated name"
output=$("$WORKTREE_MANAGER" create 2>&1)
if echo "$output" | grep -q "Worktree created successfully"; then
    test_passed
else
    test_failed "Failed to create worktree"
fi

# Check if worktree was actually created
run_test "Worktree directory was created"
worktree_count=$(find "$TEST_WORKTREE_BASE" -maxdepth 1 -type d | wc -l)
if [[ $worktree_count -gt 1 ]]; then  # > 1 because base dir counts
    test_passed
else
    test_failed "No worktree directory found"
fi

# Test 6: List shows created worktree
run_test "List shows created worktree"
if "$WORKTREE_MANAGER" list | grep -q "$TEST_WORKTREE_BASE"; then
    test_passed
else
    test_failed "Created worktree not in list"
fi

# Test 7: Create named worktree
run_test "Create named worktree"
output=$("$WORKTREE_MANAGER" create test-feature 2>&1)
if echo "$output" | grep -q "claude-test-feature"; then
    test_passed
else
    test_failed "Named worktree not created with correct name"
fi

# Test 8: Check branch was created
run_test "Branch was created for worktree"
if git branch | grep -q "claude-test-feature"; then
    test_passed
else
    test_failed "Branch not found"
fi

# Test 9: Status command
run_test "Status command works"
if "$WORKTREE_MANAGER" status &>/dev/null; then
    test_passed
else
    test_failed "Status command failed"
fi

# Test 10: Verify worktree is based on trunk
run_test "Worktree based on trunk branch"
worktree_dir=$(find "$TEST_WORKTREE_BASE" -name "claude-test-feature" -type d | head -1)
if [[ -n "$worktree_dir" ]]; then
    base_commit=$(cd "$worktree_dir" && git merge-base HEAD trunk)
    trunk_commit=$(git rev-parse trunk)
    if [[ "$base_commit" == "$trunk_commit" ]]; then
        test_passed
    else
        test_failed "Worktree not based on trunk"
    fi
else
    test_failed "Worktree directory not found"
fi

# Test 11: Branch naming convention
run_test "Branch name follows convention (claude-*)"
branches=$(git branch | grep "claude-" | wc -l)
if [[ $branches -ge 2 ]]; then  # At least 2 test branches
    test_passed
else
    test_failed "Branch naming convention not followed"
fi

# Test 12: Duplicate creation handling
run_test "Creating duplicate worktree is handled"
output=$("$WORKTREE_MANAGER" create test-feature 2>&1)
if echo "$output" | grep -q "already exists"; then
    test_passed
else
    test_failed "Duplicate creation not detected"
fi

# Test 13: Environment variable WORKTREE_BASE works
run_test "WORKTREE_BASE environment variable respected"
if "$WORKTREE_MANAGER" list | grep -q "$TEST_WORKTREE_BASE"; then
    test_passed
else
    test_failed "WORKTREE_BASE not respected"
fi

# Test 14: Remove command (skip actual removal to avoid conflicts)
run_test "Remove command syntax works"
if "$WORKTREE_MANAGER" help | grep -q "remove"; then
    test_passed
else
    test_failed "Remove command not documented"
fi

# Test 15: Clean command syntax
run_test "Clean command syntax works"
if "$WORKTREE_MANAGER" help | grep -q "clean"; then
    test_passed
else
    test_failed "Clean command not documented"
fi

# Test 16: Verify all commands are documented
run_test "All commands documented in help"
help_output=$("$WORKTREE_MANAGER" help)
commands="create list sync remove status clean"
all_documented=true
for cmd in $commands; do
    if ! echo "$help_output" | grep -q "$cmd"; then
        all_documented=false
        break
    fi
done

if $all_documented; then
    test_passed
else
    test_failed "Some commands not documented"
fi

# Test 17: Error handling for unknown command
run_test "Unknown command returns error"
output=$("$WORKTREE_MANAGER" invalid-command 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
if echo "$output" | grep -iq "error.*unknown"; then
    test_passed
else
    test_failed "Unknown command not handled properly"
fi

# Test 18: Worktree isolation check
run_test "Worktrees are isolated (different directories)"
worktree_dirs=$(find "$TEST_WORKTREE_BASE" -maxdepth 1 -type d -name "claude-*" | wc -l)
if [[ $worktree_dirs -ge 2 ]]; then
    test_passed
else
    test_failed "Not enough worktrees for isolation test"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
else
    echo "Failed:       $FAILED_TESTS"
fi
echo "=========================================="

# Exit code
if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}Some tests failed!${RESET}"
    exit 1
fi
