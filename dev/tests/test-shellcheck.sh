#!/usr/bin/env bash
#
# Test: ShellCheck Static Analysis
# Runs shellcheck on all bash scripts in the project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0
warning_count=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    pass_count=$((pass_count + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    fail_count=$((fail_count + 1))
}

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    warning_count=$((warning_count + 1))
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

echo ""
echo "=== BitBot ShellCheck Static Analysis ==="
echo ""

# ============================================================================
# Test 1: Check if shellcheck is available
# ============================================================================

echo "[Test 1] Check shellcheck availability..."
if command -v shellcheck &>/dev/null; then
    test_pass "shellcheck is available"
    shellcheck_version=$(shellcheck --version | grep '^version:' | awk '{print $2}')
    test_info "ShellCheck version: $shellcheck_version"
else
    test_fail "shellcheck not found - install with: apt-get install shellcheck"
    exit 1
fi

# ============================================================================
# Test 2: Analyze main bitbot script
# ============================================================================

echo ""
echo "[Test 2] Analyzing main bitbot script..."

if [[ -f "$BITBOT_ROOT/bitbot" ]]; then
    if shellcheck -x "$BITBOT_ROOT/bitbot" 2>&1 | tee /tmp/shellcheck-bitbot.log; then
        test_pass "bitbot script: no issues"
    else
        test_fail "bitbot script: has issues (see above)"
        test_info "Detailed output saved to /tmp/shellcheck-bitbot.log"
    fi
else
    test_fail "bitbot script not found"
fi

# ============================================================================
# Test 3: Analyze core/ scripts
# ============================================================================

echo ""
echo "[Test 3] Analyzing core/ scripts..."

core_scripts_count=0
core_scripts_pass=0
core_scripts_fail=0

if [[ -d "$BITBOT_ROOT/core" ]]; then
    while IFS= read -r -d '' script; do
        script_name=$(basename "$script")
        core_scripts_count=$((core_scripts_count + 1))

        echo ""
        echo "  Checking: $script_name"

        # Run shellcheck with sourcing support
        if shellcheck -x "$script" 2>&1 | tee "/tmp/shellcheck-${script_name}.log"; then
            echo -e "    ${GREEN}✓${NC} $script_name: no issues"
            core_scripts_pass=$((core_scripts_pass + 1))
        else
            echo -e "    ${RED}✗${NC} $script_name: has issues"
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
# Test 4: Analyze container-bitbot/ scripts
# ============================================================================

echo ""
echo "[Test 4] Analyzing container-bitbot/ scripts..."

container_scripts_count=0
container_scripts_pass=0
container_scripts_fail=0

if [[ -d "$BITBOT_ROOT/container-bitbot" ]]; then
    # Check main container script
    if [[ -f "$BITBOT_ROOT/container-bitbot/bitbot" ]]; then
        container_scripts_count=$((container_scripts_count + 1))
        echo ""
        echo "  Checking: bitbot (container)"

        if shellcheck -x "$BITBOT_ROOT/container-bitbot/bitbot" 2>&1 | tee "/tmp/shellcheck-container-bitbot.log"; then
            echo -e "    ${GREEN}✓${NC} container bitbot: no issues"
            container_scripts_pass=$((container_scripts_pass + 1))
        else
            echo -e "    ${RED}✗${NC} container bitbot: has issues"
            container_scripts_fail=$((container_scripts_fail + 1))
        fi
    fi

    # Check other scripts
    while IFS= read -r -d '' script; do
        script_name=$(basename "$script")
        container_scripts_count=$((container_scripts_count + 1))

        echo ""
        echo "  Checking: $script_name"

        if shellcheck -x "$script" 2>&1 | tee "/tmp/shellcheck-container-${script_name}.log"; then
            echo -e "    ${GREEN}✓${NC} $script_name: no issues"
            container_scripts_pass=$((container_scripts_pass + 1))
        else
            echo -e "    ${RED}✗${NC} $script_name: has issues"
            container_scripts_fail=$((container_scripts_fail + 1))
        fi
    done < <(find "$BITBOT_ROOT/container-bitbot/core" -name "*.sh" -type f -print0 2>/dev/null || true)

    echo ""
    if [[ $container_scripts_fail -eq 0 ]]; then
        test_pass "All $container_scripts_count container scripts passed"
    else
        test_fail "$container_scripts_fail/$container_scripts_count container scripts have issues"
    fi
else
    test_warning "container-bitbot/ directory not found"
fi

# ============================================================================
# Test 5: Check for syntax errors only (quick check)
# ============================================================================

echo ""
echo "[Test 5] Quick syntax check (bash -n)..."

syntax_errors=0

# Check main script
if ! bash -n "$BITBOT_ROOT/bitbot" 2>/dev/null; then
    test_fail "bitbot: syntax error"
    syntax_errors=$((syntax_errors + 1))
fi

# Check all .sh files
while IFS= read -r -d '' script; do
    if ! bash -n "$script" 2>/dev/null; then
        test_fail "$(basename "$script"): syntax error"
        syntax_errors=$((syntax_errors + 1))
    fi
done < <(find "$BITBOT_ROOT/core" "$BITBOT_ROOT/container-bitbot" -name "*.sh" -type f -print0 2>/dev/null || true)

if [[ $syntax_errors -eq 0 ]]; then
    test_pass "All scripts have valid bash syntax"
else
    test_fail "$syntax_errors scripts have syntax errors"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== ShellCheck Summary ==="
echo ""
echo "Scripts analyzed:"
echo "  Main script: 1"
echo "  Core scripts: $core_scripts_count"
echo "  Container scripts: $container_scripts_count"
echo ""
echo "Results:"
echo -e "  Passed: ${GREEN}${pass_count}${NC}"
echo -e "  Failed: ${RED}${fail_count}${NC}"
echo -e "  Warnings: ${YELLOW}${warning_count}${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All shellcheck tests passed!${NC}"
    echo ""
    test_info "Note: Some warnings may be acceptable. Review logs in /tmp/shellcheck-*.log"
    exit 0
else
    echo -e "${RED}✗ Some shellcheck tests failed${NC}"
    echo ""
    echo "Review the issues above and fix them."
    echo "Detailed logs saved to /tmp/shellcheck-*.log"
    exit 1
fi
