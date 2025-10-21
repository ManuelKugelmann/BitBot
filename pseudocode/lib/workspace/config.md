# Config Mode Pseudocode (Workspace)

**Component**: Config Mode Command (Workspace Context)
**Script**: `scripts/lib/workspace/bitbot-config.sh`
**Purpose**: Launch config devcontainer (RW .devcontainer) for workspace

---

## Overview

```
bitbot config [vscode] → Validate workspace → Git warning → Launch config devcontainer
```

**Config Mode**: Uses global `~/.bitbot/config-devcontainer/` with workspace mounted (RW .devcontainer)

---

## Main Config Command

```pseudocode
FUNCTION bitbot_config(args):
    # Launch config mode, optionally in VS Code

    SET workspace_path = get_current_directory()

    # Check for vscode modifier
    SET use_vscode = false
    IF "vscode" IN args:
        SET use_vscode = true
    END IF

    # Validate workspace
    IF NOT validate_workspace(workspace_path):
        ERROR "Invalid workspace - run 'bitbot init' first"
        EXIT 4
    END IF

    # Git safety warning (non-blocking)
    CALL check_git_uncommitted(workspace_path) → has_uncommitted

    IF has_uncommitted:
        WARN "[!] Uncommitted changes detected"
        PRINT "    Files modified: " + count_uncommitted_files()
        PRINT "    Recommendation: Commit before infrastructure changes"
        PRINT ""
    END IF

    PRINT "[>] Launching config mode..."

    # Launch config devcontainer
    IF use_vscode:
        CALL launch_config_via_vscode(workspace_path)
    ELSE:
        CALL launch_config_via_devcontainer_cli(workspace_path)
    END IF
END FUNCTION
```

---

## Launch Methods

```pseudocode
FUNCTION launch_config_via_devcontainer_cli(workspace_path):
    # Use global config devcontainer with workspace mounted

    SET config_devcontainer_path = "~/.bitbot/config-devcontainer"
    SET workspace_config_path = workspace_path + "/.bitbot/internal"

    # Check global config devcontainer exists
    IF NOT directory_exists(config_devcontainer_path):
        ERROR "Config devcontainer not found in ~/.bitbot/"
        PRINT "This should have been created during 'bitbot' global init"
        EXIT 1
    END IF

    # Create workspace-specific config if doesn't exist
    IF NOT directory_exists(workspace_config_path):
        CALL create_directory(workspace_config_path)
        # Copy global template, customize for this workspace
        CALL copy_file(config_devcontainer_path + "/devcontainer.json",
                      workspace_config_path + "/devcontainer.json")
    END IF

    # Set environment variable for workspace path
    SET_ENV("BITBOT_WORKSPACE", workspace_path)

    # Launch using devcontainer CLI with global config
    # Config devcontainer.json uses: "workspaceFolder": "${localEnv:BITBOT_WORKSPACE}"
    # No RO mount = .devcontainer is writable

    EXECUTE "devcontainer up --config " + config_devcontainer_path

    IF exit_code == 0:
        PRINT "[+] Config container launched successfully"
        # Attach to container
        EXECUTE "devcontainer exec --config " + config_devcontainer_path + " tmux new-session -A -s config"
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

## Implementation Notes

**Key Difference from Work Mode**:
- Uses global config devcontainer, not workspace's .devcontainer
- Workspace mounted without RO .devcontainer mount = RW by default
- Can edit .devcontainer files

**Modifiers**:
- `vscode` - Launch in VS Code (limited support in MVP)

**MVP Scope**:
- Single session
- Git warnings only (non-blocking)
- Global config devcontainer template
- VS Code support is basic (just launches code)

**Future**:
- Full VS Code config mode support
- Template customization
- Multiple config devcontainer variants

**Counterpart**: `lib/global/config.md` for global BitBot configuration
