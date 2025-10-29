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
# 6. Dual-location filesystem compatibility (WSL native + Windows mounts)
#
# Usage:
#   ./test-integration.sh [--location wsl|windows|both] [--skip-build]
#
# Options:
#   --location <loc>  Test location(s): wsl, windows, or both (default: both)
#   --skip-build      Skip devcontainer build (faster, default via BITBOT_TEST_SKIP_BUILD=1)
#
# Test Locations:
#   wsl              WSL native filesystem (ext4) - best performance
#   windows          Windows mount (/mnt/c/) - 9P filesystem
#   both             Test both locations (default)
#
# Examples:
#   ./test-integration.sh                              # Test both locations, skip build
#   ./test-integration.sh --location windows           # Test Windows mount only
#   BITBOT_TEST_SKIP_BUILD=0 ./test-integration.sh     # Test with devcontainer build
#
# Known Limitations:
#   - devcontainer.cmd cannot accept WSL native paths when called from bash
#   - WSL home tests are skipped when using devcontainer.cmd
#   - For full WSL testing, install native devcontainer CLI: npm install -g @devcontainers/cli
#
# Performance Notes:
#   - WSL filesystem (ext4) provides better performance than /mnt/c/ (9P)
#   - Recommendation: Use WSL filesystem for development (see VS Code documentation)
#
# Note: This test validates the full BitBot system integration across
# different filesystem configurations to ensure compatibility.

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

# Parse arguments
TEST_LOCATION="both"  # Default: test both locations
SKIP_BUILD="${BITBOT_TEST_SKIP_BUILD:-0}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --location)
            TEST_LOCATION="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--location wsl|windows|both] [--skip-build]"
            exit 1
            ;;
    esac
done

# Validate location argument
if [[ "$TEST_LOCATION" != "wsl" && "$TEST_LOCATION" != "windows" && "$TEST_LOCATION" != "both" ]]; then
    echo "Invalid location: $TEST_LOCATION"
    echo "Must be one of: wsl, windows, both"
    exit 1
fi

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0

# Test workspaces for both locations
WSL_TEST_WORKSPACE="$HOME/bitbot-integration-test-$$"
WIN_TEST_WORKSPACE="/mnt/c/bitbot-integration-test-$$"

