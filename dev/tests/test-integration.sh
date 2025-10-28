#!/usr/bin/env bash
#
# BitBot Full Integration Test
# End-to-end validation of BitBot components
#
# This test validates:
# 1. Global BitBot configuration
# 2. Container template structure
# 3. Template script integrity
# 4. Configuration file validity
# 5. Complete component integration
#
# Note: This test validates the full BitBot system integration.
# Use --quick flag in run-tests.sh to skip this test.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0

# Test workspace location (use /mnt/c/ for devcontainer.cmd compatibility)
TEST_WORKSPACE="/mnt/c/bitbot-integration-test-$$"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   BitBot Integration Test Suite       ║${NC}"
echo -e "${CYAN}║   Full End-to-End Workflow             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Test Framework
# ============================================================================

test_passed() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} ${test_name}"
    passed_tests=$((passed_tests + 1))
}

test_failed() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason: ${reason}${NC}"
    fi
    failed_tests=$((failed_tests + 1))
}

run_test() {
    local test_name="$1"
    total_tests=$((total_tests + 1))
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    echo ""
    echo "Cleaning up test workspace..."

    # Stop any running containers
    if [[ -f "$TEST_WORKSPACE/.devcontainer/devcontainer.json" ]]; then
        cd "$TEST_WORKSPACE" 2>/dev/null || true
        if command -v devcontainer.cmd &>/dev/null; then
            timeout 30 cmd.exe /c devcontainer.cmd down --workspace-folder "$(echo "$TEST_WORKSPACE" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')" &>/dev/null || true
        elif command -v devcontainer &>/dev/null; then
            timeout 30 devcontainer down --workspace-folder "$TEST_WORKSPACE" &>/dev/null || true
        fi
    fi

    # Remove test workspace
    rm -rf "$TEST_WORKSPACE" 2>/dev/null || true

    # Remove test global config if we created it
    if [[ -f "$BITBOT_ROOT/config.json" ]]; then
        local created_at
        created_at=$(jq -r '.created_at // ""' "$BITBOT_ROOT/config.json" 2>/dev/null || echo "")
        if [[ "$created_at" == "test-run" ]]; then
            rm -f "$BITBOT_ROOT/config.json"
        fi
    fi

    echo -e "${BLUE}Cleanup complete${NC}"
}

trap cleanup EXIT

# ============================================================================
# Prerequisites Check
# ============================================================================

echo -e "${BLUE}═══ Prerequisites ═══${NC}"
echo ""

# Set BITBOT_HOME and add to PATH
export BITBOT_HOME="$BITBOT_ROOT"
export PATH="$BITBOT_HOME/core:$PATH"

# Check bitbot command
if ! command -v bitbot &>/dev/null; then
    echo -e "${RED}✗ FAILED${NC}: bitbot command not found"
    echo "BITBOT_HOME: $BITBOT_HOME"
    echo "PATH: $PATH"
    exit 1
fi
echo -e "${GREEN}✓${NC} bitbot command available"

# Ensure global config exists (required for workspace init)
run_test "Verify global config"
if [[ ! -f "$BITBOT_HOME/config.json" ]]; then
    # Create minimal global config for testing
    cat > "$BITBOT_HOME/config.json" <<'EOF'
{
  "version": "0.1.0",
  "launch_mode": "terminal",
  "created_at": "test-run"
}
EOF
    test_passed "Created test global config"
else
    test_passed "Global config exists"
fi

# Check devcontainer CLI
DEVC_CMD=""
if command -v devcontainer.cmd &>/dev/null; then
    DEVC_CMD="cmd.exe /c devcontainer.cmd"
    echo -e "${GREEN}✓${NC} Using devcontainer.cmd (VS Code built-in)"
elif command -v devcontainer &>/dev/null; then
    DEVC_CMD="devcontainer"
    echo -e "${GREEN}✓${NC} Using devcontainer CLI"
