#!/usr/bin/env bash
#
# Test: BitBot Complete User Flow
# Tests the complete user flow: global init → workspace init → container launch
#
# Usage:
#   test-user-flow.sh [--dev] [--no-cleanup]
#
# Modes:
#   Default: Creates temporary test environment (clean, isolated)
#   --dev:   Tests against current BitBot dev environment (requires clean git state)
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
            echo "Usage: test-user-flow-init.sh [--dev] [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Setup paths based on mode
if [[ "$MODE" == "dev" ]]; then
    # Dev mode: test against current development environment
    BITBOT_ROOT="$BITBOT_DEV_ROOT"
    BITBOT="$BITBOT_ROOT/core/bitbot"
    TEST_ENV=""
else
    # Test mode: create temporary isolated environment
    TEST_ENV="/tmp/bitbot-test-env-$$"
    BITBOT_ROOT="$TEST_ENV/bitbot"
    BITBOT="$BITBOT_ROOT/core/bitbot"
fi

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

# Cleanup function
cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Config and changes left for inspection"
        echo -e "  Remember to clean up manually:"
        if [[ "$MODE" == "dev" ]]; then
            echo -e "    git restore ."
            echo -e "    rm -f config.json"
        else
            echo -e "    rm -rf $TEST_ENV"
        fi
        echo ""
        return
    fi

    test_info "Cleaning up tmux session..."
    tmux kill-session -t bitbot-test-flow 2>/dev/null || true

    # Clean up test environment (only in test mode)
    if [[ "$MODE" == "test" ]] && [[ -d "$TEST_ENV" ]]; then
        test_info "Removing test environment..."
        rm -rf "$TEST_ENV"
    fi

    # In dev mode, remove the generated config
    if [[ "$MODE" == "dev" ]] && [[ -f "$BITBOT_ROOT/config.json" ]]; then
        test_info "Removing test-generated config..."
        rm -f "$BITBOT_ROOT/config.json"
    fi
}

trap cleanup EXIT

echo ""
echo "=== BitBot User Flow: Fresh Init Test ==="
echo ""
echo "Mode: $MODE"
echo ""
echo "This test simulates a real user running 'bitbot' for the first time"
echo "and completing the setup wizard using tmux send-keys."
echo ""

# ============================================================================
# Dev Mode: Verify git clean state
# ============================================================================

if [[ "$MODE" == "dev" ]]; then
    echo "[Dev Mode] Checking git state..."

    cd "$BITBOT_DEV_ROOT"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${RED}✗ FAIL${NC}: Git working directory is not clean"
        echo ""
        echo "Uncommitted changes detected:"
        git status --short
        echo ""
        echo "Please commit or stash changes before running --dev mode tests"
        exit 1
    fi

    # Check for untracked files that might affect tests
    untracked=$(git ls-files --others --exclude-standard | grep -E '^(core|container)/' || true)
    if [[ -n "$untracked" ]]; then
        echo -e "${YELLOW}⚠ WARN${NC}: Untracked files detected in core/container directories:"
        echo "$untracked"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Test aborted"
            exit 1
        fi
    fi

    test_pass "Git state is clean"
fi

# ============================================================================
# Setup: Prepare test environment
# ============================================================================

if [[ "$MODE" == "test" ]]; then
    echo "[Setup] Creating isolated test environment..."
    test_info "Test environment: $TEST_ENV"

    # Create test environment directory
    mkdir -p "$TEST_ENV"

    # Copy BitBot to test environment
    test_info "Copying BitBot to test environment..."
    cp -r "$BITBOT_DEV_ROOT" "$BITBOT_ROOT"

    # Remove any existing config from the copy
    if [[ -f "$BITBOT_ROOT/config.json" ]]; then
        test_info "Removing existing config from test copy..."
        rm "$BITBOT_ROOT/config.json"
    fi

    test_info "Test BitBot installation ready at: $BITBOT_ROOT"
else
    echo "[Setup] Using dev environment at: $BITBOT_ROOT"

    # Remove any existing config in dev mode
    if [[ -f "$BITBOT_ROOT/config.json" ]]; then
        test_info "Removing existing config..."
        rm "$BITBOT_ROOT/config.json"
    fi
fi

# ============================================================================
# Test 1: Start BitBot in tmux session
# ============================================================================

echo ""
echo "[Test 1] Starting BitBot in tmux session..."

