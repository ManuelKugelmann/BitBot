# CLI Entry Point - Host Pseudocode

**Component**: `bin/bitbot` (Host script)
**Implements**: SPEC-05 (Cross-Platform CLI), SPEC-09 (CLI UX)
**Purpose**: Container management and workspace operations on host system

---

## Overview

```
User Command (Host) → Parse Args → Check First-Run → Detect Workspace → Execute Command
                                           ↓
                        [work | setup | vscode | list | stop | init | ...]
```

**Scope**: Host-side operations only (container management)
**Counterpart**: `01B_cli-entry-container.md` (in-container operations)

---

## Main Entry Point

```pseudocode
FUNCTION main(args):
    # Parse command line arguments
    CALL parse_arguments(args) → command, flags, options

    # Set up error handling
    CALL setup_error_handlers()

    # Check for first-run
    IF NOT file_exists("~/.bitbot/first-run"):
        CALL first_run_wizard()
        RETURN
    END IF

    # Detect workspace (unless command doesn't need it)
    IF command NOT IN ["help", "version", "doctor"]:
        CALL detect_workspace(options) → workspace_path

        IF workspace_path is NULL AND command != "init":
            ERROR "No workspace found. Run 'bitbot init' to create one."
            EXIT 4
        END IF

        # Set global workspace path
        SET WORKSPACE_PATH = workspace_path
    END IF

    # Route to host commands
    CALL handle_host_commands(command, flags, options)
END FUNCTION
```

---

## Argument Parsing

```pseudocode
FUNCTION parse_arguments(args) → (command, flags, options):
    SET command = ""
    SET flags = empty_map
    SET options = empty_map

    # Parse flags and options
    FOR EACH arg IN args:
        IF arg starts_with("--"):
            # Long flag: --flag or --option=value
            IF arg contains "=":
                SPLIT arg by "=" → key, value
                SET options[key] = value
            ELSE:
                SET flags[arg] = true
            END IF
        ELSE IF arg starts_with("-"):
            # Short flag: -f
            SET flags[arg] = true
        ELSE:
            # Positional argument (command)
            IF command is empty:
                SET command = arg
            ELSE:
                # Additional positional args
                APPEND arg to options["args"]
            END IF
        END IF
    END FOR

    RETURN (command, flags, options)
END FUNCTION
```

---

## Host Command Handling

```pseudocode
FUNCTION handle_host_commands(command, flags, options):
    # Validate prerequisites
    CALL validate_prerequisites()

    # Log command
    CALL log_command(command, flags, options, "host")

    # Route command
    SWITCH command:
        CASE "" OR "smart-launch":
            CALL smart_launch(flags, options)

        CASE "work":
            CALL launch_work_mode(flags, options)

        CASE "setup":
            CALL launch_setup_mode(flags, options)

        CASE "vscode":
            CALL launch_vscode(flags, options)

        CASE "list":
            CALL list_sessions(flags, options)

        CASE "stop":
            CALL stop_session(flags, options)

        CASE "kill":
            CALL kill_all_containers(flags, options)

        CASE "init":
            CALL initialize_workspace(flags, options)

        CASE "config":
            CALL configure_bitbot(flags, options)

        CASE "mcp":
            CALL manage_mcp_services(flags, options)

        CASE "agent":
            CALL manage_ai_agents(flags, options)

        CASE "doctor":
            CALL run_diagnostics(flags, options)

        CASE "metadata":
            CALL show_metadata(flags, options)

        CASE "session":
            CALL manage_sessions(flags, options)

        CASE "backup":
            CALL manage_backups(flags, options)

        CASE "template":
            CALL manage_templates(flags, options)

        CASE "help":
            CALL show_help(flags, options)

        CASE "version":
            CALL show_version()

        DEFAULT:
            ERROR "Unknown command: " + command
            PRINT "Run 'bitbot help' for usage"
            EXIT 2
    END SWITCH
END FUNCTION
```

---

## Smart Launch Logic

```pseudocode
FUNCTION smart_launch(flags, options):
    # Smart launch: Resume or create session

    CALL list_detached_sessions() → sessions

    IF length(sessions) == 0:
        # No sessions: start work mode
        PRINT "[>] No active sessions, starting work mode..."
        CALL launch_work_mode(flags, options)

    ELSE IF length(sessions) == 1:
        # One session: auto-attach
        PRINT "[>] Attaching to session: " + sessions[0].name
        CALL attach_session(sessions[0].id)

    ELSE:
        # Multiple sessions: prompt user
        IF flags["--non-interactive"]:
            ERROR "Multiple sessions found. Specify session with --session"
            EXIT 1
        END IF

        CALL prompt_session_choice(sessions) → chosen_session

        IF chosen_session == "new":
            CALL launch_work_mode(flags, options)
        ELSE:
            CALL attach_session(chosen_session.id)
        END IF
    END IF
END FUNCTION
```

