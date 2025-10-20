# Container Launch Pseudocode

**Component**: Container Launch & Management
**Implements**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes)
**Purpose**: Launch, manage, and attach to work/setup containers

---

## Overview

```
Launch Command → Detect Existing → [Found: Attach | Not Found: Create] → Enter Container
                                           ↓
                           Build Image → Start Container → Setup Environment
```

---

## Launch Work Mode

```pseudocode
FUNCTION launch_work_mode(flags, options):
    PRINT "[>] Launching work mode..."

    # Validate prerequisites
    CALL validate_prerequisites()

    # Get workspace info
    SET workspace_path = WORKSPACE_PATH
    SET workspace_hash = get_workspace_hash(workspace_path)
    SET container_name = "bitbot-work-" + workspace_hash

    # Check if container already exists
    CALL container_exists(container_name) → exists

    IF exists:
        CALL container_is_running(container_name) → running

        IF running:
            PRINT "[i] Work container already running"
            CALL attach_to_container(container_name, flags, options)
        ELSE:
            PRINT "[i] Starting existing work container"
            CALL start_container(container_name)
            CALL attach_to_container(container_name, flags, options)
        END IF
    ELSE:
        # Create new container
        PRINT "[>] Creating work container..."

        # Use devcontainer CLI or fallback to docker
        IF devcontainer_cli_available():
            CALL launch_via_devcontainer_cli(workspace_path, "work", flags, options)
        ELSE:
            CALL launch_via_docker(workspace_path, "work", flags, options)
        END IF

        CALL attach_to_container(container_name, flags, options)
    END IF
END FUNCTION
```

---

## Launch Setup Mode

```pseudocode
FUNCTION launch_setup_mode(flags, options):
    PRINT "[>] Launching setup mode..."

    # Setup mode requires approval
    IF NOT flags["--allow-socket"]:
        ERROR "Setup mode requires --allow-socket flag"
        PRINT "Usage: bitbot setup --allow-socket --reason \"description\""
        EXIT 3
    END IF

    IF NOT options["--reason"]:
        ERROR "Setup mode requires --reason for Docker socket access"
        EXIT 3
    END IF

    # Check git safety
    CALL check_git_safety(WORKSPACE_PATH) → safe

    IF NOT safe AND NOT flags["--force"]:
        ERROR "Uncommitted changes detected. Commit or use --force"
        EXIT 3
    END IF

    # Log approval
    CALL log_setup_approval(options["--reason"])

    # Get workspace info
    SET workspace_path = WORKSPACE_PATH
    SET workspace_hash = get_workspace_hash(workspace_path)
    SET container_name = "bitbot-setup-" + workspace_hash

    # Check if container exists
    CALL container_exists(container_name) → exists

    IF exists:
        CALL container_is_running(container_name) → running

        IF running:
            PRINT "[i] Setup container already running"
            CALL attach_to_container(container_name, flags, options)
        ELSE:
            PRINT "[i] Starting existing setup container"
            CALL start_container(container_name)
            CALL attach_to_container(container_name, flags, options)
        END IF
    ELSE:
        # Create new setup container
        PRINT "[>] Creating setup container..."
        CALL launch_setup_container(workspace_path, flags, options)
        CALL attach_to_container(container_name, flags, options)
    END IF
END FUNCTION
```

---

## Launch via DevContainer CLI

```pseudocode
FUNCTION launch_via_devcontainer_cli(workspace_path, mode, flags, options):
    # Use @devcontainers/cli for standards compliance

    SET devcontainer_path = workspace_path + "/.devcontainer"

    IF NOT directory_exists(devcontainer_path):
        ERROR "No .devcontainer found. Run 'bitbot init' first."
        EXIT 4
    END IF

    # Sync UID/GID (SPEC-02 Section 1.3)
    CALL get_uid_gid() → host_uid, host_gid

    # Build and start container
    SET command = build_devcontainer_command(workspace_path, mode, host_uid, host_gid, flags, options)

    PRINT "[>] Building devcontainer..."
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to launch devcontainer"
        EXIT 1
    END IF

    PRINT "[+] Container launched successfully"
END FUNCTION
```

---

## Launch via Docker

