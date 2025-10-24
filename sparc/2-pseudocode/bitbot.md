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

    # Detect context: global (install folder) vs workspace (project folder)
    SET bitbot_install = get_bitbot_install_dir()
    SET cwd = get_current_directory()

    IF cwd == bitbot_install:
        # GLOBAL CONTEXT: Running from BitBot install folder
        IF NOT file_exists(bitbot_install + "/config.json"):
            # First run - no config.json → run global init
            CALL run_global_init()  # From lib/global/init.md
            RETURN
        ELSE:
            # Subsequent run from install folder → validate environment
            CALL validate_global_environment()  # From lib/global/init.md
            RETURN
        END IF
    ELSE:
        # WORKSPACE CONTEXT: Running from project folder

        # Check if workspace is initialized
        IF NOT directory_exists(cwd + "/.bitbot"):
            # Workspace not initialized
            IF command == "" OR command == "work":
                # Running bare "bitbot" or "bitbot work" in uninitialized workspace
                # Offer to initialize
                PRINT "[!] Workspace not initialized in: " + cwd
                PRINT ""
                CALL prompt_yes_no("Initialize workspace now?", "yes") → should_init

                IF should_init:
                    CALL initialize_workspace_in(cwd)  # From lib/workspace/init.md
                    PRINT ""
                    PRINT "Workspace initialized! Run 'bitbot work' to start."
                    RETURN
                ELSE:
                    PRINT ""
                    PRINT "To initialize later, run: bitbot init"
                    EXIT 4
                END IF
            ELSE IF command != "init" AND command NOT IN ["help", "version"]:
                # Other commands require initialized workspace
                ERROR "Workspace not initialized. Run 'bitbot init' first."
                EXIT 4
            END IF
        END IF

        # Set global workspace path
        SET WORKSPACE_PATH = cwd
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
    # Validate prerequisites (from lib/util/prerequisites.md)
    # This checks Docker, DevContainer CLI, and platform-specific requirements
    CALL validate_prerequisites(command)

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
    PRINT "  bitbot work      # Launch work mode (uses your default: terminal or VS Code)"
    PRINT "  bitbot config    # Edit .devcontainer configuration"
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
    PRINT "Flags:"
    PRINT "  --vscode             Launch in VS Code (overrides default)"
    PRINT "  --terminal           Launch in terminal (overrides default)"
    PRINT ""
    PRINT "Examples:"
    PRINT "  bitbot               # Launch work mode (uses default from global config)"
    PRINT "  bitbot work          # Launch work mode (uses default)"
    PRINT "  bitbot work --vscode # Launch work mode in VS Code"
    PRINT "  bitbot config        # Launch config mode (uses default)"
    PRINT "  bitbot init          # Initialize workspace"
    PRINT ""
    PRINT "Note: Default launch mode (terminal/vscode) is set during global init."
    PRINT "      Use --vscode or --terminal flags to override the default."
    PRINT ""
    PRINT "For more info, see: https://docs.bitbot.dev/"
END FUNCTION

FUNCTION show_version():
    # Show version and comprehensive dependency status
    # (calls show_doctor() from lib/util/prerequisites.md)

    PRINT "BitBot MVP v0.1.0"
    PRINT ""

    # Show full dependency status
    CALL show_doctor()
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
# NOTE: Prerequisite validation moved to lib/util/prerequisites.md
# See that file for comprehensive dependency checking including:
# - Docker (with auto-start)
# - DevContainer CLI detection and installation
# - VS Code extension check
# - WSL Docker integration
# - Doctor command for dependency status
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

