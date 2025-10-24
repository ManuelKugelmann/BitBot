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
├── local/            # Local runtime data (gitignored, empty for MVP)
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
    PRINT ""

    # Git push recommendation - first step before any changes
    # From lib/util/git.md
    CALL recommend_git_push_before_init(workspace_path)

    # Git safety checks (recommended but not required)
    # From lib/util/git.md
    CALL check_git_safety(workspace_path)

    # Create minimal .bitbot structure
    CALL create_directory(workspace_path + "/.bitbot")
    CALL create_directory(workspace_path + "/.bitbot/local")
    CALL create_directory(workspace_path + "/.bitbot/internal")
    CALL create_directory(workspace_path + "/.bitbot/internal/local")

    # Create config.json (workspace configuration)
    SET config = {
        "default_mode": "work",
        "workspace_name": basename(workspace_path),
        "skip_push_recommendation": false,
        "skip_safety_checks": false
    }

    CALL write_json(workspace_path + "/.bitbot/config.json", config)

    # Create config mode devcontainer.json (adjusted copy of global template)
    # This copy references global Dockerfile but mounts this workspace
    SET bitbot_install = get_bitbot_install_dir()
    SET global_config_devcontainer = bitbot_install + "/templates/bitbot/config/devcontainer.json"
    SET workspace_config_devcontainer = workspace_path + "/.bitbot/internal/devcontainer.json"

    # Copy global config devcontainer.json
    CALL read_json(global_config_devcontainer) → config_dc

    # Adjust workspace mount to point to this workspace
    SET config_dc.workspaceFolder = workspace_path
    SET config_dc.workspaceMount = "source=" + workspace_path + ",target=/workspace,type=bind"

    # Save adjusted copy
    CALL write_json(workspace_config_devcontainer, config_dc)
    PRINT "  ✓ Created config mode devcontainer"

    # Add .bitbot/local/ and .bitbot/internal/local/ to .gitignore (if git repo exists)
    IF directory_exists(workspace_path + "/.git"):
        SET gitignore_path = workspace_path + "/.gitignore"
        SET gitignore_entries = "\n# BitBot local runtime data\n.bitbot/local/\n.bitbot/internal/local/\n"

        # Check if .gitignore exists and already contains the entries
        IF file_exists(gitignore_path):
            CALL read_file(gitignore_path) → gitignore_content
            SET needs_update = false

            IF NOT (gitignore_content contains ".bitbot/local/"):
                SET needs_update = true
            END IF

            IF NOT (gitignore_content contains ".bitbot/internal/local/"):
                SET needs_update = true
            END IF

            IF needs_update:
                # Append to existing .gitignore
                CALL append_to_file(gitignore_path, gitignore_entries)
                PRINT "  ✓ Added .bitbot/local/ and .bitbot/internal/local/ to .gitignore"
            END IF
        ELSE:
            # Create new .gitignore
            CALL write_file(gitignore_path, "# BitBot local runtime data\n.bitbot/local/\n.bitbot/internal/local/\n")
            PRINT "  ✓ Created .gitignore with .bitbot/local/ and .bitbot/internal/local/"
        END IF
    END IF

    # Check if .devcontainer exists
    SET devcontainer_path = workspace_path + "/.devcontainer"
    IF NOT directory_exists(devcontainer_path):
        # Copy base template from global BitBot installation
        PRINT "[>] Creating base .devcontainer from template..."
        SET bitbot_install = get_bitbot_install_dir()
        SET template_path = bitbot_install + "/templates/bitbot/workspace"

        CALL copy_directory(template_path, devcontainer_path)
        PRINT "  ✓ Created .devcontainer/ from template"
    ELSE:
        PRINT "[i] Found existing .devcontainer/"
        PRINT "    AI agent can help you review and adjust it"
    END IF

    PRINT "[+] Workspace initialized"
    PRINT ""

    # Always launch config mode - AI agent will configure .devcontainer
    PRINT "Launching config mode..."
    PRINT ""
    PRINT "Config mode runs BitBot AI agent in a devcontainer optimized for devcontainer setup."
    PRINT "The AI provides guidance and help to configure your .devcontainer."
    PRINT "Close VS Code or terminal when finished."
    PRINT ""
    PRINT "You can test your workspace devcontainer in parallel:"
    PRINT "  • Open another terminal"
    PRINT "  • Run: bitbot work"
    PRINT "  • Test your .devcontainer changes while config mode is still running"
    PRINT ""

    # Launch config mode (AI agent provides guidance for devcontainer setup)
    CALL launch_mode("config", empty_flags, empty_options)
