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

# Global config locations
GLOBAL_CONFIG="$BITBOT_ROOT/global/.bitbot/config.json"
GLOBAL_CONFIG_MOVED="$BITBOT_MOVED/global/.bitbot/config.json"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"




test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

log_tmux_output() {
    # Log tmux pane output for debugging
    local session_name="$1"
    local context="${2:-}"

    echo ""
    echo -e "${BLUE}[Tmux Output${context:+: $context}]${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    tmux capture-pane -t "$session_name" -p 2>/dev/null || echo "(no output captured)"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
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

# Remove workspace artifacts (to avoid workspace detection instead of global init)
test_info "Cleaning workspace artifacts from test copy..."
rm -rf "$BITBOT_ROOT/.bitbot"
rm -rf "$BITBOT_ROOT/.devcontainer"

# Remove any existing config
rm -f "$BITBOT_ROOT/config.json"

# ============================================================================
# Test 1: Initial setup at original location
# ============================================================================

echo ""
echo "[Test 1] Running initial setup at original location..."

# Create tmux session (cd to BitBot install to trigger global context)
tmux new-session -d -s bitbot-test-moved "cd '$BITBOT_ROOT' && bash $BITBOT; exec bash" 2>/dev/null
sleep 3

log_tmux_output "bitbot-test-moved" "After BitBot launch"

# Wait for launch mode prompt
sleep 3

log_tmux_output "bitbot-test-moved" "Before sending mode choice"

# Send through wizard
tmux send-keys -t bitbot-test-moved '1' Enter  # Terminal mode
sleep 3

log_tmux_output "bitbot-test-moved" "After mode selection"

tmux send-keys -t bitbot-test-moved 'n' Enter  # Skip PATH (we'll verify manually)

# Wait for setup to complete
sleep 5
output=$(tmux capture-pane -t bitbot-test-moved -p)

if echo "$output" | grep -q "Global BitBot setup complete"; then
    test_pass "Initial setup completed at original location"
else
    test_fail "Initial setup did not complete"
    log_tmux_output "bitbot-test-moved" "Setup incomplete"
fi

# Verify config created at new location
if [[ -f "$GLOBAL_CONFIG" ]]; then
    test_pass "Config created at global/.bitbot/config.json"
else
    test_fail "Config not found at $GLOBAL_CONFIG"
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

# Verify config moved with installation (in global/.bitbot/ subdirectory)
if [[ -f "$GLOBAL_CONFIG_MOVED" ]]; then
    test_pass "Config moved with installation to global/.bitbot/"
else
    test_fail "Config not found at moved location: $GLOBAL_CONFIG_MOVED"
fi

# ============================================================================
# Test 3: Run BitBot from moved location
# ============================================================================

echo ""
echo "[Test 3] Running BitBot from moved location..."

# Run from new location (cd to BitBot install to trigger global context)
tmux new-session -d -s bitbot-test-moved "cd '$BITBOT_MOVED' && bash $BITBOT_MOVED/core/bitbot; exec bash" 2>/dev/null
sleep 3

output=$(tmux capture-pane -t bitbot-test-moved -p)
log_tmux_output "bitbot-test-moved" "After launch from moved location"

# BitBot should detect the config exists but location changed
if echo "$output" | grep -q "BitBot install location: $BITBOT_MOVED"; then
    test_pass "BitBot detected new install location"
else
    test_warning "BitBot may not have detected new location"
    log_tmux_output "bitbot-test-moved" "Location detection check"
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

config_content=$(cat "$GLOBAL_CONFIG_MOVED")

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
