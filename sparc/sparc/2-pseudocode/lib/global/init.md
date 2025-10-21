# Global BitBot Initialization Pseudocode (MVP)

**Component**: Global BitBot Setup
**Implements**: First-time BitBot installation init
**Purpose**: Set up BitBot globally when run from install folder

---

## Overview

```
User runs ./bitbot (from install folder) → Detect first run → Global init
                                    ↓
                    [Add to PATH | Set BITBOT_HOME | Create config.json in install folder]
```

**Decision**: Minimal global setup for MVP
- Add BitBot to PATH (prompt user)
- Set BITBOT_HOME environment variable
- Create config.json in install folder (serves as init marker)
- Check prerequisites (Docker, etc.)
- Portable design: No ~/.bitbot/ directory, everything in install folder

---

## Global Init Detection

```pseudocode
FUNCTION is_global_init_needed() → boolean:
    # Check if global initialization is needed based on config file
    # Config file is in the BitBot install folder, not ~/.bitbot/

    SET bitbot_install = get_bitbot_install_dir()
    SET config_file = bitbot_install + "/config.json"

    IF NOT file_exists(config_file):
        RETURN true  # No config → need global init
    END IF

    RETURN false  # Config exists → already initialized
END FUNCTION
```

---

## Global Environment Validation

```pseudocode
FUNCTION validate_global_environment() → boolean:
    # Validate PATH and BITBOT_HOME are set correctly
    # Handles portable installation - detects if folder was moved
    # Called by ALL global commands

    SET bitbot_install = get_bitbot_install_dir()
    SET path_ok = false
    SET env_ok = false
    SET moved = false

    # Check if BitBot is in PATH
    EXECUTE "command -v bitbot" → bitbot_in_path, exit_code
    IF exit_code == 0:
        # Found in PATH - check if it's this installation
        SET resolved_path = resolve_symlink(bitbot_in_path)
        SET expected_path = bitbot_install + "/bitbot"

        IF resolved_path == expected_path:
            SET path_ok = true
        ELSE:
            # Different BitBot installation in PATH
            SET path_ok = false
        END IF
    END IF

    # Check BITBOT_HOME environment variable
    SET bitbot_home_env = get_env("BITBOT_HOME")
    IF bitbot_home_env == bitbot_install:
        SET env_ok = true
    ELSE IF bitbot_home_env != "" AND bitbot_home_env != bitbot_install:
        # Installation was moved!
        SET moved = true
    END IF

    # If both OK, return success
    IF path_ok AND env_ok:
        RETURN true
    END IF

    # Something is wrong - offer to fix
    PRINT ""

    IF moved:
        PRINT "[!] BitBot installation moved:"
        PRINT "    Was: " + bitbot_home_env
        PRINT "    Now: " + bitbot_install
        PRINT ""
    ELSE:
        PRINT "[!] BitBot environment not configured correctly:"
        PRINT ""
    END IF

    IF NOT path_ok:
        PRINT "  ✗ BitBot not in PATH (or wrong installation)"
    END IF

    IF NOT env_ok:
        IF bitbot_home_env == "":
            PRINT "  ✗ BITBOT_HOME not set"
        ELSE:
            PRINT "  ✗ BITBOT_HOME points to: " + bitbot_home_env
            PRINT "    Current location: " + bitbot_install
        END IF
    END IF

    PRINT ""
    CALL prompt_yes_no("Update shell configuration now?", "yes") → should_fix

    IF should_fix:
        CALL add_to_path()  # Will update PATH and BITBOT_HOME
        PRINT ""
        PRINT "[i] Please reload your shell: source ~/.bashrc (or ~/.zshrc)"
        PRINT ""
        RETURN true
    ELSE:
        PRINT ""
        PRINT "[!] Environment not updated. Some commands may not work correctly."
        PRINT ""
        RETURN false
    END IF
END FUNCTION
```

---

## Main Global Init (First-Run)