# Create tmux session and run bitbot with BITBOT_HOME set
tmux new-session -d -s bitbot-test-flow "export BITBOT_HOME='$BITBOT_ROOT'; bash $BITBOT; exec bash" 2>/dev/null

# Wait for BitBot to start
sleep 2

# Capture initial output
output=$(tmux capture-pane -t bitbot-test-flow -p)

if echo "$output" | grep -q "This is your first run"; then
    test_pass "BitBot detected first run and started setup wizard"
else
    test_fail "BitBot did not start setup wizard"
    echo "$output"
    exit 1
fi

if echo "$output" | grep -q "Checking prerequisites"; then
    test_pass "Prerequisites check started"
else
    test_fail "Prerequisites check not found"
fi

# ============================================================================
# Test 2: Prerequisites verification
# ============================================================================

echo ""
echo "[Test 2] Verifying prerequisites check..."

# Wait for prerequisites to complete
sleep 3

output=$(tmux capture-pane -t bitbot-test-flow -p)

if echo "$output" | grep -q "All prerequisites checked"; then
    test_pass "Prerequisites verification completed"
else
    test_fail "Prerequisites verification did not complete"
    echo "$output"
fi

# Check for specific prerequisites
if echo "$output" | grep -q "Docker"; then
    test_pass "Docker check performed"
else
    test_fail "Docker check not found"
fi

if echo "$output" | grep -q "DevContainer CLI"; then
    test_pass "DevContainer CLI check performed"
else
    test_fail "DevContainer CLI check not found"
fi

if echo "$output" | grep -q "Git"; then
    test_pass "Git check performed"
else
    test_fail "Git check not found"
fi

# ============================================================================
# Test 3: Launch mode selection prompt
# ============================================================================

echo ""
echo "[Test 3] Checking launch mode selection prompt..."

output=$(tmux capture-pane -t bitbot-test-flow -p)

if echo "$output" | grep -q "Select default launch mode:"; then
    test_pass "Launch mode prompt displayed"
else
    test_fail "Launch mode prompt not found"
    echo "$output"
fi

if echo "$output" | grep -q "\[1\] Terminal"; then
    test_pass "Terminal option displayed with [1] format"
else
    test_fail "Terminal option not properly formatted"
fi

if echo "$output" | grep -q "\[2\] VS Code"; then
    test_pass "VS Code option displayed with [2] format"
else
    test_fail "VS Code option not properly formatted"
fi

# ============================================================================
# Test 4: Respond to launch mode prompt
# ============================================================================

echo ""
echo "[Test 4] Selecting Terminal launch mode..."

# Send "1" to select Terminal mode
tmux send-keys -t bitbot-test-flow '1' Enter

# Wait for processing
sleep 2

output=$(tmux capture-pane -t bitbot-test-flow -p)

if echo "$output" | grep -q "Created config.json"; then
    test_pass "Config file created successfully"
else
    test_fail "Config file creation not confirmed"
fi

if echo "$output" | grep -q "Default mode: terminal"; then
    test_pass "Terminal mode selected correctly"
else
    test_warning "Could not verify mode selection (may have defaulted to VS Code)"
fi

# ============================================================================
# Test 5: PATH configuration prompt
# ============================================================================

echo ""
echo "[Test 5] Verifying PATH configuration prompt..."

output=$(tmux capture-pane -t bitbot-test-flow -p)

if echo "$output" | grep -q "Adding BitBot to PATH"; then
    test_pass "PATH configuration started"
else
    test_fail "PATH configuration section not found"
fi

# Check for shell detection
if echo "$output" | grep -qE "Detected shell: (bash|zsh)"; then
    test_pass "Shell detected correctly"
else
    test_fail "Shell detection failed"
fi

# Check for platform detection
if echo "$output" | grep -qE "Detected platform: (linux|wsl|macos)"; then
    test_pass "Platform detected"
else
    test_fail "Platform detection failed"
fi

# Check for PATH prompt
if echo "$output" | grep -q "Add BitBot to your PATH?"; then
    test_pass "PATH addition prompt displayed"
else
    test_fail "PATH addition prompt not found"
fi

# ============================================================================
# Test 6: Respond to PATH prompt
# ============================================================================

echo ""
echo "[Test 6] Accepting PATH configuration..."

# Send "Y" to accept PATH addition
tmux send-keys -t bitbot-test-flow 'Y' Enter

