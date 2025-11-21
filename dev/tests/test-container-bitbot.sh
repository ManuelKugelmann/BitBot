#!/usr/bin/env bash
#
# Test: Container BitBot
# Tests container-side BitBot scripts
#
# Container BitBot Mount Configuration:
# - Base template (container/templates/bitbot-base/devcontainer.json) includes:
#     "mounts": ["source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly"]
# - During 'bitbot init', container/bitbot/ is copied to user's .devcontainer/bitbot/
# - Mount makes scripts available at /usr/local/bitbot in all containers
# - See sparc/1-specification/01_CONTAINER_ORCHESTRATION_STRATEGY.md for details
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

test_suite_begin "Container BitBot Test Suite"

# ============================================================================
# Test 1: Bash Syntax Check
# ============================================================================

test_section "Test 1: Bash Syntax Check"

test_bash_syntax() {
    local file="$1"
    local basename=$(basename "$file")

    if bash -n "$file" 2>/dev/null; then
        test_pass "Syntax check: $basename"
        return 0
    else
        local error
        error=$(bash -n "$file" 2>&1 || true)
        test_fail "Syntax check: $basename" "$error"
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

# ============================================================================
# Test 2: Main Entry Point
# ============================================================================

test_section "Test 2: Main Entry Point"

# Test: help command
if output=$("${CONTAINER_BITBOT_ROOT}/bitbot" help 2>&1); then
    if echo "$output" | grep -q "BitBot (Container)"; then
        test_pass "bitbot help - shows help"
    else
        test_fail "bitbot help - no help output"
    fi
else
    test_fail "bitbot help - command failed"
fi

# Test: invalid command
output=$("${CONTAINER_BITBOT_ROOT}/bitbot" invalid 2>&1 || true)
if echo "$output" | grep -q "Unknown command"; then
    test_pass "bitbot invalid - shows error"
else
    test_fail "bitbot invalid - no error message"
fi

# ============================================================================
# Test 3: Helper Utilities
# ============================================================================

test_section "Test 3: Helper Utilities"

# Test: helpers.sh can be sourced
if source "${CONTAINER_BITBOT_ROOT}/core/util/helpers.sh" 2>/dev/null; then
    test_pass "helpers.sh - can be sourced"
else
    test_fail "helpers.sh - cannot be sourced"
fi

# Test: command_exists function
if command_exists bash; then
    test_pass "helpers - command_exists works"
else
    test_fail "helpers - command_exists broken"
fi

# Test: get_workspace function
WORKSPACE="/test/path"
if [[ "$(get_workspace)" == "/test/path" ]]; then
    test_pass "helpers - get_workspace works"
else
    test_fail "helpers - get_workspace broken"
fi

# Test: get_bitbot_mode function
BITBOT_MODE="work"
if [[ "$(get_bitbot_mode)" == "work" ]]; then
    test_pass "helpers - get_bitbot_mode works"
else
    test_fail "helpers - get_bitbot_mode broken"
fi

# Test: is_work_mode function
BITBOT_MODE="work"
if is_work_mode; then
    test_pass "helpers - is_work_mode works"
else
    test_fail "helpers - is_work_mode broken"
fi

# Test: is_config_mode function
BITBOT_MODE="config"
if is_config_mode; then
    test_pass "helpers - is_config_mode works"
else
    test_fail "helpers - is_config_mode broken"
fi

# ============================================================================
# Test 4: Wrapper Integration
# ============================================================================

test_section "Test 4: Wrapper Integration"

# Test: wrapper directory exists
if [[ -d "${CONTAINER_BITBOT_ROOT}/wrapper" ]]; then
    test_pass "wrapper - directory exists"
else
    test_fail "wrapper - directory not found"
fi

# Test: wrapper scripts exist
if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" ]]; then
    test_pass "wrapper - claude-wrapper.sh exists"
else
    test_fail "wrapper - claude-wrapper.sh not found"
fi

if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/watchdog.sh" ]]; then
    test_pass "wrapper - watchdog.sh exists"
else
    test_fail "wrapper - watchdog.sh not found"
fi

if [[ -f "${CONTAINER_BITBOT_ROOT}/wrapper/send-wrapper-command.sh" ]]; then
    test_pass "wrapper - send-wrapper-command.sh exists"
else
    test_fail "wrapper - send-wrapper-command.sh not found"
fi

# Test: wrapper scripts are executable
if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" ]]; then
    test_pass "wrapper - claude-wrapper.sh executable"
else
    test_fail "wrapper - claude-wrapper.sh not executable"
fi

if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/watchdog.sh" ]]; then
    test_pass "wrapper - watchdog.sh executable"
else
    test_fail "wrapper - watchdog.sh not executable"
fi

if [[ -x "${CONTAINER_BITBOT_ROOT}/wrapper/send-wrapper-command.sh" ]]; then
    test_pass "wrapper - send-wrapper-command.sh executable"
else
    test_fail "wrapper - send-wrapper-command.sh not executable"
fi

# Test: start.sh references correct wrapper path
if grep -q "/usr/local/bitbot/wrapper/claude-wrapper.sh" "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - references correct wrapper path"
else
    test_fail "start.sh - wrapper path incorrect"
fi

# Test: start.sh does not reference old wrapper path
if ! grep -q "/opt/bitbot/wrapper" "${CONTAINER_BITBOT_ROOT}/core/commands/start.sh"; then
    test_pass "start.sh - no old wrapper path references"
else
    test_fail "start.sh - still references old /opt/bitbot/wrapper/"
fi

# Test: wrapper can be sourced (basic functionality)
if bash -n "${CONTAINER_BITBOT_ROOT}/wrapper/claude-wrapper.sh" 2>/dev/null; then
    test_pass "wrapper - claude-wrapper.sh valid bash"
else
    test_fail "wrapper - claude-wrapper.sh has syntax errors"
fi

# ============================================================================
# Test 5: File Permissions
# ============================================================================

test_section "Test 5: File Permissions"

# Test: bitbot executable
if [[ -x "${CONTAINER_BITBOT_ROOT}/bitbot" ]]; then
    test_pass "bitbot - is executable"
else
    test_fail "bitbot - not executable"
fi

# Test: command scripts executable
for cmd in default resume start; do
    if [[ -x "${CONTAINER_BITBOT_ROOT}/core/commands/${cmd}.sh" ]]; then
        test_pass "$cmd.sh - is executable"
    else
        test_fail "$cmd.sh - not executable"
    fi
done

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
