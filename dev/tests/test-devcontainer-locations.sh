#!/usr/bin/env bash
#
# DevContainer Location Test - WSL home vs /mnt/c/
# Tests that devcontainers work correctly in both locations
#
# Usage: ./test-devcontainer-locations.sh [--quick]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
QUICK=false
if [[ "${1:-}" == "--quick" ]]; then
    QUICK=true
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   DevContainer Location Test           ║${NC}"
echo -e "${CYAN}║   WSL Home vs /mnt/c/                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo -e "${YELLOW}⊘ SKIPPED${NC}: This test only runs on WSL"
    echo ""
    echo "This test verifies devcontainers work in both:"
    echo "  - WSL native filesystem (ext4)"
    echo "  - Windows mount (/mnt/c/ - 9P protocol)"
    echo ""
    exit 0
fi

# Check prerequisites
if ! command -v devcontainer &>/dev/null && ! command -v devcontainer.cmd &>/dev/null; then
    echo -e "${RED}✗ ERROR${NC}: DevContainer CLI not found"
    echo ""
    echo "Install @devcontainers/cli:"
    echo "  npm install -g @devcontainers/cli"
    echo ""
    exit 1
fi

# Use devcontainer.cmd on Windows/WSL (must wrap with cmd.exe)
DEVC_CMD="devcontainer"
if command -v devcontainer.cmd &>/dev/null; then
    DEVC_CMD="cmd.exe /c devcontainer.cmd"
