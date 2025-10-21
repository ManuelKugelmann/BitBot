# Workspace Initialization Pseudocode

**Component**: Workspace Initialization (bitbot init)
**Script**: `scripts/lib/workspace/bitbot-init.sh`
**Purpose**: Initialize a new BitBot workspace in current directory

---

## Overview

```
bitbot init → Create .bitbot/ → Create config.json → Launch config mode
```

**Workspace Structure Created**:
```
.bitbot/
├── config.json       # Workspace configuration
├── state/            # Runtime state (empty for MVP)
└── internal/         # BitBot internals (not mounted)
    └── devcontainer.json  # Per-workspace config mode config
```

---

## Main Initialization Function

```pseudocode
FUNCTION bitbot_init():
    # Initialize BitBot workspace in current directory

    SET workspace_path = get_current_directory()

    # Check if already initialized
    IF directory_exists(workspace_path + "/.bitbot"):
        ERROR "Workspace already initialized"
        PRINT "Found existing .bitbot/ directory"
        EXIT 1
    END IF

    PRINT "[>] Initializing BitBot workspace: " + workspace_path

    # Create minimal .bitbot structure
    CALL create_directory(workspace_path + "/.bitbot")
    CALL create_directory(workspace_path + "/.bitbot/state")

    # Create config.json (workspace configuration)
    SET config = {
        "default_mode": "work",
        "workspace_name": basename(workspace_path)
    }

    CALL write_json(workspace_path + "/.bitbot/config.json", config)

    PRINT "[+] Workspace initialized"
    PRINT ""

    # Always launch config mode to configure .devcontainer
    PRINT "Launching config mode to configure workspace..."
    PRINT "(Use config mode to create/modify .devcontainer for bitbot)"
    PRINT ""

    # Launch config mode (will create .bitbot/internal/devcontainer.json)
    CALL launch_mode("config", empty_flags, empty_options)
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Creates minimal .bitbot/ structure
- Always launches config mode after initialization
- No check for existing .devcontainer (config mode helps create it)

**Files Created**:
- `.bitbot/config.json` - Workspace configuration
- `.bitbot/state/` - Empty directory for runtime state
- `.bitbot/internal/devcontainer.json` - Created by config mode launch

**Counterpart**: `lib/global/init.md` for global initialization
