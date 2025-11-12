#!/usr/bin/env bash
#
# Test: Infrastructure Sync
# Tests syncing from container/ to .bitbot/internal/container/
#
# Purpose:
#   Ensures BitBot workspaces are self-contained for Codespaces
#   while maintaining auto-update capability locally.
#
# Related: sparc/1-specification/13_CODESPACES_INFRASTRUCTURE.md
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "Infrastructure Sync Test Suite"

# ============================================================================
# Test 1: Verify source structure exists
# ============================================================================

test_section "Test 1: Source Structure"

# Test: Check container/ directory exists
if [ -d "$BITBOT_ROOT/container" ]; then
    test_pass "container/ directory exists"
else
    test_fail "container/ directory not found"
fi

# Test: Check container/bitbot/ exists
if [ -d "$BITBOT_ROOT/container/bitbot" ]; then
    test_pass "container/bitbot/ exists"
else
    test_fail "container/bitbot/ not found"
fi

# Test: Check container/templates/bitbot-base/home/ exists
if [ -d "$BITBOT_ROOT/container/templates/bitbot-base/home" ]; then
    test_pass "container/templates/bitbot-base/home/ exists"
else
    test_fail "container/templates/bitbot-base/home/ not found"
fi

# Test: Check container/templates/ exists
if [ -d "$BITBOT_ROOT/container/templates" ]; then
    test_pass "container/templates/ exists"
else
    test_fail "container/templates/ not found"
fi

# ============================================================================
# Test 2: Verify sync target exists
# ============================================================================

test_section "Test 2: Sync Target"

# Test: Check .bitbot/internal/container/ exists
if [ -d "$BITBOT_ROOT/.bitbot/internal/container" ]; then
    test_pass ".bitbot/internal/container/ exists"
else
    test_fail ".bitbot/internal/container/ not found"
fi

# ============================================================================
# Test 3: Verify sync completeness
# ============================================================================

test_section "Test 3: Sync Completeness"

# Test: Check bitbot/ directory synced
if [ -d "$BITBOT_ROOT/.bitbot/internal/container/bitbot" ]; then
    test_pass "bitbot/ directory synced"
else
    test_fail "bitbot/ directory not synced"
fi

# Test: Check templates/bitbot-base/home/ directory synced
if [ -d "$BITBOT_ROOT/.bitbot/internal/container/templates/bitbot-base/home" ]; then
    test_pass "templates/bitbot-base/home/ directory synced"
else
    test_fail "templates/bitbot-base/home/ directory not synced"
fi

# Test: Check templates/ directory synced
if [ -d "$BITBOT_ROOT/.bitbot/internal/container/templates" ]; then
    test_pass "templates/ directory synced"
else
    test_fail "templates/ directory not synced"
fi

# ============================================================================
# Test 4: Verify key files are synced
# ============================================================================

test_section "Test 4: Key Files"

# Test: Check container bitbot main script
if [ -f "$BITBOT_ROOT/.bitbot/internal/container/bitbot/bitbot" ]; then
    test_pass "container/bitbot/bitbot synced"
else
    test_fail "container/bitbot/bitbot not synced"
fi

# Test: Check tmux config
if [ -f "$BITBOT_ROOT/.bitbot/internal/container/templates/bitbot-base/home/.tmux.conf" ]; then
    test_pass "templates/bitbot-base/home/.tmux.conf synced"
else
    test_fail "templates/bitbot-base/home/.tmux.conf not synced"
fi

# Test: Check wrapper scripts
if [ -f "$BITBOT_ROOT/.bitbot/internal/container/bitbot/wrapper/claude-wrapper.sh" ]; then
    test_pass "wrapper/claude-wrapper.sh synced"
else
    test_fail "wrapper/claude-wrapper.sh not synced"
fi

# Test: Check base template
if [ -f "$BITBOT_ROOT/.bitbot/internal/container/templates/bitbot-base/devcontainer.json" ]; then
    test_pass "templates/bitbot-base/devcontainer.json synced"
else
    test_fail "templates/bitbot-base/devcontainer.json not synced"
fi

# ============================================================================
# Test 5: Verify file permissions
# ============================================================================

test_section "Test 5: File Permissions"

# Test: Check container bitbot is executable
if [ -x "$BITBOT_ROOT/.bitbot/internal/container/bitbot/bitbot" ]; then
    test_pass "bitbot/bitbot is executable"
else
    test_fail "bitbot/bitbot is not executable"
fi

# Test: Check start.sh is executable
if [ -x "$BITBOT_ROOT/.bitbot/internal/container/bitbot/core/commands/start.sh" ]; then
    test_pass "start.sh is executable"
