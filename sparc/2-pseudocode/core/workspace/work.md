# Work Mode Pseudocode

**Component**: Work Mode Command
**Script**: `scripts/lib/workspace/bitbot-work.sh`
**Purpose**: Launch work devcontainer (RO .devcontainer)

---

## Overview

```
bitbot work [vscode] → Validate workspace → Git push recommendation → Launch work devcontainer
```

**Work Mode**: Uses workspace's `.devcontainer/` with RO bind mount for .devcontainer

---

## Main Work Command

```pseudocode
FUNCTION bitbot_work(args):
    # Launch work mode, optionally in VS Code

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
        PRINT "[>] Launching work mode in VS Code..."
    ELSE:
        PRINT "[>] Launching work mode in terminal..."
    END IF

    # Launch work devcontainer
    IF use_vscode:
        CALL launch_work_via_vscode(workspace_path)
    ELSE:
        CALL launch_work_via_devcontainer_cli(workspace_path)
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
    SET config_file = bitbot_install + "/global/.bitbot/config.json"

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
FUNCTION launch_work_via_devcontainer_cli(workspace_path):
    # Use @devcontainers/cli to launch work container

    SET devcontainer_path = workspace_path + "/.devcontainer"

    IF NOT directory_exists(devcontainer_path):
        ERROR "No .devcontainer found - run 'bitbot init' first"
        EXIT 4
    END IF

    # Launch using devcontainer CLI
    # The .devcontainer/devcontainer.json should include RO mount:
    # "mounts": ["source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"]

    EXECUTE "devcontainer up --workspace-folder " + workspace_path

    IF exit_code == 0:
        PRINT "[+] Work container launched successfully"
        # Attach to container
        EXECUTE "devcontainer exec --workspace-folder " + workspace_path + " tmux new-session -A -s work"
    ELSE:
        ERROR "Failed to launch work container"
        EXIT 1
    END IF
END FUNCTION

FUNCTION launch_work_via_vscode(workspace_path):
    # Launch VS Code, let devcontainer extension handle container

    PRINT "[>] Launching VS Code..."

    # VS Code will detect .devcontainer and launch container automatically
    EXECUTE "code " + workspace_path

    IF exit_code == 0:
        PRINT "[+] VS Code launched"
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

**Work Mode Architecture**:
- Uses workspace `.devcontainer/devcontainer.json`
- Workspace mounted (excluding `.bitbot/internal/`)
- `.devcontainer/` mounted read-only for security
- Special submounts: `.bitbot/local/.bash_history` → container bash history
- Default shell: bash (zsh support in future, see FUTURE_FEATURES.md)

**Flags**:
- `--vscode` or `vscode` - Launch in VS Code (overrides default)
- `--terminal` or `terminal` - Launch in terminal (overrides default)
- No flag: Uses global config default (set during global init)

**MVP Scope**:
- Single session (auto-named)
- Git push recommendations with skip options (non-blocking)
- RO .devcontainer mount via bind mount in devcontainer.json
- Workspace mount excludes `.bitbot/internal/` directory

**Future**:
- Named sessions
- Session resumption
- Other launch methods (tmux, ssh, etc.)
