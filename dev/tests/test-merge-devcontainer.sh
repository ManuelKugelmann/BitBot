#!/bin/bash
set -e

# Test script for devcontainer merge system
# Tests: base.devcontainer.json + details.devcontainer.json => devcontainer.json

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helpers
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}[TEST $TESTS_RUN]${NC} $1"
}

test_passed() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}  ✓ PASS${NC}"
}

test_failed() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}  ✗ FAIL: $1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══ $1 ═══${NC}"
}

# Setup
print_section "DevContainer Merge Test Suite"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MERGE_SCRIPT="$PROJECT_ROOT/container/templates/shared/scripts/merge-devcontainer.sh"
TEST_DIR="$SCRIPT_DIR/tmp-merge-test"

# Check prerequisites
print_section "Prerequisites"

run_test "Check if jq is installed"
if command -v jq &> /dev/null; then
    test_passed
    echo "    jq version: $(jq --version)"
else
    test_failed "jq not found"
    echo ""
    echo -e "${YELLOW}Install jq:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  macOS:         brew install jq"
    echo "  Alpine:        apk add jq"
    echo "  Windows:       choco install jq"
    exit 1
fi

run_test "Check if merge script exists"
if [ -f "$MERGE_SCRIPT" ]; then
    test_passed
else
    test_failed "Merge script not found at: $MERGE_SCRIPT"
    exit 1
fi

# Setup test directory
print_section "Test Setup"

run_test "Create test directory"
mkdir -p "$TEST_DIR"
if [ -d "$TEST_DIR" ]; then
    test_passed
else
    test_failed "Failed to create test directory"
    exit 1
fi

# Test 1: Basic merge
print_section "Test 1: Basic Merge"

run_test "Create base.devcontainer.json"
cat > "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" << 'EOF'
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
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" ]; then
    test_passed
else
    test_failed "Failed to create test base file"
fi

run_test "Create details.devcontainer.json"
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
    test_passed
else
    test_failed "Failed to create test details file"
fi

run_test "Run merge"
# Temporarily copy base to test location
cp "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.bak"
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json" ]; then
    cp "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original"
fi
cp "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"

if bash "$MERGE_SCRIPT" "$TEST_DIR/template1" &> /dev/null; then
    test_passed
else
    test_failed "Merge failed"
fi

# Restore original base
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" ]; then
    mv "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
else
    rm "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
fi

run_test "Verify merged devcontainer.json exists"
if [ -f "$TEST_DIR/template1/devcontainer.json" ]; then
    test_passed
else
    test_failed "Merged devcontainer.json not created"
fi

run_test "Verify merged devcontainer.json has name from details"
if grep -q '"name": "Test Template"' "$TEST_DIR/template1/devcontainer.json"; then
    test_passed
else
    test_failed "Name from details not in merged file"
fi

run_test "Verify merged devcontainer.json has base features"
if grep -q '"ghcr.io/devcontainers/features/node:1"' "$TEST_DIR/template1/devcontainer.json"; then
    test_passed
else
    test_failed "Base features not in merged file"
fi

run_test "Verify merged devcontainer.json has details features"
if grep -q '"ghcr.io/anthropics/devcontainer-features/claude-code:1"' "$TEST_DIR/template1/devcontainer.json"; then
    test_passed
else
    test_failed "Details features not in merged file"
fi

run_test "Verify merged devcontainer.json has remoteUser from base"
if grep -q '"remoteUser": "root"' "$TEST_DIR/template1/devcontainer.json"; then
    test_passed
else
    test_failed "remoteUser from base not in merged file"
fi

# Test 2: Override behavior
print_section "Test 2: Override Behavior"

run_test "Create details with override"
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
    test_passed
else
    test_failed "Failed to create override test details"
fi

run_test "Merge with override"
cp "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
if bash "$MERGE_SCRIPT" "$TEST_DIR/template2" &> /dev/null; then
    test_passed
else
    test_failed "Override merge failed"
fi
if [ -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" ]; then
    mv "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.original" "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json"
fi

run_test "Verify remoteUser is overridden"
if grep -q '"remoteUser": "vscode"' "$TEST_DIR/template2/devcontainer.json"; then
    test_passed
else
    test_failed "remoteUser not overridden (should be vscode)"
fi

run_test "Verify Node version is overridden"
if grep -q '"version": "18"' "$TEST_DIR/template2/devcontainer.json"; then
    test_passed
else
    test_failed "Node version not overridden (should be 18)"
fi

# Test 3: Real templates
print_section "Test 3: Real Template Tests"

run_test "Test bitbot-work template merge"
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-work" &> /dev/null; then
    test_passed
else
    test_failed "bitbot-work template merge failed"
fi

run_test "Verify bitbot-work devcontainer.json created"
if [ -f "$PROJECT_ROOT/container/templates/bitbot-work/devcontainer.json" ]; then
    test_passed
else
    test_failed "bitbot-work devcontainer.json not created"
fi

run_test "Test bitbot-config template merge"
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-config" &> /dev/null; then
    test_passed
else
    test_failed "bitbot-config template merge failed"
fi

run_test "Verify bitbot-config devcontainer.json created"
if [ -f "$PROJECT_ROOT/container/templates/bitbot-config/devcontainer.json" ]; then
    test_passed
else
    test_failed "bitbot-config devcontainer.json not created"
fi

run_test "Test bitbot-base template merge"
if bash "$MERGE_SCRIPT" "$PROJECT_ROOT/container/templates/bitbot-base" &> /dev/null; then
    test_passed
else
    test_failed "bitbot-base template merge failed"
fi

run_test "Verify bitbot-base devcontainer.json created"
if [ -f "$PROJECT_ROOT/container/templates/bitbot-base/devcontainer.json" ]; then
    test_passed
else
    test_failed "bitbot-base devcontainer.json not created"
fi

# Cleanup
print_section "Cleanup"

run_test "Remove test directory"
rm -rf "$TEST_DIR"
if [ ! -d "$TEST_DIR" ]; then
    test_passed
else
    test_failed "Failed to remove test directory"
fi

run_test "Remove test base file"
rm -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json"
rm -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.json.bak"
if [ ! -f "$PROJECT_ROOT/container/templates/shared/base.devcontainer.test.json" ]; then
    test_passed
else
    test_failed "Failed to remove test base file"
fi

# Summary
print_section "Test Summary"
echo ""
echo "Total tests:  $TESTS_RUN"
echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
else
    echo "Failed:       $TESTS_FAILED"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