**Modular Script Implementation**:
Main script (`bitbot` in install root) routes to global or workspace commands:
```bash
#!/bin/bash
# Main entry - routes to global or workspace commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$SCRIPT_DIR"  # bitbot script is in install root

# Detect context: global (install folder) vs workspace (project folder)
if [[ "$PWD" == "$BITBOT_ROOT" ]]; then
    # Running from BitBot install folder → global context
    if [[ ! -f "$BITBOT_ROOT/config.json" ]]; then
        # First run - no config.json → global init
        source "$BITBOT_ROOT/lib/global/init.sh"
        run_global_init "$@"
    else
        # Subsequent runs from install folder → validate environment
        source "$BITBOT_ROOT/lib/global/init.sh"
        validate_global_environment
        echo ""
        echo "To use BitBot, navigate to a project and run:"
        echo "  cd ~/my-project"
        echo "  bitbot init    # Initialize workspace"
        echo "  bitbot work    # Start working"
    fi
else
    # Workspace context - route to workspace commands
    COMMAND="${1:-work}"  # Default to work
    shift || true

    # Check if workspace is initialized
    if [[ ! -d "$PWD/.bitbot" ]]; then
        # Workspace not initialized
        if [[ "$COMMAND" == "work" ]] || [[ -z "$COMMAND" ]]; then
            # Offer to initialize
            echo "[!] Workspace not initialized in: $PWD"
            echo ""
            read -p "Initialize workspace now? (Y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                source "$BITBOT_ROOT/lib/workspace/init.sh"
                initialize_workspace_in "$PWD"
                echo ""
                echo "Workspace initialized! Run 'bitbot work' to start."
                exit 0
            else
                echo ""
                echo "To initialize later, run: bitbot init"
                exit 4
            fi
        elif [[ "$COMMAND" != "init" ]] && [[ "$COMMAND" != "help" ]] && [[ "$COMMAND" != "version" ]]; then
            echo "ERROR: Workspace not initialized. Run 'bitbot init' first."
            exit 4
        fi
    fi

    case "$COMMAND" in
        work|config|vscode|init)
            source "$BITBOT_ROOT/lib/workspace/$COMMAND.sh"
            bitbot_$COMMAND "$@"
            ;;
        help|--help|-h)
            source "$BITBOT_ROOT/lib/workspace/help.sh"
            bitbot_help
            ;;
        version|--version|-v)
            source "$BITBOT_ROOT/lib/util/version.sh"
            bitbot_version
            ;;
        *)
            echo "Unknown command: $COMMAND"
            source "$BITBOT_ROOT/lib/workspace/help.sh"
            bitbot_help
            exit 2
            ;;
    esac
fi
```

Script structure (bitbot in install root, organized under lib/):
```
{INSTALL_BASE_PATH}/bitbot/
├── bitbot                       # Main router (bash script)
├── bitbot.ps1                   # Windows wrapper
├── bitbot.bat                   # Windows wrapper
├── config.json                  # Created during first run
├── config-devcontainer/         # Config mode devcontainer
│   ├── devcontainer.json
│   └── Dockerfile
├── devcontainer-template/       # Base template for workspace .devcontainer
│   ├── devcontainer.json        # Minimal template with BitBot defaults
│   └── Dockerfile               # Base Alpine/Ubuntu image
└── lib/
    ├── global/                  # Global commands (from install folder)
    │   └── init.sh              # First-run setup + environment validation
    ├── workspace/               # Workspace commands (from projects)
    │   ├── work.sh              # Work mode
    │   ├── config.sh            # Config mode
    │   ├── vscode.sh            # VS Code launch
    │   ├── init.sh              # Workspace init
    │   └── help.sh              # Workspace help text
    └── util/                    # Shared utilities
        ├── prerequisites.sh     # Dependency checking
        ├── version.sh           # Universal: Version
        └── helpers.sh           # Common utilities
```

**Pseudocode to Script Mapping**:
- `bitbot.md` (this file) → `bitbot` (main router in install root)
- `lib/global/init.md` → `lib/global/init.sh` (first run + environment validation)
- `lib/workspace/init.md` → `lib/workspace/init.sh` (workspace initialization)
- `lib/workspace/work.md` → `lib/workspace/work.sh` (work mode)
- `lib/workspace/config.md` → `lib/workspace/config.sh` (config mode)
- `lib/util/prerequisites.md` → `lib/util/prerequisites.sh` (dependency checking)

**Context Detection**:
- **Global context**: Running `bitbot` from install folder
  - First run (no config.json): Runs global init
  - Subsequent runs: Validates environment, shows usage
- **Workspace context**: Running `bitbot` from project folder
  - Uninitialized (.bitbot/ missing): Prompts to initialize
  - Initialized: Bare `bitbot` defaults to `bitbot work`
  - Routes to workspace commands: work, config, vscode, init, help, version

**Core Commands**:
1. `bitbot` or `bitbot work` - Launch work mode (protected .devcontainer)
2. `bitbot config` - Launch config mode (editable .devcontainer)
3. `bitbot vscode` - Launch VS Code
4. `bitbot init` - Initialize workspace
5. `bitbot help` - Show help
6. `bitbot version` - Show version
