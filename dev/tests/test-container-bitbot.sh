#!/usr/bin/env bash
#
# Container BitBot Test Suite
# Tests container-side BitBot scripts
#
# Container BitBot Mount Configuration:
# - Base template (container/templates/shared/base.devcontainer.json) includes:
#     "mounts": ["source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly"]
# - During 'bitbot init', container/bitbot/ is copied to user's .devcontainer/bitbot/
# - Mount makes scripts available at /usr/local/bitbot in all containers
# - See sparc/1-specification/01_CONTAINER_ORCHESTRATION_STRATEGY.md for details
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONTAINER_BITBOT_ROOT="${BITBOT_ROOT}/container/bitbot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
total_tests=0
passed_tests=0
failed_tests=0

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Container BitBot Test Suite          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Test Framework
# ============================================================================

test_passed() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} ${test_name}"
    passed_tests=$((passed_tests + 1))
}

test_failed() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason: ${reason}${NC}"
    fi
    failed_tests=$((failed_tests + 1))
}

run_test() {
    local test_name="$1"
    total_tests=$((total_tests + 1))
}

# ============================================================================
# Test 1: Bash Syntax Check
# ============================================================================

echo -e "${BLUE}═══ Test 1: Bash Syntax Check ═══${NC}"
echo ""

test_bash_syntax() {
    local file="$1"
    local basename=$(basename "$file")

    run_test "Syntax check: $basename"

    if bash -n "$file" 2>/dev/null; then
        test_passed "Syntax check: $basename"
        return 0
    else
        local error
        error=$(bash -n "$file" 2>&1 || true)
        test_failed "Syntax check: $basename" "$error"
        return 1
    fi
}

# Check all bash scripts (including wrapper)
for script in "${CONTAINER_BITBOT_ROOT}/bitbot" \
              "${CONTAINER_BITBOT_ROOT}/core/commands/"*.sh \
              "${CONTAINER_BITBOT_ROOT}/core/util/"*.sh \
              "${CONTAINER_BITBOT_ROOT}/wrapper/"*.sh; do
    if [[ -f "$script" ]]; then
        test_bash_syntax "$script"
    fi
done

echo ""

# ============================================================================
# Test 2: Main Entry Point
# ============================================================================

echo -e "${BLUE}═══ Test 2: Main Entry Point ═══${NC}"
echo ""

# Test help command
run_test "bitbot help"
if output=$("${CONTAINER_BITBOT_ROOT}/bitbot" help 2>&1); then
    if echo "$output" | grep -q "BitBot (Container)"; then
        test_passed "bitbot help - shows help"
    else
        test_failed "bitbot help - no help output"
    fi
else
    test_failed "bitbot help - command failed"
fi

# Test invalid command
run_test "bitbot invalid - error handling"
output=$("${CONTAINER_BITBOT_ROOT}/bitbot" invalid 2>&1 || true)
if echo "$output" | grep -q "Unknown command"; then
    test_passed "bitbot invalid - shows error"
else
    test_failed "bitbot invalid - no error message"
fi

echo ""

# ============================================================================
# Test 3: Helper Utilities
# ============================================================================

echo -e "${BLUE}═══ Test 3: Helper Utilities ═══${NC}"
echo ""

# Source helpers
run_test "helpers.sh - source"
if source "${CONTAINER_BITBOT_ROOT}/core/util/helpers.sh" 2>/dev/null; then
    test_passed "helpers.sh - can be sourced"
else
    test_failed "helpers.sh - cannot be sourced"
fi

# Test helper functions
run_test "helpers - command_exists"
if command_exists bash; then
    test_passed "helpers - command_exists works"
else
    test_failed "helpers - command_exists broken"
fi

run_test "helpers - get_workspace"
WORKSPACE="/test/path"
if [[ "$(get_workspace)" == "/test/path" ]]; then
    test_passed "helpers - get_workspace works"
else
    test_failed "helpers - get_workspace broken"
fi

run_test "helpers - get_bitbot_mode"
BITBOT_MODE="work"
if [[ "$(get_bitbot_mode)" == "work" ]]; then
    test_passed "helpers - get_bitbot_mode works"
else
    test_failed "helpers - get_bitbot_mode broken"
fi