# Current test workspace (will be set per test run)
TEST_WORKSPACE=""

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
    echo "Cleaning up test workspaces..."

    # Stop any running containers and remove workspaces
    for workspace in "$WSL_TEST_WORKSPACE" "$WIN_TEST_WORKSPACE"; do
        if [[ -f "$workspace/.devcontainer/devcontainer.json" ]]; then
            cd "$workspace" 2>/dev/null || true
            if command -v devcontainer.cmd &>/dev/null; then
                # Convert to Windows path if needed
                if [[ "$workspace" == /mnt/* ]]; then
                    local win_path
                    win_path=$(echo "$workspace" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
                    timeout 30 cmd.exe /c devcontainer.cmd down --workspace-folder "$win_path" &>/dev/null || true
                fi
            elif command -v devcontainer &>/dev/null; then
                timeout 30 devcontainer down --workspace-folder "$workspace" &>/dev/null || true
            fi
        fi

        # Remove workspace
        rm -rf "$workspace" 2>/dev/null || true
    done

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
# Main Integration Test Function
# ============================================================================

run_integration_tests_for_location() {
    local location_name="$1"
    local workspace_path="$2"

    # Set global TEST_WORKSPACE for all tests
    TEST_WORKSPACE="$workspace_path"

    # Track container build status for this location
    local CONTAINER_BUILT=false

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Testing Location: $(printf '%-21s' "$location_name")║${NC}"
    echo -e "${CYAN}║  Path: $(printf '%-29s' "$workspace_path" | head -c 29)║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    # Check if using devcontainer.cmd with WSL home (unsupported)
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]] && [[ "$workspace_path" != /mnt/* ]]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC}: $location_name"
        echo ""
        echo "Reason: devcontainer.cmd cannot accept WSL native paths when called from bash"
        echo "This is a known limitation (see test-devcontainer-locations.sh)"
        echo ""
        echo "To test WSL locations, use native devcontainer CLI:"
        echo "  npm install -g @devcontainers/cli"
        echo ""
        return 0
    fi

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

# Build container (controlled by argument or environment variable)
CONTAINER_BUILT=false

if [[ "$SKIP_BUILD" == "1" ]]; then
    echo -e "${YELLOW}⊘ SKIPPED${NC}: Container build (BITBOT_TEST_SKIP_BUILD=1)"
    echo -e "${YELLOW}ℹ${NC}  To test in-container execution, run: BITBOT_TEST_SKIP_BUILD=0 $0"
    echo ""
elif [[ "${BITBOT_TEST_BUILD_ONLY:-0}" == "1" ]]; then
    run_test "Build DevContainer (build-only mode)"

    # Convert path for Windows if using devcontainer.cmd
    workspace_arg="$TEST_WORKSPACE"
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        workspace_arg=$(echo "$TEST_WORKSPACE" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
    fi

    echo "Building container (this may take several minutes)..."
    if timeout 600 $DEVC_CMD build --workspace-folder "$workspace_arg" &>/tmp/integration-build-$$.log; then
        test_passed "DevContainer built successfully"
        CONTAINER_BUILT=true
    else
        test_failed "DevContainer build failed"
        echo "Build log:"
        tail -20 /tmp/integration-build-$$.log
        rm -f /tmp/integration-build-$$.log
    fi
    rm -f /tmp/integration-build-$$.log

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
        CONTAINER_BUILT=true
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
# Test 3: Container BitBot Commands (Execution Tests)
# ============================================================================

echo -e "${BLUE}═══ Test 3: Container BitBot Commands ═══${NC}"
echo ""

run_test "Test bitbot help command"
if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
    if bash ".devcontainer/bitbot/bitbot" help &>/tmp/bitbot-help-$$.log; then
        if grep -qiE "usage|help|command" /tmp/bitbot-help-$$.log; then
            test_passed "bitbot help command works"
        else
            test_failed "bitbot help output invalid"
            cat /tmp/bitbot-help-$$.log
        fi
    else
        test_failed "bitbot help command failed"
        cat /tmp/bitbot-help-$$.log
    fi
    rm -f /tmp/bitbot-help-$$.log
else
    test_failed "Container bitbot command not found"
fi

run_test "Test bitbot invalid command handling"
if bash ".devcontainer/bitbot/bitbot" invalid-command &>/tmp/bitbot-invalid-$$.log; then
    test_failed "Invalid command should return error"
else
    # Should fail with error
    if grep -qE "Unknown command|usage:" /tmp/bitbot-invalid-$$.log; then
        test_passed "Invalid command handled correctly"
    else
        test_failed "Invalid command error message missing"
    fi
fi
rm -f /tmp/bitbot-invalid-$$.log

run_test "Test helpers.sh can be sourced"
if [[ -f ".devcontainer/bitbot/core/util/helpers.sh" ]]; then
    if bash -c "source .devcontainer/bitbot/core/util/helpers.sh && command_exists bash" 2>/dev/null; then
        test_passed "helpers.sh sourced and functions work"
    else
        test_failed "helpers.sh sourcing failed"
    fi
else
    test_failed "helpers.sh not found"
fi

run_test "Test bitbot script has valid shebang"
if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
    if head -1 ".devcontainer/bitbot/bitbot" | grep -q "^#!/"; then
        test_passed "bitbot has valid shebang"
    else
        test_failed "bitbot missing shebang"
    fi
else
    test_failed "bitbot not found"
fi

run_test "Test all core commands are executable"
all_executable=true
for cmd in .devcontainer/bitbot/core/commands/*.sh; do
    if [[ ! -x "$cmd" ]]; then
        all_executable=false
        break
    fi
done
if [[ "$all_executable" == "true" ]]; then
    test_passed "All core commands are executable"
else
    test_failed "Some commands not executable"
fi

echo ""

# ============================================================================
# Test 4: Wrapper Integration (Execution Tests)
# ============================================================================

echo -e "${BLUE}═══ Test 4: Wrapper Integration ═══${NC}"
echo ""

run_test "Test claude-wrapper.sh syntax and structure"
if [[ -f ".devcontainer/bitbot/wrapper/claude-wrapper.sh" ]]; then
    if bash -n ".devcontainer/bitbot/wrapper/claude-wrapper.sh" 2>/dev/null; then
        # Check for key functions
        if grep -qE "handle_command|start_watchdog|cleanup" ".devcontainer/bitbot/wrapper/claude-wrapper.sh"; then
            test_passed "claude-wrapper.sh has valid structure"
        else
            test_failed "claude-wrapper.sh missing key functions"
        fi
    else
        test_failed "claude-wrapper.sh has syntax errors"
    fi
else
    test_failed "claude-wrapper.sh not found"
fi

run_test "Test watchdog.sh syntax and monitoring logic"
if [[ -f ".devcontainer/bitbot/wrapper/watchdog.sh" ]]; then
    if bash -n ".devcontainer/bitbot/wrapper/watchdog.sh" 2>/dev/null; then
        # Check for monitoring functions
        if grep -q "check_session_alive" ".devcontainer/bitbot/wrapper/watchdog.sh" || grep -q "monitor" ".devcontainer/bitbot/wrapper/watchdog.sh"; then
            test_passed "watchdog.sh has monitoring logic"
        else
            test_failed "watchdog.sh missing monitoring functions"
        fi
    else
        test_failed "watchdog.sh has syntax errors"
    fi
else
    test_failed "watchdog.sh not found"
fi

run_test "Test wrapper scripts are executable"
wrapper_executable=true
for script in .devcontainer/bitbot/wrapper/*.sh; do
    if [[ ! -x "$script" ]]; then
        wrapper_executable=false
        break
    fi
done
if [[ "$wrapper_executable" == "true" ]]; then
    test_passed "All wrapper scripts are executable"
else
    test_failed "Some wrapper scripts not executable"
fi

run_test "Test send-wrapper-command.sh exists"
if [[ -f ".devcontainer/bitbot/wrapper/send-wrapper-command.sh" ]]; then
    if [[ -x ".devcontainer/bitbot/wrapper/send-wrapper-command.sh" ]]; then
        test_passed "send-wrapper-command.sh is executable"
    else
        test_failed "send-wrapper-command.sh not executable"
    fi
else
    test_failed "send-wrapper-command.sh not found"
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
# Test 6: In-Container Execution (Layer 1 Tests)
# ============================================================================

echo -e "${BLUE}═══ Test 6: In-Container Execution ═══${NC}"
echo ""

if [[ "$CONTAINER_BUILT" == "false" ]]; then
    echo -e "${YELLOW}⊘ SKIPPED${NC}: Container not built (tests require built container)"
    echo -e "${YELLOW}ℹ${NC}  To run these tests: BITBOT_TEST_SKIP_BUILD=0 $0"
    echo ""
else
    # Convert path for devcontainer exec
    workspace_arg="$TEST_WORKSPACE"
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        workspace_arg=$(echo "$TEST_WORKSPACE" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
    fi

    # Helper function to run commands in container
    run_in_container() {
        local cmd="$1"
        if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
            timeout 30 cmd.exe /c "cd /d $workspace_arg && devcontainer.cmd exec --workspace-folder $workspace_arg $cmd" 2>&1
        else
            timeout 30 devcontainer exec --workspace-folder "$workspace_arg" bash -c "$cmd" 2>&1
        fi
    }

    run_test "Test bitbot command in container"
    if run_in_container "/usr/local/bitbot/bitbot help" | grep -qiE "usage|help|command"; then
        test_passed "bitbot command works in container"
    else
        test_failed "bitbot command failed in container"
    fi

    run_test "Test wrapper script accessibility"
    if run_in_container "test -x /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
        test_passed "Wrapper scripts mounted and executable"
    else
        test_failed "Wrapper scripts not accessible"
    fi

    run_test "Test pipe directory can be created"
    if run_in_container "mkdir -p /workspace/.bitbot/tmp/pipes && echo OK" | grep -q "OK"; then
        test_passed "Pipe directory creation works"
    else
        test_failed "Pipe directory creation failed"
    fi

    run_test "Test tmux availability in container"
    if run_in_container "command -v tmux && echo OK" | grep -q "OK"; then
        test_passed "tmux available in container"
    else
        test_failed "tmux not available (required for layer 2)"
    fi

    run_test "Test helpers.sh functions in container"
    if run_in_container "source /usr/local/bitbot/core/util/helpers.sh && command_exists bash && echo OK" | grep -q "OK"; then
        test_passed "helpers.sh works in container"
    else
        test_failed "helpers.sh failed in container"
    fi

    run_test "Test claude command availability"
    if run_in_container "command -v claude && echo OK" | grep -q "OK"; then
        test_passed "Claude Code available in container"
    else
        test_failed "Claude Code not available (expected in devcontainer)"
    fi

    echo ""
fi

} # End of run_integration_tests_for_location()

# ============================================================================
# Test Orchestration - Run Tests for Selected Locations
# ============================================================================

# Determine which locations to test
locations_to_test=()
case "$TEST_LOCATION" in
    wsl)
        locations_to_test=("WSL Home:$WSL_TEST_WORKSPACE")
        ;;
    windows)
        locations_to_test=("Windows Mount:$WIN_TEST_WORKSPACE")
        ;;
    both)
        locations_to_test=("WSL Home:$WSL_TEST_WORKSPACE" "Windows Mount:$WIN_TEST_WORKSPACE")
        ;;
esac

# Run tests for each location
for location in "${locations_to_test[@]}"; do
    IFS=':' read -r location_name location_path <<< "$location"
    run_integration_tests_for_location "$location_name" "$location_path"
done

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
