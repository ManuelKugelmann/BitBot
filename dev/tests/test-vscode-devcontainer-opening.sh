#!/usr/bin/env bash
#
# Test: VS Code DevContainer Opening
# Tests VS Code automatic DevContainer opening for BitBot workspaces
#
# Usage:
#   test-vscode-devcontainer-opening.sh [--no-cleanup]
#
# Options:
#   --no-cleanup: Skip cleanup (leave workspace for inspection)
#
# Requirements:
#   - VS Code installed with code CLI in PATH
#   - Docker running
#   - Remote-Containers extension installed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BITBOT_CMD="$BITBOT_ROOT/core/bitbot"

# Source test helpers
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"
source "${SCRIPT_DIR}/helpers/vscode-helper.sh"

# Parse arguments
SKIP_CLEANUP=false

for arg in "$@"; do
    case "$arg" in
        --no-cleanup)
            SKIP_CLEANUP=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: test-vscode-devcontainer-opening.sh [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Test workspace
TEST_WORKSPACE=""

# Cleanup function
cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Workspace left for inspection: $TEST_WORKSPACE"
        echo -e "  Remember to clean up manually:"
        echo -e "    rm -rf $TEST_WORKSPACE"
        if vscode_devcontainer_is_running "$TEST_WORKSPACE" 2>/dev/null; then
            local container_id
            container_id=$(vscode_get_devcontainer_info "$TEST_WORKSPACE" 2>/dev/null)
            if [[ -n "$container_id" ]]; then
                echo -e "    docker stop $container_id"
                echo -e "    docker rm $container_id"
            fi
        fi
        echo ""
        return
    fi

    echo ""
    echo "Cleaning up test environment..."

    # Stop and remove DevContainer if running
    if [[ -n "$TEST_WORKSPACE" ]] && vscode_devcontainer_is_running "$TEST_WORKSPACE" 2>/dev/null; then
        local container_id
        container_id=$(vscode_get_devcontainer_info "$TEST_WORKSPACE" 2>/dev/null)
        if [[ -n "$container_id" ]]; then
            echo "  Stopping DevContainer: $container_id"
            docker stop "$container_id" &>/dev/null || true
            docker rm "$container_id" &>/dev/null || true
        fi
    fi

    # Remove test workspace
    if [[ -n "$TEST_WORKSPACE" ]] && [[ -d "$TEST_WORKSPACE" ]]; then
        cleanup_test_workspace "$TEST_WORKSPACE"
    fi
}

trap cleanup EXIT

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "VS Code DevContainer Opening Test"

# ============================================================================
# Prerequisites Check
# ============================================================================

test_section "Prerequisites Check"

# Check VS Code CLI
if vscode_cli_available; then
    test_pass "VS Code CLI available"
    code_version=$(code --version 2>/dev/null | head -1)
    echo "  ℹ VS Code version: $code_version"
else
    test_fail "VS Code CLI not found (code command not in PATH)"
    echo ""
    echo "Install VS Code and add to PATH:"
    echo "  Windows: Install VS Code and select 'Add to PATH' during install"
    echo "  Linux:   sudo snap install code --classic"
    echo "  macOS:   brew install --cask visual-studio-code"
    exit 1
fi

# Check Docker
if command -v docker &>/dev/null; then
    test_pass "Docker command available"
else
    test_fail "Docker not found"
    exit 1
fi

if docker info &>/dev/null; then
    test_pass "Docker daemon running"
else
    test_fail "Docker daemon not running"
    exit 1
fi

# Check Remote-Containers extension (optional for basic tests)
DEVCONTAINER_EXTENSION_INSTALLED=false
if code --list-extensions 2>/dev/null | grep -q "ms-vscode-remote.remote-containers"; then
    test_pass "Remote-Containers extension installed"
    DEVCONTAINER_EXTENSION_INSTALLED=true
elif command -v powershell.exe &>/dev/null; then
    # On WSL, check Windows extensions via PowerShell
    if powershell.exe -NoProfile -Command "Test-Path \"\$env:USERPROFILE\\.vscode\\extensions\\ms-vscode-remote.remote-containers-*\"" 2>/dev/null | grep -q "True"; then
        test_pass "Remote-Containers extension installed (detected via Windows)"
        DEVCONTAINER_EXTENSION_INSTALLED=true
    else
        test_skip "Remote-Containers extension" "Not installed (DevContainer tests will be skipped)"
        echo ""
        echo "  To enable full DevContainer testing, install:"
        echo "  code --install-extension ms-vscode-remote.remote-containers"
        echo ""
    fi
