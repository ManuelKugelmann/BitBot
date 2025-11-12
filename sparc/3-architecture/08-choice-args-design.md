# BitBot Choice Arguments Design

## Overview

Design for `--choice-*` arguments to make all BitBot interactive prompts bypassable for headless/CI testing.

## Requirements

1. **All user flow tests use tmux** - Even non-interactive flows should run in tmux for consistent output capture
2. **Each prompt has --choice arg** - Headless operation possible without tmux for CI testing
3. **Backward compatibility** - Existing behavior (TTY detection, CI mode) continues to work

## Interactive Prompts Inventory

### workspace/bitbot-init.sh

| Prompt | Context | Choices | Proposed Flag |
|--------|---------|---------|---------------|
| Config mode | `bitbot init` (auto mode) | yes/no | `BITBOT_CHOICE_CONFIG_MODE` |

Note: `--config` and `--no-config` flags still available for explicit control.

### util/git.sh

| Prompt | Context | Choices | Proposed Flag |
|--------|---------|---------|---------------|
| No git repo | `bitbot init` | 0=Exit, 1=Skip, 2=Skip perm | `--choice-git-no-repo=N` |
| No remote | `bitbot init` | 0=Exit, 1=Skip, 2=Skip perm | `--choice-git-no-remote=N` |
| Unpushed changes | `bitbot init` | 0=Exit, 1=Skip, 2=Skip perm | `--choice-git-unpushed=N` |
| Safety warning | `bitbot init` | 0=Exit, 1=Skip, 2=Skip perm | `--choice-git-safety=N` |

### global/bitbot-init.sh

| Prompt | Context | Choices | Proposed Flag |
|--------|---------|---------|---------------|
| Update shell config | First run | yes/no | `--choice-update-shell=yes\|no` |
| Launch mode | First run | 0=Terminal, 1=VS Code | `--choice-launch-mode=N` |
| Add to PATH | First run | yes/no | `--choice-add-path=yes\|no` |

## Design Approach

### Environment Variables (Recommended)

Use environment variables for simplicity and flexibility:

```bash
# Workspace init prompts
BITBOT_CHOICE_CONFIG_MODE="yes|no"

# Git prompts
BITBOT_CHOICE_GIT_NO_REPO="0|1|2"
BITBOT_CHOICE_GIT_NO_REMOTE="0|1|2"
BITBOT_CHOICE_GIT_UNPUSHED="0|1|2"
BITBOT_CHOICE_GIT_SAFETY="0|1|2"

# Global init prompts
BITBOT_CHOICE_UPDATE_SHELL="yes|no"
BITBOT_CHOICE_LAUNCH_MODE="0|1"
BITBOT_CHOICE_ADD_PATH="yes|no"
```

### Modified Prompt Functions

Update `prompt_yes_no` and `prompt_choice` in `core/util/helpers.sh`:

```bash
prompt_yes_no() {
    local question="$1"
    local default="${2:-}"
    local choice_var="${3:-}"  # Optional: environment variable name

    # Check if choice provided via environment
    if [[ -n "$choice_var" ]]; then
        local choice_value="${!choice_var:-}"
        if [[ -n "$choice_value" ]]; then
            echo "$choice_value"
            return 0
        fi
    fi

    # ... existing interactive logic ...
}

prompt_choice() {
    local question="$1"
    local default_index="$2"
    local choice_var="${3:-}"  # Optional: environment variable name
    shift 3
    local choices=("$@")

    # Check if choice provided via environment
    if [[ -n "$choice_var" ]]; then
        local choice_value="${!choice_var:-}"
        if [[ -n "$choice_value" ]]; then
            echo "$choice_value"
            return 0
        fi
    fi

    # ... existing interactive logic ...
}
```

### Usage in git.sh

```bash
# Before (interactive only)
choice=$(prompt_choice "What would you like to do?" 0 \
    "Exit and add remote" \
    "Skip this time" \
    "Skip permanently")

# After (supports environment override)
choice=$(prompt_choice "What would you like to do?" 0 \
    "BITBOT_CHOICE_GIT_NO_REMOTE" \
    "Exit and add remote" \
    "Skip this time" \
    "Skip permanently")
```

### Test Usage

```bash
# Interactive test with tmux (captures actual user interaction)
tmux_test_start "$SESSION_NAME" "bash $BITBOT_CMD init"
tmux_test_wait_for "$SESSION_NAME" "What would you like to do?" 5
tmux_test_send_keys "$SESSION_NAME" "2"  # Skip this time
tmux_test_send_enter "$SESSION_NAME"

# Headless test with choice env var (CI-friendly, no tmux needed)
BITBOT_CHOICE_GIT_NO_REMOTE=1 bash "$BITBOT_CMD" init --no-config
```

## Implementation Plan

1. ✓ Document all prompts
2. Update `prompt_yes_no()` in helpers.sh to support environment variable override
3. Update `prompt_choice()` in helpers.sh to support environment variable override
4. Update all git.sh prompts to pass choice_var parameter
5. Update bitbot-init.sh prompts to pass choice_var parameter
6. Update global/bitbot-init.sh prompts to pass choice_var parameter
7. Update test-bitbot-init-non-interactive.sh to use environment variables
8. Update all test-user-flow-*.sh to:
   - Use tmux harness for interactive tests
   - Use environment variables for headless/CI tests
9. Document the new system in README

## Benefits

- **Consistent testing**: All tests use tmux for uniform output capture
- **CI-friendly**: Headless tests can use environment variables without tmux
- **Backward compatible**: Existing TTY detection and CI mode continue to work
- **Flexible**: Can mix interactive and non-interactive testing
- **Simple**: Environment variables are easy to use in scripts

## Migration

### Current State

```bash
# test-bitbot-init-non-interactive.sh (current approach)
git remote add origin https://github.com/test/test.git  # Hack to avoid prompt
bash "$BITBOT_CMD" init --no-config
```

### New State

```bash
# test-bitbot-init-interactive.sh (interactive path)
tmux_test_start "$SESSION_NAME" "bash $BITBOT_CMD init --no-config"
tmux_test_wait_for "$SESSION_NAME" "What would you like to do?" 5
tmux_test_send_keys "$SESSION_NAME" "1"  # Skip this time
tmux_test_send_enter "$SESSION_NAME"

# test-bitbot-init-non-interactive.sh (headless path)
BITBOT_CHOICE_GIT_NO_REMOTE=1 bash "$BITBOT_CMD" init --no-config
```
