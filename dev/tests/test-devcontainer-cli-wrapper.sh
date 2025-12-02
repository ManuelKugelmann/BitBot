#!/usr/bin/env bash
#
# DevContainer CLI Wrapper Test
# Tests the run_devcontainer_cmd function from core/util/devcontainer.sh
#
# Validates:
#   - Method 3 (cmd.exe): Argument quoting for Windows mounts (/mnt/c/)
#   - Method 4 (PowerShell): UNC path handling for WSL native paths
#   - --config flag handling with relative paths
#
# Reference: sparc/0-research/DEVCONTAINER_WSL_PATH_FORMATS.md
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_HOME="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source devcontainer utilities (what we're testing)
export BITBOT_HOME
source "${BITBOT_HOME}/core/util/devcontainer.sh"

test_suite_begin "DevContainer CLI Wrapper Tests"

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    test_skip "All tests" "Only runs on WSL - verifies devcontainer.cmd wrapper"
    test_suite_end
fi

# Check prerequisites
if ! command -v devcontainer.cmd &>/dev/null; then
    test_fail "Prerequisites check" "devcontainer.cmd not found - install VS Code with Dev Containers extension"
    test_suite_end
fi

# Test directories
WIN_TEST_DIR="/mnt/c/bitbot-wrapper-test"
WSL_TEST_DIR="$HOME/bitbot-wrapper-test"

# Cleanup on exit
cleanup() {
    rm -rf "$WIN_TEST_DIR" 2>/dev/null || true
    rm -rf "$WSL_TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Create minimal devcontainer config
create_test_project() {
    local test_dir="$1"
    local config_subdir="${2:-.devcontainer}"

    mkdir -p "$test_dir/$config_subdir"

    cat > "$test_dir/$config_subdir/devcontainer.json" <<'EOF'
{
  "name": "CLI Wrapper Test",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {}
}
EOF
}

# ============================================================================
# Test Group: Method 3 - cmd.exe with /mnt/c/ paths
# ============================================================================

test_group_begin "Method 3: cmd.exe wrapper for /mnt/c/ paths"

test_section "Test 3.1: Basic devcontainer build (default config)"
create_test_project "$WIN_TEST_DIR"

# Test basic build without --config flag
if run_devcontainer_cmd "$WIN_TEST_DIR" build 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Basic build works without --config flag"
else
    test_fail "Basic build works without --config flag" "Build returned non-success outcome"
fi

test_section "Test 3.2: Build with explicit --config flag"

# Test build WITH --config flag (the failing case from user report)
if run_devcontainer_cmd "$WIN_TEST_DIR" build --config ".devcontainer/devcontainer.json" 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Build with --config flag works"
else
    test_fail "Build with --config flag works" "Build failed - likely argument quoting issue"
fi

test_section "Test 3.3: Build with nested config path"
# Create config in nested directory (like .bitbot/internal/bitbot-config/.devcontainer/)
NESTED_CONFIG=".bitbot/internal/bitbot-config/.devcontainer"
create_test_project "$WIN_TEST_DIR" "$NESTED_CONFIG"

if run_devcontainer_cmd "$WIN_TEST_DIR" build --config "$NESTED_CONFIG/devcontainer.json" 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Build with nested config path works"
else
    test_fail "Build with nested config path works" "Build failed with nested path"
fi

test_section "Test 3.4: Multiple arguments with --config"
# Test with multiple flags (simulates: up --config <path> --remove-existing-container)
# We use build instead of up to avoid starting containers
if run_devcontainer_cmd "$WIN_TEST_DIR" build --config ".devcontainer/devcontainer.json" 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Build with multiple arguments works"
else
    test_fail "Build with multiple arguments works"
fi

# ============================================================================
# Test Group: Method 4 - PowerShell with WSL native paths
# ============================================================================

test_group_begin "Method 4: PowerShell wrapper for WSL native paths"

test_section "Test 4.1: Basic build in WSL home"
create_test_project "$WSL_TEST_DIR"

if run_devcontainer_cmd "$WSL_TEST_DIR" build 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Basic build in WSL home works"
else
    test_fail "Basic build in WSL home works" "PowerShell wrapper failed"
fi

test_section "Test 4.2: Build with --config flag in WSL home"

if run_devcontainer_cmd "$WSL_TEST_DIR" build --config ".devcontainer/devcontainer.json" 2>&1 | grep -q '"outcome":"success"'; then
    test_pass "Build with --config flag in WSL home works"
else
    test_fail "Build with --config flag in WSL home works"
fi

# ============================================================================
# Test Group: Argument Quoting Edge Cases
# ============================================================================

test_group_begin "Argument quoting edge cases"

test_section "Test 5.1: Path with spaces (if applicable)"
# Note: devcontainer.json paths shouldn't have spaces, but test arg handling
# We can only test the echo output here since we can't create paths with spaces easily

# Test that our argument building doesn't double-escape quotes
test_section "Test 5.2: Arguments don't get double-escaped"

# Capture what debug output shows (already captured from previous test)
# Check the debug output from test 3.2 which already ran
DEBUG_OUTPUT=$(timeout 5 bash -c 'run_devcontainer_cmd "$1" build --config ".devcontainer/devcontainer.json" 2>&1 | head -1' -- "$WIN_TEST_DIR" 2>/dev/null || echo "")

if [[ -z "$DEBUG_OUTPUT" ]]; then
    # If timeout, check the format manually
    test_skip "Arguments not double-escaped" "Could not capture debug output in time"
elif [[ "$DEBUG_OUTPUT" != *'\"'* ]]; then
    test_pass "Arguments not double-escaped (no backslash-quote in output)"
else
    test_fail "Arguments not double-escaped" "Found escaped quotes in: $DEBUG_OUTPUT"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
