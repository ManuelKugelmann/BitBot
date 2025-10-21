# Prerequisites and Dependency Checking Pseudocode

**Component**: Prerequisites Validation
**Script**: `scripts/lib/util/prerequisites.sh`
**Purpose**: Check, validate, and auto-fix runtime dependencies
**Based on**: test-windows-launch/scripts/bitbot

---

## Overview

Runtime dependency checking performed on every BitBot command invocation:
- Docker (install check, running check, auto-start)
- DevContainer CLI (builtin, standalone, or offer install)
- VS Code (optional, with extension check)
- WSL Docker integration (Windows-specific)

---

## Main Validation Function

```pseudocode
FUNCTION validate_prerequisites(command):
    # Quick validation for most commands
    # Full validation only for commands that need containers

    IF command IN ["help", "version", "doctor"]:
        RETURN true  # No prerequisites needed
    END IF

    # Check Docker
    IF NOT check_docker():
        EXIT 1
    END IF

    # Check DevContainer CLI (if needed for this command)
    IF command IN ["work", "config", "vscode"]:
        IF NOT check_devcontainer_cli_available():
            # Offer installation or show instructions
            handle_missing_devcontainer_cli()
            EXIT 1
        END IF
    END IF

    # WSL-specific: Check Docker integration
    IF is_wsl():
        IF NOT check_docker_wsl_integration():
            EXIT 1
        END IF
    END IF

    RETURN true
END FUNCTION
```

---

## Docker Checks

```pseudocode
FUNCTION check_docker() → boolean:
    # Check if Docker is installed
    IF NOT command_exists("docker"):
        PRINT_ERROR "Docker not found"
        PRINT ""
        PRINT "Install Docker Desktop:"
        PRINT "  https://www.docker.com/products/docker-desktop"
        PRINT ""
        RETURN false
    END IF

    # Check if Docker is running
    EXECUTE "docker ps" → output
    IF exit_code != 0:
        PRINT_WARNING "Docker is not running"
        PRINT ""

        # Offer to start Docker
        CALL prompt_yes_no("Start Docker now?", default="yes") → should_start

        IF should_start:
            IF start_docker():
                PRINT_SUCCESS "Docker started"
                RETURN true
            ELSE:
                PRINT_ERROR "Failed to start Docker"
                RETURN false
            END IF
        ELSE:
            PRINT ""
            PRINT "Start Docker Desktop manually and try again"
            RETURN false
        END IF
    END IF

    # Check Docker Compose v2
    EXECUTE "docker compose version" → output
    IF exit_code != 0:
        PRINT_ERROR "Docker Compose v2 not found"
        PRINT "Usually bundled with Docker Desktop"
        RETURN false
    END IF

    RETURN true
END FUNCTION

FUNCTION start_docker() → boolean:
    # Platform-specific Docker startup

    SET platform = detect_platform()

    PRINT "[>] Starting Docker..."

    SWITCH platform:
        CASE "wsl":
            # Windows: Start Docker Desktop via PowerShell
            EXECUTE "powershell.exe -Command \"Start-Process 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe'\""
            IF exit_code != 0:
                RETURN false
            END IF

        CASE "macos":
            # macOS: Start Docker Desktop
            EXECUTE "open -a Docker"
            IF exit_code != 0:
                RETURN false
            END IF

        CASE "linux":
            # Linux: Try systemd
            IF command_exists("systemctl"):
                EXECUTE "sudo systemctl start docker"
                IF exit_code != 0:
                    RETURN false
                END IF
            ELSE IF command_exists("service"):
                EXECUTE "sudo service docker start"
                IF exit_code != 0:
                    RETURN false
                END IF
            ELSE:
                PRINT "  Cannot auto-start Docker on this system"
                RETURN false
            END IF
    END SWITCH

    # Wait for Docker to be ready (max 60 seconds)
    PRINT "  Waiting for Docker to start..."

    SET timeout = 60
    SET elapsed = 0

    WHILE NOT docker_is_running():
        IF elapsed >= timeout:
            PRINT ""
            PRINT "  Timeout after ${timeout}s"
            IF platform == "wsl":
                PRINT "  Docker Desktop may need more time for WSL integration"
            END IF
            PRINT "  Check Docker Desktop status and try again"
            RETURN false
        END IF

        SLEEP 2
        SET elapsed = elapsed + 2

        # Progress indicator
        PRINT_INLINE "."

        IF elapsed % 10 == 0:
            PRINT_INLINE " ${elapsed}s"
        END IF
    END WHILE

    PRINT ""
    PRINT_SUCCESS "Docker ready (took ${elapsed}s)"
    RETURN true
END FUNCTION

FUNCTION docker_is_running() → boolean:
    EXECUTE "docker ps" >/dev/null 2>&1
    RETURN exit_code == 0
END FUNCTION
```

