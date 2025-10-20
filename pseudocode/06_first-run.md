# First-Run Experience Pseudocode

**Component**: First-Run Wizard & Onboarding
**Implements**: SPEC-09 Part A (First-Run Experience), SPEC-08 (Workspace Init)
**Purpose**: Guide new users through BitBot setup

---

## Overview

```
bitbot (first run) → Check prerequisites → Create ~/.bitbot/ → Workspace init → Mark complete
                            ↓
                    [Docker | Git | VS Code | WSL2]
```

**Decision**: Quick 3-question setup + workspace wizard

---

## First-Run Detection

```pseudocode
FUNCTION check_first_run() → boolean:
    # Check if BitBot has been run before

    IF file_exists("~/.bitbot/first-run"):
        RETURN false  # Not first run
    END IF

    IF NOT directory_exists("~/.bitbot"):
        RETURN true  # Definitely first run
    END IF

    # ~/.bitbot exists but no marker - treat as first run
    RETURN true
END FUNCTION
```

---

## Main First-Run Wizard

```pseudocode
FUNCTION first_run_wizard():
    CALL show_welcome_banner()

    # Step 1: Prerequisite checks
    PRINT ""
    PRINT "[1/4] Checking prerequisites..."
    PRINT ""

    CALL check_prerequisites() → all_ok

    IF NOT all_ok:
        ERROR "Please install missing prerequisites and try again"
        EXIT 1
    END IF

    # Step 2: Global BitBot setup
    PRINT ""
    PRINT "[2/4] Setting up BitBot..."
    PRINT ""

    CALL setup_global_bitbot()

    # Step 3: Platform-specific setup
    PRINT ""
    PRINT "[3/4] Platform setup..."
    PRINT ""

    IF platform == "windows":
        CALL setup_windows_wsl()
    END IF

    # Step 4: Workspace initialization (optional)
    PRINT ""
    PRINT "[4/4] Workspace initialization"
    PRINT ""

    CALL prompt_yes_no("Initialize a workspace now?", default="yes") → should_init

    IF should_init:
        PRINT ""
        CALL workspace_initialization_wizard()
    ELSE:
        PRINT ""
        PRINT "[i] You can initialize a workspace later with: bitbot init"
    END IF

    # Mark first-run complete
    CALL write_file("~/.bitbot/first-run", current_iso8601_timestamp())

    # Show quick start guide
    PRINT ""
    CALL show_quick_start_guide()

    PRINT ""
    PRINT "[+] BitBot setup complete!"
    PRINT ""
END FUNCTION
```

---

## Welcome Banner

```pseudocode
FUNCTION show_welcome_banner():
    PRINT "=============================================="
    PRINT "  Welcome to BitBot!"
    PRINT "=============================================="
    PRINT ""
    PRINT "BitBot is a secure development environment"
    PRINT "manager for AI-assisted coding."
    PRINT ""
    PRINT "This wizard will guide you through the setup."
    PRINT ""
END FUNCTION
```

---

## Prerequisite Checks