else
    test_skip "Remote-Containers extension" "Could not verify (DevContainer tests will be skipped)"
    echo ""
    echo "  To enable full DevContainer testing, install:"
    echo "  code --install-extension ms-vscode-remote.remote-containers"
    echo ""
fi

# Check BitBot
if [[ -f "$BITBOT_CMD" ]] && [[ -x "$BITBOT_CMD" ]]; then
    test_pass "BitBot command available"
else
    test_fail "BitBot command not found or not executable"
    exit 1
fi

# ============================================================================
# Test 1: Create BitBot Workspace
# ============================================================================

test_section "Test 1: Create BitBot Workspace"

TEST_WORKSPACE=$(create_test_workspace "vscode-devcontainer-test")
echo "  Created test workspace: $TEST_WORKSPACE"

cd "$TEST_WORKSPACE"
git init -q

# Configure git for test
git config user.email "test@bitbot.test"
git config user.name "BitBot Test"

# Initialize with BitBot
echo "test project for VS Code DevContainer" > README.md
git add README.md
git commit -q -m "Initial commit"

# Add dummy git remote (required by bitbot init)
git remote add origin https://github.com/test/test-vscode-devcontainer.git

test_pass "Test workspace created and initialized"

# ============================================================================
# Test 2: Run bitbot init
# ============================================================================

test_section "Test 2: Run bitbot init (non-interactive)"

export BITBOT_HOME="$BITBOT_ROOT"

# Run bitbot init with --no-config flag (non-interactive)
if timeout 30 bash "$BITBOT_CMD" init --no-config &>/dev/null; then
    test_pass "bitbot init completed successfully"
elif [[ $? -eq 124 ]]; then
    test_fail "bitbot init timed out"
    exit 1
else
    test_fail "bitbot init failed"
    exit 1
fi

# Verify DevContainer configuration created
if [[ -d ".devcontainer" ]] && [[ -f ".devcontainer/devcontainer.json" ]]; then
    test_pass "DevContainer configuration created"
else
    test_fail "DevContainer configuration not created"
    exit 1
fi

# ============================================================================
# Test 3: Open Workspace in VS Code
# ============================================================================

test_section "Test 3: Open Workspace in VS Code"

# Record initial state
INITIAL_VSCODE_RUNNING=false
if vscode_is_running; then
    INITIAL_VSCODE_RUNNING=true
    echo "  ℹ VS Code already running"
else
    echo "  ℹ VS Code not running initially"
fi

# Open workspace in VS Code
echo "  Opening workspace in VS Code..."
if vscode_open_workspace "$TEST_WORKSPACE"; then
    test_pass "VS Code open command executed"
else
    test_fail "Failed to execute VS Code open command"
    exit 1
fi

# Wait for VS Code to start
echo "  Waiting for VS Code to start..."
if vscode_wait_for_start 30; then
    test_pass "VS Code started"
else
    test_fail "VS Code did not start within timeout"
    exit 1
fi

# ============================================================================
# Test 4: Check VS Code Process State
# ============================================================================

test_section "Test 4: Check VS Code Process State"

if vscode_is_running; then
    test_pass "VS Code process is running"

    process_count=$(vscode_process_count)
    echo "  ℹ VS Code processes: $process_count"
else
    test_fail "VS Code process not detected"
fi

# Try to get VS Code status
if vscode_get_status &>/dev/null; then
    test_pass "VS Code status command successful"
    echo "  ℹ VS Code status:"
    vscode_get_status 2>/dev/null | head -20
else
    test_skip "VS Code status check" "code --status not available or failed"
fi

# ============================================================================
# Test 5: Check Workspace Storage
# ============================================================================

test_section "Test 5: Check Workspace Storage"

# Wait a bit for VS Code to initialize workspace
sleep 3

workspace_hash=$(vscode_get_workspace_hash "$TEST_WORKSPACE" 2>/dev/null)
if [[ -n "$workspace_hash" ]]; then
    test_pass "Workspace registered in VS Code storage"
    echo "  ℹ Workspace hash: $workspace_hash"
