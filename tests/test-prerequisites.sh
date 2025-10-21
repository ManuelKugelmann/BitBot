#!/usr/bin/env bash
#
# Test: Prerequisites Checking
# Tests bitbot's prerequisite validation system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_WORKSPACE="$SCRIPT_DIR/test-workspace"

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
    ((pass_count++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((fail_count++))
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

echo ""
echo "=== BitBot Prerequisite Tests ==="
echo ""

# ============================================================================
# Test 1: Check if bash exists
# ============================================================================

echo "[Test 1] Check bash availability..."
if command -v bash &>/dev/null; then
    test_pass "bash is available"
else
    test_fail "bash not found"
fi

# ============================================================================
# Test 2: Check if docker exists
# ============================================================================

echo ""
echo "[Test 2] Check Docker availability..."
if command -v docker &>/dev/null; then
    test_pass "docker command is available"

    # Check if Docker is running
    if docker ps &>/dev/null 2>&1; then
        test_pass "Docker daemon is running"
    else
        test_fail "Docker daemon is not running (this is OK if testing auto-start)"
    fi
else
    test_fail "docker command not found"
fi

# ============================================================================
# Test 3: Check devcontainer CLI
# ============================================================================

echo ""
echo "[Test 3] Check DevContainer CLI..."

# Platform detection
platform=""
if grep -qi microsoft /proc/version 2>/dev/null; then
    platform="wsl"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    platform="macos"
else
    platform="linux"
fi

test_info "Detected platform: $platform"

# Check for devcontainer.cmd on WSL
if [[ "$platform" == "wsl" ]]; then
    if command -v devcontainer.cmd &>/dev/null; then
        test_pass "devcontainer.cmd found (VS Code built-in)"
    elif command -v devcontainer &>/dev/null; then
        test_pass "devcontainer CLI found (standalone)"
    else
        test_fail "No devcontainer CLI found"
    fi
else
    if command -v devcontainer &>/dev/null; then
        test_pass "devcontainer CLI found"
    else
        test_fail "devcontainer CLI not found"
    fi
fi

# ============================================================================
# Test 4: Check git
# ============================================================================

echo ""
echo "[Test 4] Check git availability..."
if command -v git &>/dev/null; then
    test_pass "git is available"
    git_version=$(git --version)
    test_info "Git version: $git_version"
else
    test_fail "git not found"
fi

# ============================================================================
# Test 5: Check VS Code (optional)
# ============================================================================

echo ""
echo "[Test 5] Check VS Code (optional)..."
if command -v code &>/dev/null; then
    test_pass "VS Code is available"
else
    test_info "VS Code not found (optional, only needed for VS Code mode)"
fi

# ============================================================================
# Test 6: Check Node.js (for standalone CLI)
# ============================================================================

echo ""
echo "[Test 6] Check Node.js (optional)..."
if command -v node &>/dev/null; then
    test_pass "Node.js is available"
    node_version=$(node --version)
    test_info "Node.js version: $node_version"
else
    test_info "Node.js not found (optional, only needed for standalone CLI install)"
fi

# ============================================================================
# Test 7: Check npm (for standalone CLI)
# ============================================================================

echo ""
echo "[Test 7] Check npm (optional)..."
if command -v npm &>/dev/null; then
    test_pass "npm is available"
    npm_version=$(npm --version)
    test_info "npm version: $npm_version"
else
    test_info "npm not found (optional, only needed for standalone CLI install)"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== Test Summary ==="
echo -e "  Passed: ${GREEN}${pass_count}${NC}"
echo -e "  Failed: ${RED}${fail_count}${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All required prerequisites available!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some prerequisites missing. BitBot may prompt for installation.${NC}"
    exit 1
fi
