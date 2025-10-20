# Mode System Pseudocode

**Component**: Mode Management (Work/Setup)
**Implements**: SPEC-02 (Security Mode System), SPEC-02A (Git Safety)
**Purpose**: Manage security modes and their restrictions

---

## Overview

```
Command → Mode Selection → Security Checks → Launch Container → Enforce Restrictions
                              ↓
                  [Work Mode | Setup Mode]
```

**Decision**: Two modes (work/setup) via separate containers, no runtime switching

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

## Work Mode Entry

```pseudocode
FUNCTION enter_work_mode(workspace_path, flags, options):
    PRINT "[>] Entering work mode"

    # Validate workspace
    IF NOT validate_workspace(workspace_path):
        ERROR "Invalid workspace"
        EXIT 4
    END IF

    # Git safety check (warning only, not blocking)
    CALL check_git_uncommitted(workspace_path) → has_uncommitted

    IF has_uncommitted:
        WARN "[!] Uncommitted changes detected"
        PRINT "    Files modified: " + count_uncommitted_files()
        PRINT "    Recommendation: Commit before major changes"
        PRINT ""
    END IF

    # Launch work container
    CALL launch_work_mode(flags, options)

    # Log entry
    CALL audit_log("mode_enter", {
        "mode": "work",
        "timestamp": current_iso8601_timestamp(),
        "workspace": workspace_path
    })
END FUNCTION
```

---

## Setup Mode Entry

```pseudocode
FUNCTION enter_setup_mode(workspace_path, flags, options):
    PRINT "[>] Entering setup mode"

    # Validate workspace
    IF NOT validate_workspace(workspace_path):
        ERROR "Invalid workspace"
        EXIT 4
    END IF

    # CRITICAL: Docker socket approval required
    IF NOT flags["--allow-socket"]:
        ERROR "Setup mode requires Docker socket access approval"
        PRINT ""
        PRINT "Usage: bitbot setup --allow-socket --reason \"Why you need it\""
        PRINT ""
        PRINT "Example:"
        PRINT "  bitbot setup --allow-socket --reason \"Adding PostgreSQL service\""
        EXIT 3
    END IF

    # CRITICAL: Reason required for audit trail
    IF NOT options["--reason"] OR options["--reason"] is empty:
        ERROR "Setup mode requires --reason for audit trail"
        EXIT 3
    END IF

    # Git safety check (blocking unless --force)
    CALL check_git_safety_strict(workspace_path, flags) → safe

    IF NOT safe:
        EXIT 3
    END IF

    # Log setup approval
    CALL log_setup_approval(workspace_path, options["--reason"])

    # Launch setup container
    CALL launch_setup_mode(flags, options)

    # Log entry
    CALL audit_log("mode_enter", {
        "mode": "setup",
        "timestamp": current_iso8601_timestamp(),
        "workspace": workspace_path,
        "reason": options["--reason"],
        "docker_socket": true
    })
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

FUNCTION check_git_safety_strict(workspace_path, flags) → boolean:
    # Strict check for setup mode (blocking unless --force)

    CHANGE_DIR workspace_path

    IF NOT directory_exists(".git"):
        WARN "[!] No git repository found"
        PRINT "    Recommendation: Initialize git for safety"
        RETURN true  # Allow but warn
    END IF

    # Check for uncommitted changes
    SET command = "git diff-index --quiet HEAD -- 2>/dev/null"
    EXECUTE command

    IF exit_code != 0:
        # Has uncommitted changes
        ERROR "[X] Uncommitted changes detected"
        PRINT ""
        PRINT "Modified files:"
        EXECUTE "git diff --name-only HEAD" → files
        PRINT files
        PRINT ""
        PRINT "Setup mode modifies infrastructure files."
        PRINT "Please commit your changes first:"
        PRINT ""
        PRINT "  git add ."
        PRINT "  git commit -m \"Description\""
        PRINT ""
        PRINT "Or use --force to proceed anyway (not recommended)"

        IF flags["--force"]:
            WARN "[!] Proceeding with --force despite uncommitted changes"
            RETURN true
        ELSE:
            RETURN false
        END IF
    END IF

    # Check for unpushed commits
    SET command = "git rev-list HEAD --not --remotes 2>/dev/null | wc -l"
    EXECUTE command → unpushed_count

    IF unpushed_count > 0:
        WARN "[!] " + unpushed_count + " unpushed commit(s) detected"
        PRINT "    Recommendation: Push commits before infrastructure changes"
        PRINT "    git push"
        PRINT ""
    END IF

    RETURN true
END FUNCTION
```

