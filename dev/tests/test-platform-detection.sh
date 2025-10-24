#!/usr/bin/env bash
#
# Test: Platform Detection
# Tests bitbot's platform detection logic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the prerequisites file to get detect_platform function
export BITBOT_HOME="$BITBOT_ROOT"
source "${BITBOT_ROOT}/core/util/prerequisites.sh"

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

echo ""
echo "=== BitBot Platform Detection Tests ==="
echo ""

# ============================================================================
# Test 1: detect_platform returns valid platform
# ============================================================================

echo "[Test 1] Platform detection returns valid value..."
platform=$(detect_platform)
if [[ "$platform" == "wsl" ]] || [[ "$platform" == "macos" ]] || [[ "$platform" == "linux" ]]; then
    test_pass "Platform detected as: $platform"
else
    test_fail "Invalid platform: $platform"
fi

# ============================================================================
# Test 2: Platform detection is consistent
# ============================================================================

echo "[Test 2] Platform detection is consistent..."
platform1=$(detect_platform)
platform2=$(detect_platform)
if [[ "$platform1" == "$platform2" ]]; then
    test_pass "Platform detection is consistent"
else
    test_fail "Platform detection inconsistent: $platform1 vs $platform2"
fi

# ============================================================================
# Test 3: Detected platform matches /proc/version for WSL
# ============================================================================

echo "[Test 3] WSL detection matches /proc/version..."
if grep -qi microsoft /proc/version 2>/dev/null; then
    # We're on WSL
    if [[ "$platform" == "wsl" ]]; then
        test_pass "WSL correctly detected from /proc/version"
    else
        test_fail "On WSL but detected as: $platform"
    fi
else
    # Not on WSL
    if [[ "$platform" != "wsl" ]]; then
        test_pass "Non-WSL platform correctly detected"
    else
        test_fail "Not on WSL but detected as wsl"
    fi
fi

# ============================================================================
# Test 4: Detected platform matches OSTYPE for macOS
# ============================================================================

echo "[Test 4] macOS detection matches OSTYPE..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # We're on macOS
    if [[ "$platform" == "macos" ]]; then
        test_pass "macOS correctly detected from OSTYPE"
    else
        test_fail "On macOS but detected as: $platform"
    fi
else
    # Not on macOS
    if [[ "$platform" != "macos" ]]; then
        test_pass "Non-macOS platform correctly detected"
    else
        test_fail "Not on macOS but detected as macos"
    fi
fi

# ============================================================================
# Test 5: Platform appears in bitbot version output
# ============================================================================

echo "[Test 5] Platform appears in version output..."
version_output=$(bash "$BITBOT_ROOT/bitbot" version 2>&1)
if echo "$version_output" | grep -q "Platform: $platform"; then
    test_pass "Platform shown in version output"
else
    test_fail "Platform not shown in version output"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
