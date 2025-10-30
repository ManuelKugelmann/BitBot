# Global Config Location Fix - Pseudocode

## Overview

**Problem**: Global BitBot config is currently stored at `$BITBOT_HOME/config.json` (root of install)

**Solution**: Move to `$BITBOT_HOME/global/.bitbot/config.json` for better organization

**Architecture**:
- Global config stored at `$BITBOT_HOME/global/.bitbot/config.json` on host
- Mounted into containers via devcontainer mounts (readonly or readwrite as needed)
- Merged with workspace-local `.bitbot/config.json` (if exists)
- User sees merged config in container

## Directory Structure

### Host (BitBot Installation)

```
$BITBOT_HOME/
├── global/
│   ├── .bitbot/
│   │   └── config.json        ← Global BitBot config (THIS TASK)
│   ├── .claude/
│   │   ├── CLAUDE.md
│   │   ├── settings.json
│   │   └── .credentials.json
│   ├── .config/
│   │   └── ccstatusline/
│   └── .tmux.conf
└── config.json                 ← OLD location (migrate from here)
```

### Container

```
Container:
├── /root/.bitbot/              ← May be mounted from host global or workspace
│   └── config.json             ← Global config visible here
├── /workspace/
│   └── .bitbot/
│       └── config.json         ← Workspace-local config (optional, overrides)
```

**Note**: The exact mount strategy for `.bitbot/` is TBD. Current task focuses on:
1. Moving config from `$BITBOT_HOME/config.json` → `$BITBOT_HOME/global/.bitbot/config.json`
2. Updating code to use new location
3. Providing backward compatibility migration

## Implementation Plan

### 1. Update Helper Functions (core/util/helpers.sh)

```bash
# NEW FUNCTIONS

get_global_config_dir() {
    # Get global BitBot config directory
    # Location: $BITBOT_HOME/global/.bitbot/
    # Creates directory if it doesn't exist
    # Returns: Path to global .bitbot directory

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local config_dir="${bitbot_install}/global/.bitbot"

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    echo "$config_dir"
}

get_global_config_file() {
    # Get global BitBot config file path
    # Location: $BITBOT_HOME/global/.bitbot/config.json
    # Returns: Path to global config file

    local config_dir
    config_dir=$(get_global_config_dir)
    echo "${config_dir}/config.json"
}
```

### 2. Add Migration Logic (core/global/bitbot-init.sh)

```bash
# NEW FUNCTION

migrate_old_config_if_needed() {
    # Migrate config from old location to new location
    # Old: $BITBOT_HOME/config.json
    # New: $BITBOT_HOME/global/.bitbot/config.json
    # Only runs if old config exists and new config doesn't

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local old_config="${bitbot_install}/config.json"
    local new_config
    new_config=$(get_global_config_file)

    # Check if migration needed
    if [[ -f "$old_config" ]] && [[ ! -f "$new_config" ]]; then
        print_info "Migrating config to new location..."
        echo "  From: $old_config"
        echo "  To:   $new_config"

        # Ensure target directory exists
        local config_dir
        config_dir=$(get_global_config_dir)
        mkdir -p "$config_dir"

        # Copy (not move) for safety
        cp "$old_config" "$new_config"

        # Backup old config with timestamp
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        mv "$old_config" "${old_config}.migrated-${timestamp}"

        print_success "Config migrated successfully"
        print_info "Old config backed up as: ${old_config}.migrated-${timestamp}"
        return 0
    fi

    return 1  # No migration needed
}

# UPDATE EXISTING FUNCTION

is_global_init_needed() {
    # Check if global initialization is needed
    # Returns: 0 if needed, 1 if already initialized

    local config_file
    config_file=$(get_global_config_file)  # ← USE NEW HELPER

    if [[ ! -f "$config_file" ]]; then
        return 0  # No config → need global init
    fi

    return 1  # Config exists → already initialized
}

# UPDATE EXISTING FUNCTION

create_global_config() {
    # Create config.json in NEW location

    local config_file
    config_file=$(get_global_config_file)  # ← USE NEW HELPER

    # ... existing logic (VS Code detection, mode selection)

    create_config_json "$config_file" \
        "version" "0.1.0" \
        "launch_mode" "$default_mode" \
        "created_at" "$timestamp"

    print_success "Created config at: $config_file"
    echo "  ✓ Default mode: $default_mode"
}
```

### 3. Integrate Migration into Main Entry (core/bitbot)

```bash
# UPDATE handle_global_context()

handle_global_context() {
    # Running from BitBot install folder

    # Try migration first (if old config exists)
    migrate_old_config_if_needed  # ← ADD THIS

    if ! is_global_init_needed; then
        # Already initialized - validate environment
        validate_global_environment
    else
        # First run - run global init
        run_global_init
    fi
}
```

### 4. Update Tests

#### test-user-flow-init.sh

```bash
# UPDATE VARIABLE
GLOBAL_CONFIG="$BITBOT_ROOT/global/.bitbot/config.json"  # ← NEW LOCATION

# UPDATE cleanup()
cleanup() {
    # ... existing cleanup

    # Remove test-generated global config
    if [[ -f "$GLOBAL_CONFIG" ]]; then
        test_info "Removing test-generated config..."
        rm -f "$GLOBAL_CONFIG"
    fi

    # Also clean old location if test created it
    if [[ -f "$BITBOT_ROOT/config.json" ]]; then
        rm -f "$BITBOT_ROOT/config.json"
    fi
}

# UPDATE Test 8: Config creation check
if [[ -f "$GLOBAL_CONFIG" ]]; then
    test_pass "Config created at global/.bitbot/config.json"
else
    test_fail "Config not found at $GLOBAL_CONFIG"
fi
```