END FUNCTION
```

---

## Git Utilities

Git recommendation and safety check functions are defined in `core/util/git.md`:

- `recommend_git_push_before_init(workspace_path)` - Recommends git setup, remote, and push with skip options
- `check_git_safety(workspace_path)` - Warns about uncommitted changes and public repo secrets

Both functions provide clear instructions and allow users to skip if needed.

---

## Implementation Notes

**Key Behaviors**:
- **First step**: Git push recommendation (if uncommitted/unpushed changes)
- Git safety checks before initialization (uncommitted changes, secrets warnings)
- Creates minimal .bitbot/ structure
- Copies base .devcontainer template if not present (immediately, not in config mode)
- **Always launches config mode after initialization** - whether template was copied or .devcontainer already existed
- AI agent in config mode provides guidance to configure/review .devcontainer (no wizard)

**Files Created**:
- `.bitbot/config.json` - Workspace configuration (committed)
- `.bitbot/local/` - Work mode local runtime data (gitignored)
  - Special submounts in work mode: `.bash_history`, etc.
- `.bitbot/internal/` - Config mode internals (excluded from container mounts)
  - `devcontainer.json` - Config mode devcontainer (committed, references global Dockerfile)
  - `local/` - Config mode local runtime data (gitignored)
    - Special submounts in config mode: `.bash_history`, etc.
- `.devcontainer/` - Copied from global template (if not present)
  - `devcontainer.json` - Minimal template with BitBot defaults
  - `Dockerfile` - Base image (Alpine or Ubuntu)
- `.gitignore` - Updated/created to ignore `.bitbot/local/` and `.bitbot/internal/local/`

**DevContainer Setup**:
- MVP: No interactive wizard - AI agent provides guidance and help
- Base template provides minimal working config
- AI agent in config mode:
  - Runs in devcontainer optimized for devcontainer setup
  - Provides guidance to configure .devcontainer for your needs
  - Helps set up development tools and dependencies
  - Parallel testing: Open another terminal and run `bitbot work` to test workspace devcontainer while config mode is running
- Exit: Close VS Code or terminal to finish config mode

**Mount Structure**:
- **Work mode** (workspace devcontainer):
  - Mounts workspace (excluding `.bitbot/internal/`)
  - Special submounts: `.bitbot/local/.bash_history` → container bash history
  - `.devcontainer/` mounted read-only for security
- **Config mode** (config devcontainer):
  - Mounts workspace (excluding `.bitbot/internal/`)
  - Special submounts: `.bitbot/internal/local/.bash_history` → container bash history
  - `.devcontainer/` writable (can be edited)
- **Exclusions**:
  - `.bitbot/internal/` never mounted (contains config mode devcontainer.json on host)
  - Each mode has separate bash history and local data
- **Future**: Zsh support (see FUTURE_FEATURES.md)

**Git Integration**:
- Instructions only - no git automation
- Shows git status to help user decide
- Recommends manual push before config mode
- User executes git commands themselves

---

## DevContainer Template Examples

**Work Mode devcontainer.json** (`.devcontainer/devcontainer.json`):
```json
{
  "name": "my-project-work",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],

  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/local/.bash_history"
  },

  "postCreateCommand": "mkdir -p /workspace/.bitbot/local",

  "remoteUser": "vscode",
  "updateRemoteUserUID": true,

  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
```

**Config Mode devcontainer.json** (`.bitbot/internal/devcontainer.json`):
```json
{
  "name": "my-project-config",
  "build": {
    "dockerfile": "${env:BITBOT_HOME}/templates/bitbot/config/Dockerfile"
  },

  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind",
  "workspaceFolder": "/workspace",

  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/internal/local/.bash_history"
  },

  "postCreateCommand": "mkdir -p /workspace/.bitbot/internal/local",

  "remoteUser": "vscode",
  "updateRemoteUserUID": true,

  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
```

**Shell History Notes**:
- MVP uses bash as default shell (universal compatibility)
- Bash history configured via `HISTFILE` environment variable
- History files persist across container rebuilds (mounted from host)
- Work mode: `.bitbot/local/.bash_history`
- Config mode: `.bitbot/internal/local/.bash_history`
- Future: Zsh support with separate `.zsh_history` files (see FUTURE_FEATURES.md)

---

**Counterpart**: `core/global/init.md` for global initialization
