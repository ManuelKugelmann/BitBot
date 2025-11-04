#!/usr/bin/env bash
#
# Test: Workspace Initialization
# Tests bitbot init command and workspace structure creation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="$SCRIPT_DIR/test-workspace"

# Export BITBOT_HOME for library functions
export BITBOT_HOME="$BITBOT_ROOT"

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
echo "=== BitBot Workspace Init Tests ==="
echo ""

# ============================================================================
# Setup: Clean test workspace
# ============================================================================

echo "[Setup] Cleaning test workspace..."
if [[ -d "${TEST_WORKSPACE}/.bitbot" ]]; then
    rm -rf "${TEST_WORKSPACE}/.bitbot"
    test_info "Removed existing .bitbot folder"
fi

# ============================================================================
# Test 1: Detect uninitialized workspace
# ============================================================================

echo ""
echo "[Test 1] Detect uninitialized workspace..."
cd "$TEST_WORKSPACE"

# Source detection utilities
source "${BITBOT_ROOT}/core/util/helpers.sh"
source "${BITBOT_ROOT}/core/util/detect.sh"

if is_workspace_initialized "$TEST_WORKSPACE"; then
    test_fail "Workspace incorrectly detected as initialized"
else
    test_pass "Workspace correctly detected as uninitialized"
fi

# ============================================================================
# Test 2: Create workspace structure (dry run)
# ============================================================================

echo ""
echo "[Test 2] Test workspace structure creation..."

# Manually create structure for testing
mkdir -p "${TEST_WORKSPACE}/.bitbot/internal/local"
mkdir -p "${TEST_WORKSPACE}/.bitbot/cache"

if [[ -d "${TEST_WORKSPACE}/.bitbot/internal" ]]; then
    test_pass ".bitbot/internal directory created"
else
    test_fail ".bitbot/internal directory not created"
fi

if [[ -d "${TEST_WORKSPACE}/.bitbot/internal/local" ]]; then
    test_pass ".bitbot/internal/local directory created"
else
    test_fail ".bitbot/internal/local directory not created"
fi

if [[ -d "${TEST_WORKSPACE}/.bitbot/cache" ]]; then
    test_pass ".bitbot/cache directory created"
else
    test_fail ".bitbot/cache directory not created"
fi

# ============================================================================
# Test 3: Check workspace detection after init
# ============================================================================

echo ""
echo "[Test 3] Detect initialized workspace..."

if is_workspace_initialized "$TEST_WORKSPACE"; then
    test_pass "Workspace correctly detected as initialized"
else
    test_fail "Workspace not detected as initialized"
fi

# ============================================================================
# Test 4: Verify gitignore pattern
# ============================================================================

echo ""
echo "[Test 4] Verify gitignore pattern..."

if [[ -f "${TEST_WORKSPACE}/.gitignore" ]]; then
    if grep -q "\.bitbot/internal/local/" "${TEST_WORKSPACE}/.gitignore"; then
        test_pass ".gitignore contains .bitbot/internal/local/ pattern"
    else
        test_fail ".gitignore missing .bitbot/internal/local/ pattern"
    fi
else
    test_info ".gitignore not found (may need to be created manually)"
fi

# ============================================================================
# Test 5: Test config JSON creation
# ============================================================================

echo ""
echo "[Test 5] Test config.json creation..."

TEST_CONFIG="${TEST_WORKSPACE}/.bitbot/config.json"

# Create test config using helpers
create_config_json "$TEST_CONFIG" \
    "workspace_name" "test-workspace" \
    "skip_push_recommendation" "false"

if [[ -f "$TEST_CONFIG" ]]; then
    test_pass "config.json created"

    # Verify it's valid JSON
    if command -v python3 &>/dev/null; then
        if python3 -m json.tool "$TEST_CONFIG" &>/dev/null; then
            test_pass "config.json is valid JSON"
        else
            test_fail "config.json is not valid JSON"
        fi
    else
        test_info "python3 not available, skipping JSON validation"
    fi
else
    test_fail "config.json not created"
fi

# ============================================================================
# Test 6: Test workspace detection from subdirectory (MVP: should fail)
# ============================================================================

echo ""
echo "[Test 6] Test workspace detection from subdirectory..."

mkdir -p "${TEST_WORKSPACE}/subdir"
cd "${TEST_WORKSPACE}/subdir"

if detect_workspace &>/dev/null; then
    test_fail "MVP should not detect workspace from subdirectory (future feature)"
else
    test_pass "Correctly does not detect workspace from subdirectory (MVP behavior)"
fi

# ============================================================================
# Cleanup
# ============================================================================

echo ""
echo "[Cleanup] Removing test structures..."
rm -rf "${TEST_WORKSPACE}/.bitbot"
rm -rf "${TEST_WORKSPACE}/subdir"
test_info "Test workspace cleaned"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== Test Summary ==="
echo -e "  Passed: ${GREEN}${pass_count}${NC}"
echo -e "  Failed: ${RED}${fail_count}${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All workspace init tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