---

## Session Listing

```pseudocode
FUNCTION list_detached_sessions() → session_list:
    # List all detached sessions for current workspace

    SET workspace_hash = get_workspace_hash(WORKSPACE_PATH)
    SET work_container = "bitbot-work-" + workspace_hash
    SET setup_container = "bitbot-setup-" + workspace_hash

    SET sessions = empty_list

    # Check work container
    IF container_exists(work_container) AND container_is_running(work_container):
        SET work_sessions = list_tmux_sessions_in_container(work_container)

        FOR EACH session IN work_sessions:
            IF NOT session.attached:
                SET session.container = work_container
                SET session.mode = "work"
                APPEND session to sessions
            END IF
        END FOR
    END IF

    # Check setup container
    IF container_exists(setup_container) AND container_is_running(setup_container):
        SET setup_sessions = list_tmux_sessions_in_container(setup_container)

        FOR EACH session IN setup_sessions:
            IF NOT session.attached:
                SET session.container = setup_container
                SET session.mode = "setup"
                APPEND session to sessions
            END IF
        END FOR
    END IF

    RETURN sessions
END FUNCTION
```

---

## Launch VS Code

```pseudocode
FUNCTION launch_vscode(flags, options):
    # Launch VS Code attached to container

    SET mode = options["mode"] OR "work"

    # Get container name
    SET workspace_hash = get_workspace_hash(WORKSPACE_PATH)
    SET container_name = "bitbot-" + mode + "-" + workspace_hash

    # Check if container exists
    IF NOT container_exists(container_name):
        PRINT "[>] Container not running, starting " + mode + " mode..."
        CALL launch_work_mode(flags, options)  # or launch_setup_mode
        # Container will be created, continue
    END IF

    # Launch VS Code
    CALL launch_vscode_into_container(container_name)
END FUNCTION
```

---

## Container Management Commands

```pseudocode
FUNCTION stop_session(flags, options):
    # Stop current session

    SET session_name = options["--session"]

    IF session_name is NULL:
        ERROR "Please specify session with --session <name>"
        EXIT 2
    END IF

    # Find session
    CALL list_detached_sessions() → sessions

    SET found = NULL
    FOR EACH session IN sessions:
        IF session.name == session_name:
            SET found = session
            BREAK
        END IF
    END FOR

    IF found is NULL:
        ERROR "Session not found: " + session_name
        EXIT 1
    END IF

    # Kill session
    PRINT "[>] Stopping session: " + session_name
    CALL kill_tmux_session(found.container, session_name)
    PRINT "[+] Session stopped"
END FUNCTION

FUNCTION kill_all_containers(flags, options):
    # Stop all BitBot containers for workspace

    SET workspace_hash = get_workspace_hash(WORKSPACE_PATH)

    PRINT "[>] Stopping all BitBot containers..."

    # Stop work container
    SET work_container = "bitbot-work-" + workspace_hash
    IF container_exists(work_container):
        CALL stop_container(work_container)
    END IF

    # Stop setup container
    SET setup_container = "bitbot-setup-" + workspace_hash
    IF container_exists(setup_container):
        CALL stop_container(setup_container)
    END IF

    PRINT "[+] All containers stopped"
END FUNCTION
```

---

## Help Display

```pseudocode
FUNCTION show_help(flags, options):
    PRINT "BitBot - Secure Development Environment Manager"
    PRINT ""
    PRINT "Usage: bitbot [command] [flags]"
    PRINT ""
    PRINT "Container Management:"
    PRINT "  bitbot               Smart launch (resume or new session)"
    PRINT "  bitbot work          Launch work mode"
    PRINT "  bitbot setup         Launch setup mode (requires approval)"
    PRINT "  bitbot vscode        Launch VS Code"
    PRINT "  bitbot list          List active sessions"
    PRINT "  bitbot stop          Stop session"
    PRINT "  bitbot kill          Stop all containers"
    PRINT ""
    PRINT "Workspace:"
    PRINT "  bitbot init          Initialize workspace"
    PRINT "  bitbot metadata      Show workspace metadata"
    PRINT "  bitbot template      Manage templates"
    PRINT ""
    PRINT "Configuration:"
    PRINT "  bitbot config        Interactive configuration"
    PRINT "  bitbot mcp           Manage MCP services"
    PRINT "  bitbot agent         Manage AI agents"
    PRINT ""
    PRINT "Utilities:"
    PRINT "  bitbot doctor        Run diagnostics"
    PRINT "  bitbot backup        Manage backups"
    PRINT "  bitbot help          Show this help"
    PRINT "  bitbot version       Show version"
    PRINT ""
    PRINT "Flags:"
    PRINT "  --non-interactive    No prompts (for automation)"
    PRINT "  --session <name>     Target specific session"
    PRINT ""
    PRINT "Examples:"
    PRINT "  bitbot work                              # Start work mode"
    PRINT "  bitbot setup --allow-socket --reason \"...\"  # Setup mode"
    PRINT "  bitbot vscode                            # Launch VS Code"
    PRINT "  bitbot stop --session 2025-10-20_14-30   # Stop session"
    PRINT ""
    PRINT "Documentation: https://docs.bitbot.dev/"
END FUNCTION

FUNCTION show_version():
    SET version = read_file("~/.bitbot/VERSION") OR "unknown"
    PRINT "BitBot version " + version
END FUNCTION
```