---

## DevContainer CLI Checks

```pseudocode
FUNCTION check_devcontainer_cli_available() → boolean:
    # Check if devcontainer CLI is available (any method)

    SET cli_status = check_devcontainer_cli()

    RETURN cli_status IN ["builtin", "standalone"]
END FUNCTION

FUNCTION check_devcontainer_cli() → status_string:
    # Return: "builtin" | "standalone" | "vscode-only" | "none"

    SET has_vscode = false
    SET has_extension = false
    SET has_standalone = false
    SET platform = detect_platform()

    # Check for VS Code
    IF command_exists("code"):
        SET has_vscode = true

        # Check for Dev Containers extension
        IF check_vscode_extension():
            SET has_extension = true
        END IF
    END IF

    # Check for standalone CLI
    IF platform == "wsl":
        # Windows: Check for devcontainer.cmd
        IF command_exists("devcontainer.cmd"):
            SET has_standalone = true
        END IF
    ELSE:
        # macOS/Linux: Check for devcontainer
        IF command_exists("devcontainer"):
            SET has_standalone = true
        END IF
    END IF

    # Return status with priority
    IF has_extension:
        RETURN "builtin"  # VS Code with Dev Containers extension (best)
    ELSE IF has_standalone:
        RETURN "standalone"  # Standalone @devcontainers/cli
    ELSE IF has_vscode:
        RETURN "vscode-only"  # VS Code without extension
    ELSE:
        RETURN "none"  # Nothing found
    END IF
END FUNCTION

FUNCTION check_vscode_extension() → boolean:
    # Check if Dev Containers extension is installed

    SET platform = detect_platform()

    IF platform == "wsl":
        # On WSL, check from Windows host
        EXECUTE "powershell.exe -Command \"code --list-extensions\"" → output
    ELSE:
        # Native Linux/macOS
        EXECUTE "code --list-extensions" → output
    END IF

    IF exit_code != 0:
        RETURN false
    END IF

    # Check if extension is in list
    IF output contains "ms-vscode-remote.remote-containers":
        RETURN true
    ELSE:
        RETURN false
    END IF
END FUNCTION

FUNCTION handle_missing_devcontainer_cli():
    # Handle missing devcontainer CLI with helpful message

    SET cli_status = check_devcontainer_cli()

    PRINT_ERROR "DevContainer CLI not available"
    PRINT ""

    SWITCH cli_status:
        CASE "vscode-only":
            PRINT "You have VS Code but Dev Containers extension is missing."
            PRINT ""
            PRINT "Install the extension:"
            PRINT "  1. Open VS Code"
            PRINT "  2. Extensions view (Ctrl+Shift+X)"
            PRINT "  3. Search: Dev Containers"
            PRINT "  4. Install: ms-vscode-remote.remote-containers"
            PRINT ""
            PRINT "Or via command line:"
            PRINT "  code --install-extension ms-vscode-remote.remote-containers"

        CASE "none":
            PRINT "Install options:"
            PRINT ""
            PRINT "Option 1: VS Code + Dev Containers extension (recommended)"
            PRINT "  https://code.visualstudio.com/"
            PRINT "  Extension: ms-vscode-remote.remote-containers"
            PRINT ""
            PRINT "Option 2: Standalone CLI (requires Node.js)"
            PRINT "  npm install -g @devcontainers/cli"
            PRINT ""

            # Offer to install standalone CLI
            IF command_exists("npm"):
                PRINT ""
                CALL prompt_yes_no("Install standalone CLI now?", default="no") → should_install

                IF should_install:
                    CALL install_devcontainer_cli_standalone()
                END IF
            END IF
    END SWITCH
END FUNCTION

FUNCTION install_devcontainer_cli_standalone() → boolean:
    # Install @devcontainers/cli via npm

    IF NOT command_exists("npm"):
        PRINT_ERROR "npm not found"
        PRINT "Install Node.js from: https://nodejs.org/"
        RETURN false
    END IF

    PRINT "[>] Installing @devcontainers/cli..."
    EXECUTE "npm install -g @devcontainers/cli"

    IF exit_code == 0:
        PRINT_SUCCESS "@devcontainers/cli installed"
        RETURN true
    ELSE:
        PRINT_ERROR "Installation failed"
        RETURN false
    END IF
END FUNCTION
```

---

## WSL Docker Integration Check

