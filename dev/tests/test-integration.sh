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
#   ./test-integration-migrated.sh [--location wsl|windows|both] [--skip-build]
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
#   ./test-integration-migrated.sh                              # Test both locations, skip build
#   ./test-integration-migrated.sh --location windows           # Test Windows mount only
#   BITBOT_TEST_SKIP_BUILD=0 ./test-integration-migrated.sh     # Test with devcontainer build
#
# DevContainer CLI Strategy:
#   - Method 3 (cmd.exe wrapper): For Windows mounts (/mnt/c/) - converts to C:\ paths
#   - Method 4 (PowerShell wrapper): For WSL native paths - uses \\wsl.localhost\<distro>\... format
#   - Reference: sparc/4-refinement/docs/DEVCONTAINER-CLI-STRATEGY.md
#
# Performance Notes:
#   - WSL filesystem (ext4) provides better performance than /mnt/c/ (9P protocol)
#   - Recommendation: Use WSL filesystem for development (see VS Code documentation)
#
# MIGRATED TO USE: test-framework.sh, workspace-helper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"

# ============================================================================
# Configuration
# ============================================================================

# Parse arguments
TEST_LOCATION="both"  # Default: test both locations
SKIP_BUILD="${BITBOT_TEST_SKIP_BUILD:-1}"

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

# Test workspaces for both locations
WSL_TEST_WORKSPACE="$HOME/bitbot-integration-test-$$"
WIN_TEST_WORKSPACE="/mnt/c/bitbot-integration-test-$$"

# Current test workspace (will be set per test run)
TEST_WORKSPACE=""

# ============================================================================
# Cleanup Functions
# ============================================================================

