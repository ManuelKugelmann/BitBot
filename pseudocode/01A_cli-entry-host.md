# CLI Entry Point - Host Pseudocode

**Component**: `bin/bitbot` (Host script)
**Implements**: SPEC-05 (Cross-Platform CLI), SPEC-09 (CLI UX)
**Purpose**: Container management and workspace operations on host system

---

## Overview

```
User Command (Host) → Parse Args → Check First-Run → Detect Workspace → Execute Command
                                           ↓
                        [work | config | vscode | list | stop | init | ...]
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

## Host Command Handling (MVP: 6 Commands)

```pseudocode
FUNCTION handle_host_commands(command, flags, options):
    # Validate Docker prerequisites
    CALL validate_prerequisites()

    # Route to MVP commands
    SWITCH command:
        CASE "" OR "work":
            # Default: launch work mode
            CALL launch_mode("work", flags, options)

        CASE "config":
            # Config mode: different devcontainer with RW .devcontainer
            CALL launch_mode("config", flags, options)

        CASE "vscode":
            CALL launch_vscode(flags, options)

        CASE "init":
            CALL initialize_workspace_command(options)

        CASE "help" OR "-h" OR "--help":
            CALL show_help()

        CASE "version" OR "-v" OR "--version":
            CALL show_version()

        DEFAULT:
            ERROR "Unknown command: " + command
            PRINT "Run 'bitbot help' for available commands"
            EXIT 2
    END SWITCH
END FUNCTION
```

---

## Launch VS Code (MVP)

```pseudocode
FUNCTION launch_vscode(flags, options):
    # Launch VS Code attached to work container

    # Get workspace path
    SET workspace_path = WORKSPACE_PATH

    # Note: devcontainer CLI handles container naming automatically

    # Launch VS Code with devcontainer
    # VS Code will automatically start container if not running
    PRINT "[>] Launching VS Code..."

    # Use devcontainer extension to open workspace
    EXECUTE "code " + workspace_path

    PRINT "[+] VS Code launched"
END FUNCTION
```

---

## Initialize Workspace Command (MVP)

```pseudocode
FUNCTION initialize_workspace_command(options):
    # Initialize workspace in current directory

    SET cwd = get_current_directory()

    # Check if already initialized
    IF directory_exists(cwd + "/.bitbot"):
        ERROR "Workspace already initialized in: " + cwd
        EXIT 1
    END IF

    # Call workspace initialization (from 02_workspace-detect.md)
    CALL initialize_workspace_in(cwd)

    PRINT ""
    PRINT "Next steps:"
    PRINT "  bitbot work      # Launch work mode"
    PRINT "  bitbot vscode    # Launch VS Code"
END FUNCTION
```

---

## Help Display (MVP Simplified)

```pseudocode
FUNCTION show_help():
    PRINT "BitBot - Secure Development Environment Manager (MVP)"
    PRINT ""
    PRINT "Usage: bitbot [command]"
    PRINT ""
    PRINT "Commands:"
    PRINT "  bitbot [work]        Launch work mode (default)"
    PRINT "  bitbot config        Launch config mode (edit .devcontainer)"
    PRINT "  bitbot vscode        Launch VS Code in container"
    PRINT "  bitbot init          Initialize workspace"
    PRINT "  bitbot help          Show this help"
    PRINT "  bitbot version       Show version"
    PRINT ""
    PRINT "Modes:"
    PRINT "  work   - Development work (.devcontainer is read-only)"
    PRINT "  config - Edit .devcontainer and infrastructure"
    PRINT ""
    PRINT "Examples:"
    PRINT "  bitbot               # Launch work mode"
    PRINT "  bitbot work          # Launch work mode"
    PRINT "  bitbot config        # Edit devcontainer configuration"
    PRINT "  bitbot vscode        # Launch VS Code"
    PRINT "  bitbot init          # Initialize workspace"
    PRINT ""
    PRINT "For more info, see: https://docs.bitbot.dev/"
END FUNCTION

FUNCTION show_version():
    PRINT "BitBot MVP v0.1.0"
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

## Implementation Notes (MVP Simplified)

**MVP Scope**:
- 6 commands only: work, config, vscode, init, help, version
- No session management (single session per container)
- No audit logging (future feature)
- No non-interactive mode (future feature)
- CWD-only workspace detection (no parent search)
- Basic error handling only

**Key Simplifications**:
- Removed smart launch (default to `bitbot work`)
- Removed session listing/stopping/kill
- Removed config/mcp/agent/backup/doctor/metadata commands
- Removed audit logging
- CWD-only workspace (no parent directory search)
- Prompt for init if no workspace in CWD

**MVP Commands**:
1. `bitbot` or `bitbot work` - Launch work mode (RO .devcontainer)
2. `bitbot config` - Launch config mode (RW .devcontainer)
3. `bitbot vscode` - Launch VS Code in work container
4. `bitbot init` - Initialize workspace in CWD
5. `bitbot help` - Show help
6. `bitbot version` - Show version

**Key Insight**: Config mode is just another devcontainer with different:
- Config location: Global `~/.bitbot/config-devcontainer/` (not workspace)
- Workspace mount: `/workspace` (no RO .devcontainer mount = RW by default)
- AI agent: Tuned for devcontainer configuration tasks
- Can work on any workspace (parameterized via env var)

**Next Steps**:
- Simplify container entry (01B_cli-entry-container.md)
- Simplify session management (05_session-management.md) ✓
- Simplify first-run (06_first-run.md)