run_test "helpers - is_work_mode"
BITBOT_MODE="work"
if is_work_mode; then
    test_passed "helpers - is_work_mode works"
else
    test_failed "helpers - is_work_mode broken"
fi

run_test "helpers - is_config_mode"
BITBOT_MODE="config"
if is_config_mode; then
    test_passed "helpers - is_config_mode works"
else
    test_failed "helpers - is_config_mode broken"
fi

echo ""

# ============================================================================
# Test 7: Wrapper Integration
# ============================================================================

echo -e "${BLUE}═══ Test 7: Wrapper Integration ═══${NC}"
echo ""

# Test wrapper directory exists
run_test "wrapper - directory exists"
if [[ -d "${CONTAINER_BITBOT_ROOT}/wrapper" ]]; then
    test_passed "wrapper - directory exists"
else
    test_failed "wrapper - directory not found"
fi

# Test wrapper scripts exist
run_test "wrapper - claude-wrapper.sh exists"
if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" ]]; then
    test_passed "wrapper - claude-wrapper.sh exists"
else
    test_failed "wrapper - claude-wrapper.sh not found"
fi

run_test "wrapper - watchdog.sh exists"
if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/watchdog.sh" ]]; then
    test_passed "wrapper - watchdog.sh exists"
else
    test_failed "wrapper - watchdog.sh not found"
fi

run_test "wrapper - send-wrapper-command.sh exists"
if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/send-wrapper-command.sh" ]]; then
    test_passed "wrapper - send-wrapper-command.sh exists"
else
    test_failed "wrapper - send-wrapper-command.sh not found"
fi

# Test wrapper scripts are executable
run_test "wrapper - claude-wrapper.sh executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" ]]; then
    test_passed "wrapper - claude-wrapper.sh executable"
else
    test_failed "wrapper - claude-wrapper.sh not executable"
fi

run_test "wrapper - watchdog.sh executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/watchdog.sh" ]]; then
    test_passed "wrapper - watchdog.sh executable"
else
    test_failed "wrapper - watchdog.sh not executable"
fi

run_test "wrapper - send-wrapper-command.sh executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/send-wrapper-command.sh" ]]; then
    test_passed "wrapper - send-wrapper-command.sh executable"
else
    test_failed "wrapper - send-wrapper-command.sh not executable"
fi

# Test start.sh references correct wrapper path
run_test "start.sh - uses /usr/local/bitbot/wrapper/ path"
if grep -q "/usr/local/bitbot/wrapper/claude-wrapper.sh" "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - references correct wrapper path"
else
    test_failed "start.sh - wrapper path incorrect"
fi

# Test start.sh does not reference old wrapper path
run_test "start.sh - no old /opt/bitbot/wrapper/ references"
if ! grep -q "/opt/bitbot/wrapper" "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - no old wrapper path references"
else
    test_failed "start.sh - still references old /opt/bitbot/wrapper/"
fi

# Test wrapper can be sourced (basic functionality)
run_test "wrapper - claude-wrapper.sh basic validation"
if bash -n "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" 2>/dev/null; then
    test_passed "wrapper - claude-wrapper.sh valid bash"
else
    test_failed "wrapper - claude-wrapper.sh has syntax errors"
fi

echo ""

# ============================================================================
# Test 8: File Permissions
# ============================================================================

echo -e "${BLUE}═══ Test 8: File Permissions ═══${NC}"
echo ""

run_test "bitbot - executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/bitbot" ]]; then
    test_passed "bitbot - is executable"
else
    test_failed "bitbot - not executable"
fi

for cmd in default resume start; do
    run_test "$cmd.sh - executable"
    if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/${cmd}.sh" ]]; then
        test_passed "$cmd.sh - is executable"
    else
        test_failed "$cmd.sh - not executable"
    fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Test Suite Summary            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total:   ${BLUE}${total_tests}${NC}"
echo -e "  Passed:  ${GREEN}${passed_tests}${NC}"
echo -e "  Failed:  ${RED}${failed_tests}${NC}"
echo ""

# Calculate success rate
if [[ $total_tests -gt 0 ]]; then
    success_rate=$((passed_tests * 100 / total_tests))
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
fi

# Final result
if [[ $failed_tests -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ALL TESTS PASSED! ✓                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     SOME TESTS FAILED ✗                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
