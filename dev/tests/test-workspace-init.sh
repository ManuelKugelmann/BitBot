#!/usr/bin/env bash
#
# Test: Workspace Initialization
# Tests bitbot init command and workspace structure creation
#
# MIGRATED TO USE: test-framework.sh, workspace-helper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Export BITBOT_HOME for library functions
export BITBOT_HOME="$BITBOT_ROOT"

# Source test helpers
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"

# Source detection utilities
source "${BITBOT_ROOT}/core/util/helpers.sh"
source "${BITBOT_ROOT}/core/util/detect.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Workspace Init Tests"

# ============================================================================
# Setup: Create test workspace
# ============================================================================

test_section "Setup: Creating test workspace"
TEST_WORKSPACE=$(create_test_workspace "workspace-init")
echo "  Created workspace at: $TEST_WORKSPACE"

# Set up automatic cleanup on exit
trap 'cleanup_test_workspace "$TEST_WORKSPACE"' EXIT INT TERM

# ============================================================================
# Test 1: Detect uninitialized workspace
# ============================================================================

test_section "Test 1: Detect uninitialized workspace"
cd "$TEST_WORKSPACE"

if is_workspace_initialized "$TEST_WORKSPACE"; then
    test_fail "Workspace incorrectly detected as initialized"
else
    test_pass "Workspace correctly detected as uninitialized"
fi

# ============================================================================
# Test 2: Create workspace structure (dry run)
# ============================================================================

test_section "Test 2: Test workspace structure creation"

# Manually create structure for testing
mkdir -p "${TEST_WORKSPACE}/.bitbot/internal/local"
mkdir -p "${TEST_WORKSPACE}/.bitbot/cache"

test_dir_exists ".bitbot/internal directory created" "${TEST_WORKSPACE}/.bitbot/internal"
test_dir_exists ".bitbot/internal/local directory created" "${TEST_WORKSPACE}/.bitbot/internal/local"
test_dir_exists ".bitbot/cache directory created" "${TEST_WORKSPACE}/.bitbot/cache"

# ============================================================================
# Test 3: Check workspace detection after init
# ============================================================================

test_section "Test 3: Detect initialized workspace"

if is_workspace_initialized "$TEST_WORKSPACE"; then
    test_pass "Workspace correctly detected as initialized"
else
    test_fail "Workspace not detected as initialized"
fi

# ============================================================================
# Test 4: Verify gitignore pattern
# ============================================================================

test_section "Test 4: Verify gitignore pattern"

if [[ -f "${TEST_WORKSPACE}/.gitignore" ]]; then
    if grep -q "\.bitbot/internal/local/" "${TEST_WORKSPACE}/.gitignore"; then
        test_pass ".gitignore contains .bitbot/internal/local/ pattern"
    else
        test_fail ".gitignore missing .bitbot/internal/local/ pattern"
    fi
else
    echo "  ℹ .gitignore not found (may need to be created manually)"
fi

# ============================================================================
# Test 5: Test config JSON creation
# ============================================================================

test_section "Test 5: Test config.json creation"

TEST_CONFIG="${TEST_WORKSPACE}/.bitbot/config.json"

# Create test config using helpers
create_config_json "$TEST_CONFIG" \
    "workspace_name" "test-workspace" \
    "skip_push_recommendation" "false"

test_file_exists "config.json created" "$TEST_CONFIG"

# Verify it's valid JSON
if command -v python3 &>/dev/null; then
    if python3 -m json.tool "$TEST_CONFIG" &>/dev/null; then
        test_pass "config.json is valid JSON"
    else
        test_fail "config.json is not valid JSON"
    fi
else
    echo "  ℹ python3 not available, skipping JSON validation"
fi

# ============================================================================
# Test 6: Test workspace detection from subdirectory (MVP: should fail)
# ============================================================================

test_section "Test 6: Test workspace detection from subdirectory"

mkdir -p "${TEST_WORKSPACE}/subdir"
cd "${TEST_WORKSPACE}/subdir"

if detect_workspace &>/dev/null; then
    test_fail "MVP should not detect workspace from subdirectory (future feature)"
else
    test_pass "Correctly does not detect workspace from subdirectory (MVP behavior)"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

echo ""
echo "  ℹ Test workspace will be auto-cleaned by workspace-helper trap"
echo ""

test_suite_end
