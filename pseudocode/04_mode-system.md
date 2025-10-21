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
- Work: `.devcontainer/` (RO .devcontainer mount)
- Setup: `.devcontainer-setup/` (RW .devcontainer mount)

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
        # Uses .devcontainer/ (RO .devcontainer mount)
        CALL launch_devcontainer(WORKSPACE_PATH, ".devcontainer", flags, options)
    ELSE IF mode == "setup":
        # Uses .devcontainer-setup/ (RW .devcontainer mount)
        CALL launch_devcontainer(WORKSPACE_PATH, ".devcontainer-setup", flags, options)
    END IF
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
- Work: `.devcontainer/` with RO mount for `.devcontainer` folder
- Setup: `.devcontainer-setup/` with RW mount for `.devcontainer` folder
- Setup devcontainer: AI agent tuned for devcontainer/infrastructure docs

**Security (Simplified)**:
- Work mode: `.devcontainer` folder read-only via mount config
- Setup mode: `.devcontainer` folder read-write for editing
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
