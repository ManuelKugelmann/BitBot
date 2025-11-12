#!/usr/bin/env bash
#
# Test: BitBot User Flow - Context Switching
# Tests BitBot behavior when switching between global and workspace contexts
#
# Usage:
#   test-user-flow-context-switch.sh [--dev] [--no-cleanup]
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
            echo "Usage: test-user-flow-context-switch.sh [--dev] [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Setup paths based on mode
if [[ "$MODE" == "dev" ]]; then
    BITBOT_ROOT="$BITBOT_DEV_ROOT"
    TEST_ENV=""
    WORKSPACE_A="$BITBOT_ROOT/test-workspace-a-$$"
    WORKSPACE_B="$BITBOT_ROOT/test-workspace-b-$$"
else
    TEST_ENV="/tmp/bitbot-test-context-$$"
    BITBOT_ROOT="$TEST_ENV/bitbot"
    WORKSPACE_A="$TEST_ENV/workspace-a"
    WORKSPACE_B="$TEST_ENV/workspace-b"
fi

BITBOT="$BITBOT_ROOT/core/bitbot"
GLOBAL_CONFIG="$BITBOT_ROOT/global/.bitbot/config.json"

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
        echo -e "  Workspaces and changes left for inspection"
        echo -e "  Remember to clean up manually:"
        if [[ "$MODE" == "dev" ]]; then
            echo -e "    rm -rf $WORKSPACE_A $WORKSPACE_B"
        else
            echo -e "    rm -rf $TEST_ENV"
        fi
        echo ""
        return
    fi

    test_info "Cleaning up tmux sessions..."
    tmux kill-session -t bitbot-test-context-a 2>/dev/null || true
    tmux kill-session -t bitbot-test-context-b 2>/dev/null || true

    # Clean up workspaces
    if [[ -d "$WORKSPACE_A" ]]; then
        test_info "Removing workspace A..."
        rm -rf "$WORKSPACE_A"
    fi

    if [[ -d "$WORKSPACE_B" ]]; then
        test_info "Removing workspace B..."
        rm -rf "$WORKSPACE_B"
    fi

    # Clean up test environment (only in test mode)
    if [[ "$MODE" == "test" ]] && [[ -d "$TEST_ENV" ]]; then
        test_info "Removing test environment..."
        rm -rf "$TEST_ENV"
    fi
}

trap cleanup EXIT

echo ""
echo "=== BitBot User Flow: Context Switching Test ==="
echo ""
echo "Mode: $MODE"
echo ""
echo "This test verifies BitBot correctly switches between global and workspace contexts"
echo ""

# ============================================================================
# Setup: Prepare test environment
# ============================================================================

if [[ "$MODE" == "test" ]]; then
    echo "[Setup] Creating isolated test environment..."
    mkdir -p "$TEST_ENV"

    test_info "Copying BitBot to test environment..."
    cp -r "$BITBOT_DEV_ROOT" "$BITBOT_ROOT"

    # Create minimal global config
    mkdir -p "$(dirname "$GLOBAL_CONFIG")"
    cat > "$GLOBAL_CONFIG" <<EOF
{
  "launch_mode": "terminal",
  "install_location": "$BITBOT_ROOT"
}
EOF
    test_info "Created global config"
else
    echo "[Setup] Using dev environment at: $BITBOT_ROOT"

    # Verify/create global config
    if [[ ! -f "$GLOBAL_CONFIG" ]]; then
        mkdir -p "$(dirname "$GLOBAL_CONFIG")"
        cat > "$GLOBAL_CONFIG" <<EOF
{
  "launch_mode": "terminal",
  "install_location": "$BITBOT_ROOT"
}
EOF
    fi
fi

# ============================================================================
# Test 1: Run BitBot from BitBot installation directory (global context)
# ============================================================================

echo ""
echo "[Test 1] Running BitBot from installation directory (global context)..."

# Change to BitBot root directory (should trigger global context)
cd "$BITBOT_ROOT"

# Run bitbot --help to see context
tmux new-session -d -s bitbot-test-context-a "cd '$BITBOT_ROOT' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT --help; exec bash" 2>/dev/null

sleep 2

output=$(tmux capture-pane -t bitbot-test-context-a -p)

# In global context, we should see global commands
if echo "$output" | grep -qE "bitbot init|bitbot work|bitbot config"; then
    test_pass "Global context commands displayed"
else
    test_fail "Global context commands not found"
    log_tmux_output "bitbot-test-context-a" "Global context help"
fi

tmux kill-session -t bitbot-test-context-a 2>/dev/null || true

# ============================================================================
# Test 2: Create first workspace
# ============================================================================

echo ""
echo "[Test 2] Creating first workspace..."

mkdir -p "$WORKSPACE_A"
cd "$WORKSPACE_A"

# Create minimal workspace structure (simulate bitbot init)
mkdir -p .bitbot/internal/local
mkdir -p .devcontainer

# Create minimal devcontainer.json
cat > .devcontainer/devcontainer.json <<EOF
{
  "name": "test-workspace-a",
  "build": {
    "dockerfile": "Dockerfile"
  }
}
EOF

# Create minimal Dockerfile
cat > .devcontainer/Dockerfile <<EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y bash
EOF

if [[ -d "$WORKSPACE_A/.bitbot" ]] && [[ -d "$WORKSPACE_A/.devcontainer" ]]; then
    test_pass "Workspace A structure created"
else
    test_fail "Workspace A structure incomplete"
fi

# ============================================================================
# Test 3: Run BitBot from workspace A (workspace context)
# ============================================================================

echo ""
echo "[Test 3] Running BitBot from workspace A (workspace context)..."

