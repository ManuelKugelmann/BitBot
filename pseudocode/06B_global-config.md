# Global BitBot Configuration Pseudocode (MVP)

**Component**: Global BitBot Configuration
**Implements**: Global settings and template setup
**Purpose**: Configure BitBot global settings (can run multiple times)

---

## Overview

```
User runs: bitbot config (from install folder) → Configure settings → Update config
                                    ↓
            [Create config.json | Setup config devcontainer | Future: templates]
```

**Decision**: Reusable configuration command
- Creates/updates ~/.bitbot/config.json
- Sets up global config-devcontainer template
- Can be called during init or standalone
- Future: Manage templates, MCP settings, etc.

---

## Main Global Config Function

```pseudocode
FUNCTION bitbot_global_config():
    # Configure global BitBot settings (reusable)

    PRINT "[>] Configuring global BitBot settings..."
    PRINT ""

    # Ensure ~/.bitbot/ exists
    IF NOT directory_exists("~/.bitbot"):
        PRINT "[!] ~/.bitbot/ not found - run 'bitbot init' first"
        EXIT 4
    END IF

    # Step 1: Create/update global config.json
    PRINT "[1/2] Updating global config..."
    PRINT ""

    CALL setup_global_config()

    # Step 2: Create global config devcontainer template
    PRINT ""
    PRINT "[2/2] Setting up config devcontainer template..."
    PRINT ""

    CALL setup_config_devcontainer_template()

    PRINT ""
    PRINT "[+] Global configuration complete!"
    PRINT ""
END FUNCTION
```

---

## Global Config.json Setup

```pseudocode
FUNCTION setup_global_config():
    SET bitbot_home = "~/.bitbot"
    SET config_file = bitbot_home + "/config.json"

    # Check if config already exists
    IF file_exists(config_file):
        PRINT "[i] Updating existing config..."
        SET existing_config = read_json(config_file)
    ELSE:
        PRINT "[i] Creating new config..."
        SET existing_config = {}
    END IF

    # Update/create config
    SET config = {
        "bitbot_install_path": get_bitbot_install_dir(),
        "version": "0.1.0-mvp",
        "created": existing_config["created"] OR current_timestamp(),
        "updated": current_timestamp()
    }

    CALL write_json(config_file, config)

    PRINT "  ✓ Config saved to ~/.bitbot/config.json"
END FUNCTION
```

---

## Config Devcontainer Template Setup

```pseudocode
FUNCTION setup_config_devcontainer_template():
    SET bitbot_home = "~/.bitbot"
    SET config_dc_dir = bitbot_home + "/config-devcontainer"

    # Create directory if doesn't exist
    IF NOT directory_exists(config_dc_dir):
        CALL create_directory(config_dc_dir)
        PRINT "[i] Creating config devcontainer template..."
    ELSE:
        PRINT "[i] Updating config devcontainer template..."
    END IF

    # Create minimal devcontainer.json template
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

    PRINT "  ✓ Config devcontainer template ready"
    PRINT "     Location: ~/.bitbot/config-devcontainer/"

    # Future: Create Dockerfile, compose, scripts here
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION get_bitbot_install_dir() → path:
    # Get absolute path to BitBot installation
    SET script_path = get_absolute_path_of_current_script()
    SET install_dir = dirname(dirname(dirname(script_path)))  # global/ → scripts/ → BitBot/
    RETURN install_dir
END FUNCTION

FUNCTION current_timestamp() → string:
    RETURN iso8601_timestamp()
END FUNCTION
```

---

## Implementation Notes (MVP)

**Key Behaviors**:
- Can be run multiple times (idempotent)
- Creates ~/.bitbot/config.json with global settings
- Sets up ~/.bitbot/config-devcontainer/ template
- Called by global init, but also standalone

**Relationship to Global Init**:
- `bitbot-init.sh` (first run): Creates folder structure, adds to PATH, calls this
- `bitbot-config.sh` (this file): Configurable settings (reusable)

**MVP Scope**:
- Minimal config.json (install path, version, timestamps)
- Basic config devcontainer template (Alpine base)
- No template management yet (future)
- No MCP service config yet (future)

**Future Enhancements**:
- Interactive configuration wizard
- Template management (install/remove templates)
- MCP service configuration
- AI agent defaults
- Shell preferences

**Usage**:
```bash
# First time (automatically called by init)
cd /opt/bitbot && ./scripts/bitbot  # Runs init → config

# Later, to reconfigure
cd /opt/bitbot && ./scripts/bitbot config  # Just config

# From elsewhere (after init)
bitbot config  # Error: must run from install folder
```

---

**Status**: MVP-focused global configuration
**Called By**: 06_global-init.md (during first run)
**Can Run Standalone**: Yes (from install folder, after init)
