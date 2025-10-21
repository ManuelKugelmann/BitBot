# Mode System Pseudocode (MVP: Simplified)

**Component**: Mode Management (Work/Setup)
**Implements**: SPEC-02 (Security Mode System), SPEC-02A (Git Safety - warnings only)
**Purpose**: Launch work or setup devcontainers with different configurations

---

## Overview (MVP Simplified)

```
Command → Select Mode → Git Warning → Launch Devcontainer
                           ↓
              [Work: RO .devcontainer | Setup: RW .devcontainer]
```

**Decision**: Two modes = two devcontainer configurations
- Work: Workspace's `.devcontainer/` (RO .devcontainer mount via bind mount)
- Setup: Global `~/.bitbot/setup-devcontainer/` (no RO mount = RW by default)

---

## Mode Detection

```pseudocode
FUNCTION detect_current_mode() → mode OR NULL:
    # Check environment variable (inside container)
    IF env_var_set("BITBOT_MODE"):
        RETURN get_env("BITBOT_MODE")
    END IF

    # Check from container name (on host)
    SET hostname = get_hostname()

    IF hostname contains "bitbot-work":
        RETURN "work"
    ELSE IF hostname contains "bitbot-setup":
        RETURN "setup"
    ELSE:
        RETURN NULL
    END IF
END FUNCTION
```

---

## Launch Mode (Unified for Work and Setup)

```pseudocode
FUNCTION launch_mode(mode, flags, options):
    # mode = "work" or "setup"

    PRINT "[>] Launching " + mode + " mode"

    # Validate workspace
    IF NOT validate_workspace(WORKSPACE_PATH):
        ERROR "Invalid workspace"
        EXIT 4
    END IF

    # Git safety check (warning only, non-blocking for both modes)
    CALL check_git_uncommitted(WORKSPACE_PATH) → has_uncommitted

    IF has_uncommitted:
        WARN "[!] Uncommitted changes detected"
        PRINT "    Files modified: " + count_uncommitted_files()
        PRINT "    Recommendation: Commit before changes"
        PRINT ""
    END IF

    # Launch appropriate devcontainer
    IF mode == "work":
        # Uses workspace's .devcontainer/
        # - Mounts workspace at /workspace
        # - Adds RO bind mount for /workspace/.devcontainer
        CALL launch_work_devcontainer(WORKSPACE_PATH, flags, options)
    ELSE IF mode == "setup":
        # Uses global ~/.bitbot/setup-devcontainer/
        # - Mounts workspace at /workspace
        # - No RO bind mount = /workspace/.devcontainer is RW by default
        CALL launch_setup_devcontainer(WORKSPACE_PATH, flags, options)
    END IF
END FUNCTION
```

---

## Launch Work Devcontainer

```pseudocode
FUNCTION launch_work_devcontainer(workspace_path, flags, options):
    # Launch workspace's devcontainer with RO .devcontainer

    SET devcontainer_path = workspace_path + "/.devcontainer"

    IF NOT directory_exists(devcontainer_path):
        ERROR "No .devcontainer found. Run 'bitbot init' first."
        EXIT 4
    END IF

    # Use devcontainer CLI with workspace's config
    # devcontainer.json should include RO bind mount for .devcontainer:
    # "mounts": [
    #   "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
    # ]

    CALL devcontainer_up(workspace_path)
END FUNCTION
```

---

## Launch Setup Devcontainer

```pseudocode
FUNCTION launch_setup_devcontainer(workspace_path, flags, options):
    # Launch global setup devcontainer parameterized for this workspace

    SET setup_config_path = "~/.bitbot/setup-devcontainer"

    IF NOT directory_exists(setup_config_path):
        ERROR "Setup devcontainer not found in ~/.bitbot/"
        PRINT "This should have been created during 'bitbot' installation"
        EXIT 1
    END IF

    # Use devcontainer CLI with global setup config
    # Pass workspace path as environment variable for mounting
    SET env_vars = {
        "BITBOT_WORKSPACE": workspace_path
    }

    # Setup devcontainer.json uses:
    # "workspaceFolder": "${localEnv:BITBOT_WORKSPACE}"
    # No RO mount for .devcontainer = writable by default

    CALL devcontainer_up_with_config(setup_config_path, env_vars)
END FUNCTION
```

---

## Git Safety Checks

```pseudocode
FUNCTION check_git_uncommitted(workspace_path) → boolean:
    # Check for uncommitted changes (non-blocking)

    CHANGE_DIR workspace_path

    IF NOT directory_exists(".git"):
        RETURN false  # No git repo
    END IF

    SET command = "git diff-index --quiet HEAD -- 2>/dev/null"
    EXECUTE command

    IF exit_code != 0:
        RETURN true  # Has uncommitted changes
    ELSE:
        RETURN false  # Clean
    END IF
END FUNCTION

FUNCTION count_uncommitted_files() → count:
    # Count uncommitted files for user feedback

    SET command = "git status --porcelain 2>/dev/null | wc -l"
    EXECUTE command → output

    RETURN parse_int(output)
END FUNCTION
```

---

## Implementation Notes (MVP Simplified)

**Key Simplifications**:
- Setup mode is just another devcontainer (no approval flow)
- No `--allow-socket` or `--reason` flags
- No approval tracking or audit logging
- Git warnings only (non-blocking for both modes)
- Unified launch function for both modes

**Mode Differences**:
- **Work**: Uses workspace's `.devcontainer/` + RO bind mount for .devcontainer folder
- **Setup**: Uses global `~/.bitbot/setup-devcontainer/` + no RO mount = RW by default
- Setup devcontainer: AI agent tuned for devcontainer/infrastructure docs

**File Locations**:
- Work config: `<workspace>/.devcontainer/devcontainer.json`
- Setup config: `~/.bitbot/setup-devcontainer/devcontainer.json`
- Both mount workspace at: `/workspace`

**Security (Simplified)**:
- Work mode: `.devcontainer` folder read-only via explicit bind mount
- Setup mode: `.devcontainer` folder writable (no RO mount)
- Both modes: Git warnings for uncommitted changes (non-blocking)
- No docker socket mounting needed (devcontainer CLI handles it)

**User Experience**:
- Simple: `bitbot work` or `bitbot setup`
- No flags required for setup
- Clear mode indication in shell prompt
- Git warnings help prevent accidents

**Future Features** (cut from MVP):
- Approval tracking (`.bitbot/approvals.json`)
- Audit logging (`.bitbot/audit.log`)
- Strict git checks (blocking mode)
- `bitbot done` workflow
- Setup mode approval prompts

**Next Steps**:
- Container launch implementation (03_container-launch.md)
- First-run simplified (06_first-run.md)