```pseudocode
FUNCTION run_global_init():
    # First-time setup - creates config.json, sets up PATH/env
    # Uses config.json as init marker

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

    # Step 2: Create config.json in install folder
    PRINT ""
    PRINT "[2/3] Creating configuration..."
    PRINT ""

    CALL create_global_config()

    # Step 3: Add to PATH and set BITBOT_HOME
    PRINT ""
    PRINT "[3/3] Adding BitBot to PATH..."
    PRINT ""

    CALL add_to_path()

    PRINT ""
    PRINT "[+] Global BitBot setup complete!"
    PRINT ""
    PRINT "Reload your shell to use 'bitbot' from anywhere:"
    PRINT "  $ source ~/.bashrc  (or ~/.zshrc)"
    PRINT ""
    PRINT "Then initialize a workspace:"
    PRINT "  $ cd ~/my-project"
    PRINT "  $ bitbot init"
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

## Create Global Config

```pseudocode
FUNCTION create_global_config():
    # Create config.json in BitBot install folder
    SET bitbot_install = get_bitbot_install_dir()
    SET config_file = bitbot_install + "/config.json"

    # Ask user preferences
    PRINT ""

    # Check if VS Code is installed
    SET vscode_installed = command_exists("code")

    IF vscode_installed:
        PRINT "Choose default launch mode for BitBot workspaces:"
        PRINT "  • Terminal: Faster, lightweight, tmux-based (good for servers, CLI workflows)"
        PRINT "  • VS Code: Full IDE experience with GUI (good for local development)"
        PRINT ""

        SET choices = ["Terminal", "VS Code"]
        CALL prompt_choice("Select default launch mode:", choices, 1) → mode_choice  # Default to VS Code (index 1)

        # Map choice to config value
        IF mode_choice == 0:
            SET launch_mode = "terminal"
        ELSE:
            SET launch_mode = "vscode"
        END IF
    ELSE:
        # VS Code not installed - only offer terminal
        PRINT "[i] VS Code not detected on this system"
        PRINT "    Default launch mode will be set to: Terminal"
        PRINT ""
        PRINT "    To use VS Code integration later:"
        PRINT "      1. Install VS Code: https://code.visualstudio.com/"
        PRINT "      2. Edit {INSTALL_BASE_PATH}/bitbot/config.json"
        PRINT "      3. Set \"launch_mode\": \"vscode\""
        PRINT ""

        SET launch_mode = "terminal"
    END IF

    # Create config
    SET config = {
        "version": "0.1.0-mvp",
        "created": current_timestamp(),
        "updated": current_timestamp(),
        "launch_mode": launch_mode,
        "skip_push_recommendation": false,
        "skip_safety_checks": false
    }

    CALL write_json(config_file, config)

    PRINT ""
    PRINT "  ✓ Created config.json"
    PRINT "  ✓ Default mode: " + (launch_mode == "vscode" ? "VS Code" : "Terminal")
    PRINT "[+] Configuration complete"
END FUNCTION
```

---

## Add to PATH

```pseudocode
FUNCTION add_to_path():
    SET bitbot_install = get_bitbot_install_dir()

    PRINT "BitBot install location: " + bitbot_install
    PRINT ""

    # Detect platform
    SET is_wsl = detect_wsl()

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
    IF is_wsl:
        PRINT "Detected platform: WSL"
    END IF
    PRINT "Shell config: " + rc_file
    PRINT ""

    CALL prompt_yes_no("Add BitBot to PATH automatically?", "yes") → auto_add

    IF auto_add:
        # Update WSL shell config
        CALL update_wsl_shell_config(rc_file, bitbot_install)

        # If WSL, also update Windows environment
        IF is_wsl:
            PRINT ""
            CALL update_windows_environment(bitbot_install)
        END IF

        PRINT ""
        PRINT "[i] Restart your shell or run: source " + rc_file
    ELSE:
        PRINT ""
        PRINT "Manual setup required:"
        PRINT ""
        PRINT "WSL shell (" + rc_file + "):"
        PRINT "  export PATH=\"[INSTALLPATH]:$PATH\""
        PRINT "  export BITBOT_HOME=\"[INSTALLPATH]\""

        IF is_wsl:
            SET windows_path = convert_wsl_to_windows_path(bitbot_install)
            PRINT ""
            PRINT "Windows environment (run in PowerShell):"
            PRINT "  [Environment]::SetEnvironmentVariable('BITBOT_HOME', '[WINDOWS_INSTALLPATH]', 'User')"
            PRINT "  $path = [Environment]::GetEnvironmentVariable('Path', 'User')"
            PRINT "  [Environment]::SetEnvironmentVariable('Path', '[WINDOWS_INSTALLPATH];' + $path, 'User')"
        END IF

        PRINT ""
    END IF
END FUNCTION
```

---

## Update WSL Shell Config

```pseudocode
FUNCTION update_wsl_shell_config(rc_file, bitbot_install):
    # Add to ALL known shell configs if present
    # Always add to bash config (create if doesn't exist)

    SET path_line = "\n# BitBot\nexport PATH=\"" + bitbot_install + ":$PATH\"\nexport BITBOT_HOME=\"" + bitbot_install + "\"\n"

    # List of known shell config files
    SET configs = [
        "~/.bashrc",     # bash (always)
        "~/.zshrc",      # zsh (if exists)
        "~/.profile"     # sh/generic (if exists)
    ]

    SET updated_count = 0

    FOR EACH config IN configs:
        IF config == "~/.bashrc":
            # Always add to bashrc (create if doesn't exist)
            IF NOT file_exists(config):
                CALL create_file(config)
            END IF

            # Remove old entries if they exist
            CALL remove_lines_matching(config, "# BitBot")
            CALL remove_lines_matching(config, "export PATH=.*bitbot")
            CALL remove_lines_matching(config, "export BITBOT_HOME=")

            CALL append_to_file(config, path_line)
            PRINT "  ✓ Added to " + config
            SET updated_count = updated_count + 1

        ELSE IF file_exists(config):
            # Only update if file exists
            CALL remove_lines_matching(config, "# BitBot")
            CALL remove_lines_matching(config, "export PATH=.*bitbot")
            CALL remove_lines_matching(config, "export BITBOT_HOME=")

            CALL append_to_file(config, path_line)
            PRINT "  ✓ Added to " + config
            SET updated_count = updated_count + 1
        END IF
    END FOR

    IF updated_count == 0:
        ERROR "Failed to update any shell config files"
    END IF