else
    test_skip "Workspace storage check" "Workspace not yet registered (may take longer)"
fi

if vscode_workspace_state_exists "$TEST_WORKSPACE" 2>/dev/null; then
    test_pass "Workspace state database exists"
else
    test_skip "Workspace state database" "Not created yet (may take longer)"
fi

# ============================================================================
# Test 6: Wait for DevContainer Build/Start
# ============================================================================

test_section "Test 6: Wait for DevContainer Build and Start"

if [[ "$DEVCONTAINER_EXTENSION_INSTALLED" == "false" ]]; then
    test_skip "DevContainer build/start" "Remote-Containers extension not installed"
else
    echo "  Waiting for DevContainer to start (this may take several minutes)..."
    echo "  ℹ DevContainer build includes installing packages and dependencies"

    if vscode_wait_for_devcontainer "$TEST_WORKSPACE" 180; then
    test_pass "DevContainer started successfully"

    container_id=$(vscode_get_devcontainer_info "$TEST_WORKSPACE" 2>/dev/null)
    if [[ -n "$container_id" ]]; then
        echo "  ℹ Container ID: $container_id"

        # Get container info
        container_name=$(docker inspect --format='{{.Name}}' "$container_id" 2>/dev/null | sed 's/^\///')
        container_image=$(docker inspect --format='{{.Config.Image}}' "$container_id" 2>/dev/null)

        echo "  ℹ Container name: $container_name"
        echo "  ℹ Container image: $container_image"

        test_pass "DevContainer info retrieved"
    else
        test_skip "DevContainer info" "Could not retrieve container details"
    fi
else
    test_fail "DevContainer did not start within timeout (180s)"
    echo ""
    echo "  This could be due to:"
    echo "  - First-time container build taking longer than expected"
    echo "  - Network issues downloading base images"
    echo "  - Docker daemon issues"
    echo "  - VS Code not configured to auto-open DevContainers"
    echo ""
    echo "  Check Docker containers:"
    docker ps -a --filter="label=vsch.quality" 2>/dev/null | head -10 || echo "  (no containers found)"
    fi
fi

# ============================================================================
# Test 7: Verify DevContainer Configuration
# ============================================================================

test_section "Test 7: Verify DevContainer Configuration"

if vscode_devcontainer_is_running "$TEST_WORKSPACE" 2>/dev/null; then
    test_pass "DevContainer is running"

    container_id=$(vscode_get_devcontainer_info "$TEST_WORKSPACE" 2>/dev/null)

    # Check if BitBot is mounted in container
    if docker exec "$container_id" test -d /usr/local/bitbot 2>/dev/null; then
        test_pass "BitBot mounted in container (/usr/local/bitbot)"
    else
        test_fail "BitBot not mounted in container"
    fi

    # Check if workspace is mounted
    if docker exec "$container_id" test -d /workspace 2>/dev/null; then
        test_pass "Workspace mounted in container (/workspace)"
    else
        test_fail "Workspace not mounted in container"
    fi

    # Check if bitbot command is available in container
    if docker exec "$container_id" which bitbot &>/dev/null; then
        test_pass "bitbot command available in container"
    else
        test_fail "bitbot command not available in container"
    fi
else
    test_skip "DevContainer verification" "DevContainer not running"
fi

# ============================================================================
# Test 8: List All DevContainers
# ============================================================================

test_section "Test 8: List All DevContainers"

devcontainer_list=$(vscode_list_devcontainers 2>/dev/null)
if [[ -n "$devcontainer_list" ]]; then
    container_count=$(echo "$devcontainer_list" | wc -l)
    test_pass "Found $container_count DevContainer(s) running"

    echo ""
    echo "  Running DevContainers:"
    while IFS= read -r container_id; do
        local_folder=$(docker inspect --format='{{index .Config.Labels "devcontainer.local_folder"}}' "$container_id" 2>/dev/null)
        container_name=$(docker inspect --format='{{.Name}}' "$container_id" 2>/dev/null | sed 's/^\///')
        echo "    - $container_name ($container_id)"
        echo "      Workspace: $local_folder"
    done <<< "$devcontainer_list"
    echo ""
else
    test_fail "No DevContainers found running"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

echo ""
echo "  ℹ Test workspace will be auto-cleaned by trap (unless --no-cleanup used)"
echo ""

test_suite_end