---

## Git Checkpoint Creation

```pseudocode
FUNCTION create_git_checkpoint(workspace_path, reason) → checkpoint_id:
    # Create checkpoint before major changes

    CHANGE_DIR workspace_path

    IF NOT directory_exists(".git"):
        RETURN NULL
    END IF

    SET timestamp = current_iso8601_timestamp()
    SET message = "BitBot checkpoint: " + reason + " (" + timestamp + ")"

    # Create stash
    SET command = "git stash push -m \"" + message + "\""
    EXECUTE command

    IF exit_code == 0:
        PRINT "[+] Created checkpoint"
        PRINT "    Restore with: git stash pop"
        RETURN "stash@{0}"
    ELSE:
        WARN "[!] Failed to create checkpoint"
        RETURN NULL
    END IF
END FUNCTION
```

---

## Setup Approval Logging

```pseudocode
FUNCTION log_setup_approval(workspace_path, reason):
    SET timestamp = current_iso8601_timestamp()
    SET workspace_hash = get_workspace_hash(workspace_path)

    CALL check_git_uncommitted(workspace_path) → has_changes
    SET git_status = has_changes ? "uncommitted" : "clean"

    SET approval = {
        "timestamp": timestamp,
        "action": "setup_mode_entry",
        "user": get_current_user(),
        "workspace": workspace_path,
        "workspace_hash": workspace_hash,
        "docker_socket_approved": true,
        "reason": reason,
        "git_status": git_status
    }

    # Log to workspace
    APPEND_JSON approval TO workspace_path + "/.bitbot/logs/approvals.log"

    # Log to global audit
    APPEND_JSON approval TO "~/.bitbot/audit.log"

    PRINT "[i] Approval logged"
END FUNCTION
```

---

## Mode Restrictions Enforcement

```pseudocode
FUNCTION enforce_work_mode_restrictions():
    # Enforced via mount configuration (read-only .devcontainer)
    # No runtime enforcement needed

    # Informational only
    PRINT "[i] Work mode active"
    PRINT "    Infrastructure files: Read-only"
    PRINT "    Source code: Read-write"
    PRINT "    To modify .devcontainer: bitbot setup"
END FUNCTION

FUNCTION enforce_setup_mode_restrictions():
    # Enforced via approval requirements
    # No runtime enforcement needed

    # Informational only
    PRINT "[i] Setup mode active"
    PRINT "    Docker socket: Available"
    PRINT "    Full workspace access: Enabled"
    PRINT "    Changes will be logged"
END FUNCTION
```

---

## Mode Exit (Done Workflow)

