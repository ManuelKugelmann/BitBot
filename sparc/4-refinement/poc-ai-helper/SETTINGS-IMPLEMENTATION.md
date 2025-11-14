# Settings System Implementation

## Overview

BitBot uses a context-aware settings system that supports both global (host) and workspace (container) settings, with workspace settings overriding global settings.

## File Naming

- **Settings file**: `settings.json` (NOT `config.json`)
- **Reason**: Avoids confusion with "config mode" (`bitbot config`) and matches Claude Code's naming convention (`.claude/settings.json`)

## Settings Locations

### Global Settings (Host Context)
```
$BITBOT_HOME/global/.bitbot/settings.json
```

Used by:
- Host-side scripts (core/)
- Scripts run before container creation
- Global preferences

### Workspace Settings (Container Context)
```
$BITBOT_WORKSPACE/.bitbot/settings.json
```

Used by:
- Container-side scripts
- Workspace-specific preferences
- Overrides global settings

## Environment Variables

### `BITBOT_HOME`
- **Purpose**: BitBot installation root directory
- **Example**: `/mnt/c/Projects/BitBot`
- **Used by**: All scripts to find installation files

### `BITBOT_WORKSPACE`
- **Purpose**: Current workspace directory (if in workspace context)
- **Example**: `/workspace` or `/tmp/my-workspace`
- **Set by**: Container environment
- **Used by**: Context-aware helpers to determine settings location

## Context-Aware Helpers

### `get_settings_file()`
Returns the appropriate settings file path based on context:
- Workspace context (`BITBOT_WORKSPACE` set) → `$BITBOT_WORKSPACE/.bitbot/settings.json`
- Global context (no `BITBOT_WORKSPACE`) → `$BITBOT_HOME/global/.bitbot/settings.json`

```bash
settings_file=$(get_settings_file)
# Returns appropriate path automatically
```

### `get_setting <key>`
Retrieves a setting value with automatic merging:
- Workspace context → Merged global + workspace (workspace wins)
- Global context → Global settings only

```bash
value=$(get_setting "skip-git-push-warning")
# Automatically checks right location and merges
```

### `update_setting <key> <value>`
Updates a setting in the appropriate location:
- Workspace context → Updates workspace settings
- Global context → Updates global settings

```bash
update_setting "skip-git-push-warning" "true"
# Automatically saves to right location
```

## Merging Behavior

When in workspace context, settings are merged:

**Global settings** (`$BITBOT_HOME/global/.bitbot/settings.json`):
```json
{
  "global-setting-1": "value1",
  "global-setting-2": "value2"
}
```

**Workspace settings** (`$BITBOT_WORKSPACE/.bitbot/settings.json`):
```json
{
  "workspace-setting-1": "ws-value1",
  "global-setting-2": "overridden"
}
```

**Merged result** (workspace overrides global):
```json
{
  "global-setting-1": "value1",
  "global-setting-2": "overridden",
  "workspace-setting-1": "ws-value1"
}
```

## Usage in print_error_with_ai_help

### Preference Checking (Skip Prompt)
```bash
# Check if user chose [a]lways before
if [[ -n "$preference_key" ]] && [[ "$allow_always" == "true" ]]; then
    saved_pref=$(get_setting "$preference_key")
    if [[ "$saved_pref" == "true" ]]; then
        return 0  # Skip prompt
    fi
fi
```

### Preference Saving
```bash
# User chose [a]lways - save preference
if [[ -n "$preference_key" ]]; then
    update_setting "$preference_key" "true"
    print_info "Saved preference: $preference_key"
fi
```

## Example: Git Push Warning

### First Run
```bash
# Check for git push to main
if [[ "$branch" == "main" ]]; then
    print_error_with_ai_help \
        "Pushing to main branch" \
        "$HELP_GIT_PUSH_WARNING" \
        "Git push safety" \
        "autofix_git_commit_and_push" \
        "true" \
        "Push to main anyway" \
        "skip-git-push-warning"

    # User chooses 'a' (always)
    # → Saves: skip-git-push-warning = true
fi
```

### Subsequent Runs
```bash
# Same check
if [[ "$branch" == "main" ]]; then
    print_error_with_ai_help ...

    # Function internally checks:
    # saved_pref=$(get_setting "skip-git-push-warning")
    # if [[ "$saved_pref" == "true" ]]; then return 0
    # → Prompt skipped, returns 0 immediately
fi
```

## Testing

### Test Script 1: Basic Preference Persistence
```bash
/tmp/test-preference-persistence.sh
```

Tests:
- ✓ Save preference
- ✓ Retrieve preference
- ✓ Context-aware file selection
- ✓ Workspace vs global context

### Test Script 2: Comprehensive Settings & Merge
```bash
/tmp/test-settings-merge.sh
```

Tests:
- ✓ Global settings read/write
- ✓ Workspace settings read/write
- ✓ Settings merge (workspace overrides global)
- ✓ Context switching
- ✓ Preference persistence

All tests passing ✅

## Implementation Status

### Complete ✅
- Context-aware helpers (`get_settings_file`, `get_setting`, `update_setting`)
- Settings file renamed to `settings.json`
- Preference persistence in `print_error_with_ai_help`
- Automatic preference checking (skip prompt if saved)
- Automatic preference saving (when user chooses [a]lways)
- Merging global + workspace settings
- Tests covering all functionality

### TODO
- [ ] Verify global settings handling in `bitbot init` (copy vs mount)
- [ ] Add preference key to all repetitive checks (git push, Docker daemon, etc.)
- [ ] Integrate into `core/util/prerequisites.sh`
- [ ] Add method to clear/reset preferences (UI or command)

## Benefits

1. **Simplified Code**: Context-aware helpers eliminate if/else logic
2. **Automatic Merging**: Workspace settings override global automatically
3. **Consistent Behavior**: Same helpers work in all contexts
4. **User Control**: Users can set preferences globally or per-workspace
5. **Clear Separation**: Settings (JSON) vs config mode (command) are distinct
