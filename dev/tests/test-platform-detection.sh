#!/usr/bin/env bash
#
# Test: Platform Detection
# Tests bitbot's platform detection logic
#
# MIGRATED TO USE: test-framework.sh helper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source the prerequisites file to get detect_platform function
export BITBOT_HOME="$BITBOT_ROOT"
source "${BITBOT_ROOT}/core/util/prerequisites.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Platform Detection Tests"

# ============================================================================
# Test 1: detect_platform returns valid platform
# ============================================================================

test_section "Test 1: Platform detection returns valid value"
platform=$(detect_platform)
if [[ "$platform" == "wsl" ]] || [[ "$platform" == "macos" ]] || [[ "$platform" == "linux" ]]; then
    test_pass "Platform detected as: $platform"
else
    test_fail "Invalid platform: $platform"
fi

# ============================================================================
# Test 2: Platform detection is consistent
# ============================================================================

test_section "Test 2: Platform detection is consistent"
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

test_section "Test 3: WSL detection matches /proc/version"
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

test_section "Test 4: macOS detection matches OSTYPE"
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

test_section "Test 5: Platform appears in version output"
version_output=$(bash "$BITBOT_ROOT/core/bitbot" version 2>&1)
if echo "$version_output" | grep -q "Platform: $platform"; then
    test_pass "Platform shown in version output"
else
    test_fail "Platform not shown in version output"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
