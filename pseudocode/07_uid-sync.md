# UID/GID Synchronization Pseudocode

**Component**: User ID Synchronization
**Implements**: SPEC-02 Section 1.3 (UID/GID Strategy)
**Purpose**: Sync container user UID/GID with host user for seamless file permissions

---

## Overview

```
Container Launch → Detect Host UID/GID → Pass to Container → Apply in Container
                          ↓
                  [Linux | macOS | Windows/WSL]
```

**Decision**: Synced UID/GID (host UID = container UID)

---

## Host UID/GID Detection

```pseudocode
FUNCTION get_uid_gid() → (uid, gid):
    # Get current user's UID and GID

    IF platform == "linux" OR platform == "macos" OR platform == "wsl":
        # Unix-like systems
        SET uid = execute_get_output("id -u")
        SET gid = execute_get_output("id -g")

        # Validate
        IF NOT is_numeric(uid) OR NOT is_numeric(gid):
            ERROR "Failed to detect UID/GID"
            EXIT 1
        END IF

        RETURN (trim(uid), trim(gid))

    ELSE IF platform == "windows":
        # Windows without WSL: Use default
        WARN "Windows native mode not fully supported"
        WARN "Using default UID/GID (1000:1000)"
        RETURN ("1000", "1000")

    ELSE:
        ERROR "Unsupported platform: " + platform
        EXIT 1
    END IF
END FUNCTION
```

---

## Container User Configuration

```pseudocode
FUNCTION configure_container_user(uid, gid, container_config) → updated_config:
    # Update container config to use synced UID/GID

    IF container_config.type == "docker":
        # Direct Docker launch
        SET container_config.user = uid + ":" + gid

    ELSE IF container_config.type == "devcontainer":
        # DevContainer configuration
        SET container_config.remoteUser = "vscode"  # Or custom user
        SET container_config.updateRemoteUserUID = true

        # Add environment variables for setup scripts
        SET container_config.containerEnv = {
            "BITBOT_HOST_UID": uid,
            "BITBOT_HOST_GID": gid
        }

        # Add to features or postCreateCommand
        SET container_config.postCreateCommand = "sync-uid-gid.sh " + uid + " " + gid

    END IF

    RETURN container_config
END FUNCTION
```

---

## DevContainer UID Sync (devcontainer.json)

```pseudocode
FUNCTION generate_devcontainer_uid_config(uid, gid) → json_config:
    # Generate devcontainer.json fragment for UID sync

    SET config = {
        "remoteUser": "vscode",
        "updateRemoteUserUID": true,
        "containerEnv": {
            "HOST_UID": uid,
            "HOST_GID": gid
        },
        "features": {
            "ghcr.io/devcontainers/features/common-utils": {
                "username": "vscode",
                "uid": uid,
                "gid": gid
            }
        }
    }

    RETURN config
END FUNCTION
```

---

## Docker Run UID Sync

```pseudocode
FUNCTION build_docker_run_with_uid(base_command, uid, gid) → command:
    # Add UID/GID to docker run command

    SET command = base_command

    # Add user flag
    APPEND "--user" to command
    APPEND uid + ":" + gid to command

    # Add environment variables
    APPEND "--env" to command
    APPEND "BITBOT_UID=" + uid to command

    APPEND "--env" to command
    APPEND "BITBOT_GID=" + gid to command

    RETURN command
END FUNCTION
```

---

## Container Entrypoint UID Fixup

```pseudocode
FUNCTION container_entrypoint_uid_sync():
    # Run inside container at startup to fix UID/GID

    # This would be in container's entrypoint script

    IF env_var_set("BITBOT_HOST_UID"):
        SET host_uid = get_env("BITBOT_HOST_UID")
        SET host_gid = get_env("BITBOT_HOST_GID")
        SET current_user = get_env("USER") OR "vscode"

        PRINT "[>] Syncing container user UID/GID..."

        # Get current UID
        SET current_uid = execute_get_output("id -u " + current_user)

        IF current_uid != host_uid:
            PRINT "  [>] Updating " + current_user + " UID: " + current_uid + " → " + host_uid

            # Update user UID/GID
            EXECUTE "usermod -u " + host_uid + " " + current_user
            EXECUTE "groupmod -g " + host_gid + " " + current_user

            # Fix ownership of home directory
            EXECUTE "chown -R " + host_uid + ":" + host_gid + " /home/" + current_user

            PRINT "  ✓ UID/GID synchronized"
        ELSE:
            PRINT "  ✓ UID/GID already synchronized"
        END IF
    END IF
END FUNCTION
```

---

## Permission Validation

```pseudocode
FUNCTION validate_workspace_permissions(workspace_path, uid, gid):
    # Ensure workspace is accessible by container user

    # Check if workspace is readable
    IF NOT is_readable(workspace_path):
        ERROR "Workspace not readable: " + workspace_path
        EXIT 1
    END IF

    # Check if workspace is writable
    IF NOT is_writable(workspace_path):
        WARN "[!] Workspace not writable: " + workspace_path
        WARN "    Container may not be able to modify files"

        # Check ownership
        SET owner = get_file_owner(workspace_path)

        IF owner.uid != uid:
            PRINT ""
            PRINT "Fix with:"
            PRINT "  sudo chown -R " + uid + ":" + gid + " " + workspace_path
            PRINT ""
        END IF
    END IF
END FUNCTION
```

---

## WSL-Specific UID Handling

