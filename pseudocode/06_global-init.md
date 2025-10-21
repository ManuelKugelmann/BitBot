# Global BitBot Initialization Pseudocode (MVP)

**Component**: Global BitBot Setup
**Implements**: First-time BitBot installation init
**Purpose**: Set up BitBot globally when run from install folder

---

## Overview

```
User runs ./scripts/bitbot (from install folder) → Detect first run → Global init
                                    ↓
                    [Add to PATH | Set BITBOT_HOME | Create ~/.bitbot/]
```

**Decision**: Minimal global setup for MVP
- Add BitBot to PATH (prompt user)
- Set BITBOT_HOME environment variable
- Create ~/.bitbot/ with global config devcontainer template
- Check prerequisites (Docker, etc.)

---

## Global Init Detection

```pseudocode
FUNCTION is_global_init_needed() → boolean:
    # Detect if running from BitBot install folder
    SET current_dir = get_current_directory()
    SET script_dir = directory_of_current_script()

    # Check if CWD is the BitBot install folder
    # (Contains scripts/, pseudocode/, etc.)
    IF current_dir == dirname(script_dir):
        # Running from install folder
        IF NOT file_exists("~/.bitbot/first-run"):
            RETURN true  # First run in install folder → global init
        ELSE:
            # Subsequent run in install folder → could launch global MCP (future)
            RETURN false
        END IF
    END IF

    # Running from elsewhere → workspace mode
    RETURN false
END FUNCTION
```

---

## Main Global Init

```pseudocode
FUNCTION run_global_init():
    CALL show_welcome_banner()

    # Step 1: Prerequisites check
    PRINT ""
    PRINT "[1/3] Checking prerequisites..."
    PRINT ""

    CALL check_prerequisites() → all_ok

    IF NOT all_ok:
        ERROR "Please install missing prerequisites and run again"
        EXIT 1
    END IF

    # Step 2: Create global BitBot folder
    PRINT ""
    PRINT "[2/3] Setting up global BitBot folder..."
    PRINT ""

    CALL setup_global_folder()

    # Step 3: Add to PATH
    PRINT ""
    PRINT "[3/3] Adding BitBot to PATH..."
    PRINT ""

    CALL add_to_path()

    # Mark init complete
    CALL write_file("~/.bitbot/first-run", current_timestamp())

    PRINT ""
    PRINT "[+] Global BitBot setup complete!"
    PRINT ""
    PRINT "You can now run 'bitbot' from anywhere."
    PRINT "Use 'bitbot init' in a project folder to initialize a workspace."
    PRINT ""
END FUNCTION
```

---

## Welcome Banner

```pseudocode
FUNCTION show_welcome_banner():
    PRINT "=============================================="
    PRINT "  BitBot Global Setup"
    PRINT "=============================================="
    PRINT ""
    PRINT "This will set up BitBot on your system."
    PRINT ""
END FUNCTION
```

---

## Prerequisites Check (MVP: Minimal)

```pseudocode
FUNCTION check_prerequisites() → boolean:
    SET all_ok = true

    # Check Docker
    PRINT "Checking Docker..."
    IF command_exists("docker"):
        PRINT "  ✓ Docker installed"

        # Check if running
        EXECUTE "docker ps" → output, exit_code

        IF exit_code == 0:
            PRINT "  ✓ Docker is running"
        ELSE:
            PRINT "  ✗ Docker is not running - please start Docker"
            SET all_ok = false
        END IF
    ELSE:
        PRINT "  ✗ Docker not found"
        PRINT "    Install: https://www.docker.com/products/docker-desktop"
        SET all_ok = false
    END IF

    # Check devcontainer CLI
    PRINT "Checking devcontainer CLI..."
    IF command_exists("devcontainer"):
        PRINT "  ✓ @devcontainers/cli installed"
    ELSE:
        PRINT "  ⚠ @devcontainers/cli not found"
        PRINT "    Install: npm install -g @devcontainers/cli"
        PRINT "    (Required for BitBot to work)"
        SET all_ok = false
    END IF

    # Check Git (optional)
    PRINT "Checking Git..."
    IF command_exists("git"):
        PRINT "  ✓ Git installed"
    ELSE:
        PRINT "  ⚠ Git not found (optional, but recommended)"
    END IF

    RETURN all_ok
END FUNCTION
```

