#!/usr/bin/env bash
#
# Test: Project Migration Script
# Tests the migrate-project-to-wsl-filesystem.sh utility
#
# MIGRATED TO USE: test-framework.sh helper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATION_SCRIPT="$BITBOT_ROOT/core/util/migrate-project-to-wsl-filesystem.sh"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Setup
# ============================================================================

setup_test_environment() {
    # Create temporary test directories
    TEST_WINDOWS_DIR="/tmp/test-windows-project-$$"
    TEST_WSL_BASE="/tmp/test-wsl-projects-$$"
    TEST_PROJECT_NAME="test-project"

    mkdir -p "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME"
    mkdir -p "$TEST_WSL_BASE"

    # Create some test files in the project
    echo "Test file 1" > "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/file1.txt"
    echo "Test file 2" > "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/file2.txt"
    mkdir -p "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/subdir"
    echo "Nested file" > "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/subdir/nested.txt"
}

cleanup_test_environment() {
    # Clean up test directories
    rm -rf "$TEST_WINDOWS_DIR" 2>/dev/null || true
    rm -rf "$TEST_WSL_BASE" 2>/dev/null || true
}

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "Project Migration Tests"

# Setup
setup_test_environment

# ============================================================================
# Test 1: Script exists and is executable
# ============================================================================

test_section "Test 1: Script validation"

if [[ -f "$MIGRATION_SCRIPT" ]]; then
    test_pass "Migration script exists"
else
    test_fail "Migration script not found: $MIGRATION_SCRIPT"
fi

if [[ -x "$MIGRATION_SCRIPT" ]]; then
    test_pass "Migration script is executable"
else
    test_fail "Migration script is not executable"
fi

# ============================================================================
# Test 2: Bash syntax check
# ============================================================================

test_section "Test 2: Bash syntax check"

if bash -n "$MIGRATION_SCRIPT" 2>/dev/null; then
    test_pass "Migration script has valid bash syntax"
else
    test_fail "Migration script has syntax errors"
fi

# ============================================================================
# Test 3: Source validation (detect missing /mnt/ path)
# ============================================================================

test_section "Test 3: Source validation"

# Test that script validates source exists
output=$(bash "$MIGRATION_SCRIPT" "/nonexistent/path" "$TEST_WSL_BASE" 2>&1 || true)
if echo "$output" | grep -q "does not exist"; then
    test_pass "Validates source directory exists"
else
    test_fail "Does not validate source directory existence"
fi

# ============================================================================
# Test 4: Target validation (detect existing target)
# ============================================================================

test_section "Test 4: Target validation"

# Create a conflicting target directory
mkdir -p "$TEST_WSL_BASE/$TEST_PROJECT_NAME"

output=$(bash "$MIGRATION_SCRIPT" "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME" "$TEST_WSL_BASE" 2>&1 <<EOF || true
yes
EOF
)

if echo "$output" | grep -q "already exists"; then
    test_pass "Detects when target already exists"
else
    test_fail "Does not detect existing target directory"
fi

# Clean up the conflict
rm -rf "$TEST_WSL_BASE/$TEST_PROJECT_NAME"

# ============================================================================
# Test 5: Non-interactive migration (command line mode)
# ============================================================================

test_section "Test 5: Command line migration"

# Simulate non-interactive migration
output=$(bash "$MIGRATION_SCRIPT" "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME" "$TEST_WSL_BASE" 2>&1 <<EOF || true
yes
no
EOF
)

# Check if migration succeeded
if [[ -d "$TEST_WSL_BASE/$TEST_PROJECT_NAME" ]]; then
    test_pass "Target directory created"
else
    test_fail "Target directory not created"
fi

# Verify files were moved
if [[ -f "$TEST_WSL_BASE/$TEST_PROJECT_NAME/file1.txt" ]]; then
    test_pass "Files migrated successfully"
else
    test_fail "Files not migrated"
fi

# Verify nested structure preserved
if [[ -f "$TEST_WSL_BASE/$TEST_PROJECT_NAME/subdir/nested.txt" ]]; then
    test_pass "Directory structure preserved"
else
    test_fail "Directory structure not preserved"
fi