else
    test_fail "start.sh is not executable"
fi

# Test: Check wrapper script is executable
if [ -x "$BITBOT_ROOT/.bitbot/internal/container/bitbot/wrapper/claude-wrapper.sh" ]; then
    test_pass "claude-wrapper.sh is executable"
else
    test_fail "claude-wrapper.sh is not executable"
fi

# ============================================================================
# Test 6: Verify content matches source
# ============================================================================

test_section "Test 6: Content Integrity"

# Test: Compare bitbot/bitbot content
if diff -q "$BITBOT_ROOT/container/bitbot/bitbot" "$BITBOT_ROOT/.bitbot/internal/container/bitbot/bitbot" > /dev/null 2>&1; then
    test_pass "bitbot/bitbot content matches source"
else
    test_fail "bitbot/bitbot content differs from source"
fi

# Test: Compare .tmux.conf content
if diff -q "$BITBOT_ROOT/container/templates/bitbot-base/home/.tmux.conf" "$BITBOT_ROOT/.bitbot/internal/container/templates/bitbot-base/home/.tmux.conf" > /dev/null 2>&1; then
    test_pass ".tmux.conf content matches source"
else
    test_fail ".tmux.conf content differs from source"
fi

# Test: Compare wrapper script content
if diff -q "$BITBOT_ROOT/container/bitbot/wrapper/claude-wrapper.sh" "$BITBOT_ROOT/.bitbot/internal/container/bitbot/wrapper/claude-wrapper.sh" > /dev/null 2>&1; then
    test_pass "claude-wrapper.sh content matches source"
else
    test_fail "claude-wrapper.sh content differs from source"
fi

# ============================================================================
# Test 7: Test sync idempotency
# ============================================================================

test_section "Test 7: Sync Idempotency"

# Test: Run sync again and check for changes
# Count files that would be transferred (excluding rsync's summary lines)
sync_output=$(rsync -avn --delete "$BITBOT_ROOT/container/" "$BITBOT_ROOT/.bitbot/internal/container/" 2>&1 | \
    grep -v "^sending incremental file list" | \
    grep -v "^$" | \
    grep -v "^sent .* bytes" | \
    grep -v "^total size" | \
    grep -v "speedup" || true | \
    wc -l)

if [ "$sync_output" -eq 0 ]; then
    test_pass "Sync is idempotent (no changes on re-run)"
else
    test_fail "Sync produced changes on re-run (should be idempotent): $sync_output lines"
fi

# ============================================================================
# Test 8: Test rsync command directly
# ============================================================================

test_section "Test 8: Rsync Command"

# Test: Test rsync dry-run
if rsync -an --delete "$BITBOT_ROOT/container/" "$BITBOT_ROOT/.bitbot/internal/container/" > /dev/null 2>&1; then
    test_pass "rsync command succeeds"
else
    test_fail "rsync command failed"
fi

# Test: Verify --delete flag behavior
# Create a test file that shouldn't exist
test_file="$BITBOT_ROOT/.bitbot/internal/container/test-should-be-deleted.txt"
touch "$test_file"
rsync -a --delete "$BITBOT_ROOT/container/" "$BITBOT_ROOT/.bitbot/internal/container/" > /dev/null 2>&1

if [ ! -f "$test_file" ]; then
    test_pass "rsync --delete removes extraneous files"
else
    test_fail "rsync --delete did not remove extraneous file"
    rm -f "$test_file"
fi

# ============================================================================
# Test 9: Verify directory structure count
# ============================================================================

test_section "Test 9: Structure Completeness"

# Test: Count templates synced
template_count=$(find "$BITBOT_ROOT/.bitbot/internal/container/templates" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
if [ "$template_count" -ge 4 ]; then
    test_pass "Templates synced (found $template_count templates)"
else
    test_fail "Not all templates synced (found only $template_count)"
fi

# Test: Count core commands synced
command_count=$(find "$BITBOT_ROOT/.bitbot/internal/container/bitbot/core/commands" -name "*.sh" -type f 2>/dev/null | wc -l)
if [ "$command_count" -ge 3 ]; then
    test_pass "Core commands synced (found $command_count commands)"
else
    test_fail "Not all commands synced (found only $command_count)"
fi

# Test: Count wrapper scripts synced
wrapper_count=$(find "$BITBOT_ROOT/.bitbot/internal/container/bitbot/wrapper" -name "*.sh" -type f 2>/dev/null | wc -l)
if [ "$wrapper_count" -ge 3 ]; then
    test_pass "Wrapper scripts synced (found $wrapper_count scripts)"
else
    test_fail "Not all wrapper scripts synced (found only $wrapper_count)"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
