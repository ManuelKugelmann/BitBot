#!/usr/bin/env bash
#
# Session Management Test Suite
# Tests start/resume/default session functions
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
echo -e "${CYAN}║   Session Management Test Suite       ║${NC}"
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
# Test 1: Start Command - Wrapper Integration
# ============================================================================

echo -e "${BLUE}═══ Test 1: Start Command (Wrapper) ═══${NC}"
echo ""

# Test start.sh references wrapper correctly
run_test "start.sh - wrapper path check"
if grep -q 'wrapper_script="/usr/local/bitbot/wrapper/claude-wrapper.sh"' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - uses correct wrapper path"
else
    test_failed "start.sh - incorrect wrapper path"
fi

# Test start.sh checks for wrapper availability
run_test "start.sh - wrapper availability check"
if grep -q 'if \[\[ ! -f "$wrapper_script" \]\] || \[\[ ! -x "$wrapper_script" \]\]' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - checks wrapper availability"
else
    test_failed "start.sh - missing wrapper check"
fi

# Test start.sh launches via wrapper (exec tmux with wrapper)
run_test "start.sh - launches via exec tmux + wrapper"
if grep -q 'exec tmux new-session.*wrapper_script' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - uses exec tmux with wrapper"
else
    test_failed "start.sh - doesn't use exec tmux with wrapper"
fi

# Test start.sh has error handling for missing wrapper
run_test "start.sh - error handling for missing wrapper"
if grep -q 'error "Wrapper not found or not executable"' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - has wrapper error handling"
else
    test_failed "start.sh - missing error handling"
fi

echo ""

# ============================================================================
# Test 2: Resume Command - Session Detection
# ============================================================================

echo -e "${BLUE}═══ Test 2: Resume Command ═══${NC}"
echo ""

# Source utilities for testing
source "${CONTAINER_BITBOT_ROOT}/core/util/helpers.sh" 2>/dev/null || true
source "${CONTAINER_BITBOT_ROOT}/core/util/tmux-utils.sh" 2>/dev/null || true

# Test resume.sh exists
run_test "resume.sh - exists"
if [[ -f "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh" ]]; then
    test_passed "resume.sh - file exists"
else
    test_failed "resume.sh - file not found"
fi

# Test resume.sh is executable
run_test "resume.sh - executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh" ]]; then
    test_passed "resume.sh - is executable"
else
    test_failed "resume.sh - not executable"
fi

# Test resume.sh has session detection logic
run_test "resume.sh - session detection"
if grep -q 'list_tmux_sessions' "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh"; then
    test_passed "resume.sh - has session detection"
else
    test_failed "resume.sh - missing session detection"
fi

# Test resume.sh handles multiple sessions
run_test "resume.sh - multiple session handling"
if grep -q 'session_count' "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh"; then
    test_passed "resume.sh - handles multiple sessions"
else
    test_failed "resume.sh - no multiple session handling"
fi

echo ""

# ============================================================================
# Test 3: Default Command - Smart Launcher
# ============================================================================

echo -e "${BLUE}═══ Test 3: Default Command (Smart Launcher) ═══${NC}"
echo ""

# Test default.sh exists
run_test "default.sh - exists"
if [[ -f "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" ]]; then
    test_passed "default.sh - file exists"
else
    test_failed "default.sh - file not found"
fi

# Test default.sh is executable
run_test "default.sh - executable"
if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" ]]; then
    test_passed "default.sh - is executable"
else
    test_failed "default.sh - not executable"
fi

# Test default.sh has auto-resume logic
run_test "default.sh - auto-resume for single session"
if grep -q 'IF session_count == 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" || \
   grep -q 'session_count -eq 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh"; then
    test_passed "default.sh - auto-resumes single session"
else
    test_failed "default.sh - no auto-resume logic"
fi

# Test default.sh offers choice for multiple sessions
run_test "default.sh - menu for multiple sessions"
if grep -q 'session_count > 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" || \
   grep -q 'session_count -gt 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh"; then
    test_passed "default.sh - shows menu for multiple sessions"
