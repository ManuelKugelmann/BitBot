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

# Test: Create base.devcontainer.json
mkdir -p "$TEST_DIR/shared"
cat > "$TEST_DIR/shared/base.devcontainer.json" << 'EOF'
{
  "workspaceFolder": "/workspace",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  },
  "remoteUser": "root"
}
EOF
if [ -f "$TEST_DIR/shared/base.devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "Failed to create test base file"
fi

# Test: Create details.devcontainer.json
mkdir -p "$TEST_DIR/template1"
cat > "$TEST_DIR/template1/details.devcontainer.json" << 'EOF'
{
  "name": "Test Template",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {
      "version": "latest"
    }
  }
}
EOF
if [ -f "$TEST_DIR/template1/details.devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "Failed to create test details file"
fi

# Test: Run merge
# Temporarily copy base to test location
mkdir -p "$PROJECT_ROOT/container/templates/shared"
cp "$TEST_DIR/shared/base.devcontainer.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.bak"
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json" ]; then
    cp "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original"
fi
cp "$TEST_DIR/shared/base.devcontainer.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"

if bash "$MERGE_SCRIPT" "$TEST_DIR/template1" &> /dev/null; then
    test_pass "Test passed"
else
    test_fail "Merge failed"
fi

# Restore original base
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" ]; then
    mv "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
else
    rm "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
fi

# Test: Verify merged devcontainer.json exists
if [ -f "$TEST_DIR/template1/devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "Merged devcontainer.json not created"
fi

# Test: Verify merged devcontainer.json has name from details
if grep -q '"name": "Test Template"' "$TEST_DIR/template1/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "Name from details not in merged file"
fi

# Test: Verify merged devcontainer.json has base features
if grep -q '"ghcr.io/devcontainers/features/node:1"' "$TEST_DIR/template1/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "Base features not in merged file"
fi

# Test: Verify merged devcontainer.json has details features
if grep -q '"ghcr.io/anthropics/devcontainer-features/claude-code:1"' "$TEST_DIR/template1/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "Details features not in merged file"
fi

# Test: Verify merged devcontainer.json has remoteUser from base
if grep -q '"remoteUser": "root"' "$TEST_DIR/template1/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "remoteUser from base not in merged file"
fi

# Test 2: Override behavior
test_section "Test 2: Override Behavior"

# Test: Create details with override
mkdir -p "$TEST_DIR/template2"
cat > "$TEST_DIR/template2/details.devcontainer.json" << 'EOF'
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
if [ -f "$TEST_DIR/template2/details.devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "Failed to create override test details"
fi

# Test: Merge with override
cp "$TEST_DIR/shared/base.devcontainer.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
if bash "$MERGE_SCRIPT" "$TEST_DIR/template2" &> /dev/null; then
    test_pass "Test passed"
else
    test_fail "Override merge failed"
fi
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" ]; then
    mv "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
fi

# Test: Verify remoteUser is overridden
if grep -q '"remoteUser": "vscode"' "$TEST_DIR/template2/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "remoteUser not overridden (should be vscode)"
fi

# Test: Verify Node version is overridden
if grep -q '"version": "18"' "$TEST_DIR/template2/devcontainer.json"; then
    test_pass "Test passed"
else
    test_fail "Node version not overridden (should be 18)"
fi

# Test 3: Real templates
test_section "Test 3: Real Template Tests"

# Test: Test bitbot-work template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-work" &> /dev/null; then
    test_pass "Test passed"
else
    test_fail "bitbot-work template merge failed"
fi

# Test: Verify bitbot-work devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-work/devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "bitbot-work devcontainer.json not created"
fi

# Test: Test bitbot-config template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-config" &> /dev/null; then
    test_pass "Test passed"
else
    test_fail "bitbot-config template merge failed"
fi

# Test: Verify bitbot-config devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-config/devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "bitbot-config devcontainer.json not created"
fi

# Test: Test bitbot-base template merge
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-base" &> /dev/null; then
    test_pass "Test passed"
else
    test_fail "bitbot-base template merge failed"
fi

# Test: Verify bitbot-base devcontainer.json created
if [ -f "$PROJECT_ROOT/container/templates/bitbot-base/devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "bitbot-base devcontainer.json not created"
fi

# Cleanup
test_section "Cleanup"

# Test: Remove test directory
rm -rf "$TEST_DIR"
if [ ! -d "$TEST_DIR" ]; then
    test_pass "Test passed"
else
    test_fail "Failed to remove test directory"
fi

# Test: Remove test base file
rm -f "$TEST_DIR/shared/base.devcontainer.json"
rm -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.bak"
if [ ! -f "$TEST_DIR/shared/base.devcontainer.json" ]; then
    test_pass "Test passed"
else
    test_fail "Failed to remove test base file"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