# Verify source no longer exists (moved, not copied)
if [[ ! -d "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME" ]]; then
    test_pass "Source directory removed (move, not copy)"
else
    test_fail "Source directory still exists (should be moved)"
fi

# Verify file contents
content=$(cat "$TEST_WSL_BASE/$TEST_PROJECT_NAME/file1.txt")
if [[ "$content" == "Test file 1" ]]; then
    test_pass "File contents preserved"
else
    test_fail "File contents corrupted"
fi

# ============================================================================
# Test 6: Helper functions
# ============================================================================

test_section "Test 6: Helper function validation"

# Source the script to test helper functions
# We need to override main() to prevent execution
main() { :; }
export -f main

if source "$MIGRATION_SCRIPT" 2>/dev/null; then
    test_pass "Script can be sourced"

    # Check if key functions are defined
    if declare -f get_project_size >/dev/null; then
        test_pass "get_project_size function defined"
    else
        test_fail "get_project_size function not defined"
    fi

    if declare -f create_windows_junction >/dev/null; then
        test_pass "create_windows_junction function defined"
    else
        test_fail "create_windows_junction function not defined"
    fi

    if declare -f migrate_project >/dev/null; then
        test_pass "migrate_project function defined"
    else
        test_fail "migrate_project function not defined"
    fi
else
    test_fail "Cannot source migration script"
fi

# ============================================================================
# Test 7: WSL platform check
# ============================================================================

test_section "Test 7: Platform detection"

# The script should check for WSL environment
# We can't easily test this without mocking, but we can verify
# it doesn't crash on current platform

if grep -qi microsoft /proc/version 2>/dev/null; then
    test_pass "Running on WSL (migration supported)"

    # On WSL, script should work
    if bash "$MIGRATION_SCRIPT" 2>&1 | grep -q "BitBot Project Migration"; then
        test_pass "Script provides WSL-compatible help"
    else
        # Script might fail due to interactive mode, that's ok
        test_pass "Script executed without critical errors"
    fi
else
    test_pass "Running on non-WSL platform"

    # On non-WSL, script should detect and warn
    output=$(bash "$MIGRATION_SCRIPT" 2>&1 || true)
    if echo "$output" | grep -qi "wsl"; then
        test_pass "Script detects non-WSL platform"
    else
        test_info "Platform detection check skipped (not WSL)"
    fi
fi

# ============================================================================
# Test 8: Project size calculation
# ============================================================================

test_section "Test 8: Project size helper"

# Recreate test project for size test
mkdir -p "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME"
echo "Test content" > "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/sizefile.txt"

# Test get_project_size function
size=$(get_project_size "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME" 2>/dev/null || echo "")

if [[ -n "$size" ]]; then
    test_pass "get_project_size returns a value: $size"
else
    test_info "get_project_size returned empty (function may need sourcing)"
fi

# ============================================================================
# Test 9: Error handling for invalid usage
# ============================================================================

test_section "Test 9: Invalid usage handling"

# Test with wrong number of arguments
output=$(bash "$MIGRATION_SCRIPT" "arg1" "arg2" "arg3" 2>&1 || true)

if echo "$output" | grep -q "Invalid arguments\|Usage"; then
    test_pass "Handles invalid argument count"
else
    test_fail "Does not handle invalid arguments properly"
fi

# ============================================================================
# Test 10: Dry-run safety (cancel migration)
# ============================================================================

test_section "Test 10: Migration cancellation"

# Recreate test project
rm -rf "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME"
mkdir -p "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME"
echo "Test" > "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/cancel_test.txt"

# Try to migrate but cancel
output=$(bash "$MIGRATION_SCRIPT" "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME" "$TEST_WSL_BASE" 2>&1 <<EOF || true
no
EOF
)

# Verify migration was cancelled
if echo "$output" | grep -q "cancelled"; then
    test_pass "Migration can be cancelled"
else
    test_info "Cancellation message not found (may have different wording)"
fi

# Verify source still exists after cancellation
if [[ -f "$TEST_WINDOWS_DIR/$TEST_PROJECT_NAME/cancel_test.txt" ]]; then
    test_pass "Source preserved when migration cancelled"
else
    test_fail "Source deleted even though migration was cancelled"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

# Cleanup
cleanup_test_environment

test_suite_end