```pseudocode
FUNCTION done_workflow():
    # Inside container: Review changes → commit → exit

    PRINT "==================================="
    PRINT "  BitBot Done Workflow"
    PRINT "==================================="
    PRINT ""

    SET mode = detect_current_mode()

    # Show changes
    PRINT "[>] Changes made in this session:"
    PRINT ""

    IF directory_exists(".git"):
        EXECUTE "git status --short"
        PRINT ""

        # Prompt for commit
        CALL prompt_yes_no("Commit these changes?", default="yes") → should_commit

        IF should_commit:
            CALL prompt_commit_message() → message

            EXECUTE "git add ."
            EXECUTE "git commit -m \"" + message + "\""

            IF exit_code == 0:
                PRINT "[+] Changes committed"

                # Prompt for push
                CALL prompt_yes_no("Push to remote?", default="yes") → should_push

                IF should_push:
                    EXECUTE "git push"

                    IF exit_code == 0:
                        PRINT "[+] Pushed to remote"
                    ELSE:
                        WARN "[!] Push failed (you can push manually later)"
                    END IF
                END IF
            ELSE:
                ERROR "[X] Commit failed"
            END IF
        END IF
    ELSE:
        PRINT "No git repository found"
        CALL prompt_yes_no("Exit anyway?", default="yes") → should_exit

        IF NOT should_exit:
            RETURN
        END IF
    END IF

    # Log done
    CALL audit_log("done_workflow", {
        "mode": mode,
        "timestamp": current_iso8601_timestamp()
    })

    PRINT ""
    PRINT "[+] Exiting container..."

    # Exit container
    EXIT 0
END FUNCTION

FUNCTION prompt_commit_message() → message:
    PRINT "Commit message: "
    SET message = read_line_from_stdin()

    IF message is empty:
        SET message = "BitBot session changes"
    END IF

    RETURN message
END FUNCTION
```

---

## Mode Information Display

```pseudocode
FUNCTION show_mode_info():
    SET mode = detect_current_mode()

    IF mode == "work":
        PRINT "╔══════════════════════════════════════╗"
        PRINT "║       BitBot Work Mode               ║"
        PRINT "╠══════════════════════════════════════╣"
        PRINT "║ Workspace:     Read-Write            ║"
        PRINT "║ .devcontainer: Read-Only             ║"
        PRINT "║ Docker socket: Not available         ║"
        PRINT "║ AI agents:     Enabled               ║"
        PRINT "╚══════════════════════════════════════╝"

    ELSE IF mode == "setup":
        PRINT "╔══════════════════════════════════════╗"
        PRINT "║       BitBot Setup Mode              ║"
        PRINT "╠══════════════════════════════════════╣"
        PRINT "║ Workspace:     Full access           ║"
        PRINT "║ .devcontainer: Modifiable            ║"
        PRINT "║ Docker socket: Approved              ║"
        PRINT "║ Changes:       Logged                ║"
        PRINT "╚══════════════════════════════════════╝"

    ELSE:
        PRINT "[i] Not in a BitBot container"
    END IF
END FUNCTION
```

---

## Mode Validation

```pseudocode
FUNCTION validate_mode_requirements(mode, workspace_path) → boolean:
    IF mode == "work":
        # Check .devcontainer exists
        IF NOT directory_exists(workspace_path + "/.devcontainer"):
            ERROR "Work mode requires .devcontainer configuration"
            PRINT "Run 'bitbot init' to set up workspace"
            RETURN false
        END IF

    ELSE IF mode == "setup":
        # Stricter requirements
        IF NOT directory_exists(workspace_path + "/.git"):
            WARN "Setup mode recommended with git repository"
        END IF
    END IF

    RETURN true
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Two separate containers (no runtime mode switching)
- Work mode: Read-only infrastructure, warnings for uncommitted changes
- Setup mode: Requires approval + reason, strict git checks, full logging
- Done workflow: Review → commit → push → exit

**Security**:
- Setup requires explicit `--allow-socket` and `--reason`
- Git safety checks prevent data loss
- All approvals logged with timestamp + reason
- `.bitbot/setup/` never mounted in either mode

**Git Safety**:
- Work mode: Warnings only (non-blocking)
- Setup mode: Blocking unless `--force`
- Checkpoint creation before major changes
- Unpushed commits warned but allowed

**User Experience**:
- Clear mode indicators in prompts
- Helpful error messages with examples
- Recovery instructions when checks fail
- Audit trail for all mode changes

**Next Steps**:
- Implement session management (05_session-management.md)
- Implement first-run wizard (06_first-run.md)
