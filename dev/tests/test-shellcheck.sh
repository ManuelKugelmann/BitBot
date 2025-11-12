#!/usr/bin/env bash
#
# Test: ShellCheck Static Analysis
# Runs shellcheck on all bash scripts in the project
#
# MIGRATED TO USE: test-framework.sh helper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot ShellCheck Static Analysis"

# ============================================================================
# Test 1: Check if shellcheck is available
# ============================================================================

test_section "Test 1: Check shellcheck availability"
if command -v shellcheck &>/dev/null; then
    test_pass "shellcheck is available"
    shellcheck_version=$(shellcheck --version | grep '^version:' | awk '{print $2}')
    echo "  ℹ ShellCheck version: $shellcheck_version"
else
    test_fail "shellcheck not found - install with: apt-get install shellcheck"
    exit 1
fi

# ============================================================================
# Test 2: Analyze main bitbot script
# ============================================================================

test_section "Test 2: Analyzing main bitbot script"

if [[ -f "$BITBOT_ROOT/core/bitbot" ]]; then
    if shellcheck -x -e SC1091 "$BITBOT_ROOT/core/bitbot" 2>&1 | tee /tmp/shellcheck-bitbot.log; then
        test_pass "bitbot script: no issues"
    else
        test_fail "bitbot script: has issues (see above)"
        echo "  ℹ Detailed output saved to /tmp/shellcheck-bitbot.log"
    fi
else
    test_fail "bitbot script not found"
fi

# ============================================================================
# Test 3: Analyze core/ scripts
# ============================================================================

test_section "Test 3: Analyzing core/ scripts"

core_scripts_count=0
core_scripts_pass=0
core_scripts_fail=0

if [[ -d "$BITBOT_ROOT/core" ]]; then
    while IFS= read -r -d '' script; do
        script_name=$(basename "$script")
        core_scripts_count=$((core_scripts_count + 1))

        echo ""
        echo "  Checking: $script_name"

        # Run shellcheck with sourcing support, exclude SC1091 (source following)
        if shellcheck -x -e SC1091 "$script" 2>&1 | tee "/tmp/shellcheck-${script_name}.log"; then
            echo -e "    ✓ $script_name: no issues"
            core_scripts_pass=$((core_scripts_pass + 1))
        else
            echo -e "    ✗ $script_name: has issues"
            core_scripts_fail=$((core_scripts_fail + 1))
        fi
    done < <(find "$BITBOT_ROOT/core" -name "*.sh" -type f -print0)
else
    test_fail "core/ directory not found"
fi

echo ""
if [[ $core_scripts_fail -eq 0 ]]; then
    test_pass "All $core_scripts_count core scripts passed"
else
    test_fail "$core_scripts_fail/$core_scripts_count core scripts have issues"
fi

# ============================================================================
# Test 4: Analyze container/bitbot/ scripts
# ============================================================================

test_section "Test 4: Analyzing container/bitbot/ scripts"

container_scripts_count=0
container_scripts_pass=0
container_scripts_fail=0

if [[ -d "$BITBOT_ROOT/container/bitbot" ]]; then
    # Check main container script
    if [[ -f "$BITBOT_ROOT/container/bitbot/bitbot" ]]; then
        container_scripts_count=$((container_scripts_count + 1))
        echo ""
        echo "  Checking: bitbot (container)"

        if shellcheck -x -e SC1091 "$BITBOT_ROOT/container/bitbot/bitbot" 2>&1 | tee "/tmp/shellcheck-container-bitbot.log"; then
            echo -e "    ✓ container bitbot: no issues"
            container_scripts_pass=$((container_scripts_pass + 1))
        else
            echo -e "    ✗ container bitbot: has issues"
            container_scripts_fail=$((container_scripts_fail + 1))
        fi
    fi

    # Check other scripts
    while IFS= read -r -d '' script; do
        script_name=$(basename "$script")
        container_scripts_count=$((container_scripts_count + 1))

        echo ""
        echo "  Checking: $script_name"

        if shellcheck -x -e SC1091 "$script" 2>&1 | tee "/tmp/shellcheck-container-${script_name}.log"; then
            echo -e "    ✓ $script_name: no issues"
            container_scripts_pass=$((container_scripts_pass + 1))
        else
            echo -e "    ✗ $script_name: has issues"
            container_scripts_fail=$((container_scripts_fail + 1))
        fi
    done < <(find "$BITBOT_ROOT/container/bitbot" -name "*.sh" -type f -print0 2>/dev/null || true)

    echo ""
    if [[ $container_scripts_fail -eq 0 ]]; then
        test_pass "All $container_scripts_count container scripts passed"
    else
        test_fail "$container_scripts_fail/$container_scripts_count container scripts have issues"
    fi
else
    test_skip "container/bitbot/ analysis" "container/bitbot/ directory not found"
fi

# ============================================================================
# Test 5: Check for syntax errors only (quick check)
# ============================================================================

test_section "Test 5: Quick syntax check (bash -n)"

syntax_errors=0

# Check main script
if ! bash -n "$BITBOT_ROOT/core/bitbot" 2>/dev/null; then
    test_fail "core/bitbot: syntax error"
    syntax_errors=$((syntax_errors + 1))
fi

# Check all .sh files
while IFS= read -r -d '' script; do
    if ! bash -n "$script" 2>/dev/null; then
        test_fail "$(basename "$script"): syntax error"
        syntax_errors=$((syntax_errors + 1))
    fi
done < <(find "$BITBOT_ROOT/core" "$BITBOT_ROOT/container/bitbot" -name "*.sh" -type f -print0 2>/dev/null || true)

if [[ $syntax_errors -eq 0 ]]; then
    test_pass "All scripts have valid bash syntax"
else
    test_fail "$syntax_errors scripts have syntax errors"
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

echo ""
echo "Scripts analyzed:"
echo "  Main script: 1"
echo "  Core scripts: $core_scripts_count"
echo "  Container scripts: $container_scripts_count"
echo ""
echo "  ℹ Note: Some warnings may be acceptable. Review logs in /tmp/shellcheck-*.log"
echo ""

test_suite_end
