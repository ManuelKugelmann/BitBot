# DevContainer Launch Pseudocode (MVP: Simplified)

**Component**: DevContainer CLI Wrapper
**Script**: `scripts/lib/util/devcontainer.sh`
**Implements**: SPEC-02 (Security Mode System), SPEC-02A (Git Safety - warnings only)
**Purpose**: Launch work or config devcontainers with different configurations

---

## Overview (MVP Simplified)

```
Command → Select Mode → Git Warning → Launch Devcontainer
                           ↓
              [Work: RO .devcontainer | Config: RW .devcontainer]
```

**Decision**: Two modes = two devcontainer configurations
- Work: Workspace's `.devcontainer/` (RO .devcontainer mount via bind mount)
- Config: Global `~/.bitbot/config-devcontainer/` (no RO mount = RW by default)

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
    ELSE IF hostname contains "bitbot-config":
        RETURN "config"
    ELSE:
        RETURN NULL
    END IF
END FUNCTION
```

---

## Launch Mode (Unified for Work and Config)

```pseudocode
FUNCTION launch_mode(mode, flags, options):
    # mode = "work" or "config"

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
    ELSE IF mode == "config":
        # Uses global ~/.bitbot/config-devcontainer/
        # - Mounts workspace at /workspace
        # - No RO bind mount = /workspace/.devcontainer is RW by default
        CALL launch_config_devcontainer(WORKSPACE_PATH, flags, options)
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

## Launch Config Devcontainer

```pseudocode
FUNCTION launch_config_devcontainer(workspace_path, flags, options):
    # Launch global config devcontainer parameterized for this workspace

    SET config_devcontainer_path = "~/.bitbot/config-devcontainer"

    IF NOT directory_exists(config_devcontainer_path):
        ERROR "Config devcontainer not found in ~/.bitbot/"
        PRINT "This should have been created during 'bitbot' global init"
        EXIT 1
    END IF

    # Use devcontainer CLI with global config devcontainer
    # Pass workspace path as environment variable for mounting
    SET env_vars = {
        "BITBOT_WORKSPACE": workspace_path
    }

    # Config devcontainer.json uses:
    # "workspaceFolder": "${localEnv:BITBOT_WORKSPACE}"
    # No RO mount for .devcontainer = writable by default

    CALL devcontainer_up_with_config(config_devcontainer_path, env_vars)
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

## DevContainer CLI Wrapper Functions

```pseudocode
FUNCTION devcontainer_up(workspace_path):
    # Launch devcontainer using workspace's .devcontainer/

    # Determine devcontainer binary (.cmd on Windows/WSL)
    IF platform == "windows" OR platform == "wsl":
        SET devcontainer_bin = "devcontainer.cmd"
    ELSE:
        SET devcontainer_bin = "devcontainer"
    END IF

    # Build command
    # Note: UID/GID sync handled natively by devcontainer CLI
    # using updateRemoteUserUID and common-utils feature in devcontainer.json
    SET command = [
        devcontainer_bin,
        "up",
        "--workspace-folder", workspace_path,
        "--remove-existing-container",
        "--remote-env", "BITBOT_MODE=work"
    ]

    PRINT "[>] Building and starting devcontainer..."
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to launch devcontainer"
        EXIT 1
    END IF

    PRINT "[+] Devcontainer launched"

    # Attach to container with tmux
    CALL devcontainer_exec_tmux(workspace_path, "work")
END FUNCTION

FUNCTION devcontainer_up_with_config(config_devcontainer_path, env_vars):
    # Launch devcontainer using global config with workspace path as env var

    # Determine devcontainer binary
    IF platform == "windows" OR platform == "wsl":
        SET devcontainer_bin = "devcontainer.cmd"
    ELSE:
        SET devcontainer_bin = "devcontainer"
    END IF

    # Build command with env vars
    # Note: UID/GID sync handled natively by devcontainer CLI
    SET command = [
        devcontainer_bin,
        "up",
        "--config", config_devcontainer_path,
        "--remove-existing-container"
    ]

    # Add environment variables
    APPEND "--remote-env" to command
    APPEND "BITBOT_MODE=config" to command

    FOR EACH key, value IN env_vars:
        APPEND "--remote-env" to command
        APPEND key + "=" + value to command
    END FOR

    PRINT "[>] Building and starting config devcontainer..."
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to launch config devcontainer"
        EXIT 1
    END IF

    PRINT "[+] Config devcontainer launched"

    # Attach to container with tmux
    CALL devcontainer_exec_tmux_with_config(config_devcontainer_path, "config")
END FUNCTION

FUNCTION devcontainer_exec_tmux(workspace_path, session_name):
    # Execute tmux inside devcontainer (attach or create)

    IF platform == "windows" OR platform == "wsl":
        SET devcontainer_bin = "devcontainer.cmd"
    ELSE:
        SET devcontainer_bin = "devcontainer"
    END IF

    SET command = [
        devcontainer_bin,
        "exec",
        "--workspace-folder", workspace_path,
        "tmux", "new-session", "-A", "-s", session_name
    ]

    EXECUTE command
END FUNCTION

FUNCTION devcontainer_exec_tmux_with_config(config_path, session_name):
    # Execute tmux inside config devcontainer

    IF platform == "windows" OR platform == "wsl":
        SET devcontainer_bin = "devcontainer.cmd"
    ELSE:
        SET devcontainer_bin = "devcontainer"
    END IF

    SET command = [
        devcontainer_bin,
        "exec",
        "--config", config_path,
        "tmux", "new-session", "-A", "-s", session_name
    ]

    EXECUTE command
END FUNCTION
```

---

## Implementation Notes (MVP Simplified)

**Key Simplifications**:
- Config mode is just another devcontainer (no approval flow)
- No `--allow-socket` or `--reason` flags
- No approval tracking or audit logging
- Git warnings only (non-blocking for both modes)
- Unified launch function for both modes

**Mode Differences**:
- **Work**: Uses workspace's `.devcontainer/` + RO bind mount for .devcontainer folder
- **Config**: Uses global `~/.bitbot/config-devcontainer/` + no RO mount = RW by default
- Config devcontainer: AI agent tuned for devcontainer/infrastructure docs

**File Locations**:
- Work config: `<workspace>/.devcontainer/devcontainer.json`
- Config config: `~/.bitbot/config-devcontainer/devcontainer.json`
- Both mount workspace at: `/workspace`

**Security (Simplified)**:
- Work mode: `.devcontainer` folder read-only via explicit bind mount
- Config mode: `.devcontainer` folder writable (no RO mount)
- Both modes: Git warnings for uncommitted changes (non-blocking)
- No docker socket mounting needed (devcontainer CLI handles it)

**User Experience**:
- Simple: `bitbot work` or `bitbot config`
- No flags required for config
- Clear mode indication in shell prompt
- Git warnings help prevent accidents

**Future Features** (cut from MVP):
- Approval tracking (`.bitbot/approvals.json`)
- Audit logging (`.bitbot/audit.log`)
- Strict git checks (blocking mode)
- `bitbot done` workflow
- Config mode approval prompts

**UID/GID Handling**:
- DevContainer CLI handles UID/GID synchronization natively
- Use `updateRemoteUserUID: true` in devcontainer.json
- Use `common-utils` feature to set UID/GID automatically
- No manual UID sync needed in bash scripts

**Dependencies**:
- Uses `lib/util/helpers.md` for file/directory operations
- Uses `lib/util/detect.md` for validate_workspace()
- Uses `lib/util/prerequisites.md` for platform detection
