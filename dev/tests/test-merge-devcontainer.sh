#!/usr/bin/env bash
#
# Test: DevContainer Merge System
# Tests: base.devcontainer.json + details.devcontainer.json => devcontainer.json
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MERGE_SCRIPT="$PROJECT_ROOT/container/templates/scripts/merge-devcontainer.sh"
TEST_DIR="$SCRIPT_DIR/tmp-merge-test"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "DevContainer Merge Test Suite"

# Check prerequisites
test_section "Prerequisites"

# Test: Check if jq is installed
if command -v jq &> /dev/null; then
    jq_version=$(jq --version 2>&1)
    test_pass "jq is installed ($jq_version)"
else
    test_fail "jq not found"
    echo ""
    echo -e "${YELLOW}Install jq:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  macOS:         brew install jq"
    echo "  Alpine:        apk add jq"
    echo "  Windows:       choco install jq"
    exit 1
fi

# Test: Check if merge script exists
if [ -f "$MERGE_SCRIPT" ]; then
    test_pass "Merge script exists"
else
    test_fail "Merge script not found at: $MERGE_SCRIPT"
    exit 1
fi

# Setup test directory
test_section "Test Setup"

# Test: Create test directory
mkdir -p "$TEST_DIR"
if [ -d "$TEST_DIR" ]; then
    test_pass "Test directory created"
else
    test_fail "Failed to create test directory"
    exit 1
fi

# Test 1: Basic merge
test_section "Test 1: Basic Merge"

# Test: Verify actual base template exists
BASE_TEMPLATE="$PROJECT_ROOT/container/templates/bitbot-base/.devcontainer/devcontainer.json"
if [ -f "$BASE_TEMPLATE" ]; then
    test_pass "Base template exists at bitbot-base/.devcontainer/devcontainer.json"
else
    test_fail "Base template not found at bitbot-base/.devcontainer/devcontainer.json"
    exit 1
fi

# Test: Create details.devcontainer.json
mkdir -p "$TEST_DIR/template1/.devcontainer"
cat > "$TEST_DIR/template1/.devcontainer/details.devcontainer.json" << 'EOF'
{
  "name": "Test Template",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "latest"
    }
  }
}
EOF
if [ -f "$TEST_DIR/template1/.devcontainer/details.devcontainer.json" ]; then
    test_pass "Created details.devcontainer.json test file"
else
    test_fail "Failed to create test details file"
fi

# Test: Run merge (uses actual bitbot-base/.devcontainer/devcontainer.json)
if bash "$MERGE_SCRIPT" "$TEST_DIR/template1" &> /dev/null; then
    test_pass "Merge script executed successfully"
else
    test_fail "Merge failed"
fi

# Test: Verify merged devcontainer.json exists
if [ -f "$TEST_DIR/template1/.devcontainer/devcontainer.json" ]; then
    test_pass "Merged devcontainer.json created"
else
    test_fail "Merged devcontainer.json not created"
fi

# Test: Verify merged devcontainer.json has name from details
if grep -q '"name": "Test Template"' "$TEST_DIR/template1/.devcontainer/devcontainer.json"; then
    test_pass "Name from details.json included in merge"
else
    test_fail "Name from details not in merged file"
fi

# Test: Verify merged devcontainer.json has base features from bitbot-base
if grep -q '"ghcr.io/devcontainers/features/node:1"' "$TEST_DIR/template1/.devcontainer/devcontainer.json"; then
    test_pass "Base features (node) included from bitbot-base template"
else
    test_fail "Base features not in merged file"
fi

# Test: Verify merged devcontainer.json has claude-code from base
if grep -q '"ghcr.io/anthropics/devcontainer-features/claude-code:1"' "$TEST_DIR/template1/.devcontainer/devcontainer.json"; then
    test_pass "Claude Code feature included from bitbot-base template"
else
    test_fail "Claude Code feature not in merged file"
fi

# Test: Verify merged devcontainer.json has details features
if grep -q '"ghcr.io/devcontainers/features/python:1"' "$TEST_DIR/template1/.devcontainer/devcontainer.json"; then
    test_pass "Details features (python) included in merge"
else
    test_fail "Details features not in merged file"
fi

# Test: Verify merged devcontainer.json has remoteUser from base
if grep -q '"remoteUser": "root"' "$TEST_DIR/template1/.devcontainer/devcontainer.json"; then
    test_pass "Base properties (remoteUser) included in merge"
else
    test_fail "remoteUser from base not in merged file"
fi

# Test 2: Override behavior
test_section "Test 2: Override Behavior"

# Test: Create details with override
mkdir -p "$TEST_DIR/template2/.devcontainer"
cat > "$TEST_DIR/template2/.devcontainer/details.devcontainer.json" << 'EOF'
{
  "name": "Override Test",
  "remoteUser": "vscode",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "18"
    }
  }
}
EOF
if [ -f "$TEST_DIR/template2/.devcontainer/details.devcontainer.json" ]; then
    test_pass "Created override test details.json"
else
    test_fail "Failed to create override test details"
fi

# Test: Merge with override (uses actual bitbot-base/devcontainer.json)
if bash "$MERGE_SCRIPT" "$TEST_DIR/template2" &> /dev/null; then
    test_pass "Override merge executed successfully"
else
    test_fail "Override merge failed"
fi

# Test: Verify remoteUser is overridden
if grep -q '"remoteUser": "vscode"' "$TEST_DIR/template2/.devcontainer/devcontainer.json"; then
    test_pass "Property override works (remoteUser: vscode)"
else
    test_fail "remoteUser not overridden (should be vscode)"
fi

# Test: Verify Node version is overridden
if grep -q '"version": "18"' "$TEST_DIR/template2/.devcontainer/devcontainer.json"; then
    test_pass "Feature override works (node version: 18)"
else
    test_fail "Node version not overridden (should be 18)"
fi

# Test 3: Real templates
test_section "Test 3: Real Template Tests"

# Test: Test bitbot-work template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-work" &> /dev/null; then
    test_pass "bitbot-work template merged successfully"
else
    test_fail "bitbot-work template merge failed"
fi

# Test: Verify bitbot-work devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-work/.devcontainer/devcontainer.json" ]; then
    test_pass "bitbot-work devcontainer.json created"
else
    test_fail "bitbot-work devcontainer.json not created"
fi

# Test: Test bitbot-config template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-config" &> /dev/null; then
    test_pass "bitbot-config template merged successfully"
else
    test_fail "bitbot-config template merge failed"
fi

# Test: Verify bitbot-config devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-config/.devcontainer/devcontainer.json" ]; then
    test_pass "bitbot-config devcontainer.json created"
else
    test_fail "bitbot-config devcontainer.json not created"
fi

# Test: Test bitbot-dev template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-dev" &> /dev/null; then
    test_pass "bitbot-dev template merged successfully"
else
    test_fail "bitbot-dev template merge failed"
fi

# Test: Verify bitbot-dev devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-dev/.devcontainer/devcontainer.json" ]; then
    test_pass "bitbot-dev devcontainer.json created"
else
    test_fail "bitbot-dev devcontainer.json not created"
fi

# Note: bitbot-base is the standalone base template (no merge needed)

# Cleanup
test_section "Cleanup"

# Test: Remove test directory
rm -rf "$TEST_DIR"
if [ ! -d "$TEST_DIR" ]; then
    test_pass "Test directory removed successfully"
else
    test_fail "Failed to remove test directory"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