cleanup_containers() {
    local workspace="$1"

    if [[ ! -f "$workspace/.devcontainer/devcontainer.json" ]]; then
        return 0
    fi

    cd "$workspace" 2>/dev/null || return 0

    if command -v devcontainer.cmd &>/dev/null; then
        # Convert path and use appropriate wrapper
        local win_path
        local distro="${WSL_DISTRO_NAME:-Ubuntu}"

        if [[ "$workspace" == /mnt/* ]]; then
            # Method 3: cmd.exe with Windows path
            win_path=$(echo "$workspace" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
            timeout 30 cmd.exe /c "cd /d $win_path && devcontainer.cmd down --workspace-folder ." &>/dev/null || true
        else
            # Method 4: PowerShell with UNC path
            win_path="\\\\wsl.localhost\\${distro}${workspace}"
            timeout 30 powershell.exe -NoProfile -Command "devcontainer.cmd down --workspace-folder '$win_path'" &>/dev/null || true
        fi
    elif command -v devcontainer &>/dev/null; then
        timeout 30 devcontainer down --workspace-folder "$workspace" &>/dev/null || true
    fi
}

cleanup() {
    echo ""
    echo "Cleaning up test workspaces..."

    # Stop any running containers and remove workspaces
    for workspace in "$WSL_TEST_WORKSPACE" "$WIN_TEST_WORKSPACE"; do
        if [[ -d "$workspace" ]]; then
            cleanup_containers "$workspace"
            rm -rf "$workspace" 2>/dev/null || true
        fi
    done

    # Remove test global config if we created it
    if [[ -f "$BITBOT_ROOT/config.json" ]]; then
        local created_at
        created_at=$(jq -r '.created_at // ""' "$BITBOT_ROOT/config.json" 2>/dev/null || echo "")
        if [[ "$created_at" == "test-run" ]]; then
            rm -f "$BITBOT_ROOT/config.json"
        fi
    fi

    echo "Cleanup complete"
}

trap cleanup EXIT

# ============================================================================
# Prerequisites Functions
# ============================================================================

check_prerequisites() {
    echo "═══ Prerequisites ═══"
    echo ""

    # Set BITBOT_HOME and add to PATH
    export BITBOT_HOME="$BITBOT_ROOT"
    export PATH="$BITBOT_HOME/core:$PATH"

    # Skip interactive git prompts in tests
    export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip "add git remote" prompt (option 1 = "Skip this time")

    # Check bitbot command
    if ! command -v bitbot &>/dev/null; then
        echo -e "${RED}✗ FAILED${NC}: bitbot command not found"
        echo "BITBOT_HOME: $BITBOT_HOME"
        echo "PATH: $PATH"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} bitbot command available"

    # Ensure global config exists (required for workspace init)
    test_section "Verify global config"
    if [[ ! -f "$BITBOT_HOME/config.json" ]]; then
        # Create minimal global config for testing
        cat > "$BITBOT_HOME/config.json" <<'EOF'
{
  "version": "0.1.0",
  "launch_mode": "terminal",
  "created_at": "test-run"
}
EOF
        test_pass "Created test global config"
    else
        test_pass "Global config exists"
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
}

# ============================================================================
# Path Conversion Helpers
# ============================================================================

# Convert WSL path to Windows format for devcontainer.cmd
# Uses wslpath built-in tool (supports both /mnt/c/ and WSL native paths)
convert_to_windows_path() {
    local wsl_path="$1"
    wslpath -w "$wsl_path"
}

# Get appropriate devcontainer command wrapper for a path
get_devcontainer_cmd() {
    local workspace_path="$1"

    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        # Using devcontainer.cmd - need wrapper
        if [[ "$workspace_path" == /mnt/* ]]; then
            # Method 3: cmd.exe for Windows mounts
            echo "cmd.exe /c"
        else
            # Method 4: PowerShell for WSL native
            echo "powershell.exe -NoProfile -Command"
        fi
    else
        # Using devcontainer CLI directly
        echo ""
    fi
}

# ============================================================================
# Test Functions
# ============================================================================

test_workspace_initialization() {
    test_section "Create test workspace"
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
    echo "# Integration Test" > README.md
    git init &>/dev/null
    test_pass "Test workspace created"

    test_section "Initialize BitBot workspace"
    # Note: bitbot init will try to launch config mode at the end,
    # which may fail in test environment. We allow failure and
    # check for successful workspace initialization instead.
    bitbot init --no-config &>/dev/null || true

    # Check if workspace was initialized (even if config launch failed)
    if [[ -d ".bitbot" ]] && [[ -d ".devcontainer" ]] && [[ -f ".bitbot/config.json" ]]; then
        test_pass "bitbot init completed (workspace structure created)"
    else
        test_fail "bitbot init failed to create workspace structure"
        exit 1
    fi

    test_section "Verify workspace structure"
    if [[ -d ".bitbot" ]] && [[ -d ".devcontainer" ]]; then
        test_pass "Workspace structure created (.bitbot, .devcontainer)"
    else
        test_fail "Workspace structure incomplete"
        exit 1
    fi

    test_section "Verify devcontainer.json"
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        if jq . .devcontainer/devcontainer.json &>/dev/null; then
            test_pass "devcontainer.json is valid JSON"
        else
            test_fail "devcontainer.json is invalid JSON"
        fi
    else
        test_fail "devcontainer.json not found"
    fi

    test_section "Verify BitBot scripts copied"
    if [[ -d ".devcontainer/bitbot" ]]; then
        if [[ -f ".devcontainer/bitbot/core/commands/start.sh" ]]; then
            test_pass "Container BitBot scripts present"
        else
            test_fail "BitBot scripts incomplete"
        fi
    else
        test_fail "BitBot scripts not copied"
    fi
}

test_devcontainer_build() {
    # Build container (controlled by argument or environment variable)
    local container_built=false

    if [[ "$SKIP_BUILD" == "1" ]]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC}: Container build (BITBOT_TEST_SKIP_BUILD=1)"
        echo -e "${YELLOW}ℹ${NC}  To test in-container execution, run: BITBOT_TEST_SKIP_BUILD=0 $0"
        echo ""
        echo "$container_built"
        return 0
    fi

    test_section "Build DevContainer"

    # Convert path and get appropriate command wrapper
    local win_path
    local cmd_wrapper
    win_path=$(convert_to_windows_path "$TEST_WORKSPACE")
    cmd_wrapper=$(get_devcontainer_cmd "$TEST_WORKSPACE")

    echo "Building container (this may take several minutes)..."

    if [[ "$TEST_WORKSPACE" == /mnt/* ]]; then
        # Method 3: cmd.exe with cd trick
        if timeout 600 $cmd_wrapper "cd /d $win_path && devcontainer.cmd build --workspace-folder ." &>/tmp/integration-build-$$.log; then
            test_pass "DevContainer built successfully"
            container_built=true
        else
            test_fail "DevContainer build failed"
            echo "Build log:"
            tail -20 /tmp/integration-build-$$.log
            # Continue with remaining tests even if build fails
        fi
    else
        # Method 4: PowerShell with UNC path
        if timeout 600 $cmd_wrapper "devcontainer.cmd build --workspace-folder '$win_path'" &>/tmp/integration-build-$$.log; then
            test_pass "DevContainer built successfully"
            container_built=true
        else
            test_fail "DevContainer build failed"
            echo "Build log:"
            tail -20 /tmp/integration-build-$$.log
            # Continue with remaining tests even if build fails
        fi
    fi

    rm -f /tmp/integration-build-$$.log
    echo ""
    echo "$container_built"
}

test_container_bitbot_commands() {
    test_section "Test bitbot help command"
    if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
        if bash ".devcontainer/bitbot/bitbot" help &>/tmp/bitbot-help-$$.log; then
            if grep -qiE "usage|help|command" /tmp/bitbot-help-$$.log; then
                test_pass "bitbot help command works"
            else
                test_fail "bitbot help output invalid"
                cat /tmp/bitbot-help-$$.log
            fi
        else
            test_fail "bitbot help command failed"
            cat /tmp/bitbot-help-$$.log
        fi
        rm -f /tmp/bitbot-help-$$.log
    else
        test_fail "Container bitbot command not found"
    fi

    test_section "Test bitbot invalid command handling"
    if bash ".devcontainer/bitbot/bitbot" invalid-command &>/tmp/bitbot-invalid-$$.log; then
        test_fail "Invalid command should return error"
    else
        # Should fail with error
        if grep -qE "Unknown command|usage:" /tmp/bitbot-invalid-$$.log; then
            test_pass "Invalid command handled correctly"
        else
            test_fail "Invalid command error message missing"
        fi
    fi
    rm -f /tmp/bitbot-invalid-$$.log

    test_section "Test helpers.sh can be sourced"
    if [[ -f ".devcontainer/bitbot/core/util/helpers.sh" ]]; then
        if bash -c "source .devcontainer/bitbot/core/util/helpers.sh && command_exists bash" 2>/dev/null; then
            test_pass "helpers.sh sourced and functions work"
        else
            test_fail "helpers.sh sourcing failed"
        fi
    else
        test_fail "helpers.sh not found"
    fi

    test_section "Test bitbot script has valid shebang"
    if [[ -f ".devcontainer/bitbot/bitbot" ]]; then
        if head -1 ".devcontainer/bitbot/bitbot" | grep -q "^#!/"; then
            test_pass "bitbot has valid shebang"
        else
            test_fail "bitbot missing shebang"
        fi
    else
        test_fail "bitbot not found"
    fi

    test_section "Test all core commands are executable"
    local all_executable=true
    for cmd in .devcontainer/bitbot/core/commands/*.sh; do
        if [[ ! -x "$cmd" ]]; then
            all_executable=false
            break
        fi
    done
    if [[ "$all_executable" == "true" ]]; then
        test_pass "All core commands are executable"
    else
        test_fail "Some commands not executable"
    fi
}

test_wrapper_integration() {
    test_section "Test claude-wrapper.sh syntax and structure"
    if [[ -f ".devcontainer/bitbot/wrapper/claude-wrapper.sh" ]]; then
        if bash -n ".devcontainer/bitbot/wrapper/claude-wrapper.sh" 2>/dev/null; then
            # Check for key functions
            if grep -qE "handle_command|start_watchdog|cleanup" ".devcontainer/bitbot/wrapper/claude-wrapper.sh"; then
                test_pass "claude-wrapper.sh has valid structure"
            else
                test_fail "claude-wrapper.sh missing key functions"
            fi
        else
            test_fail "claude-wrapper.sh has syntax errors"
        fi
    else
        test_fail "claude-wrapper.sh not found"
    fi

    test_section "Test watchdog.sh syntax and monitoring logic"
    if [[ -f ".devcontainer/bitbot/wrapper/watchdog.sh" ]]; then
        if bash -n ".devcontainer/bitbot/wrapper/watchdog.sh" 2>/dev/null; then
            # Check for monitoring functions
            if grep -q "check_session_alive" ".devcontainer/bitbot/wrapper/watchdog.sh" || grep -q "monitor" ".devcontainer/bitbot/wrapper/watchdog.sh"; then
                test_pass "watchdog.sh has monitoring logic"
            else
                test_fail "watchdog.sh missing monitoring functions"
            fi
        else
            test_fail "watchdog.sh has syntax errors"
        fi
    else
        test_fail "watchdog.sh not found"
    fi

    test_section "Test wrapper scripts are executable"
    local wrapper_executable=true
    for script in .devcontainer/bitbot/wrapper/*.sh; do
        if [[ ! -x "$script" ]]; then
            wrapper_executable=false
            break
        fi
    done
    if [[ "$wrapper_executable" == "true" ]]; then
        test_pass "All wrapper scripts are executable"
    else
        test_fail "Some wrapper scripts not executable"
    fi

    test_section "Test send-wrapper-command.sh exists"
    if [[ -f ".devcontainer/bitbot/wrapper/send-wrapper-command.sh" ]]; then
        if [[ -x ".devcontainer/bitbot/wrapper/send-wrapper-command.sh" ]]; then
            test_pass "send-wrapper-command.sh is executable"
        else
            test_fail "send-wrapper-command.sh not executable"
        fi
    else
        test_fail "send-wrapper-command.sh not found"
    fi
}

test_configuration_files() {
    test_section "Verify .bitbot/config.json"
    if [[ -f ".bitbot/config.json" ]]; then
        if jq . .bitbot/config.json &>/dev/null; then
            test_pass "config.json is valid JSON"
        else
            test_fail "config.json is invalid JSON"
        fi
    else
        test_fail "config.json not found"
    fi

    test_section "Verify .gitignore patterns"
    if [[ -f ".gitignore" ]]; then
        if grep -q ".bitbot/internal/local/" .gitignore; then
            test_pass ".gitignore contains .bitbot/internal/local/ pattern"
        else
            test_fail ".gitignore missing .bitbot/internal/local/ pattern"
        fi
    else
        test_fail ".gitignore not found"
    fi
}

test_in_container_execution() {
    local container_built="$1"

    if [[ "$container_built" == "false" ]]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC}: Container not built (tests require built container)"
        echo -e "${YELLOW}ℹ${NC}  To run these tests: BITBOT_TEST_SKIP_BUILD=0 $0"
        echo ""
        return 0
    fi

    # Convert path and get appropriate command wrapper
    local win_path
    local cmd_wrapper
    win_path=$(convert_to_windows_path "$TEST_WORKSPACE")
    cmd_wrapper=$(get_devcontainer_cmd "$TEST_WORKSPACE")

    # Helper function to run commands in container
    run_in_container() {
        local cmd="$1"
        if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
            if [[ "$TEST_WORKSPACE" == /mnt/* ]]; then
                # Method 3: cmd.exe with cd trick
                timeout 30 cmd.exe /c "cd /d $win_path && devcontainer.cmd exec --workspace-folder . $cmd" 2>&1
            else
                # Method 4: PowerShell with UNC path
                timeout 30 powershell.exe -NoProfile -Command "devcontainer.cmd exec --workspace-folder '$win_path' $cmd" 2>&1
            fi
        else
            timeout 30 devcontainer exec --workspace-folder "$TEST_WORKSPACE" bash -c "$cmd" 2>&1
        fi
    }

    test_section "Test bitbot command in container"
    if run_in_container "/usr/local/bitbot/bitbot help" | grep -qiE "usage|help|command"; then
        test_pass "bitbot command works in container"
    else
        test_fail "bitbot command failed in container"
    fi

    test_section "Test wrapper script accessibility"
    if run_in_container "test -x /usr/local/bitbot/wrapper/claude-wrapper.sh && echo OK" | grep -q "OK"; then
        test_pass "Wrapper scripts mounted and executable"
    else
        test_fail "Wrapper scripts not accessible"
    fi

    test_section "Test pipe directory can be created"
    if run_in_container "mkdir -p /workspace/.bitbot/tmp/pipes && echo OK" | grep -q "OK"; then
        test_pass "Pipe directory creation works"
    else
        test_fail "Pipe directory creation failed"
    fi

    test_section "Test tmux availability in container"
    if run_in_container "command -v tmux && echo OK" | grep -q "OK"; then
        test_pass "tmux available in container"
    else
        test_fail "tmux not available (required for layer 2)"
    fi

    test_section "Test helpers.sh functions in container"
    if run_in_container "source /usr/local/bitbot/core/util/helpers.sh && command_exists bash && echo OK" | grep -q "OK"; then
        test_pass "helpers.sh works in container"
    else
        test_fail "helpers.sh failed in container"
    fi

    test_section "Test claude command availability"
    if run_in_container "command -v claude && echo OK" | grep -q "OK"; then
        test_pass "Claude Code available in container"
    else
        test_fail "Claude Code not available (expected in devcontainer)"
    fi
}

# ============================================================================
# Main Integration Test Function
# ============================================================================

run_integration_tests_for_location() {
    local location_name="$1"
    local workspace_path="$2"

    # Set global TEST_WORKSPACE for all tests
    TEST_WORKSPACE="$workspace_path"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo -e "${CYAN}║  Testing Location: $(printf '%-59s' "$location_name")║${NC}"
    echo -e "${CYAN}║  Path: $(printf '%-67s' "$workspace_path")║${NC}"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Test 1: Workspace Initialization
    echo "═══ Test 1: Workspace Initialization ═══"
    echo ""
    test_workspace_initialization
    echo ""

    # Test 2: DevContainer Build (Optional)
    echo "═══ Test 2: DevContainer Build (Optional) ═══"
    echo ""
    local container_built
    container_built=$(test_devcontainer_build)

    # Test 3: Container BitBot Commands
    echo "═══ Test 3: Container BitBot Commands ═══"
    echo ""
    test_container_bitbot_commands
    echo ""

    # Test 4: Wrapper Integration
    echo "═══ Test 4: Wrapper Integration ═══"
    echo ""
    test_wrapper_integration
    echo ""

    # Test 5: Configuration Files
    echo "═══ Test 5: Configuration Files ═══"
    echo ""
    test_configuration_files
    echo ""

    # Test 6: In-Container Execution
    echo "═══ Test 6: In-Container Execution ═══"
    echo ""
    test_in_container_execution "$container_built"
}

# ============================================================================
# Test Orchestration
# ============================================================================

test_suite_begin "BitBot Integration Test Suite - Full End-to-End Workflow"

# Check prerequisites
check_prerequisites

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
# Test Suite Complete
# ============================================================================

test_suite_end