```pseudocode
FUNCTION get_wsl_uid_gid() → (uid, gid):
    # Get UID/GID in WSL context

    # Check if running in WSL
    IF NOT is_wsl():
        ERROR "Not running in WSL"
        EXIT 1
    END IF

    # Get WSL user UID/GID
    SET uid = execute_get_output("id -u")
    SET gid = execute_get_output("id -g")

    # In WSL, default user is usually 1000:1000
    # But respect actual values

    PRINT "[i] WSL UID/GID: " + uid + ":" + gid

    RETURN (trim(uid), trim(gid))
END FUNCTION

FUNCTION is_wsl() → boolean:
    # Detect if running in WSL

    IF file_exists("/proc/sys/fs/binfmt_misc/WSLInterop"):
        RETURN true
    END IF

    SET kernel = execute_get_output("uname -r")

    IF kernel contains "microsoft" OR kernel contains "WSL":
        RETURN true
    END IF

    RETURN false
END FUNCTION
```

---

## UID/GID Caching

```pseudocode
FUNCTION get_cached_uid_gid() → (uid, gid) OR NULL:
    # Cache UID/GID to avoid repeated lookups

    SET cache_file = "~/.bitbot/cache/uid-gid"

    IF file_exists(cache_file):
        SET content = read_file(cache_file)
        SPLIT content by ":" → uid, gid

        # Validate cache
        SET current_uid = execute_get_output("id -u")

        IF trim(current_uid) == trim(uid):
            # Cache valid
            RETURN (uid, gid)
        ELSE:
            # Cache stale, delete it
            DELETE cache_file
        END IF
    END IF

    RETURN NULL
END FUNCTION

FUNCTION cache_uid_gid(uid, gid):
    # Cache UID/GID for faster lookups

    SET cache_file = "~/.bitbot/cache/uid-gid"
    CALL write_file(cache_file, uid + ":" + gid)
END FUNCTION
```

---

## File Ownership Fix

```pseudocode
FUNCTION fix_workspace_ownership(workspace_path, uid, gid):
    # Fix ownership of workspace files if needed

    PRINT "[>] Checking workspace file ownership..."

    # Count files with wrong ownership
    SET wrong_owner_count = 0

    FOR EACH file IN recursive_list_files(workspace_path):
        SET owner = get_file_owner(file)

        IF owner.uid != uid:
            INCREMENT wrong_owner_count
        END IF
    END FOR

    IF wrong_owner_count > 0:
        PRINT "  [!] Found " + wrong_owner_count + " files with incorrect ownership"
        PRINT ""

        CALL prompt_yes_no("Fix ownership?", default="yes") → should_fix

        IF should_fix:
            PRINT "  [>] Fixing ownership (this may take a while)..."

            IF has_sudo_permission():
                EXECUTE "sudo chown -R " + uid + ":" + gid + " " + workspace_path
                PRINT "  ✓ Ownership fixed"
            ELSE:
                ERROR "sudo permission required to fix ownership"
                EXIT 1
            END IF
        END IF
    ELSE:
        PRINT "  ✓ Ownership correct"
    END IF
END FUNCTION
```

---

## Dockerfile UID Sync Fragment

```pseudocode
FUNCTION generate_dockerfile_uid_sync() → dockerfile_fragment:
    # Generate Dockerfile lines for UID sync

    SET fragment = "
# UID/GID synchronization
ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=vscode

# Create user with specific UID/GID if not exists
RUN if ! id -u ${USERNAME} > /dev/null 2>&1; then \
        groupadd --gid ${USER_GID} ${USERNAME} && \
        useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}; \
    fi

# Update existing user UID/GID
RUN usermod -u ${USER_UID} ${USERNAME} && \
    groupmod -g ${USER_GID} ${USERNAME} && \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}

USER ${USERNAME}
    "

    RETURN fragment
END FUNCTION
```

---

## UID Information Display

```pseudocode
FUNCTION show_uid_info():
    # Display UID/GID information for debugging

    PRINT "UID/GID Information"
    PRINT "==================="
    PRINT ""

    # Host
    CALL get_uid_gid() → host_uid, host_gid
    PRINT "Host User:"
    PRINT "  UID: " + host_uid
    PRINT "  GID: " + host_gid
    PRINT "  User: " + get_current_user()
    PRINT ""

    # Container (if running inside)
    IF is_container():
        SET container_uid = execute_get_output("id -u")
        SET container_gid = execute_get_output("id -g")
        SET container_user = execute_get_output("whoami")

        PRINT "Container User:"
        PRINT "  UID: " + container_uid
        PRINT "  GID: " + container_gid
        PRINT "  User: " + container_user
        PRINT ""

        IF container_uid == host_uid:
            PRINT "✓ UID/GID synchronized"
        ELSE:
            PRINT "✗ UID/GID mismatch"
        END IF
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Host UID/GID detected via `id -u` and `id -g`
- Passed to container via `--user` flag or environment variables
- Container user updated at runtime if needed
- File ownership validated and fixed if necessary

**Platform Support**:
- Linux: Native support
- macOS: Native support
- WSL2: Native support (treat as Linux)
- Windows native: Fallback to 1000:1000 (not recommended)

**Methods**:
1. **Docker run**: Use `--user UID:GID` flag
2. **DevContainer**: Use `updateRemoteUserUID` + features
3. **Runtime fixup**: Entrypoint script updates user UID/GID

**Caching**:
- UID/GID cached in `~/.bitbot/cache/uid-gid`
- Validated on each use (detect user switch)
- Improves performance for repeated launches

**Error Handling**:
- Detect UID/GID lookup failures
- Validate workspace permissions
- Offer to fix ownership issues
- Clear error messages

**Trade-offs**:
- ✅ Seamless file permissions
- ✅ Standard devcontainer practice
- ❌ All modes use same UID (security via mounts instead)

**Next Steps**:
- Integrate with container launch (03_container-launch.md)
- Test across platforms (Linux, macOS, WSL2)