#### test-user-flow-moved.sh

```bash
# UPDATE VARIABLE
GLOBAL_CONFIG="$BITBOT_ROOT/global/.bitbot/config.json"  # ← NEW LOCATION

# UPDATE cleanup()
# Same changes as test-user-flow-init.sh

# UPDATE Test 1: Config location check
if [[ -f "$GLOBAL_CONFIG" ]]; then
    test_pass "Config created at global/.bitbot/config.json"
else
    test_fail "Config not found at $GLOBAL_CONFIG"
fi

# UPDATE Test 2: Config stays at global location
# Verify config STAYS at $BITBOT_HOME/global/.bitbot/ (doesn't move with installation!)
if [[ -f "$GLOBAL_CONFIG" ]]; then
    test_fail "Config should have moved with installation, but it's still at old path"
fi

# Check new location
GLOBAL_CONFIG_MOVED="$BITBOT_MOVED/global/.bitbot/config.json"
if [[ -f "$GLOBAL_CONFIG_MOVED" ]]; then
    test_pass "Config moved with installation to global/.bitbot/"
else
    test_fail "Config not found at moved location"
fi
```

## Migration Behavior

**Scenario 1: Fresh Install**
- No old config at `$BITBOT_HOME/config.json`
- Creates new config at `$BITBOT_HOME/global/.bitbot/config.json`
- ✓ Works as expected

**Scenario 2: Existing Install (before fix)**
- Old config exists at `$BITBOT_HOME/config.json`
- On first run after update:
  1. Detects old config
  2. Copies to `$BITBOT_HOME/global/.bitbot/config.json`
  3. Renames old config to `config.json.migrated-TIMESTAMP`
- ✓ Backward compatible, no data loss

**Scenario 3: Already migrated**
- Config exists at `$BITBOT_HOME/global/.bitbot/config.json`
- Old config doesn't exist (or is backup)
- Migration skipped
- ✓ No unnecessary operations

**Scenario 4: Moved Installation**
- User moves `$BITBOT_HOME` to new location
- Config moves WITH installation (it's in `$BITBOT_HOME/global/.bitbot/`)
- Path variables update automatically
- ✓ Portable installation

## Files to Update

1. **core/util/helpers.sh**
   - Add `get_global_config_dir()`
   - Add `get_global_config_file()`

2. **core/global/bitbot-init.sh**
   - Add `migrate_old_config_if_needed()`
   - Update `is_global_init_needed()` to use new helper
   - Update `create_global_config()` to use new helper

3. **core/bitbot**
   - Update `handle_global_context()` to call migration

4. **dev/tests/test-user-flow-init.sh**
   - Update `GLOBAL_CONFIG` variable
   - Update cleanup to handle both locations
   - Update Test 8 config location check

5. **dev/tests/test-user-flow-moved.sh**
   - Update `GLOBAL_CONFIG` variable
   - Update cleanup to handle both locations
   - Update Test 1 config location check
   - Update Test 2 to verify config moves with installation

## Testing Plan

1. **Fresh Install Test**
   - Run `dev/tests/test-user-flow-init.sh`
   - Verify config created at `global/.bitbot/config.json`
   - ✓ Tests should pass

2. **Migration Test**
   - Manually create old config at `$BITBOT_HOME/config.json`
   - Run `core/bitbot` (trigger global context)
   - Verify migration occurs
   - Verify old config backed up with timestamp
   - ✓ Manual verification

3. **Moved Installation Test**
   - Run `dev/tests/test-user-flow-moved.sh`
   - Verify config moves with installation
   - ✓ Tests should pass

4. **Existing Install Test (Already Migrated)**
   - Config already at `global/.bitbot/config.json`
   - Run `core/bitbot`
   - Verify no migration occurs
   - ✓ Manual verification

## Commit Strategy

**Single Commit** (atomic change):
```
Fix global config location: Move to global/.bitbot/config.json

- Add helper functions for global config path
- Implement automatic migration from old location
- Update tests to check new location
- Backward compatible with existing installations

Old: $BITBOT_HOME/config.json
New: $BITBOT_HOME/global/.bitbot/config.json
```

## Mount Configuration (Future Work)

**Note**: This task focuses on HOST-side config location. Container mounting strategy for `global/.bitbot/` is separate work.

**Possible mount strategies** (TBD):
1. Mount entire `$BITBOT_HOME/global/` → `/root/` (simple, but exposes all global files)
2. Mount `$BITBOT_HOME/global/.bitbot/` → `/root/.bitbot/` (targeted, cleaner)
3. Individual file mounts like `.claude/` (most control, more complex)

**Current task does NOT implement mounts** - only fixes host-side location.

## Config Merging (Future Work)

**Note**: User mentioned "merge-eval with local workspace config"

**Possible merge strategy** (TBD):
```bash
get_effective_config() {
    # Merge global + workspace configs
    local workspace_path="$1"
    local global_config
    global_config=$(get_global_config_file)
    local workspace_config="${workspace_path}/.bitbot/config.json"

    # Use jq to merge (workspace overrides global)
    if [[ -f "$workspace_config" ]]; then
        jq -s '.[0] * .[1]' "$global_config" "$workspace_config"
    else
        cat "$global_config"
    fi
}
```

**Current task does NOT implement merging** - future enhancement.
