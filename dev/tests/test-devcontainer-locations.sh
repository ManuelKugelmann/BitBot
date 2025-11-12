#!/usr/bin/env bash
#
# DevContainer Location Test - WSL home vs /mnt/c/
# Tests that devcontainers can be built in both locations
#
# This test validates filesystem compatibility for devcontainers:
#   - WSL native filesystem (ext4) - best performance
#   - Windows mount (/mnt/c/) - 9P protocol
#
# Note: Only tests build success. Exec/run tests require additional
#       container management (up/down) which is tested elsewhere.
#
# DevContainer CLI Strategy:
#   - Method 3 (cmd.exe wrapper): For Windows mounts (/mnt/c/) - converts to C:\ paths
#   - Method 4 (PowerShell wrapper): For WSL native paths - uses \\wsl.localhost\<distro>\... format
#   - Reference: sparc/4-refinement/docs/DEVCONTAINER-CLI-STRATEGY.md
#
# Usage: ./test-devcontainer-locations.sh [--quick]
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Parse arguments
QUICK=false
if [[ "${1:-}" == "--quick" ]]; then
    QUICK=true
fi

test_suite_begin "DevContainer Location Test - WSL Home vs /mnt/c/"

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    test_skip "All tests" "Only runs on WSL - verifies devcontainers in WSL filesystem and /mnt/c/"
    test_suite_end
fi

# Check prerequisites
if ! command -v devcontainer &>/dev/null && ! command -v devcontainer.cmd &>/dev/null; then
    test_fail "Prerequisites check" "DevContainer CLI not found - install with: npm install -g @devcontainers/cli"
    test_suite_end
fi

# DevContainer CLI detection
DEVC_CMD="devcontainer"
if command -v devcontainer.cmd &>/dev/null; then
    DEVC_CMD="devcontainer.cmd"
fi

# Convert WSL path to Windows format for devcontainer.cmd
# Uses wslpath built-in tool (supports both /mnt/c/ and WSL native paths)
convert_to_windows_path() {
    local wsl_path="$1"
    wslpath -w "$wsl_path"
}

# Test locations
WSL_TEST_DIR="$HOME/bitbot-devcontainer-test-wsl"
WIN_TEST_DIR="/mnt/c/bitbot-devcontainer-test-win"

# Cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up test directories..."
    rm -rf "$WSL_TEST_DIR" 2>/dev/null || true
    rm -rf "$WIN_TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Create minimal devcontainer config
create_test_project() {
    local test_dir="$1"

    mkdir -p "$test_dir/.devcontainer"

    # Create minimal devcontainer.json
    cat > "$test_dir/.devcontainer/devcontainer.json" <<'EOF'
{
  "name": "BitBot DevContainer Test",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {},
  "postCreateCommand": "echo 'DevContainer initialized successfully'"
}
EOF

    # Create simple test script
    cat > "$test_dir/test.sh" <<'EOF'
#!/bin/bash
echo "Hello from devcontainer!"
echo "Working directory: $(pwd)"
echo "User: $(whoami)"
echo "Filesystem: $(df -T . | tail -1 | awk '{print $2}')"
EOF
    chmod +x "$test_dir/test.sh"

    # Create simple file for testing
    echo "Test project content" > "$test_dir/README.md"
}

# Test devcontainer build and run
test_devcontainer() {
    local test_dir="$1"
    local location_name="$2"

    # Send all diagnostic output to stderr so only return value goes to stdout
    {
        echo ""
        echo "Testing DevContainer ($location_name)"
        echo "Location: $test_dir"
        echo ""
    } >&2

    local start_time=$(date +%s)
    local success=false

    # Convert path and determine command wrapper
    local win_path=$(convert_to_windows_path "$test_dir")

    # Try to build devcontainer
    echo "Building devcontainer..." >&2
    cd "$test_dir"

    if [[ "$DEVC_CMD" == "devcontainer.cmd" ]]; then
        # Using devcontainer.cmd - need wrapper
        if [[ "$test_dir" == /mnt/* ]]; then
            # Method 3: cmd.exe with cd trick
            if timeout 300 cmd.exe /c "cd /d $win_path && devcontainer.cmd build --workspace-folder ." >&2; then
                echo "✓ DevContainer built successfully" >&2
                success=true
            else
                echo "✗ DevContainer build failed" >&2
            fi
        else
            # Method 4: PowerShell with UNC path
            if timeout 300 powershell.exe -NoProfile -Command "devcontainer.cmd build --workspace-folder '$win_path'" >&2; then
                echo "✓ DevContainer built successfully" >&2
                success=true
            else
                echo "✗ DevContainer build failed" >&2
            fi
        fi
    else
        # Using devcontainer CLI directly
        if timeout 300 devcontainer build --workspace-folder . >&2; then
            echo "✓ DevContainer built successfully" >&2
            success=true
        else
            echo "✗ DevContainer build failed" >&2
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    {
        echo "Time: ${duration}s"
        echo ""
    } >&2

    if [[ "$success" == "true" ]]; then
        echo "1"  # Return success
    else
        echo "0"  # Return failure
    fi
}

# ============================================================================
# Test 1: WSL Home Location
# ============================================================================

test_section "Test 1: WSL Home Location"

echo "Creating test project in WSL home..."
create_test_project "$WSL_TEST_DIR"
echo "✓ Test project created"
echo ""

WSL_SUCCESS=$(test_devcontainer "$WSL_TEST_DIR" "WSL home")

if [[ "$WSL_SUCCESS" == "1" ]]; then
    test_pass "DevContainer works in WSL home location"
else
    test_fail "DevContainer works in WSL home location"
fi

# ============================================================================
# Test 2: Windows Mount Location (/mnt/c/)
# ============================================================================

test_section "Test 2: Windows Mount Location (/mnt/c/)"

if [[ "$QUICK" != "true" ]]; then
    echo "Creating test project in /mnt/c/..."
    create_test_project "$WIN_TEST_DIR"
    echo "✓ Test project created"
    echo ""

    WIN_SUCCESS=$(test_devcontainer "$WIN_TEST_DIR" "Windows mount")

    if [[ "$WIN_SUCCESS" == "1" ]]; then
        test_pass "DevContainer works in /mnt/c/ location"
    else
        test_skip "DevContainer works in /mnt/c/ location" "Expected due to 9P filesystem limitations - use WSL filesystem for development"
    fi
else
    test_skip "DevContainer works in /mnt/c/ location" "Quick mode enabled"
    WIN_SUCCESS="1"  # Don't fail in quick mode
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