END FUNCTION
```

---

## Update Windows Environment (WSL only)

```pseudocode
FUNCTION update_windows_environment(bitbot_install):
    # Convert WSL path to Windows path
    # Example: /mnt/c/Users/user/bitbot → C:\Users\user\bitbot
    SET windows_path = convert_wsl_to_windows_path(bitbot_install)

    PRINT "[>] Updating Windows environment variables..."

    # Check if we can run PowerShell commands
    EXECUTE "powershell.exe -Command 'echo test'" → output, exit_code

    IF exit_code != 0:
        WARN "Cannot access PowerShell from WSL"
        PRINT ""
        PRINT "Manual Windows setup required (run in PowerShell as Admin):"
        PRINT "  [Environment]::SetEnvironmentVariable('BITBOT_HOME', '" + windows_path + "', 'User')"
        PRINT "  $path = [Environment]::GetEnvironmentVariable('Path', 'User')"
        PRINT "  [Environment]::SetEnvironmentVariable('Path', '" + windows_path + ";' + $path, 'User')"
        RETURN
    END IF

    # Get current Windows PATH
    SET get_path_cmd = "[Environment]::GetEnvironmentVariable('Path', 'User')"
    EXECUTE "powershell.exe -NoProfile -Command \"" + get_path_cmd + "\"" → current_path

    # Remove old BitBot entries from Windows PATH
    SET cleaned_path = remove_bitbot_from_path(current_path)

    # Add new Windows PATH entry
    SET new_path = windows_path + ";" + cleaned_path

    # Set BITBOT_HOME in Windows
    SET set_home_cmd = "[Environment]::SetEnvironmentVariable('BITBOT_HOME', '" + windows_path + "', 'User')"
    EXECUTE "powershell.exe -NoProfile -Command \"" + set_home_cmd + "\""

    IF exit_code == 0:
        PRINT "  ✓ Set BITBOT_HOME in Windows: " + windows_path
    ELSE:
        WARN "Failed to set BITBOT_HOME in Windows"
    END IF

    # Set PATH in Windows
    SET set_path_cmd = "[Environment]::SetEnvironmentVariable('Path', '" + new_path + "', 'User')"
    EXECUTE "powershell.exe -NoProfile -Command \"" + set_path_cmd + "\""

    IF exit_code == 0:
        PRINT "  ✓ Updated Windows PATH"
    ELSE:
        WARN "Failed to update Windows PATH"
        PRINT ""
        PRINT "Manual Windows setup required (run in PowerShell as Admin):"
        PRINT "  [Environment]::SetEnvironmentVariable('BITBOT_HOME', '" + windows_path + "', 'User')"
        PRINT "  $path = [Environment]::GetEnvironmentVariable('Path', 'User')"
        PRINT "  [Environment]::SetEnvironmentVariable('Path', '" + windows_path + ";' + $path, 'User')"
    END IF
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION detect_wsl() → boolean:
    # Check if running in WSL
    IF file_exists("/proc/version"):
        EXECUTE "grep -qi microsoft /proc/version" → output, exit_code
        IF exit_code == 0:
            RETURN true
        END IF
    END IF

    # Alternative: check WSL_DISTRO_NAME env var
    IF get_env("WSL_DISTRO_NAME") != "":
        RETURN true
    END IF

    RETURN false
END FUNCTION

FUNCTION convert_wsl_to_windows_path(wsl_path) → windows_path:
    # Use wslpath utility to convert
    # Example: /mnt/c/Users/user/bitbot → C:\Users\user\bitbot
    EXECUTE "wslpath -w '" + wsl_path + "'" → windows_path, exit_code

    IF exit_code == 0:
        RETURN trim(windows_path)
    ELSE:
        # Manual conversion for /mnt/c/... paths
        IF wsl_path starts with "/mnt/":
            SET drive_letter = uppercase(wsl_path[5])  # /mnt/c → C
            SET rest_of_path = wsl_path[7:]  # Remove /mnt/c/
            SET windows_path = drive_letter + ":\" + replace(rest_of_path, "/", "\\")
            RETURN windows_path
        ELSE:
            ERROR "Cannot convert WSL path to Windows path: " + wsl_path
            EXIT 1
        END IF
    END IF
