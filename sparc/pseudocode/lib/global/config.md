# Global BitBot Configuration Pseudocode (MVP)

**Component**: Global BitBot Configuration
**Implements**: Global settings and template setup
**Purpose**: Configure BitBot global settings (can run multiple times)

---

## Overview

```
User runs: bitbot config (from install folder) → Configure settings → Update config
                                    ↓
                        [Update config.json in install folder]
```

**Decision**: Reusable configuration command
- Creates/updates config.json in BitBot install folder
- Can be called during init or standalone
- Future: Manage templates, MCP settings, etc.

---

## Main Global Config Function

```pseudocode
FUNCTION bitbot_global_config():
    # Configure global BitBot settings (reusable)
    # Called by global init or standalone

    # NOTE: validate_global_environment() already called by main entry script
    # (All global commands validate environment before executing)

    PRINT "[>] Configuring global BitBot settings..."
    PRINT ""

    # Update config.json in install folder
    CALL setup_global_config()

    PRINT ""
    PRINT "[+] Global configuration complete!"
    PRINT ""
END FUNCTION
```

---

## Global Config.json Setup

```pseudocode
FUNCTION setup_global_config():
    SET bitbot_install = get_bitbot_install_dir()
    SET config_file = bitbot_install + "/config.json"

    # Check if config already exists
    IF file_exists(config_file):
        PRINT "[i] Updating existing config..."
        SET existing_config = read_json(config_file)
    ELSE:
        PRINT "[i] Creating new config..."
        SET existing_config = {}
    END IF

    # Update/create config
    # NOTE: No absolute paths stored - BitBot is portable!
    SET config = {
        "version": "0.1.0-mvp",
        "created": existing_config["created"] OR current_timestamp(),
        "updated": current_timestamp()
    }

    CALL write_json(config_file, config)

    PRINT "  ✓ Config saved to config.json"
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION get_bitbot_install_dir() → path:
    # Get absolute path to BitBot installation
    SET script_path = get_absolute_path_of_current_script()
    SET install_dir = dirname(dirname(dirname(dirname(script_path))))  # global/ → lib/ → scripts/ → BitBot/
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
- Creates/updates config.json in BitBot install folder
- No ~/.bitbot/ directory used - everything self-contained
- Called by global init, but also standalone

**Relationship to Global Init**:
- `bitbot-init.sh` (first run): Creates config.json, adds to PATH
- `bitbot-config.sh` (this file): Updates config (reusable)

**MVP Scope**:
- Minimal config.json (version, timestamps only)
- No absolute paths stored (portable)
- Config devcontainer template already in install folder
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
cd {INSTALL_BASE_PATH}/bitbot && ./bitbot  # Runs init

# Later, to reconfigure
cd {INSTALL_BASE_PATH}/bitbot && ./bitbot config

# From elsewhere (after init)
bitbot config  # Error: must run from install folder
```

---

**Status**: MVP-focused global configuration
**Called By**: 06_global-init.md (during first run)
**Can Run Standalone**: Yes (from install folder, after init)