```pseudocode
FUNCTION check_prerequisites() → boolean:
    SET all_ok = true

    # Check Docker
    PRINT "Checking Docker..."
    IF command_exists("docker"):
        EXECUTE "docker --version" → version
        PRINT "  ✓ Docker installed (" + version + ")"

        # Check if Docker is running
        EXECUTE "docker ps" → output

        IF exit_code == 0:
            PRINT "  ✓ Docker is running"
        ELSE:
            PRINT "  ✗ Docker is not running"
            PRINT "    Please start Docker Desktop"
            SET all_ok = false
        END IF
    ELSE:
        PRINT "  ✗ Docker not found"
        PRINT "    Install: https://www.docker.com/products/docker-desktop"
        SET all_ok = false
    END IF

    # Check Docker Compose
    PRINT "Checking Docker Compose..."
    EXECUTE "docker compose version" → output

    IF exit_code == 0:
        PRINT "  ✓ Docker Compose v2 installed"
    ELSE:
        PRINT "  ✗ Docker Compose v2 not found"
        PRINT "    Usually bundled with Docker Desktop"
        SET all_ok = false
    END IF

    # Check Git (optional but recommended)
    PRINT "Checking Git..."
    IF command_exists("git"):
        EXECUTE "git --version" → version
        PRINT "  ✓ Git installed (" + version + ")"
    ELSE:
        PRINT "  ⚠ Git not found (optional, but recommended)"
        PRINT "    Install: https://git-scm.com/"
    END IF

    # Check VS Code (optional)
    PRINT "Checking VS Code..."
    IF command_exists("code"):
        PRINT "  ✓ VS Code installed"
    ELSE:
        PRINT "  ⚠ VS Code not found (optional, install for full experience)"
        PRINT "    Install: https://code.visualstudio.com/"
    END IF

    # Windows-specific: Check WSL2
    IF platform == "windows":
        PRINT "Checking WSL2..."
        IF command_exists("wsl"):
            EXECUTE "wsl --status" → output

            IF output contains "WSL 2":
                PRINT "  ✓ WSL2 installed"
            ELSE:
                PRINT "  ✗ WSL2 required on Windows"
                PRINT "    Install: https://aka.ms/wsl2"
                SET all_ok = false
            END IF
        ELSE:
            PRINT "  ✗ WSL not found"
            PRINT "    Install: https://aka.ms/wsl2"
            SET all_ok = false
        END IF
    END IF

    RETURN all_ok
END FUNCTION
```

---

## Global BitBot Setup

```pseudocode
FUNCTION setup_global_bitbot():
    SET bitbot_home = "~/.bitbot"

    # Create directory structure
    PRINT "Creating BitBot directory structure..."

    CALL create_directory(bitbot_home)
    CALL create_directory(bitbot_home + "/templates")
    CALL create_directory(bitbot_home + "/config")
    CALL create_directory(bitbot_home + "/secrets")
    CALL create_directory(bitbot_home + "/cache")

    PRINT "  ✓ Created ~/.bitbot/"

    # Create default config
    PRINT "Creating default configuration..."

    SET config = {
        "version": "1.0",
        "default_interface": "cli",
        "default_agent": null,
        "default_shell": detect_shell(),
        "auto_start_mcp": false
    }

    CALL write_json(bitbot_home + "/config/settings.json", config)

    PRINT "  ✓ Created default configuration"

    # Download/copy built-in templates
    PRINT "Setting up built-in templates..."

    CALL copy_builtin_templates(bitbot_home + "/templates")

    PRINT "  ✓ Installed built-in templates"

    # Install @devcontainers/cli if needed
    PRINT "Checking @devcontainers/cli..."

    IF NOT command_exists("devcontainer"):
        CALL prompt_yes_no("Install @devcontainers/cli?", default="yes") → should_install

        IF should_install:
            PRINT "  [>] Installing @devcontainers/cli..."
            CALL install_devcontainer_cli()
            PRINT "  ✓ Installed @devcontainers/cli"
        ELSE:
            PRINT "  [i] You can install it later with: npm install -g @devcontainers/cli"
        END IF
    ELSE:
        PRINT "  ✓ @devcontainers/cli already installed"
    END IF

    PRINT "[+] Global setup complete"
END FUNCTION
```

---

## Windows WSL Setup

