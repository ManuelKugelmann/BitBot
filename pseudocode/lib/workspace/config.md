# Config Mode Pseudocode (Workspace)

**Component**: Config Mode Command (Workspace Context)
**Script**: `scripts/lib/workspace/bitbot-config.sh`
**Purpose**: Launch config devcontainer (RW .devcontainer) for workspace

---

## Overview

```
bitbot config [vscode] → Validate workspace → Git push recommendation → Launch config devcontainer
```

**Config Mode**: Uses global `config-devcontainer/` with workspace mounted (RW .devcontainer)

**Purpose in MVP**:
- AI agent analyzes project and configures .devcontainer
- No interactive wizard - AI handles tech stack detection and setup
- Uses base template from `devcontainer-template/` as starting point
- AI adjusts configuration for specific project needs

---

## Main Config Command

```pseudocode
FUNCTION bitbot_config(args):
    # Launch config mode, optionally in VS Code

    SET workspace_path = get_current_directory()

    # Determine launch mode: check args, then global config default
    SET use_vscode = get_launch_mode_preference(args)

    # Validate workspace
    IF NOT validate_workspace(workspace_path):
        ERROR "Invalid workspace - run 'bitbot init' first"
        EXIT 4
    END IF

    # Git push recommendation (non-blocking with skip options)
    # From lib/util/git.md
    CALL recommend_git_push_before_init(workspace_path)

    # Git safety checks (public repo warnings)
    # From lib/util/git.md
    CALL check_git_safety(workspace_path)

    IF use_vscode:
        PRINT "[>] Launching config mode in VS Code..."
    ELSE:
        PRINT "[>] Launching config mode in terminal..."
    END IF

    # Launch config devcontainer
    IF use_vscode:
        CALL launch_config_via_vscode(workspace_path)
    ELSE:
        CALL launch_config_via_devcontainer_cli(workspace_path)
    END IF
END FUNCTION
```

---

## Get Launch Mode Preference

```pseudocode
FUNCTION get_launch_mode_preference(args) → boolean:
    # Determine launch mode from args or global config
    # Returns true if should use VS Code, false for terminal

    # Check for explicit flag in args (overrides default)
    IF "--vscode" IN args OR "vscode" IN args:
        RETURN true
    END IF

    IF "--terminal" IN args OR "terminal" IN args:
        RETURN false
    END IF

    # No explicit flag - check global config default
    SET bitbot_install = get_bitbot_install_dir()
    SET config_file = bitbot_install + "/config.json"

    IF NOT file_exists(config_file):
        # No config - default to terminal
        RETURN false
    END IF

    CALL read_json(config_file) → config

    IF config.launch_mode:
        RETURN config.launch_mode == "vscode"
    ELSE:
        # No default set - use terminal
        RETURN false
    END IF
END FUNCTION
```

---

## Launch Methods

```pseudocode
FUNCTION launch_config_via_devcontainer_cli(workspace_path):
    # Use workspace-specific config devcontainer (created during init)
    # This is an adjusted copy of global config devcontainer.json
    # It references global Dockerfile but mounts this specific workspace

    SET bitbot_install = get_bitbot_install_dir()
    SET global_config_dir = bitbot_install + "/config-devcontainer"
    SET workspace_config_devcontainer = workspace_path + "/.bitbot/internal/devcontainer.json"

    # Verify workspace config devcontainer exists (created during init)
    IF NOT file_exists(workspace_config_devcontainer):
        ERROR "Config devcontainer.json not found in .bitbot/internal/"
        PRINT "This should have been created during 'bitbot init'"
        PRINT "Try re-initializing: bitbot init"
        EXIT 1
    END IF

    # Verify global config-devcontainer directory exists (for Dockerfile, etc.)
    IF NOT directory_exists(global_config_dir):
        ERROR "Global config-devcontainer not found in BitBot installation"
        PRINT "This should have been created during BitBot installation"
        EXIT 1
    END IF

    # Launch using workspace-specific devcontainer.json
    # The devcontainer.json references global Dockerfile via "dockerFile" or "build.dockerfile"
    # Workspace is already mounted via workspaceMount in devcontainer.json
    # No RO mount = .devcontainer is writable

    EXECUTE "devcontainer up --workspace-folder " + workspace_path + " --config " + workspace_path + "/.bitbot/internal"

    IF exit_code == 0:
        PRINT "[+] Config container launched successfully"
        # Attach to container
        EXECUTE "devcontainer exec --workspace-folder " + workspace_path + " --config " + workspace_path + "/.bitbot/internal tmux new-session -A -s config"
    ELSE:
        ERROR "Failed to launch config container"
        EXIT 1
    END IF
END FUNCTION

FUNCTION launch_config_via_vscode(workspace_path):
    # Launch VS Code with config devcontainer

    PRINT "[>] Launching VS Code in config mode..."
    PRINT "[i] Note: VS Code config mode support is limited in MVP"

    # For MVP, just launch VS Code normally
    # Future: Use devcontainer.json override or specific config
    EXECUTE "code " + workspace_path

    IF exit_code == 0:
        PRINT "[+] VS Code launched"
        PRINT "[i] You may need to manually select config devcontainer"
    ELSE:
        ERROR "Failed to launch VS Code"
        EXIT 1
    END IF
END FUNCTION
```

---

## Git Utilities

Git recommendation and safety check functions are defined in `lib/util/git.md`:

- `recommend_git_push_before_init(workspace_path)` - Recommends git setup, remote, and push with skip options
- `check_git_safety(workspace_path)` - Warns about uncommitted changes and public repo secrets

Both functions provide clear instructions and allow users to skip if needed.

---

## Implementation Notes

**Config Mode Architecture**:
- Uses workspace-specific `.bitbot/internal/devcontainer.json` (adjusted copy of global template)
- This copy references global `config-devcontainer/Dockerfile` and other global resources
- Workspace mounted via `workspaceMount` setting in devcontainer.json (excluding `.bitbot/internal/`)
- Special submounts: `.bitbot/internal/local/.bash_history` → container bash history
- No RO mount for .devcontainer = RW by default
- Can edit workspace .devcontainer files
- Default shell: bash (zsh support in future, see FUTURE_FEATURES.md)

**Key Difference from Work Mode**:
- Work mode:
  - Uses workspace `.devcontainer/devcontainer.json`
  - `.devcontainer/` mounted read-only for security
  - Bash history: `.bitbot/local/.bash_history`
- Config mode:
  - Uses `.bitbot/internal/devcontainer.json` (references global Dockerfile)
  - `.devcontainer/` writable (can be edited)
  - Bash history: `.bitbot/internal/local/.bash_history`
- Both modes exclude `.bitbot/internal/` from workspace mount

**Flags**:
- `--vscode` or `vscode` - Launch in VS Code (overrides default, limited support in MVP)
- `--terminal` or `terminal` - Launch in terminal (overrides default)
- No flag: Uses global config default (set during global init)

**MVP Scope**:
- Single session
- Git push recommendations with skip options (non-blocking)
- Workspace-specific config devcontainer.json (created during init)
- References global config-devcontainer/Dockerfile
- VS Code integration (fully supported via devcontainer CLI)
- Exit: Close VS Code or terminal to finish config mode
- Parallel testing: Open another terminal and run `bitbot work` to test workspace devcontainer while config mode is running

**Future**:
- Template customization
- Multiple config devcontainer variants
- `bitbot stop` command to cleanly stop containers

**Counterpart**: `lib/global/config.md` for global BitBot configuration
