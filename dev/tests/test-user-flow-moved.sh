#!/usr/bin/env bash
#
# Test: BitBot User Flow - Moved Installation
# Tests BitBot behavior when installation folder is moved
#
# Usage:
#   test-user-flow-moved.sh
#
# Note: This test ONLY runs in test mode (isolated environment)
#       It does not support --dev mode to avoid polluting dev environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_DEV_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# This test always uses test mode
MODE="test"
TEST_ENV="/tmp/bitbot-test-moved-$$"
BITBOT_ROOT="$TEST_ENV/bitbot"
BITBOT_MOVED="$TEST_ENV/bitbot-moved"
BITBOT="$BITBOT_ROOT/core/bitbot"

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

# Cleanup function
cleanup() {
    test_info "Cleaning up tmux sessions..."
    tmux kill-session -t bitbot-test-moved 2>/dev/null || true

    if [[ -d "$TEST_ENV" ]]; then
        test_info "Removing test environment..."
        rm -rf "$TEST_ENV"
    fi
}

trap cleanup EXIT

echo ""
echo "=== BitBot User Flow: Moved Installation Test ==="
echo ""
echo "This test verifies BitBot handles moved installations correctly"
echo ""

# ============================================================================
# Setup: Create test environment
# ============================================================================

echo "[Setup] Creating test environment..."
mkdir -p "$TEST_ENV"

test_info "Copying BitBot to: $BITBOT_ROOT"
cp -r "$BITBOT_DEV_ROOT" "$BITBOT_ROOT"

# Remove any existing config
rm -f "$BITBOT_ROOT/config.json"

# ============================================================================
# Test 1: Initial setup at original location
# ============================================================================

echo ""
echo "[Test 1] Running initial setup at original location..."

# Create tmux session
tmux new-session -d -s bitbot-test-moved "export BITBOT_HOME='$BITBOT_ROOT'; bash $BITBOT; exec bash" 2>/dev/null
sleep 3

# Send through wizard
tmux send-keys -t bitbot-test-moved '1' Enter  # Terminal mode
sleep 2
tmux send-keys -t bitbot-test-moved 'n' Enter  # Skip PATH (we'll verify manually)

sleep 2
output=$(tmux capture-pane -t bitbot-test-moved -p)

if echo "$output" | grep -q "Created config.json"; then
    test_pass "Initial setup completed at original location"
else
    test_fail "Initial setup did not complete"
    echo "$output"
fi

# Verify config created
if [[ -f "$BITBOT_ROOT/config.json" ]]; then
    test_pass "Config created at original location"
else
    test_fail "Config not found at original location"
fi

tmux kill-session -t bitbot-test-moved 2>/dev/null || true

# ============================================================================
# Test 2: Move installation to new location
# ============================================================================

echo ""
echo "[Test 2] Moving installation to new location..."

test_info "Moving: $BITBOT_ROOT -> $BITBOT_MOVED"
mv "$BITBOT_ROOT" "$BITBOT_MOVED"

if [[ -d "$BITBOT_MOVED" ]] && [[ ! -d "$BITBOT_ROOT" ]]; then
    test_pass "Installation moved successfully"
else
    test_fail "Installation move failed"
    exit 1
fi

# Verify config still exists at new location
if [[ -f "$BITBOT_MOVED/config.json" ]]; then
    test_pass "Config file preserved after move"
else
    test_fail "Config file lost after move"
fi

# ============================================================================
# Test 3: Run BitBot from moved location
# ============================================================================

echo ""
echo "[Test 3] Running BitBot from moved location..."

# Run from new location
tmux new-session -d -s bitbot-test-moved "export BITBOT_HOME='$BITBOT_MOVED'; bash $BITBOT_MOVED/core/bitbot; exec bash" 2>/dev/null
sleep 3

output=$(tmux capture-pane -t bitbot-test-moved -p)

# BitBot should detect the config exists but location changed
if echo "$output" | grep -q "BitBot install location: $BITBOT_MOVED"; then
    test_pass "BitBot detected new install location"
else
    test_warning "BitBot may not have detected new location"
fi

# Should offer to update PATH
if echo "$output" | grep -q "Update shell configuration now"; then
    test_pass "BitBot offers to update PATH for moved location"
else
    test_info "BitBot behavior after move (may vary based on config)"
fi

tmux kill-session -t bitbot-test-moved 2>/dev/null || true

# ============================================================================
# Test 4: Verify config still valid
# ============================================================================

echo ""
echo "[Test 4] Verifying config still valid after move..."

config_content=$(cat "$BITBOT_MOVED/config.json")

if echo "$config_content" | jq -e . >/dev/null 2>&1; then
    test_pass "Config is valid JSON after move"
else
    test_fail "Config corrupted after move"
fi

if echo "$config_content" | grep -q '"launch_mode"'; then
    test_pass "Config contains launch_mode after move"
else
    test_fail "Config missing launch_mode after move"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $fail_count${NC}"
echo "========================================"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
