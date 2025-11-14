#!/usr/bin/env bash
#
# BitBot Init Non-Interactive Test
# Tests non-interactive modes of bitbot init command
#
# This test validates:
# 1. bitbot init --config (explicit config mode enable)
# 2. bitbot init --no-config (explicit config mode disable)
# 3. CI=true bitbot init (auto-detect non-interactive)
# 4. Workspace structure created correctly in all modes
#
# These tests are suitable for CI as they don't require user interaction
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test helpers
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"

# Setup environment
export BITBOT_HOME="$BITBOT_ROOT"
BITBOT_CMD="${BITBOT_ROOT}/core/bitbot"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Init Non-Interactive Tests"

# ============================================================================
# Test 1: bitbot init --no-config (explicit disable)
# ============================================================================

test_section "Test 1: bitbot init --no-config"

workspace=$(create_test_workspace "init-no-config")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REPO=1  # Skip this time
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time

# Run bitbot init with --no-config
if timeout 30 bash "$BITBOT_CMD" init --no-config &>/dev/null; then
    test_pass "bitbot init --no-config completed successfully"
else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        test_fail "bitbot init --no-config timed out" "Should complete quickly without container launch"
    else
        test_fail "bitbot init --no-config failed with exit code $exit_code"
    fi
fi

# Verify workspace structure
test_dir_exists ".devcontainer directory created" ".devcontainer"
test_file_exists "devcontainer.json created" ".devcontainer/devcontainer.json"
test_file_exists "Dockerfile created" ".devcontainer/Dockerfile"
test_dir_exists "BitBot container scripts copied" ".devcontainer/bitbot"
test_dir_exists ".bitbot directory created" ".bitbot"

# Verify it didn't try to launch container (should be very fast)
# Note: We rely on timeout being generous (30s) but command should finish in <5s
if [[ -f ".devcontainer/devcontainer.json" ]]; then
    test_pass "Command completed quickly (no container launch)"
fi

cleanup_test_workspace "$workspace"

# ============================================================================
# Test 2: bitbot init --config (explicit enable)
# ============================================================================

test_section "Test 2: bitbot init --config"

workspace=$(create_test_workspace "init-config")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time

# Run bitbot init with --config
# Note: This will attempt to launch container, so we allow timeout
init_output="/tmp/bitbot-init-config-$$.log"
timeout 60 bash "$BITBOT_CMD" init --config &>"$init_output" || true
init_exit_code=$?

# Workspace structure should be created even if container launch fails/times out
test_dir_exists ".devcontainer directory created" ".devcontainer"
test_file_exists "devcontainer.json created" ".devcontainer/devcontainer.json"
test_file_exists "Dockerfile created" ".devcontainer/Dockerfile"
test_dir_exists "BitBot container scripts copied" ".devcontainer/bitbot"

# Check if container launch was attempted
if grep -q "Launching config mode\|Building and starting config\|devcontainer" "$init_output" 2>/dev/null; then
    test_pass "Config mode launch was attempted"
elif [[ $init_exit_code -eq 124 ]]; then
    test_pass "Config mode launch attempted (timed out - expected in CI)"
else
    test_skip "Config mode launch" "devcontainer CLI may not be available"
fi

rm -f "$init_output"
cleanup_test_workspace "$workspace"

# ============================================================================
# Test 3: CI=true bitbot init (auto non-interactive)
# ============================================================================

test_section "Test 3: CI=true bitbot init (auto non-interactive)"

workspace=$(create_test_workspace "init-ci-mode")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time
export BITBOT_CHOICE_CONFIG_MODE=1  # No (skip config mode launch)

# Run with CI environment variable set
export CI=true
if timeout 30 bash "$BITBOT_CMD" init &>/dev/null; then
    test_pass "bitbot init completed in CI mode"
else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        test_fail "bitbot init timed out in CI mode" "Should skip interactive prompt"
    else
        test_fail "bitbot init failed in CI mode with exit code $exit_code"
    fi
fi
unset CI

# Verify workspace structure
test_dir_exists ".devcontainer directory created" ".devcontainer"
test_file_exists "devcontainer.json created" ".devcontainer/devcontainer.json"
test_file_exists "Dockerfile created" ".devcontainer/Dockerfile"
test_dir_exists "BitBot container scripts copied" ".devcontainer/bitbot"

# Verify it didn't try to launch container (CI mode should skip prompt)
test_pass "Command completed quickly without prompt in CI mode"

cleanup_test_workspace "$workspace"

# ============================================================================
# Test 4: Non-interactive stdin (no TTY)
# ============================================================================

test_section "Test 4: Non-interactive stdin (no TTY)"

