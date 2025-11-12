#!/usr/bin/env bash
#
# Test: BitBot User Flow - Workspace Initialization
# Tests complete workspace setup: bitbot init with template selection
#
# Usage:
#   test-user-flow-workspace-init.sh [--dev] [--no-cleanup]
#
# Modes:
#   Default: Creates temporary test environment (clean, isolated)
#   --dev:   Tests against current BitBot dev environment
#
# Options:
#   --no-cleanup: Skip cleanup (leave config/changes for inspection)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_DEV_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse command line arguments
MODE="test"
SKIP_CLEANUP=false

for arg in "$@"; do
    case "$arg" in
        --dev)
            MODE="dev"
            ;;
        --no-cleanup)
            SKIP_CLEANUP=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: test-user-flow-workspace-init.sh [--dev] [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Setup paths based on mode
if [[ "$MODE" == "dev" ]]; then
    BITBOT_ROOT="$BITBOT_DEV_ROOT"
    TEST_ENV=""
    WORKSPACE_DIR="$BITBOT_ROOT/test-workspace-$$"
else
    TEST_ENV="/tmp/bitbot-test-workspace-$$"
    BITBOT_ROOT="$TEST_ENV/bitbot"
    WORKSPACE_DIR="$TEST_ENV/workspace"
fi

BITBOT="$BITBOT_ROOT/core/bitbot"

# Global config location (assuming already initialized)
GLOBAL_CONFIG="$BITBOT_ROOT/global/.bitbot/config.json"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"




test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

log_tmux_output() {
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
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Workspace and changes left for inspection"
        echo -e "  Remember to clean up manually:"
        if [[ "$MODE" == "dev" ]]; then
            echo -e "    rm -rf $WORKSPACE_DIR"
        else
            echo -e "    rm -rf $TEST_ENV"
        fi
        echo ""
        return
    fi

    test_info "Cleaning up tmux session..."
    tmux kill-session -t bitbot-test-workspace 2>/dev/null || true

    # Clean up workspace directory
    if [[ -d "$WORKSPACE_DIR" ]]; then
        test_info "Removing test workspace..."
        rm -rf "$WORKSPACE_DIR"
    fi

    # Clean up test environment (only in test mode)
    if [[ "$MODE" == "test" ]] && [[ -d "$TEST_ENV" ]]; then
        test_info "Removing test environment..."
        rm -rf "$TEST_ENV"
    fi
}

trap cleanup EXIT

echo ""
echo "=== BitBot User Flow: Workspace Initialization Test ==="
echo ""
echo "Mode: $MODE"
echo ""
echo "This test simulates a user running 'bitbot init' in a new workspace"
echo "and completing the template selection wizard."
echo ""

# ============================================================================
# Setup: Prepare test environment
# ============================================================================

if [[ "$MODE" == "test" ]]; then
    echo "[Setup] Creating isolated test environment..."
    mkdir -p "$TEST_ENV"

    test_info "Copying BitBot to test environment..."
    cp -r "$BITBOT_DEV_ROOT" "$BITBOT_ROOT"

    # Create minimal global config (simulate already initialized BitBot)
    mkdir -p "$(dirname "$GLOBAL_CONFIG")"
    cat > "$GLOBAL_CONFIG" <<EOF
{
  "launch_mode": "terminal",
  "install_location": "$BITBOT_ROOT"
}
EOF
    test_info "Created minimal global config"
else
    echo "[Setup] Using dev environment at: $BITBOT_ROOT"

    # Verify global config exists in dev mode
    if [[ ! -f "$GLOBAL_CONFIG" ]]; then
        test_warning "Global config not found - creating temporary config"
        mkdir -p "$(dirname "$GLOBAL_CONFIG")"
        cat > "$GLOBAL_CONFIG" <<EOF
{
  "launch_mode": "terminal",
  "install_location": "$BITBOT_ROOT"
}
EOF
    fi
fi

# Create empty workspace directory
mkdir -p "$WORKSPACE_DIR"
test_info "Created workspace directory: $WORKSPACE_DIR"

# ============================================================================
# Test 1: Initialize workspace with template selection
# ============================================================================

echo ""
echo "[Test 1] Running 'bitbot init' in empty workspace..."

# Start tmux session in workspace directory
tmux new-session -d -s bitbot-test-workspace "cd '$WORKSPACE_DIR' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT init; exec bash" 2>/dev/null

# Wait for BitBot to start
sleep 3

output=$(tmux capture-pane -t bitbot-test-workspace -p)

if echo "$output" | grep -q "Select a template"; then
    test_pass "BitBot started workspace init wizard"
else
    test_fail "BitBot did not start workspace init wizard"
    log_tmux_output "bitbot-test-workspace" "Failed to start wizard"
    exit 1
fi

# ============================================================================
# Test 2: Verify template options displayed
# ============================================================================

echo ""
echo "[Test 2] Verifying template options..."

output=$(tmux capture-pane -t bitbot-test-workspace -p)

# Check for standard templates
if echo "$output" | grep -qE "\[1\].*bitbot-base"; then
    test_pass "bitbot-base template option displayed"
else
    test_fail "bitbot-base template option not found"
fi

if echo "$output" | grep -qE "\[2\].*bitbot-config"; then
    test_pass "bitbot-config template option displayed"
else
    test_fail "bitbot-config template option not found"
fi

if echo "$output" | grep -qE "\[3\].*bitbot-work"; then
    test_pass "bitbot-work template option displayed"
else
    test_fail "bitbot-work template option not found"
fi

# ============================================================================
# Test 3: Select bitbot-work template
# ============================================================================

echo ""
echo "[Test 3] Selecting bitbot-work template..."

# Send "3" to select bitbot-work
tmux send-keys -t bitbot-test-workspace '3' Enter

# Wait for processing
sleep 5

output=$(tmux capture-pane -t bitbot-test-workspace -p)

if echo "$output" | grep -qE "Initializing|Setting up|Created"; then
    test_pass "Workspace initialization started"
else
    test_warning "Could not confirm initialization started"
    log_tmux_output "bitbot-test-workspace" "After template selection"
fi

# Wait for initialization to complete
echo "  Waiting for initialization to complete..."
max_wait=20
waited=0
init_complete=false

while [[ $waited -lt $max_wait ]]; do
    sleep 1
    waited=$((waited + 1))
    output=$(tmux capture-pane -t bitbot-test-workspace -p)

    if echo "$output" | grep -qE "Workspace initialization complete|successfully initialized|ready to use"; then
        init_complete=true
        break
    fi
done

# ============================================================================
# Test 4: Verify initialization completion
# ============================================================================

echo ""
echo "[Test 4] Verifying initialization completion..."

if [[ "$init_complete" == "true" ]]; then
    test_pass "Workspace initialization completed (waited ${waited}s)"
else
    test_fail "Workspace initialization did not complete (waited ${waited}s)"
    log_tmux_output "bitbot-test-workspace" "Initialization timeout"
fi

# ============================================================================
# Test 5: Verify workspace structure created
# ============================================================================

echo ""
echo "[Test 5] Verifying workspace structure..."

# Check for .bitbot directory
if [[ -d "$WORKSPACE_DIR/.bitbot" ]]; then
    test_pass ".bitbot directory created"
else
    test_fail ".bitbot directory not found"
fi

# Check for .devcontainer directory
if [[ -d "$WORKSPACE_DIR/.devcontainer" ]]; then
    test_pass ".devcontainer directory created"
else
    test_fail ".devcontainer directory not found"
fi

# Check for devcontainer.json
if [[ -f "$WORKSPACE_DIR/.devcontainer/devcontainer.json" ]]; then
    test_pass "devcontainer.json created"

    # Verify it's valid JSON
    if jq -e . "$WORKSPACE_DIR/.devcontainer/devcontainer.json" >/dev/null 2>&1; then
        test_pass "devcontainer.json is valid JSON"
    else
        test_fail "devcontainer.json is not valid JSON"
    fi
else
    test_fail "devcontainer.json not found"
fi

# Check for Dockerfile
if [[ -f "$WORKSPACE_DIR/.devcontainer/Dockerfile" ]]; then
    test_pass "Dockerfile created"
else
    test_fail "Dockerfile not found"
fi

# ============================================================================
# Test 6: Verify BitBot infrastructure copied
# ============================================================================

echo ""
echo "[Test 6] Verifying BitBot infrastructure..."

# Check for container BitBot scripts
if [[ -d "$WORKSPACE_DIR/.devcontainer/bitbot" ]]; then
    test_pass "Container BitBot directory copied"

    # Check for key files
    if [[ -f "$WORKSPACE_DIR/.devcontainer/bitbot/core/commands/work.sh" ]]; then
        test_pass "BitBot work command present"
    else
        test_fail "BitBot work command not found"
    fi

    if [[ -d "$WORKSPACE_DIR/.devcontainer/bitbot/wrapper" ]]; then
        test_pass "Wrapper infrastructure present"
    else
        test_fail "Wrapper infrastructure not found"
    fi
else
    test_fail "Container BitBot directory not found"
fi

# ============================================================================
# Test 7: Verify template-specific .claude configuration
# ============================================================================

echo ""
echo "[Test 7] Verifying Claude Code configuration..."

# Check for .devcontainer/home/.claude
if [[ -d "$WORKSPACE_DIR/.devcontainer/home/.claude" ]]; then
    test_pass ".claude configuration directory created"

    # Check for key Claude files
    if [[ -f "$WORKSPACE_DIR/.devcontainer/home/.claude/settings.json" ]]; then
        test_pass "Claude settings.json present"
    else
        test_warning "Claude settings.json not found (may be optional)"
    fi

    if [[ -d "$WORKSPACE_DIR/.devcontainer/home/.claude/skills" ]]; then
        test_pass "Claude skills directory present"
    else
        test_warning "Claude skills directory not found (may be optional)"
    fi
else
    test_fail ".claude configuration directory not found"
fi

# ============================================================================
# Test 8: Verify mounts in devcontainer.json
# ============================================================================

echo ""
echo "[Test 8] Verifying devcontainer mounts..."

if [[ -f "$WORKSPACE_DIR/.devcontainer/devcontainer.json" ]]; then
    devc_config=$(cat "$WORKSPACE_DIR/.devcontainer/devcontainer.json")

    # Check for BitBot mount
    if echo "$devc_config" | grep -q "/usr/local/bitbot"; then
        test_pass "BitBot mount configured in devcontainer.json"
    else
        test_fail "BitBot mount not found in devcontainer.json"
    fi

    # Check for Claude home mount
    if echo "$devc_config" | grep -q "/root/.claude"; then
        test_pass "Claude home mount configured"
    else
        test_fail "Claude home mount not found"
    fi

    # Verify mount count (bitbot-work should have multiple mounts)
    mount_count=$(echo "$devc_config" | grep -c '"source":' || echo "0")
    if [[ "$mount_count" -ge 3 ]]; then
        test_pass "Multiple mounts configured ($mount_count mounts)"
    else
        test_warning "Fewer mounts than expected ($mount_count mounts)"
    fi
else
    test_fail "Cannot verify mounts - devcontainer.json not found"
fi

# ============================================================================
# Test 9: Re-run init in initialized workspace
# ============================================================================

echo ""
echo "[Test 9] Testing re-initialization detection..."

# Kill previous session
tmux kill-session -t bitbot-test-workspace 2>/dev/null || true
sleep 1

# Try to init again
tmux new-session -d -s bitbot-test-workspace "cd '$WORKSPACE_DIR' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT init; exec bash" 2>/dev/null

sleep 3

output=$(tmux capture-pane -t bitbot-test-workspace -p)

if echo "$output" | grep -qE "already initialized|already exists"; then
    test_pass "BitBot detected already initialized workspace"
else
    test_warning "Could not verify re-initialization detection"
    log_tmux_output "bitbot-test-workspace" "Re-init detection"
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