```pseudocode
FUNCTION setup_windows_wsl():
    # Install BitBot-Alpine WSL distro (Decision D-12)

    PRINT "Setting up BitBot WSL environment..."

    # Check if BitBot-Alpine already exists
    EXECUTE "wsl -l -q" → distros

    IF distros contains "BitBot-Alpine":
        PRINT "  ✓ BitBot-Alpine already installed"
        RETURN
    END IF

    PRINT ""
    PRINT "BitBot uses a dedicated WSL distribution to avoid"
    PRINT "conflicts with Docker Desktop."
    PRINT ""
    PRINT "This will install BitBot-Alpine (8 MB)."
    PRINT ""

    CALL prompt_yes_no("Continue?", default="yes") → should_install

    IF NOT should_install:
        WARN "BitBot requires BitBot-Alpine on Windows"
        EXIT 1
    END IF

    PRINT "[>] Downloading Alpine Linux..."
    # Download or use embedded rootfs
    CALL download_alpine_rootfs() → rootfs_path

    PRINT "[>] Installing BitBot-Alpine..."
    EXECUTE "wsl --import BitBot-Alpine ~/.bitbot/wsl " + rootfs_path

    IF exit_code != 0:
        ERROR "Failed to install BitBot-Alpine"
        EXIT 1
    END IF

    PRINT "[>] Configuring BitBot-Alpine..."
    CALL configure_bitbot_alpine()

    PRINT "  ✓ BitBot-Alpine installed"

    # Clean up
    DELETE rootfs_path
END FUNCTION

FUNCTION configure_bitbot_alpine():
    # Install required tools in BitBot-Alpine

    SET setup_script = "
        apk update
        apk add bash git docker-cli nodejs npm
        npm install -g @devcontainers/cli
    "

    EXECUTE "wsl -d BitBot-Alpine sh -c '" + setup_script + "'"
END FUNCTION
```

---

## Workspace Initialization Wizard

```pseudocode
FUNCTION workspace_initialization_wizard():
    PRINT "Workspace Initialization Wizard"
    PRINT "================================"
    PRINT ""

    SET cwd = get_current_directory()

    PRINT "Current directory: " + cwd
    PRINT ""

    # Check for existing .devcontainer
    IF directory_exists(cwd + "/.devcontainer"):
        PRINT "Found existing .devcontainer configuration"
        PRINT ""

        CALL prompt_yes_no("Keep existing .devcontainer?", default="yes") → keep

        IF keep:
            CALL initialize_workspace_in(cwd, {"keep_devcontainer": true})
            RETURN
        ELSE:
            PRINT ""
            PRINT "Will create new .devcontainer configuration"
            PRINT ""
        END IF
    END IF

    # Template selection
    PRINT "Select workspace template:"
    PRINT ""

    CALL list_available_templates() → templates

    FOR i FROM 0 TO length(templates) - 1:
        SET template = templates[i]
        PRINT "  " + (i + 1) + ") " + template.name + " - " + template.description
    END FOR

    PRINT ""

    CALL prompt_number("Select template (1-" + length(templates) + "):", min=1, max=length(templates)) → choice

    SET selected_template = templates[choice - 1]

    PRINT ""
    PRINT "Selected: " + selected_template.name
    PRINT ""

    # AI profile selection
    PRINT "Select AI agent profile:"
    PRINT ""
    PRINT "  1) Balanced (recommended)"
    PRINT "  2) Conservative (more confirmations)"
    PRINT "  3) Aggressive (fewer prompts)"
    PRINT "  4) None (manual agent setup)"
    PRINT ""

    CALL prompt_number("Select profile (1-4):", min=1, max=4) → ai_choice

    # Apply template
    PRINT ""
    PRINT "[>] Initializing workspace..."

    CALL apply_workspace_template(cwd, selected_template, ai_choice)

    PRINT "[+] Workspace initialized!"
END FUNCTION
```

---

## Template Listing

```pseudocode
FUNCTION list_available_templates() → template_list:
    SET templates_dir = "~/.bitbot/templates"
    SET templates = []

    # Read built-in templates
    FOR EACH dir IN list_directories(templates_dir):
        SET metadata_file = dir + "/metadata.json"

        IF file_exists(metadata_file):
            SET metadata = read_json(metadata_file)

            SET template = {
                "name": metadata.name,
                "description": metadata.description,
                "path": dir
            }

            APPEND template to templates
        END IF
    END FOR

    RETURN templates
END FUNCTION
```

