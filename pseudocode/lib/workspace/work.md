# Work Mode Pseudocode

**Component**: Work Mode Command
**Script**: `scripts/lib/workspace/bitbot-work.sh`
**Purpose**: Launch work devcontainer (RO .devcontainer)

---

## Overview

```
bitbot work [vscode] → Validate workspace → Git warning → Launch work devcontainer
```

**Work Mode**: Uses workspace's `.devcontainer/` with RO bind mount for .devcontainer

---

## Main Work Command

```pseudocode
FUNCTION bitbot_work(args):
    # Launch work mode, optionally in VS Code

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
        PRINT "    Recommendation: Commit before making changes"
        PRINT ""
    END IF

    PRINT "[>] Launching work mode..."

    # Launch work devcontainer
    IF use_vscode:
        CALL launch_work_via_vscode(workspace_path)
    ELSE:
        CALL launch_work_via_devcontainer_cli(workspace_path)
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

## Implementation Notes

**Modifiers**:
- `vscode` - Launch in VS Code instead of devcontainer CLI

**MVP Scope**:
- Single session (auto-named)
- Git warnings only (non-blocking)
- RO .devcontainer mount via bind mount in devcontainer.json

**Future**:
- Named sessions
- Session resumption
- Other launch methods (tmux, ssh, etc.)