---

## Global Folder Setup

```pseudocode
FUNCTION setup_global_folder():
    SET bitbot_home = "~/.bitbot"

    # Create base directory
    PRINT "Creating ~/.bitbot/..."
    CALL create_directory(bitbot_home)
    PRINT "  ✓ Created ~/.bitbot/"

    # Create global config.json
    PRINT "Creating global config..."
    SET config = {
        "bitbot_install_path": get_bitbot_install_dir(),
        "version": "0.1.0-mvp",
        "created": current_timestamp()
    }

    CALL write_json(bitbot_home + "/config.json", config)
    PRINT "  ✓ Created config.json"

    # Create global config-devcontainer template
    PRINT "Creating global config devcontainer template..."
    CALL setup_config_devcontainer_template(bitbot_home)
    PRINT "  ✓ Created config-devcontainer/"

    PRINT "[+] Global folder ready"
END FUNCTION
```

---

## Config Devcontainer Template Setup

```pseudocode
FUNCTION setup_config_devcontainer_template(bitbot_home):
    SET config_dc_dir = bitbot_home + "/config-devcontainer"

    CALL create_directory(config_dc_dir)

    # Create minimal devcontainer.json
    SET devcontainer_json = {
        "name": "BitBot Config Mode",
        "image": "mcr.microsoft.com/devcontainers/base:alpine",
        "workspaceFolder": "${localEnv:BITBOT_WORKSPACE}",
        "customizations": {
            "vscode": {
                "extensions": [
                    "ms-vscode-remote.remote-containers"
                ]
            }
        },
        "postCreateCommand": "echo 'BitBot config mode ready'",
        "remoteUser": "vscode"
    }

    CALL write_json(config_dc_dir + "/devcontainer.json", devcontainer_json)

    # Note: In future, can add Dockerfile, compose, scripts here
END FUNCTION
```

---

## Add to PATH

```pseudocode
FUNCTION add_to_path():
    SET bitbot_install = get_bitbot_install_dir()
    SET bitbot_scripts = bitbot_install + "/scripts"

    PRINT "BitBot install location: " + bitbot_install
    PRINT ""

    # Detect shell
    SET shell = detect_shell()

    IF shell == "bash":
        SET rc_file = "~/.bashrc"
    ELSE IF shell == "zsh":
        SET rc_file = "~/.zshrc"
    ELSE:
        SET rc_file = "~/.profile"
    END IF

    PRINT "Detected shell: " + shell
    PRINT "Shell config: " + rc_file
    PRINT ""

    CALL prompt_yes_no("Add BitBot to PATH automatically?", "yes") → auto_add

    IF auto_add:
        # Add to shell config
        SET path_line = "\n# BitBot\nexport PATH=\"" + bitbot_scripts + ":$PATH\"\nexport BITBOT_HOME=\"" + bitbot_install + "\"\n"

        CALL append_to_file(rc_file, path_line)

        PRINT "  ✓ Added to " + rc_file
        PRINT ""
        PRINT "[i] Restart your shell or run: source " + rc_file
    ELSE:
        PRINT ""
        PRINT "Manual setup required:"
        PRINT ""
        PRINT "Add these lines to your " + rc_file + ":"
        PRINT ""
        PRINT "  export PATH=\"" + bitbot_scripts + ":$PATH\""
        PRINT "  export BITBOT_HOME=\"" + bitbot_install + "\""
        PRINT ""
    END IF
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION get_bitbot_install_dir() → path:
    # Get absolute path to BitBot installation
    SET script_path = get_absolute_path_of_current_script()
    SET install_dir = dirname(dirname(script_path))  # scripts/ → BitBot/
    RETURN install_dir
END FUNCTION

FUNCTION detect_shell() → shell_name:
    SET shell_path = get_env("SHELL") OR "/bin/bash"
    SET shell_name = basename(shell_path)
    RETURN shell_name
END FUNCTION

FUNCTION current_timestamp() → string:
    RETURN iso8601_timestamp()
END FUNCTION
```