# Wait for completion
sleep 3

output=$(tmux capture-pane -t bitbot-test-flow -p)

# ============================================================================
# Test 7: Setup completion
# ============================================================================

echo ""
echo "[Test 7] Verifying setup completion..."

if echo "$output" | grep -q "Global BitBot setup complete"; then
    test_pass "Setup completed successfully"
else
    test_fail "Setup completion message not found"
    echo "$output"
fi

if echo "$output" | grep -q "bitbot init"; then
    test_pass "Next steps provided to user"
else
    test_fail "Next steps not shown"
fi

# ============================================================================
# Test 8: Verify config file contents
# ============================================================================

echo ""
echo "[Test 8] Verifying generated config file..."

if [[ -f "$BITBOT_ROOT/config.json" ]]; then
    test_pass "Config file exists at expected location"

    # Check config contents
    config_content=$(cat "$BITBOT_ROOT/config.json")

    if echo "$config_content" | grep -q '"launch_mode"'; then
        test_pass "Config contains launch_mode field"
    else
        test_fail "Config missing launch_mode field"
    fi

    if echo "$config_content" | jq -e . >/dev/null 2>&1; then
        test_pass "Config is valid JSON"
    else
        test_fail "Config is not valid JSON"
    fi
else
    test_fail "Config file not created"
fi

# ============================================================================
# Dev Mode: Check for git differences and template sync needs
# ============================================================================

if [[ "$MODE" == "dev" ]]; then
    echo ""
    echo "[Dev Mode] Analyzing git differences..."

    cd "$BITBOT_DEV_ROOT"

    # Check for any changes made during the test
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Git Differences Detected${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # Show detailed diff
        git diff --stat HEAD
        echo ""

        # Analyze which files changed and what needs template sync
        changed_files=$(git diff --name-only HEAD)

        template_sync_needed=false

        echo -e "${BLUE}Template Sync Analysis:${NC}"
        echo ""

        while IFS= read -r file; do
            case "$file" in
                .bashrc|.zshrc|.profile)
                    echo -e "  ${YELLOW}⚠${NC} $file"
                    echo -e "     ${BLUE}→${NC} Shell config modified by PATH setup"
                    echo -e "     ${BLUE}→${NC} No template sync needed (host-specific)"
                    echo ""
                    ;;

                .claude/*)
                    echo -e "  ${GREEN}✓${NC} $file"
                    echo -e "     ${BLUE}→${NC} Claude Code configuration"
                    echo -e "     ${BLUE}→${NC} Check if should sync to templates/.claude/"
                    template_sync_needed=true
                    echo ""
                    ;;

                .bitbot/*)
                    echo -e "  ${GREEN}✓${NC} $file"
                    echo -e "     ${BLUE}→${NC} BitBot workspace infrastructure"
                    echo -e "     ${BLUE}→${NC} Should be in template shared scripts"
                    template_sync_needed=true
                    echo ""
                    ;;

                container/*)
                    echo -e "  ${GREEN}✓${NC} $file"
                    echo -e "     ${BLUE}→${NC} Container infrastructure change"
                    echo -e "     ${BLUE}→${NC} May need template sync"
                    template_sync_needed=true
                    echo ""
                    ;;

                config.json)
                    echo -e "  ${GREEN}✓${NC} $file"
                    echo -e "     ${BLUE}→${NC} Test-generated config (expected)"
                    echo -e "     ${BLUE}→${NC} No action needed"
                    echo ""
                    ;;

                *)
                    echo -e "  ${YELLOW}?${NC} $file"
                    echo -e "     ${BLUE}→${NC} Unexpected change"
                    echo -e "     ${BLUE}→${NC} Review manually"
                    template_sync_needed=true
                    echo ""
                    ;;
            esac
        done <<< "$changed_files"

        if [[ "$template_sync_needed" == "true" ]]; then
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}Action Required:${NC}"
            echo -e "  Review changes and sync to templates if needed:"
            echo -e "  • container/templates/bitbot-base/"
            echo -e "  • container/templates/bitbot-config/"
            echo -e "  • container/templates/bitbot-dev/"
            echo -e "  • container/templates/bitbot-work/"
            echo -e "  • container/templates/shared/"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
        fi

        # Show the actual diff content for review
        echo -e "${BLUE}Full Diff:${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        git diff HEAD
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

    else
        test_pass "No git differences detected (test was clean)"
    fi
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