```pseudocode
FUNCTION launch_via_docker(workspace_path, mode, flags, options):
    # Fallback: Direct Docker launch

    SET workspace_hash = get_workspace_hash(workspace_path)
    SET container_name = "bitbot-" + mode + "-" + workspace_hash

    # Get UID/GID
    CALL get_uid_gid() → host_uid, host_gid

    # Build mount configuration
    CALL build_mount_config(workspace_path, mode) → mounts

    # Build environment variables
    CALL build_env_vars(workspace_path, mode) → env_vars

    # Get base image
    SET image = get_base_image(workspace_path, mode)

    # Build docker run command
    SET docker_cmd = [
        "docker", "run",
        "--name", container_name,
        "--user", host_uid + ":" + host_gid,
        "--workdir", "/workspace",
        "--hostname", "bitbot-" + mode,
        "-it",
        "--detach"
    ]

    # Add mounts
    FOR EACH mount IN mounts:
        APPEND "--volume" to docker_cmd
        APPEND mount to docker_cmd
    END FOR

    # Add environment variables
    FOR EACH env_var IN env_vars:
        APPEND "--env" to docker_cmd
        APPEND env_var to docker_cmd
    END FOR

    # Add network
    APPEND "--network" to docker_cmd
    APPEND "bitbot-network" to docker_cmd

    # Add image
    APPEND image to docker_cmd

    # Execute
    PRINT "[>] Starting Docker container..."
    EXECUTE docker_cmd

    IF exit_code != 0:
        ERROR "Failed to start container"
        EXIT 1
    END IF

    PRINT "[+] Container started: " + container_name
END FUNCTION
```

---

## Mount Configuration (SPEC-02 Section 2.1 & 3.1)

```pseudocode
FUNCTION build_mount_config(workspace_path, mode) → mount_list:
    SET mounts = []

    IF mode == "work":
        # Work mode: .devcontainer read-only
        APPEND workspace_path + ":/workspace" to mounts
        APPEND workspace_path + "/.devcontainer:/workspace/.devcontainer:ro" to mounts

        # BitBot state (selective read-write)
        APPEND workspace_path + "/.bitbot/logs:/workspace/.bitbot/logs" to mounts
        APPEND workspace_path + "/.bitbot/sessions:/workspace/.bitbot/sessions" to mounts
        APPEND workspace_path + "/.bitbot/state:/workspace/.bitbot/state" to mounts

        # .bitbot/setup/ is NOT mounted

    ELSE IF mode == "setup":
        # Setup mode: Full workspace access
        APPEND workspace_path + ":/setup/workspace" to mounts

        # Docker socket (with approval)
        APPEND "/var/run/docker.sock:/var/run/docker.sock" to mounts

        # .bitbot/setup/ is NOT mounted
    END IF

    # Global BitBot config (read-only)
    APPEND "~/.bitbot/config:/opt/bitbot/config:ro" to mounts

    RETURN mounts
END FUNCTION
```

---

## Environment Variables

```pseudocode
FUNCTION build_env_vars(workspace_path, mode) → env_list:
    SET env_vars = []

    # BitBot context
    APPEND "BITBOT_CONTAINER=true" to env_vars
    APPEND "BITBOT_MODE=" + mode to env_vars
    APPEND "BITBOT_WORKSPACE=" + workspace_path to env_vars

    # Time sync
    SET timezone = get_host_timezone()
    APPEND "TZ=" + timezone to env_vars

    # Development environment
    IF mode == "work":
        APPEND "REMOTE_CONTAINERS=true" to env_vars
    END IF

    RETURN env_vars
END FUNCTION
```

---

## Image Selection

```pseudocode
FUNCTION get_base_image(workspace_path, mode) → image_name:
    IF mode == "work":
        # Read from .devcontainer/devcontainer.json
        SET devcontainer_json = read_json(workspace_path + "/.devcontainer/devcontainer.json")

        IF devcontainer_json["image"] exists:
            RETURN devcontainer_json["image"]
        ELSE IF devcontainer_json["dockerFile"] exists:
            # Build from Dockerfile
            CALL build_dockerfile(workspace_path + "/.devcontainer")
            RETURN "bitbot-work-custom"
        ELSE:
            ERROR "No image or dockerfile specified in devcontainer.json"
            EXIT 1
        END IF

    ELSE IF mode == "setup":
        # Setup container uses custom image
        RETURN "bitbot-setup:latest"
    END IF
END FUNCTION
```

---

## Attach to Container

```pseudocode
FUNCTION attach_to_container(container_name, flags, options):
    # Check if vscode flag
    IF flags.contains("vscode") OR options["--interface"] == "vscode":
        CALL launch_vscode_into_container(container_name)
        RETURN
    END IF

    # Attach to tmux session inside container
    CALL enter_container_tmux(container_name, options)
END FUNCTION

FUNCTION enter_container_tmux(container_name, options):
    SET session_name = options["--session"] OR "main"

    # Check if tmux session exists
    SET tmux_check = "docker exec " + container_name + " tmux ls 2>/dev/null"
    EXECUTE tmux_check → output

    IF output contains session_name:
        PRINT "[>] Attaching to existing session: " + session_name
        SET attach_cmd = "docker exec -it " + container_name + " tmux attach -t " + session_name
    ELSE:
        PRINT "[>] Creating new session: " + session_name
        SET attach_cmd = "docker exec -it " + container_name + " tmux new-session -s " + session_name
    END IF

    # Execute attach
    EXECUTE attach_cmd
END FUNCTION
```

