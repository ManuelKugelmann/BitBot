#!/usr/bin/env bash
#
# Test: Project Migration Script
# Tests the migrate-project-to-wsl-filesystem.sh utility
#
# MIGRATED TO USE: test-framework.sh helper
#
# SAFETY: This test does NOT migrate the BitBot repository!
# It only validates the migration script's structure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATION_SCRIPT="$BITBOT_ROOT/core/util/migrate-project-to-wsl-filesystem.sh"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "Project Migration Tests"

# ============================================================================
# Test 1: Script validation
# ============================================================================

test_section "Test 1: Script validation"

if [[ -f "$MIGRATION_SCRIPT" ]]; then
    test_pass "Migration script exists"
else
    test_fail "Migration script not found"
fi

if [[ -x "$MIGRATION_SCRIPT" ]]; then
    test_pass "Migration script is executable"
else
    test_fail "Migration script is not executable"
fi

# ============================================================================
# Test 2: Bash syntax
# ============================================================================

test_section "Test 2: Bash syntax check"

if bash -n "$MIGRATION_SCRIPT" 2>/dev/null; then
    test_pass "Valid bash syntax"
else
    test_fail "Syntax errors found"
fi

# ============================================================================
# Test 3: Usage information
# ============================================================================

test_section "Test 3: Usage information"

output=$(bash "$MIGRATION_SCRIPT" "arg1" "arg2" "arg3" 2>&1 || true)

if echo "$output" | grep -q "Invalid arguments\|Usage"; then
    test_pass "Provides usage information"
else
    test_fail "Missing usage information"
fi

# ============================================================================
# Test 4: Script structure
# ============================================================================

test_section "Test 4: Script structure"

if grep -q "show_banner" "$MIGRATION_SCRIPT"; then
    test_pass "Contains show_banner function"
else
    test_fail "Missing show_banner function"
fi

if grep -q "migrate_project" "$MIGRATION_SCRIPT"; then
    test_pass "Contains migrate_project function"
else
    test_fail "Missing migrate_project function"
fi

if grep -q "interactive_mode" "$MIGRATION_SCRIPT"; then
    test_pass "Contains interactive_mode function"
else
    test_fail "Missing interactive_mode function"
fi

if grep -q "prompt_yes_no\|should_migrate" "$MIGRATION_SCRIPT"; then
    test_pass "Contains safety confirmations"
else
    test_fail "Missing safety confirmations"
fi

if grep -q "mklink\|wslpath" "$MIGRATION_SCRIPT"; then
    test_pass "Contains Windows junction support"
else
    test_fail "Missing Windows junction support"
fi

# ============================================================================
# Test 5: Error handling
# ============================================================================

test_section "Test 5: Error handling"

if grep -q "set -euo pipefail" "$MIGRATION_SCRIPT"; then
    test_pass "Uses strict error handling"
else
    test_fail "Missing strict error handling"
fi

if grep -q "print_error\|return 1" "$MIGRATION_SCRIPT"; then
    test_pass "Contains error reporting"
else
    test_fail "Missing error reporting"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