---

## Template Application

```pseudocode
FUNCTION apply_workspace_template(workspace_path, template, ai_profile):
    # Copy template files
    PRINT "  [>] Copying template files..."

    CALL copy_directory(template.path + "/.devcontainer", workspace_path + "/.devcontainer")

    # Apply AI profile
    IF ai_profile != 4:
        PRINT "  [>] Configuring AI agent..."

        SET profile_name = ["balanced", "conservative", "aggressive"][ai_profile - 1]
        CALL apply_ai_profile(workspace_path, profile_name)
    END IF

    # Initialize .bitbot
    PRINT "  [>] Creating .bitbot directory..."

    CALL initialize_workspace_in(workspace_path, {})

    PRINT "  ✓ Template applied"
END FUNCTION

FUNCTION apply_ai_profile(workspace_path, profile_name):
    # Create CLAUDE.md or similar based on profile

    SET profile_content = load_ai_profile_template(profile_name)

    CALL write_file(workspace_path + "/CLAUDE.md", profile_content)
END FUNCTION
```

---

## Quick Start Guide

```pseudocode
FUNCTION show_quick_start_guide():
    PRINT "=============================================="
    PRINT "  Quick Start Guide"
    PRINT "=============================================="
    PRINT ""
    PRINT "Your BitBot environment is ready!"
    PRINT ""
    PRINT "🚀 Launch development environment:"
    PRINT "   bitbot work"
    PRINT ""
    PRINT "📝 Common commands:"
    PRINT "   bitbot work          # Start work mode"
    PRINT "   bitbot setup         # Infrastructure changes"
    PRINT "   bitbot list          # Show sessions"
    PRINT "   bitbot stop          # Stop current session"
    PRINT ""
    PRINT "🤖 AI Agents:"
    PRINT "   Run 'bitbot' inside the container to launch"
    PRINT "   your configured AI agent"
    PRINT ""
    PRINT "📚 Learn more:"
    PRINT "   bitbot help"
    PRINT "   https://docs.bitbot.dev/"
    PRINT ""
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION detect_shell() → shell_name:
    # Detect user's preferred shell

    SET shell_path = get_env("SHELL") OR "/bin/bash"
    SET shell_name = basename(shell_path)

    RETURN shell_name
END FUNCTION

FUNCTION install_devcontainer_cli():
    # Install @devcontainers/cli globally

    IF NOT command_exists("npm"):
        ERROR "npm not found. Install Node.js first."
        EXIT 1
    END IF

    EXECUTE "npm install -g @devcontainers/cli"

    IF exit_code != 0:
        ERROR "Failed to install @devcontainers/cli"
        EXIT 1
    END IF
END FUNCTION

FUNCTION copy_builtin_templates(dest):
    # Copy built-in templates from BitBot installation

    SET bitbot_install = get_bitbot_install_dir()
    SET templates_src = bitbot_install + "/templates"

    IF directory_exists(templates_src):
        CALL copy_directory(templates_src, dest)
    ELSE:
        WARN "Built-in templates not found at: " + templates_src
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- First-run detected by absence of `~/.bitbot/first-run`
- Prerequisites checked before setup
- Global BitBot directory created with structure
- Optional workspace initialization
- Platform-specific setup (BitBot-Alpine on Windows)

**User Experience**:
- Clear step-by-step wizard
- Helpful error messages with install links
- Optional components clearly marked
- Quick start guide at end

**Prerequisites**:
- Required: Docker, Docker Compose, WSL2 (Windows)
- Optional: Git, VS Code
- Auto-install: @devcontainers/cli

**Windows-Specific**:
- BitBot-Alpine WSL distro installation
- Automatic configuration of tools in distro
- Transparent to user (no manual WSL management)

**Next Steps**:
- Implement UID synchronization (07_uid-sync.md)
- Create README index