---

## Container Management

```pseudocode
FUNCTION container_exists(container_name) → boolean:
    SET command = "docker ps -a --filter name=" + container_name + " --format '{{.Names}}'"
    EXECUTE command → output

    RETURN output contains container_name
END FUNCTION

FUNCTION container_is_running(container_name) → boolean:
    SET command = "docker ps --filter name=" + container_name + " --format '{{.Names}}'"
    EXECUTE command → output

    RETURN output contains container_name
END FUNCTION

FUNCTION start_container(container_name):
    SET command = "docker start " + container_name
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to start container: " + container_name
        EXIT 1
    END IF
END FUNCTION

FUNCTION stop_container(container_name):
    PRINT "[>] Stopping container: " + container_name
    SET command = "docker stop " + container_name
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to stop container: " + container_name
        EXIT 1
    END IF

    PRINT "[+] Container stopped"
END FUNCTION

FUNCTION remove_container(container_name):
    PRINT "[>] Removing container: " + container_name
    SET command = "docker rm " + container_name
    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to remove container: " + container_name
        EXIT 1
    END IF

    PRINT "[+] Container removed"
END FUNCTION
```

---

## DevContainer Command Builder

```pseudocode
FUNCTION build_devcontainer_command(workspace_path, mode, uid, gid, flags, options) → command:
    # Determine devcontainer binary (cmd or cli)
    IF platform == "windows" OR platform == "wsl":
        SET devcontainer_bin = "devcontainer.cmd"
    ELSE:
        SET devcontainer_bin = "devcontainer"
    END IF

    SET command = [
        devcontainer_bin,
        "up",
        "--workspace-folder", workspace_path,
        "--remove-existing-container"
    ]

    # Add UID/GID override
    APPEND "--remote-env" to command
    APPEND "LOCAL_WORKSPACE_FOLDER=" + workspace_path to command

    APPEND "--remote-env" to command
    APPEND "BITBOT_UID=" + uid to command

    APPEND "--remote-env" to command
    APPEND "BITBOT_GID=" + gid to command

    APPEND "--remote-env" to command
    APPEND "BITBOT_MODE=" + mode to command

    RETURN command
END FUNCTION
```

---

## Launch VS Code

```pseudocode
FUNCTION launch_vscode_into_container(container_name):
    # Get workspace path from container
    SET inspect_cmd = "docker inspect " + container_name + " --format '{{.Config.Labels.\"devcontainer.local_folder\"}}'"
    EXECUTE inspect_cmd → workspace_path

    IF workspace_path is empty:
        # Fallback: Use mount info
        SET inspect_cmd = "docker inspect " + container_name + " --format '{{json .Mounts}}'"
        EXECUTE inspect_cmd → mounts_json
        PARSE mounts_json to find workspace mount
    END IF

    # Build vscode URI
    SET vscode_uri = "vscode://vscode-remote/attached-container+" + container_name + workspace_path

    PRINT "[>] Launching VS Code..."
    PRINT "    URI: " + vscode_uri

    # Launch VS Code
    IF platform == "windows":
        EXECUTE "cmd.exe /c start " + vscode_uri
    ELSE IF platform == "macos":
        EXECUTE "open " + vscode_uri
    ELSE:
        EXECUTE "code --folder-uri " + vscode_uri
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Prefer @devcontainers/cli for standards compliance
- Fallback to direct Docker if devcontainer CLI unavailable
- Container names: `bitbot-{mode}-{workspace_hash}`
- UID/GID synced from host (SPEC-02 Section 1.3)
- Work mode: `.devcontainer` read-only, `.bitbot/setup/` invisible
- Setup mode: Full workspace access, Docker socket mounted with approval

**Security**:
- Setup mode requires explicit `--allow-socket` and `--reason`
- Git safety check before setup mode
- All approvals logged to audit trail
- `.bitbot/setup/` never mounted in any container

**Error Handling**:
- Validate prerequisites before launch
- Check git safety in setup mode
- Clear errors for missing .devcontainer
- Fail fast if Docker not running

**Next Steps**:
- Implement mode system (04_mode-system.md)
- Implement session management (05_session-management.md)