else
    echo -e "${RED}✗ FAILED${NC}: DevContainer CLI not found"
    echo "Install: npm install -g @devcontainers/cli"
    exit 1
fi

# Check Docker
if ! docker info &>/dev/null; then
    echo -e "${RED}✗ FAILED${NC}: Docker daemon not running"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker daemon running"

echo ""

# ============================================================================
# Test 1: Workspace Initialization
# ============================================================================

echo -e "${BLUE}═══ Test 1: Workspace Initialization ═══${NC}"
echo ""

run_test "Create test workspace"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
echo "# Integration Test" > README.md
git init &>/dev/null
test_passed "Test workspace created"

run_test "Initialize BitBot workspace"
# Note: bitbot init will try to launch config mode at the end,
# which may fail in test environment. We capture the output and
# check for successful workspace initialization instead.
bitbot init --template bitbot-base &>/tmp/bitbot-init-$$.log || true

# Check if workspace was initialized (even if config launch failed)
if [[ -d ".bitbot" ]] && [[ -d ".devcontainer" ]] && [[ -f ".bitbot/config.json" ]]; then
    test_passed "bitbot init completed (workspace structure created)"
else
    test_failed "bitbot init failed to create workspace structure"
    echo "Init log:"
    cat /tmp/bitbot-init-$$.log
    rm -f /tmp/bitbot-init-$$.log
    exit 1
fi
rm -f /tmp/bitbot-init-$$.log

run_test "Verify workspace structure"
if [[ -d ".bitbot" ]] && [[ -d ".devcontainer" ]]; then
    test_passed "Workspace structure created (.bitbot, .devcontainer)"
else
    test_failed "Workspace structure incomplete"
    exit 1
fi

run_test "Verify devcontainer.json"
if [[ -f ".devcontainer/devcontainer.json" ]]; then
    if jq . .devcontainer/devcontainer.json &>/dev/null; then
        test_passed "devcontainer.json is valid JSON"
    else
        test_failed "devcontainer.json is invalid JSON"
    fi
else
    test_failed "devcontainer.json not found"
fi

run_test "Verify BitBot scripts copied"
if [[ -d ".devcontainer/bitbot" ]]; then
    if [[ -f ".devcontainer/bitbot/core/commands/start.sh" ]]; then
        test_passed "Container BitBot scripts present"
    else
        test_failed "BitBot scripts incomplete"
    fi
else
    test_failed "BitBot scripts not copied"
fi

echo ""

# ============================================================================
# Test 2: DevContainer Build (Optional - Very Slow)
# ============================================================================

echo -e "${BLUE}═══ Test 2: DevContainer Build (Optional) ═══${NC}"
echo ""

# Skip actual container build if CI or quick mode
if [[ "${BITBOT_TEST_SKIP_BUILD:-}" == "1" ]]; then
    echo -e "${YELLOW}⊘ SKIPPED${NC}: Container build (BITBOT_TEST_SKIP_BUILD=1)"
    echo ""