---

## Implementation Notes (MVP)

**Key Behaviors**:
- Runs only when BitBot is executed from install folder first time
- Creates minimal ~/.bitbot/ with config-devcontainer template
- Adds BitBot to PATH (with user confirmation)
- Sets BITBOT_HOME environment variable
- Checks prerequisites (Docker, devcontainer CLI)

**Modular Script Architecture**:
Main entry script (`scripts/bitbot`):
```bash
#!/bin/bash
# Minimal main script - sources appropriate subscript

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect mode: global vs workspace
if [[ "$PWD" == "$BITBOT_ROOT" ]]; then
    # Running from BitBot install folder
    if [[ ! -f ~/.bitbot/first-run ]]; then
        # First run → global init
        source "$SCRIPT_DIR/global/bitbot-init.sh"
        bitbot_global_init "$@"
    else
        # Subsequent runs → future: global MCP launch
        echo "Global MCP compose launch (future feature)"
        echo "For workspace commands, run 'bitbot' from a project folder"
    fi
else
    # Workspace mode - route to workspace commands
    COMMAND="${1:-work}"
    shift || true

    case "$COMMAND" in
        work|config|vscode|init|help|version)
            source "$SCRIPT_DIR/workspace/bitbot-$COMMAND.sh"
            bitbot_$COMMAND "$@"
            ;;
        *)
            echo "Unknown command: $COMMAND"
            source "$SCRIPT_DIR/workspace/bitbot-help.sh"
            bitbot_help
            exit 2
            ;;
    esac
fi
```

Subscript structure (separated by context):
```
scripts/
├── bitbot                       # Main router
├── bitbot.ps1                   # Windows PowerShell wrapper
├── bitbot.bat                   # Windows batch wrapper
├── lib/                         # Shared libraries & universal commands
│   ├── detect.sh                # Workspace detection (02)
│   ├── mode.sh                  # Mode launch helpers (04)
│   ├── helpers.sh               # Common utilities
│   └── bitbot-version.sh        # Universal command
├── global/                      # Global-only commands
│   ├── bitbot-init.sh           # Global initialization (this file)
│   └── bitbot-mcp.sh            # Future: Global MCP compose
└── workspace/                   # Workspace-only commands
    ├── bitbot-work.sh           # Work mode
    ├── bitbot-config.sh         # Config mode
    ├── bitbot-vscode.sh         # VS Code launch
    ├── bitbot-init.sh           # Workspace initialization
    └── bitbot-help.sh           # Workspace help text
```

**Command Context**:
- Universal: `version` (works everywhere)
- Global-only: `init` (global setup), `mcp` (future)
- Workspace-only: `work`, `config`, `vscode`, `init`, `help`

**Benefits of Modular Structure**:
- Each pseudocode file maps to one bash script
- Easier to test individual components
- Clearer separation of concerns
- Can source common utilities
- Smaller, more manageable files

**MVP Simplifications**:
- No template wizard (future feature)
- No MCP service setup (future feature)
- No AI agent config (future feature)
- Minimal devcontainer template (just JSON, no Dockerfile)
- No WSL-specific setup in MVP

**Prerequisites Required**:
- Docker and Docker running
- @devcontainers/cli installed globally

**Prerequisites Optional**:
- Git (recommended)
- VS Code (for `bitbot vscode`)

**Future Enhancements**:
- Template management
- WSL-specific setup (BitBot-Alpine distro)
- MCP service initialization
- AI agent configuration wizard

**Next Steps**:
- User runs `bitbot` from anywhere (now in PATH)
- Use `bitbot init` in project folders to initialize workspaces

---

**Status**: MVP-focused global initialization
**Counterpart**: 02_workspace-detect.md (workspace initialization)