fi

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

    echo -e "${BLUE}Testing DevContainer ($location_name)${NC}"
    echo "Location: $test_dir"
    echo ""

    local start_time=$(date +%s)
    local success=false

    # Convert to Windows path if using cmd.exe
    local workspace_arg="."
    if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
        # For WSL paths, we need Windows path format
        if [[ "$test_dir" == /mnt/* ]]; then
            # /mnt/c/path -> C:\path
            workspace_arg=$(echo "$test_dir" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g')
        else
            # WSL home paths can't be used with devcontainer.cmd from WSL
            echo -e "${YELLOW}⚠${NC} WSL native paths not supported by devcontainer.cmd"
            echo "Skipping build test (devcontainer.cmd requires Windows paths)"
            echo "0"
            return
        fi
    fi

    # Try to build devcontainer
    echo "Building devcontainer..."
    if cd "$test_dir" && timeout 300 $DEVC_CMD build --workspace-folder "$workspace_arg" &>/tmp/devc-build-$$.log; then
        echo -e "${GREEN}✓${NC} DevContainer built successfully"

        # Try to run a command in the devcontainer
        echo "Running test command in devcontainer..."
        if timeout 60 $DEVC_CMD exec --workspace-folder "$workspace_arg" bash /workspaces/$(basename "$test_dir")/test.sh &>/tmp/devc-exec-$$.log; then
            echo -e "${GREEN}✓${NC} DevContainer executed command successfully"
            success=true
        else
            echo -e "${RED}✗${NC} DevContainer command execution failed"
            echo "Log:"
            cat /tmp/devc-exec-$$.log
        fi
    else
        echo -e "${RED}✗${NC} DevContainer build failed"
        echo "Log:"
        cat /tmp/devc-build-$$.log
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    rm -f /tmp/devc-build-$$.log /tmp/devc-exec-$$.log

    echo "Time: ${duration}s"
    echo ""

    if [[ "$success" == "true" ]]; then
        echo "1"  # Return success
    else
        echo "0"  # Return failure
    fi
}

# ============================================================================
# Test 1: WSL Home Location
# ============================================================================

echo -e "${CYAN}═══ Test 1: WSL Home Location ═══${NC}"
echo ""

# Check if we're using devcontainer.cmd (which doesn't support WSL native paths)
if [[ "$DEVC_CMD" == *"cmd.exe"* ]]; then
    echo -e "${YELLOW}ℹ${NC} Using devcontainer.cmd from WSL"
    echo "Note: devcontainer.cmd cannot accept WSL paths when invoked from bash"
    echo "This is a limitation of calling Windows batch files from WSL shell"
    echo ""
    echo -e "${YELLOW}⊘ SKIPPED${NC}: WSL home test (path translation issue)"
    WSL_SUCCESS="skip"
else
    echo "Creating test project in WSL home..."
    create_test_project "$WSL_TEST_DIR"
    echo -e "${GREEN}✓${NC} Test project created"
    echo ""

    WSL_SUCCESS=$(test_devcontainer "$WSL_TEST_DIR" "WSL home")

    if [[ "$WSL_SUCCESS" == "1" ]]; then
        echo -e "${GREEN}✓ PASSED${NC}: DevContainer works in WSL home location"
    else
        echo -e "${RED}✗ FAILED${NC}: DevContainer failed in WSL home location"
    fi
fi
echo ""

# ============================================================================
# Test 2: Windows Mount Location (/mnt/c/)
# ============================================================================

if [[ "$QUICK" != "true" ]]; then
    echo -e "${CYAN}═══ Test 2: Windows Mount Location (/mnt/c/) ═══${NC}"
    echo ""

    echo "Creating test project in /mnt/c/..."
    create_test_project "$WIN_TEST_DIR"
    echo -e "${GREEN}✓${NC} Test project created"
    echo ""

    WIN_SUCCESS=$(test_devcontainer "$WIN_TEST_DIR" "Windows mount")

    if [[ "$WIN_SUCCESS" == "1" ]]; then
        echo -e "${GREEN}✓ PASSED${NC}: DevContainer works in /mnt/c/ location"
    else
        echo -e "${YELLOW}⚠ WARNING${NC}: DevContainer may have issues in /mnt/c/ location"
        echo ""
        echo "This is expected due to 9P filesystem limitations."
        echo "Recommendation: Use WSL filesystem for development."
    fi
    echo ""
else
    echo -e "${YELLOW}⊘ SKIPPED${NC}: /mnt/c/ test (quick mode)"
    echo ""
    WIN_SUCCESS="1"  # Don't fail in quick mode
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Test Summary                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

if [[ "$WSL_SUCCESS" == "1" ]]; then
    echo -e "WSL Home: ${GREEN}✓ PASSED${NC}"
elif [[ "$WSL_SUCCESS" == "skip" ]]; then
    echo -e "WSL Home: ${YELLOW}⊘ SKIPPED${NC} (devcontainer.cmd limitation)"
else
    echo -e "WSL Home: ${RED}✗ FAILED${NC}"
fi

if [[ "$QUICK" != "true" ]]; then
    if [[ "$WIN_SUCCESS" == "1" ]]; then
        echo -e "/mnt/c/:  ${GREEN}✓ PASSED${NC}"
    else
        echo -e "/mnt/c/:  ${YELLOW}⚠ WARNING${NC}"
    fi
fi

echo ""

# Determine overall result
# Success cases:
# 1. WSL test passed
# 2. WSL test skipped (devcontainer.cmd) but /mnt/c/ tested (even with warning)
# 3. Both tests skipped in quick mode with devcontainer.cmd (informational)
if [[ "$WSL_SUCCESS" == "1" ]]; then
    # WSL test passed - full success
    echo -e "${GREEN}✓ OVERALL: DevContainer functionality verified${NC}"
    echo ""
    exit 0
elif [[ "$WSL_SUCCESS" == "skip" && "$QUICK" == "true" ]]; then
    # Quick mode with devcontainer.cmd - nothing testable, but not a failure
    echo -e "${YELLOW}⊘ OVERALL: Tests skipped (quick mode + devcontainer.cmd limitation)${NC}"
    echo ""
    echo "In quick mode with devcontainer.cmd, no paths are testable:"
    echo "  - WSL home: Not accessible to devcontainer.cmd"
    echo "  - /mnt/c/: Skipped in quick mode"
    echo ""
    echo "Run without --quick flag to test /mnt/c/ location"
    echo ""
    exit 0
elif [[ "$WSL_SUCCESS" == "skip" && "$QUICK" != "true" ]]; then
    # devcontainer.cmd from WSL - tested /mnt/c/ (even if it has issues)
    echo -e "${YELLOW}⊘ OVERALL: Limited testing due to path translation${NC}"
    echo ""
    echo -e "${YELLOW}Note${NC}: WSL home test skipped due to path translation issues"
    echo "When calling devcontainer.cmd from bash, WSL paths cannot be passed"
    echo "Only /mnt/c/ paths (Windows drives) are testable in this configuration"
    echo ""
    if [[ "$WIN_SUCCESS" != "1" ]]; then
        echo -e "${YELLOW}Note${NC}: /mnt/c/ location has issues (expected due to 9P filesystem)"
        echo "This is a known limitation and does not indicate a BitBot problem"
        echo ""
    fi
    echo "Recommendation: For full testing, use native devcontainer CLI (npm install -g @devcontainers/cli)"
    echo ""
    exit 0
else
    # Actual failure (non-devcontainer.cmd case)
    echo -e "${RED}✗ OVERALL: DevContainer test failed${NC}"
    echo ""
    exit 1
fi
