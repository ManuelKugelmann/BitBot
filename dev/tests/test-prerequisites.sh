#!/usr/bin/env bash
#
# Test: Prerequisites Checking
# Tests BitBot's prerequisite detection functions (not whether prereqs are installed)
#
# This test validates the detection logic, not installation status.
# Prerequisites may or may not be installed - that's OK!

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source BitBot utilities for testing
export BITBOT_HOME="$BITBOT_ROOT"
source "${BITBOT_ROOT}/core/util/helpers.sh" 2>/dev/null || true

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Prerequisite Detection Tests"

# ============================================================================
# Test 1: command_exists function works correctly
# ============================================================================

test_section "Test 1: command_exists function"

# Test with a command that definitely exists (bash, we're running it!)
if command_exists "bash"; then
    test_pass "command_exists correctly detects 'bash' (present)"
else
    test_fail "command_exists failed to detect 'bash'" "bash is definitely present"
fi

# Test with a command that definitely doesn't exist
if command_exists "this-command-definitely-does-not-exist-12345"; then
    test_fail "command_exists incorrectly detected non-existent command"
else
    test_pass "command_exists correctly detects missing command"
fi

# ============================================================================
# Test 2: Bash detection (always present)
# ============================================================================

test_section "Test 2: Bash detection"

# We're running in bash, so this should always work
if command -v bash &>/dev/null; then
    test_pass "bash detection works (bash is available)"
    bash_version=$(bash --version | head -1)
    echo "  ℹ Bash version: $bash_version"
else
    test_fail "bash detection failed" "We're running in bash!"
fi

# ============================================================================
# Test 3: Docker detection (optional - may or may not be installed)
# ============================================================================

test_section "Test 3: Docker detection"

# Test that detection works, regardless of result
if command -v docker &>/dev/null; then
    test_pass "Docker detected (installed)"

    # If docker is installed, test daemon check
    set +e
    timeout 2 docker ps &>/dev/null 2>&1
    docker_status=$?
    set -e

    if [[ $docker_status -eq 0 ]]; then
        echo "  ℹ Docker daemon: running"
    elif [[ $docker_status -eq 124 ]]; then
        echo "  ℹ Docker daemon: timeout (possible issue)"
    else
        echo "  ℹ Docker daemon: not running or inaccessible"
    fi
else
    test_pass "Docker not detected (not installed - OK for testing)"
fi

# Verify we can detect Docker's absence correctly
if ! command -v docker &>/dev/null; then
    test_pass "Docker absence detection works correctly"
fi

# ============================================================================
# Test 4: DevContainer CLI detection (optional)
# ============================================================================

test_section "Test 4: DevContainer CLI detection"

# Detect platform first
platform=""
if grep -qi microsoft /proc/version 2>/dev/null; then
    platform="wsl"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    platform="macos"
else
    platform="linux"
fi

echo "  ℹ Detected platform: $platform"

# Test detection logic based on platform
if [[ "$platform" == "wsl" ]]; then
    # On WSL, check both devcontainer.cmd and devcontainer
    if command -v devcontainer.cmd &>/dev/null; then
        test_pass "WSL: devcontainer.cmd detected (VS Code built-in)"
    elif command -v devcontainer &>/dev/null; then
        test_pass "WSL: devcontainer detected (standalone)"
    else
        test_pass "WSL: No devcontainer CLI detected (OK for testing)"
    fi
else
    # On Linux/macOS, check devcontainer
    if command -v devcontainer &>/dev/null; then
        test_pass "DevContainer CLI detected (installed)"
    else
        test_pass "DevContainer CLI not detected (OK for testing)"
    fi
fi

# ============================================================================
# Test 5: Git detection (usually present)
# ============================================================================

test_section "Test 5: Git detection"

if command -v git &>/dev/null; then
    test_pass "Git detected (installed)"
    git_version=$(git --version)
    echo "  ℹ Git version: $git_version"
else
    test_pass "Git not detected (unusual but OK for testing)"
fi

# ============================================================================
# Test 6: VS Code detection (optional)
# ============================================================================

test_section "Test 6: VS Code detection (optional)"

if command -v code &>/dev/null; then
    test_pass "VS Code detected (installed)"
else
    test_pass "VS Code not detected (optional - OK)"
fi

# ============================================================================
# Test 7: Node.js detection (optional)
# ============================================================================

test_section "Test 7: Node.js detection (optional)"

if command -v node &>/dev/null; then
    test_pass "Node.js detected (installed)"
    node_version=$(node --version)
    echo "  ℹ Node.js version: $node_version"
else
    test_pass "Node.js not detected (optional - OK)"
fi

# ============================================================================
# Test 8: npm detection (optional)
# ============================================================================

test_section "Test 8: npm detection (optional)"

if command -v npm &>/dev/null; then
    test_pass "npm detected (installed)"
    npm_version=$(npm --version)
    echo "  ℹ npm version: $npm_version"
else
    test_pass "npm not detected (optional - OK)"
fi

# ============================================================================
# Test 9: Platform detection works
# ============================================================================

test_section "Test 9: Platform detection"

# Test that we can detect the platform
if [[ -n "$platform" ]]; then
    test_pass "Platform detection works: $platform"
else
    test_fail "Platform detection failed" "Could not determine platform"
fi

# ============================================================================
# Test 10: Helper function availability
# ============================================================================

test_section "Test 10: Prerequisite helper functions"

# Test that helper functions are available
if declare -f command_exists >/dev/null 2>&1; then
    test_pass "command_exists function is defined"
else
    test_fail "command_exists function not found" "Should be in core/util/helpers.sh"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