---

## Error Handling

```pseudocode
FUNCTION setup_error_handlers():
    # Trap signals
    TRAP SIGINT:
        PRINT "\n[!] Interrupted by user"
        CALL cleanup()
        EXIT 130

    TRAP SIGTERM:
        PRINT "\n[!] Terminated"
        CALL cleanup()
        EXIT 143

    TRAP ERR:
        PRINT "[X] Error on line " + LINE_NUMBER
        CALL cleanup()
        EXIT 1
END FUNCTION

FUNCTION cleanup():
    # Clean up temporary files
    IF temp_dir exists:
        REMOVE temp_dir
    END IF

    # Release locks
    CALL release_lock()
END FUNCTION
```

---

## Validation Functions

```pseudocode
FUNCTION validate_prerequisites():
    # Check Docker
    IF NOT command_exists("docker"):
        ERROR "Docker not found. Install: https://docker.com"
        EXIT 1
    END IF

    # Check Docker running
    IF NOT docker_is_running():
        ERROR "Docker is not running. Start Docker Desktop."
        EXIT 1
    END IF

    # Check Docker Compose
    IF NOT docker_compose_v2_available():
        ERROR "Docker Compose v2 not found"
        EXIT 1
    END IF

    RETURN true
END FUNCTION

FUNCTION docker_is_running() → boolean:
    EXECUTE "docker ps" → output
    RETURN exit_code == 0
END FUNCTION

FUNCTION docker_compose_v2_available() → boolean:
    EXECUTE "docker compose version" → output
    RETURN exit_code == 0
END FUNCTION
```

---

## Logging & Audit

```pseudocode
FUNCTION log_command(command, flags, options, context):
    SET timestamp = current_iso8601_timestamp()
    SET log_entry = {
        "timestamp": timestamp,
        "command": command,
        "flags": flags,
        "options": options,
        "context": context,
        "user": get_current_user(),
        "workspace": WORKSPACE_PATH
    }

    APPEND_JSON log_entry TO "~/.bitbot/audit.log"
END FUNCTION

FUNCTION audit_log(action, details):
    SET timestamp = current_iso8601_timestamp()
    SET entry = timestamp + " " + action + " " + JSON_stringify(details)

    APPEND entry TO WORKSPACE_PATH + "/.bitbot/logs/audit.log"
END FUNCTION
```

---

## Exit Codes

```pseudocode
# Standard exit codes (SPEC-09 C5)
EXIT_SUCCESS = 0           # Command succeeded
EXIT_ERROR = 1             # Generic error
EXIT_USAGE_ERROR = 2       # Invalid command/arguments
EXIT_SECURITY_FAILED = 3   # Security check failed
EXIT_NOT_INITIALIZED = 4   # Workspace not initialized
EXIT_LOCK_FAILED = 5       # Could not acquire lock
```

---

## Implementation Notes

**Key Decisions**:
- Host-only script (no container command handling)
- First-run detection and wizard launch
- Workspace detection required for most commands
- All container management operations
- Smart launch with session resumption
- Comprehensive help and validation

**Command Categories**:
- Container management: work, setup, vscode, list, stop, kill
- Workspace: init, metadata, template
- Configuration: config, mcp, agent
- Utilities: doctor, backup, help, version

**Error Handling**:
- Trap SIGINT/SIGTERM for graceful cleanup
- Validate prerequisites before operations
- Clear error messages with exit codes
- Lock mechanism prevents concurrent operations

**Next Steps**:
- Implement container script (01B_cli-entry-container.md)
- Separate installation and PATH setup
- Platform-specific launchers (Windows .ps1, etc.)