END FUNCTION

FUNCTION remove_bitbot_from_path(path_string) → cleaned_path:
    # Split PATH by semicolon (Windows) or colon (Unix)
    SET separator = ";"
    SET entries = split(path_string, separator)
    SET cleaned_entries = []

    FOR EACH entry IN entries:
        # Skip entries containing "bitbot" (case insensitive)
        IF NOT (lowercase(entry) contains "bitbot"):
            APPEND entry to cleaned_entries
        END IF
    END FOR

    RETURN join(cleaned_entries, separator)
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
- First run: Triggered when config.json doesn't exist in install folder
- Creates config.json in BitBot install folder (not ~/.bitbot/)
- Adds BitBot to PATH (with user confirmation)
- Sets BITBOT_HOME environment variable
- Checks prerequisites (Docker, devcontainer CLI)
- config.json serves as init marker
- **Portable**: No absolute paths stored in config - installation can be moved
- **Self-contained**: No ~/.bitbot/ directory - everything in install folder

**Environment Validation** (Subsequent Runs):
- **EVERY** invocation from global folder calls `validate_global_environment()` (even with no command)
- Checks if BitBot is in PATH and BITBOT_HOME is set correctly
- **Detects moved installations** - compares BITBOT_HOME to current location
- Offers to update shell config if environment is incorrect or installation moved
- Removes old PATH entries before adding new ones
- Running `./bitbot` (no args) from install folder is enough to trigger move check
- **WSL**: Updates both WSL shell config AND Windows environment variables

**Modular Script Architecture**:
Main entry script (`bitbot` in install folder root):
```bash
#!/bin/bash
# Minimal main script - sources appropriate subscript

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect mode: global vs workspace
if [[ "$PWD" == "$BITBOT_ROOT" ]]; then
    # Running from BitBot install folder → global context
    COMMAND="${1:-}"

    if [[ ! -f "$BITBOT_ROOT/config.json" ]]; then
        # First run → force global init
        source "$SCRIPT_DIR/lib/global/bitbot-init.sh"
        bitbot_global_init "$@"
    else
        # Subsequent runs → validate environment (detects moves)
        source "$SCRIPT_DIR/lib/global/bitbot-init.sh"
        validate_global_environment

        # No global commands in MVP - just show info
        echo ""
        echo "BitBot is installed at: $BITBOT_ROOT"
        echo "Environment is configured correctly"
        echo ""
        echo "To use BitBot, navigate to a project and initialize:"
        echo "  $ cd ~/my-project"
        echo "  $ bitbot init"
        echo ""
    fi
else
    # Workspace context - route to workspace commands
    COMMAND="${1:-work}"
    shift || true

    case "$COMMAND" in
        work|config|init)
            source "$SCRIPT_DIR/lib/workspace/bitbot-$COMMAND.sh"
            bitbot_$COMMAND "$@"  # Pass remaining args (vscode modifier, etc.)
            ;;
        help|--help|-h)
            source "$SCRIPT_DIR/lib/workspace/bitbot-help.sh"
            bitbot_help
            ;;
        *)
            echo "Unknown command: $COMMAND"
            source "$SCRIPT_DIR/lib/workspace/bitbot-help.sh"
            bitbot_help
            exit 2
            ;;
    esac
fi
```

Subscript structure:
```
{INSTALL_BASE_PATH}/bitbot/
├── bitbot                       # Main entry point (bash script)
├── bitbot.ps1                   # Windows PowerShell wrapper
├── bitbot.bat                   # Windows batch wrapper
├── config.json                  # Created during first run
└── lib/
    ├── global/                  # Global context logic
    │   └── bitbot-init.sh       # First-run setup (this file)
    ├── workspace/               # Workspace commands (from projects)
    │   ├── bitbot-work.sh       # Work mode
    │   ├── bitbot-config.sh     # Config mode
    │   ├── bitbot-init.sh       # Workspace initialization
    │   └── bitbot-help.sh       # Workspace help text
    └── util/                    # Shared utilities
        ├── detect.sh            # Workspace detection
        ├── devcontainer.sh      # DevContainer CLI wrapper
        ├── helpers.sh           # Common utilities
        └── prerequisites.sh     # Dependency checking
```

**Command Context**:
- Universal: `version` (works everywhere)
- Global-only: `init` (first run only, creates config.json and sets PATH/env)
- Workspace-only: `work`, `config`, `init`, `help`, `vscode`
- **Note**: Running from install folder after init just validates environment
- **MVP+**: Global `config` and `serve` commands (future features)

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