```pseudocode
FUNCTION check_docker_wsl_integration() → boolean:
    # WSL-specific: Check if Docker Desktop has BitBot-Alpine integration enabled

    SET platform = detect_platform()

    # Only check on WSL with BitBot-Alpine
    IF platform != "wsl":
        RETURN true  # Not WSL, skip check
    END IF

    IF get_env("WSL_DISTRO_NAME") != "BitBot-Alpine":
        RETURN true  # Not BitBot-Alpine, skip check
    END IF

    # Try docker command
    IF docker_is_running():
        RETURN true  # Docker works, all good
    END IF

    # Docker not accessible - check if it's integration issue
    EXECUTE "docker ps 2>&1" → error_output

    IF error_output contains "Cannot connect to the Docker daemon":
        # This is a WSL integration issue
        CALL prompt_docker_wsl_integration_setup()
        RETURN false
    END IF

    # Other Docker error
    RETURN false
END FUNCTION

FUNCTION prompt_docker_wsl_integration_setup():
    # Prompt user to enable Docker WSL integration for BitBot-Alpine

    PRINT ""
    PRINT "========================================================="
    PRINT "  Docker WSL Integration Setup Required"
    PRINT "========================================================="
    PRINT ""
    PRINT "BitBot-Alpine cannot access Docker."
    PRINT ""
    PRINT "This is a one-time setup that will:"
    PRINT "  - Stop Docker Desktop"
    PRINT "  - Enable BitBot-Alpine in Docker settings"
    PRINT "  - Restart Docker Desktop (~30 seconds)"
    PRINT ""

    CALL prompt_yes_no("Enable Docker integration for BitBot-Alpine?", default="yes") → should_enable

    IF NOT should_enable:
        PRINT ""
        PRINT "Setup cancelled."
        PRINT ""
        show_manual_docker_integration_instructions()
        RETURN
    END IF

    # Get setup script path (relative to bitbot script)
    SET script_dir = get_script_directory()
    SET setup_script = script_dir + "/../tests/enable-docker-wsl-integration-simple.ps1"

    IF NOT file_exists(setup_script):
        PRINT_ERROR "Setup script not found: " + setup_script
        PRINT ""
        show_manual_docker_integration_instructions()
        RETURN
    END IF

    # Run setup script from Windows
    SET windows_path = wsl_to_windows_path(setup_script)

    PRINT "[>] Running Docker integration setup..."
    EXECUTE "powershell.exe -ExecutionPolicy Bypass -File \"" + windows_path + "\""

    IF exit_code == 0:
        PRINT ""
        PRINT_SUCCESS "Docker integration setup complete!"
        PRINT ""
    ELSE:
        PRINT ""
        PRINT_ERROR "Setup failed"
        PRINT ""
        show_manual_docker_integration_instructions()
    END IF
END FUNCTION

FUNCTION show_manual_docker_integration_instructions():
    PRINT "Manual setup:"
    PRINT "  1. Open Docker Desktop"
    PRINT "  2. Settings → Resources → WSL Integration"
    PRINT "  3. Enable 'BitBot-Alpine'"
    PRINT "  4. Apply & Restart"
    PRINT ""
    PRINT "Then run: bitbot work"
    PRINT ""
END FUNCTION
```

---

## Doctor Command (Dependency Status)