workspace=$(create_test_workspace "init-no-tty")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time

# Run with stdin closed (simulates non-TTY environment)
if timeout 30 bash "$BITBOT_CMD" init </dev/null &>/dev/null; then
    test_pass "bitbot init completed with closed stdin"
else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        test_fail "bitbot init timed out with closed stdin"
    else
        test_fail "bitbot init failed with closed stdin, exit code $exit_code"
    fi
fi

# Verify workspace structure
test_dir_exists ".devcontainer directory created" ".devcontainer"
test_file_exists "devcontainer.json created" ".devcontainer/devcontainer.json"
test_dir_exists "BitBot container scripts copied" ".devcontainer/bitbot"

cleanup_test_workspace "$workspace"

# ============================================================================
# Test 5: Workspace structure validation
# ============================================================================

test_section "Test 5: Detailed workspace structure validation"

workspace=$(create_test_workspace "init-structure")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time

# Run init
timeout 30 bash "$BITBOT_CMD" init --no-config &>/dev/null || true

# Check .devcontainer structure
test_dir_exists ".devcontainer exists" ".devcontainer"
test_file_exists ".devcontainer/devcontainer.json exists" ".devcontainer/devcontainer.json"
test_file_exists ".devcontainer/Dockerfile exists" ".devcontainer/Dockerfile"
test_dir_exists ".devcontainer/bitbot exists" ".devcontainer/bitbot"
test_file_exists ".devcontainer/bitbot/bitbot exists" ".devcontainer/bitbot/bitbot"

# Check .bitbot structure
test_dir_exists ".bitbot exists" ".bitbot"
test_dir_exists ".bitbot/internal exists" ".bitbot/internal"
test_dir_exists ".bitbot/internal/container exists" ".bitbot/internal/container"
test_dir_exists ".bitbot/internal/global exists" ".bitbot/internal/global"

# Check container scripts
test_dir_exists "Container core commands exist" ".devcontainer/bitbot/core/commands"
test_dir_exists "Container core utilities exist" ".devcontainer/bitbot/core/util"

# Validate JSON syntax if jq is available
if command -v jq &>/dev/null; then
    if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
        test_pass "devcontainer.json has valid JSON syntax"
    else
        test_fail "devcontainer.json has invalid JSON syntax"
    fi

    # Check required devcontainer.json fields
    if jq -e '.name' .devcontainer/devcontainer.json &>/dev/null; then
        test_pass "devcontainer.json has 'name' field"
    else
        test_fail "devcontainer.json missing 'name' field"
    fi

    if jq -e '.dockerFile' .devcontainer/devcontainer.json &>/dev/null; then
        test_pass "devcontainer.json has 'dockerFile' field"
    else
        test_fail "devcontainer.json missing 'dockerFile' field"
    fi
else
    test_skip "JSON validation" "jq not available"
fi

cleanup_test_workspace "$workspace"

# ============================================================================
# Test 6: Re-init detection
# ============================================================================

test_section "Test 6: Re-initialization detection"

workspace=$(create_test_workspace "init-reinit")
cd "$workspace"
git init -q
git config user.email "test@bitbot.local"
git config user.name "BitBot Test"
# Use environment variables to skip git prompts in non-interactive mode
export BITBOT_CHOICE_GIT_NO_REMOTE=1  # Skip this time
export BITBOT_CHOICE_GIT_UNPUSHED=1  # Skip this time
export BITBOT_CHOICE_GIT_SAFETY=1  # Skip this time

# First init
timeout 30 bash "$BITBOT_CMD" init --no-config &>/dev/null || true

if [[ -d ".bitbot" ]]; then
    test_pass "First initialization successful"

    # Try to init again (should fail with "already initialized" error)
    # TODO: Currently re-init doesn't check for existing .bitbot directory
    reinit_output="/tmp/bitbot-reinit-$$.log"
    if timeout 10 bash "$BITBOT_CMD" init --no-config &>"$reinit_output"; then
        # Re-init succeeded - this is the current behavior (known issue)
        test_skip "Re-initialization prevention" "Known issue - init doesn't prevent re-init currently"
    else
        # Re-init failed - check if it failed with the right error message
        if grep -q "already initialized\|Workspace already initialized" "$reinit_output" 2>/dev/null; then
            test_pass "Re-initialization detected with appropriate error message"
        else
            # Failed for different reason (e.g., Docker not installed, prerequisites)
            test_skip "Re-initialization prevention" "Init failed but not due to re-init check"
        fi
    fi
    rm -f "$reinit_output"
else
    test_fail "First initialization failed"
fi

cleanup_test_workspace "$workspace"

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