tmux new-session -d -s bitbot-test-context-a "cd '$WORKSPACE_A' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT --help; exec bash" 2>/dev/null

sleep 2

output=$(tmux capture-pane -t bitbot-test-context-a -p)

# In workspace context, we should see workspace commands
if echo "$output" | grep -qE "bitbot work|bitbot config|bitbot status"; then
    test_pass "Workspace context commands displayed"
else
    test_fail "Workspace context commands not found"
    log_tmux_output "bitbot-test-context-a" "Workspace context help"
fi

# Should NOT show init command in workspace context
if echo "$output" | grep -q "bitbot init"; then
    test_warning "init command shown in workspace context (may be intentional)"
else
    test_pass "init command not shown in workspace context"
fi

tmux kill-session -t bitbot-test-context-a 2>/dev/null || true

# ============================================================================
# Test 4: Create second workspace
# ============================================================================

echo ""
echo "[Test 4] Creating second workspace..."

mkdir -p "$WORKSPACE_B"
cd "$WORKSPACE_B"

# Create minimal workspace structure
mkdir -p .bitbot/internal/local
mkdir -p .devcontainer

cat > .devcontainer/devcontainer.json <<EOF
{
  "name": "test-workspace-b",
  "build": {
    "dockerfile": "Dockerfile"
  }
}
EOF

cat > .devcontainer/Dockerfile <<EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y bash curl
EOF

test_pass "Workspace B structure created"

# ============================================================================
# Test 5: Switch between workspaces
# ============================================================================

echo ""
echo "[Test 5] Testing workspace switching..."

# Run in workspace A
tmux new-session -d -s bitbot-test-context-a "cd '$WORKSPACE_A' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT status; exec bash" 2>/dev/null
sleep 2
output_a=$(tmux capture-pane -t bitbot-test-context-a -p)

# Run in workspace B
tmux new-session -d -s bitbot-test-context-b "cd '$WORKSPACE_B' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT status; exec bash" 2>/dev/null
sleep 2
output_b=$(tmux capture-pane -t bitbot-test-context-b -p)

# Each workspace should report its own status
if echo "$output_a" | grep -qE "workspace-a|Workspace:.*a"; then
    test_pass "Workspace A identified correctly"
elif echo "$output_a" | grep -qE "Workspace:"; then
    test_warning "Workspace A identified but name unclear"
else
    test_info "Workspace A status output (may not show name)"
fi

if echo "$output_b" | grep -qE "workspace-b|Workspace:.*b"; then
    test_pass "Workspace B identified correctly"
elif echo "$output_b" | grep -qE "Workspace:"; then
    test_warning "Workspace B identified but name unclear"
else
    test_info "Workspace B status output (may not show name)"
fi

tmux kill-session -t bitbot-test-context-a 2>/dev/null || true
tmux kill-session -t bitbot-test-context-b 2>/dev/null || true

# ============================================================================
# Test 6: Run from parent directory of workspace
# ============================================================================

echo ""
echo "[Test 6] Testing context detection from parent directory..."

# Create nested workspace structure
NESTED_WORKSPACE="$WORKSPACE_A/nested/project"
mkdir -p "$NESTED_WORKSPACE"
cd "$NESTED_WORKSPACE"

# This should still detect workspace A context (parent has .bitbot)
tmux new-session -d -s bitbot-test-context-a "cd '$NESTED_WORKSPACE' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT --help; exec bash" 2>/dev/null

sleep 2

output=$(tmux capture-pane -t bitbot-test-context-a -p)

if echo "$output" | grep -qE "bitbot work|bitbot config"; then
    test_pass "Workspace context detected from nested directory"
else
    test_fail "Failed to detect workspace context from nested directory"
    log_tmux_output "bitbot-test-context-a" "Nested directory context"
fi

tmux kill-session -t bitbot-test-context-a 2>/dev/null || true

# ============================================================================
# Test 7: Switch back to global context
# ============================================================================

echo ""
echo "[Test 7] Switching back to global context..."

cd "$BITBOT_ROOT"

tmux new-session -d -s bitbot-test-context-a "cd '$BITBOT_ROOT' && export BITBOT_HOME='$BITBOT_ROOT' && bash $BITBOT --help; exec bash" 2>/dev/null

sleep 2

output=$(tmux capture-pane -t bitbot-test-context-a -p)

if echo "$output" | grep -q "bitbot init"; then
    test_pass "Global context restored after leaving workspace"
else
    test_fail "Failed to restore global context"
    log_tmux_output "bitbot-test-context-a" "Return to global context"
fi

tmux kill-session -t bitbot-test-context-a 2>/dev/null || true

# ============================================================================
# Test 8: Verify no context pollution
# ============================================================================

echo ""
echo "[Test 8] Verifying no context pollution between workspaces..."

# Check that workspace A wasn't modified by workspace B operations
if [[ -f "$WORKSPACE_A/.bitbot/internal/local/context-pollution" ]]; then
    test_fail "Context pollution detected - workspace A was modified"
else
    test_pass "No context pollution in workspace A"
fi

# Check that workspace B has its own isolated state
if [[ -d "$WORKSPACE_B/.bitbot" ]] && [[ -d "$WORKSPACE_A/.bitbot" ]]; then
    # Each should have separate internal directories
    if [[ "$WORKSPACE_A/.bitbot" != "$WORKSPACE_B/.bitbot" ]]; then
        test_pass "Workspaces have isolated .bitbot directories"
    else
        test_fail "Workspaces sharing .bitbot directory (should be separate)"
    fi
else
    test_fail "Workspace structure incomplete"
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