```pseudocode
FUNCTION show_doctor():
    # Show comprehensive dependency status (like bitbot doctor or version --verbose)

    PRINT "BitBot Dependency Status"
    PRINT "========================"
    PRINT ""

    SET platform = detect_platform()
    PRINT "Platform: " + platform
    PRINT ""

    # Docker
    IF command_exists("docker"):
        EXECUTE "docker --version" → version
        PRINT_SUCCESS "Docker installed (" + trim(version) + ")"

        IF docker_is_running():
            PRINT_SUCCESS "Docker is running"
        ELSE:
            PRINT_WARNING "Docker is not running"
        END IF

        # Docker Compose
        EXECUTE "docker compose version 2>/dev/null" → compose_version
        IF exit_code == 0:
            PRINT_SUCCESS "Docker Compose v2 (" + trim(compose_version) + ")"
        ELSE:
            PRINT_ERROR "Docker Compose v2 not found"
        END IF
    ELSE:
        PRINT_ERROR "Docker not found"
        PRINT "  Install: https://www.docker.com/products/docker-desktop"
    END IF

    PRINT ""

    # DevContainer CLI
    SET cli_status = check_devcontainer_cli()

    SWITCH cli_status:
        CASE "builtin":
            PRINT_SUCCESS "DevContainer CLI (VS Code builtin)"

        CASE "standalone":
            IF platform == "wsl":
                EXECUTE "devcontainer.cmd --version" → version
            ELSE:
                EXECUTE "devcontainer --version" → version
            END IF
            PRINT_SUCCESS "DevContainer CLI (standalone " + trim(version) + ")"

        CASE "vscode-only":
            PRINT_WARNING "DevContainer CLI missing"
            PRINT "  Install extension: code --install-extension ms-vscode-remote.remote-containers"

        CASE "none":
            PRINT_ERROR "DevContainer CLI not found"
            PRINT "  Option 1: Install VS Code + Dev Containers extension"
            PRINT "  Option 2: npm install -g @devcontainers/cli"
    END SWITCH

    PRINT ""

    # VS Code
    IF command_exists("code"):
        PRINT_SUCCESS "VS Code installed"

        IF check_vscode_extension():
            PRINT_SUCCESS "Dev Containers extension installed"
        ELSE:
            PRINT_WARNING "Dev Containers extension not installed"
        END IF
    ELSE:
        PRINT_INFO "VS Code not found (optional)"
        PRINT "  Install: https://code.visualstudio.com/"
    END IF

    PRINT ""

    # WSL-specific checks
    IF platform == "wsl":
        PRINT "WSL Environment:"

        SET distro = get_env("WSL_DISTRO_NAME")
        PRINT "  Distro: " + distro

        IF distro == "BitBot-Alpine":
            IF check_docker_wsl_integration():
                PRINT_SUCCESS "Docker WSL integration enabled"
            ELSE:
                PRINT_WARNING "Docker WSL integration not configured"
            END IF
        END IF

        PRINT ""
    END IF

    # Git (optional but recommended)
    IF command_exists("git"):
        EXECUTE "git --version" → git_version
        PRINT_SUCCESS "Git installed (" + trim(git_version) + ")"
    ELSE:
        PRINT_INFO "Git not found (optional, recommended)"
        PRINT "  Install: https://git-scm.com/"
    END IF

    PRINT ""
    PRINT "========================"

    # Summary
    SET all_required_ok = (cli_status IN ["builtin", "standalone"]) AND command_exists("docker") AND docker_is_running()

    IF all_required_ok:
        PRINT_SUCCESS "All required dependencies OK"
    ELSE:
        PRINT_WARNING "Some dependencies missing or not configured"
    END IF
END FUNCTION
```

---

## Platform Detection

```pseudocode
FUNCTION detect_platform() → platform_string:
    # Detect: "wsl" | "linux" | "macos" | "windows"

    # Check WSL
    IF file_exists("/proc/sys/fs/binfmt_misc/WSLInterop"):
        RETURN "wsl"
    END IF

    # Check /proc/version for microsoft (WSL indicator)
    IF file_exists("/proc/version"):
        SET proc_version = read_file("/proc/version")
        IF lowercase(proc_version) contains "microsoft":
            RETURN "wsl"
        END IF
    END IF

    # Check OSTYPE environment variable
    SET ostype = get_env("OSTYPE") OR ""

    IF ostype starts_with "darwin":
        RETURN "macos"
    ELSE IF ostype starts_with "linux":
        RETURN "linux"
    ELSE IF ostype starts_with "msys" OR ostype starts_with "cygwin":
        RETURN "windows"  # Git Bash or Cygwin
    END IF

    # Default to linux
    RETURN "linux"
END FUNCTION

FUNCTION is_wsl() → boolean:
    RETURN detect_platform() == "wsl"
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Checks run on every BitBot invocation (fast for help/version)
- Auto-start Docker if not running (with user confirmation)
- Offer to install devcontainer CLI if missing
- WSL-specific Docker integration setup assistance
- Clear, actionable error messages with install links

**Based on Test Implementation**:
- test-windows-launch/scripts/bitbot lines 105-167 (check_devcontainer_cli)
- test-windows-launch/scripts/bitbot lines 208-270 (start_docker)
- test-windows-launch/scripts/bitbot lines 272-357 (check_docker_wsl_integration)
- test-windows-launch/scripts/bitbot lines 607-657 (show_version with checks)

**Doctor Command**:
- Shows comprehensive dependency status
- Color-coded output (✓ success, ⚠ warning, ✗ error)
- Platform-specific information
- Summary of readiness

**Used by**:
- bitbot.md main() - Calls validate_prerequisites() for all commands
- lib/util/mode.md - Before launching containers
- Doctor command - Shows full dependency status

**Dependencies**:
- Uses lib/util/helpers.md for prompts, output formatting
- Uses lib/util/detect.md for platform detection
