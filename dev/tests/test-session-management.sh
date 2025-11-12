#!/usr/bin/env bash
#
# Test: Session Management
# Tests start/resume/default session functions
#
# MIGRATED TO USE: test-framework.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONTAINER_BITBOT_ROOT="${BITBOT_ROOT}/container/bitbot"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "Session Management Test Suite"

# ============================================================================
# Test 1: Start Command - Wrapper Integration
# ============================================================================

test_section "Test 1: Start Command (Wrapper)"

# Test: start.sh references wrapper correctly
if grep -q 'wrapper_script="/usr/local/bitbot/wrapper/claude-wrapper.sh"' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - uses correct wrapper path"
else
    test_fail "start.sh - incorrect wrapper path"
fi

# Test: start.sh checks for wrapper availability
if grep -q 'if \[\[ ! -f "$wrapper_script" \]\] || \[\[ ! -x "$wrapper_script" \]\]' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - checks wrapper availability"
else
    test_fail "start.sh - missing wrapper check"
fi

# Test: start.sh launches via wrapper (exec tmux with wrapper)
if grep -q 'exec tmux new-session.*wrapper_script' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - uses exec tmux with wrapper"
else
    test_fail "start.sh - doesn't use exec tmux with wrapper"
fi

# Test: start.sh has error handling for missing wrapper
if grep -q 'error "Wrapper not found or not executable"' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - has wrapper error handling"
else
    test_fail "start.sh - missing error handling"
fi

# ============================================================================
# Test 2: Resume Command - Session Detection
# ============================================================================

test_section "Test 2: Resume Command"

# Source utilities for testing
source "${CONTAINER_BITBOT_ROOT}/core/util/helpers.sh" 2>/dev/null || true
source "${CONTAINER_BITBOT_ROOT}/core/util/tmux-utils.sh" 2>/dev/null || true

# Test: resume.sh exists
if [[ -f "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh" ]]; then
    test_pass "resume.sh - file exists"
else
    test_fail "resume.sh - file not found"
fi

# Test: resume.sh is executable
if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh" ]]; then
    test_pass "resume.sh - is executable"
else
    test_fail "resume.sh - not executable"
fi

# Test: resume.sh has session detection logic
if grep -q 'list_tmux_sessions' "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh"; then
    test_pass "resume.sh - has session detection"
else
    test_fail "resume.sh - missing session detection"
fi

# Test: resume.sh handles multiple sessions
if grep -q 'session_count' "${CONTAINER_BITBOT_ROOT}/core/commands/resume.sh"; then
    test_pass "resume.sh - handles multiple sessions"
else
    test_fail "resume.sh - no multiple session handling"
fi

# ============================================================================
# Test 3: Default Command - Smart Launcher
# ============================================================================

test_section "Test 3: Default Command (Smart Launcher)"

# Test: default.sh exists
if [[ -f "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" ]]; then
    test_pass "default.sh - file exists"
else
    test_fail "default.sh - file not found"
fi

# Test: default.sh is executable
if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" ]]; then
    test_pass "default.sh - is executable"
else
    test_fail "default.sh - not executable"
fi

# Test: default.sh has auto-resume logic
if grep -q 'IF session_count == 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" || \
   grep -q 'session_count -eq 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh"; then
    test_pass "default.sh - auto-resumes single session"
else
    test_fail "default.sh - no auto-resume logic"
fi

# Test: default.sh offers choice for multiple sessions
if grep -q 'session_count > 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh" || \
   grep -q 'session_count -gt 1' "${CONTAINER_BITBOT_ROOT}/core/commands/default.sh"; then
    test_pass "default.sh - shows menu for multiple sessions"
else
    test_fail "default.sh - no menu for multiple sessions"
fi

# ============================================================================
# Test 4: Tmux Utilities
# ============================================================================

test_section "Test 4: Tmux Utilities"

# Test: tmux-utils.sh can be sourced
if source "${CONTAINER_BITBOT_ROOT}/core/util/tmux-utils.sh" 2>/dev/null; then
    test_pass "tmux-utils.sh - successfully sourced"
else
    test_fail "tmux-utils.sh - failed to source"
fi

# Test: tmux utilities define required functions
if declare -f list_tmux_sessions >/dev/null 2>&1; then
    test_pass "tmux-utils.sh - list_tmux_sessions defined"
else
    test_fail "tmux-utils.sh - list_tmux_sessions not defined"
fi

if declare -f tmux_available >/dev/null 2>&1; then
    test_pass "tmux-utils.sh - tmux_available defined"
else
    test_fail "tmux-utils.sh - tmux_available not defined"
fi

if declare -f generate_session_name >/dev/null 2>&1; then
    test_pass "tmux-utils.sh - generate_session_name defined"
else
    test_fail "tmux-utils.sh - generate_session_name not defined"
fi

# Test: session name generation format
session_name=$(generate_session_name 2>/dev/null || echo "")
if [[ "$session_name" =~ ^bitbot-[0-9]{8}-[0-9]{4}$ ]]; then
    test_pass "tmux-utils.sh - generates valid session name: $session_name"
else
    test_fail "tmux-utils.sh - invalid session name format: $session_name"
fi

# ============================================================================
# Test 5: Session Flow Integration
# ============================================================================

test_section "Test 5: Session Flow Integration"

# Test: bitbot main entry routes to commands
if grep -q 'start)' "${CONTAINER_BITBOT_ROOT}/bitbot" && \
   grep -q 'core/commands/start.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_pass "bitbot - routes start command"
else
    test_fail "bitbot - doesn't route start command"
fi

if grep -q 'resume)' "${CONTAINER_BITBOT_ROOT}/bitbot" && \
   grep -q 'core/commands/resume.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_pass "bitbot - routes resume command"
else
    test_fail "bitbot - doesn't route resume command"
fi

if grep -q 'core/commands/default.sh' "${CONTAINER_BITBOT_ROOT}/bitbot"; then
    test_pass "bitbot - routes to default command"
else
    test_fail "bitbot - doesn't route to default"
fi

# ============================================================================
# Test 6: Mode Detection
# ============================================================================

test_section "Test 6: Mode Detection"

# Test: mode detection in commands
if grep -q 'get_bitbot_mode' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - calls get_bitbot_mode"
else
    test_fail "start.sh - doesn't detect mode"
fi

if grep -q 'get_workspace' "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - calls get_workspace"
else
    test_fail "start.sh - doesn't detect workspace"
fi

# Test: mode environment variable support
export BITBOT_MODE="work"
if [[ "$(get_bitbot_mode)" == "work" ]]; then
    test_pass "helpers - respects BITBOT_MODE env var"
else
    test_fail "helpers - doesn't respect BITBOT_MODE"
fi
unset BITBOT_MODE

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