else
    test_failed "default.sh - no menu for multiple sessions"
fi

echo ""

# ============================================================================
# Test 4: Tmux Utilities
# ============================================================================

echo -e "${BLUE}═══ Test 4: Tmux Utilities ═══${NC}"
echo ""

# Test tmux-utils.sh can be sourced
run_test "tmux-utils.sh - can be sourced"
if source "${CONTAINER_BITBOT_ROOT}/core/util/tmux-utils.sh" 2>/dev/null; then
    test_passed "tmux-utils.sh - successfully sourced"
else
    test_failed "tmux-utils.sh - failed to source"
fi

# Test tmux utilities define required functions
run_test "tmux-utils.sh - list_tmux_sessions function"
if declare -f list_tmux_sessions >/dev/null 2>&1; then
    test_passed "tmux-utils.sh - list_tmux_sessions defined"
else
    test_failed "tmux-utils.sh - list_tmux_sessions not defined"
fi

run_test "tmux-utils.sh - tmux_available function"
if declare -f tmux_available >/dev/null 2>&1; then
    test_passed "tmux-utils.sh - tmux_available defined"
else
    test_failed "tmux-utils.sh - tmux_available not defined"
fi

run_test "tmux-utils.sh - generate_session_name function"
if declare -f generate_session_name >/dev/null 2>&1; then
    test_passed "tmux-utils.sh - generate_session_name defined"
else
    test_failed "tmux-utils.sh - generate_session_name not defined"
fi

# Test session name generation format
run_test "tmux-utils.sh - session name format"
session_name=$(generate_session_name 2>/dev/null || echo "")
if [[ "$session_name" =~ ^claude-[0-9]{8}-[0-9]{4}$ ]]; then
    test_passed "tmux-utils.sh - generates valid session name: $session_name"
else
    test_failed "tmux-utils.sh - invalid session name format: $session_name"
fi

echo ""

# ============================================================================
# Test 5: Session Flow Integration
# ============================================================================

echo -e "${BLUE}═══ Test 5: Session Flow Integration ═══${NC}"
echo ""

# Test bitbot main entry routes to commands
run_test "bitbot - routes 'start' command"
if grep -q 'start)' "${CONTAINER_BITBOT_ROOT}/bitbot" && \
   grep -q 'core/commands/start.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_passed "bitbot - routes start command"
else
    test_failed "bitbot - doesn't route start command"
fi

run_test "bitbot - routes 'resume' command"
if grep -q 'resume)' "${CONTAINER_BITBOT_ROOT}/bitbot" && \
   grep -q 'core/commands/resume.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_passed "bitbot - routes resume command"
else
    test_failed "bitbot - doesn't route resume command"
fi

run_test "bitbot - default command routing"
if grep -q 'core/commands/default.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_passed "bitbot - routes to default command"
else
    test_failed "bitbot - doesn't route to default"
fi

echo ""

# ============================================================================
# Test 6: Mode Detection
# ============================================================================

echo -e "${BLUE}═══ Test 6: Mode Detection ═══${NC}"
echo ""

# Test mode detection in commands
run_test "start.sh - detects mode"
if grep -q 'get_bitbot_mode' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - calls get_bitbot_mode"
else
    test_failed "start.sh - doesn't detect mode"
fi

run_test "start.sh - detects workspace"
if grep -q 'get_workspace' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_passed "start.sh - calls get_workspace"
else
    test_failed "start.sh - doesn't detect workspace"
fi

# Test mode environment variable support
run_test "helpers - BITBOT_MODE support"
export BITBOT_MODE="work"
if [[ "$(get_bitbot_mode)" == "work" ]]; then
    test_passed "helpers - respects BITBOT_MODE env var"
else
    test_failed "helpers - doesn't respect BITBOT_MODE"
fi
unset BITBOT_MODE

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