else
    run_test "Build DevContainer"

    # Convert path for Windows if using devcontainer.cmd
    workspace_arg="$TEST_WORKSPACE"
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        workspace_arg=$(echo "$TEST_WORKSPACE" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
    fi

    echo "Building container (this may take several minutes)..."
    if timeout 600 $DEVC_CMD build --workspace-folder "$workspace_arg" &>/tmp/integration-build-$$.log; then
        test_passed "DevContainer built successfully"
    else
        test_failed "DevContainer build failed"
        echo "Build log:"
        tail -20 /tmp/integration-build-$$.log
        rm -f /tmp/integration-build-$$.log
        # Continue with remaining tests even if build fails
    fi
    rm -f /tmp/integration-build-$$.log

    echo ""
fi

# ============================================================================
# Test 3: Container BitBot Commands (Validation)
# ============================================================================

echo -e "${BLUE}═══ Test 3: Container BitBot Commands ═══${NC}"
echo ""

run_test "Verify bitbot command exists in container scripts"
if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
    if bash -n ".devcontainer/bitbot/bitbot" 2>/dev/null; then
        test_passed "Container bitbot command has valid syntax"
    else
        test_failed "Container bitbot command has syntax errors"
    fi
else
    test_failed "Container bitbot command not found"
fi

run_test "Verify start.sh command"
if [[ -f ".devcontainer/bitbot/core/commands/start.sh" ]]; then
    if bash -n ".devcontainer/bitbot/core/commands/start.sh" 2>/dev/null; then
        test_passed "start.sh has valid syntax"
    else
        test_failed "start.sh has syntax errors"
    fi
else
    test_failed "start.sh not found"
fi

run_test "Verify resume.sh command"
if [[ -f ".devcontainer/bitbot/core/commands/resume.sh" ]]; then
    if bash -n ".devcontainer/bitbot/core/commands/resume.sh" 2>/dev/null; then
        test_passed "resume.sh has valid syntax"
    else
        test_failed "resume.sh has syntax errors"
    fi
else
    test_failed "resume.sh not found"
fi

run_test "Verify helpers.sh utilities"
if [[ -f ".devcontainer/bitbot/core/util/helpers.sh" ]]; then
    if bash -n ".devcontainer/bitbot/core/util/helpers.sh" 2>/dev/null; then
        test_passed "helpers.sh has valid syntax"
    else
        test_failed "helpers.sh has syntax errors"
    fi
else
    test_failed "helpers.sh not found"
fi

echo ""

# ============================================================================
# Test 4: Wrapper Integration
# ============================================================================

echo -e "${BLUE}═══ Test 4: Wrapper Integration ═══${NC}"
echo ""

run_test "Verify wrapper scripts"
if [[ -f ".devcontainer/bitbot/wrapper/claude-wrapper.sh" ]]; then
    if bash -n ".devcontainer/bitbot/wrapper/claude-wrapper.sh" 2>/dev/null; then
        test_passed "claude-wrapper.sh has valid syntax"
    else
        test_failed "claude-wrapper.sh has syntax errors"
    fi
else
    test_failed "claude-wrapper.sh not found"
fi

run_test "Verify watchdog script"
if [[ -f ".devcontainer/bitbot/wrapper/watchdog.sh" ]]; then
    if bash -n ".devcontainer/bitbot/wrapper/watchdog.sh" 2>/dev/null; then
        test_passed "watchdog.sh has valid syntax"
    else
        test_failed "watchdog.sh has syntax errors"
    fi
else
    test_failed "watchdog.sh not found"
fi

echo ""

# ============================================================================
# Test 5: Configuration Files
# ============================================================================

echo -e "${BLUE}═══ Test 5: Configuration Files ═══${NC}"
echo ""

run_test "Verify .bitbot/config.json"
if [[ -f ".bitbot/config.json" ]]; then
    if jq . .bitbot/config.json &>/dev/null; then
        test_passed "config.json is valid JSON"
    else
        test_failed "config.json is invalid JSON"
    fi
else
    test_failed "config.json not found"
fi

run_test "Verify .gitignore patterns"
if [[ -f ".gitignore" ]]; then
    if grep -q ".bitbot/internal/local/" .gitignore; then
        test_passed ".gitignore contains .bitbot/internal/local/ pattern"
    else
        test_failed ".gitignore missing .bitbot/internal/local/ pattern"
    fi
else
    test_failed ".gitignore not found"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Test Suite Summary            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total:   ${BLUE}${total_tests}${NC}"
echo -e "  Passed:  ${GREEN}${passed_tests}${NC}"
echo -e "  Failed:  ${RED}${failed_tests}${NC}"
echo ""

# Calculate success rate
if [[ $total_tests -gt 0 ]]; then
    success_rate=$((passed_tests * 100 / total_tests))
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
fi

# Final result
if [[ $failed_tests -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ALL TESTS PASSED! ✓                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     SOME TESTS FAILED ✗                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
