# Utility Libraries

Shared utility functions and modules used across BitBot commands.

## Overview

These utilities are **not** standalone commands. They are libraries sourced by BitBot's main scripts to provide common functionality.

---

## Utility Modules

### detect.md
**Purpose**: Workspace detection and validation
**Script**: `scripts/lib/util/detect.sh`
**Used by**:
- `bitbot` (main router) - Determines if running in global vs workspace context
- `lib/workspace/work.md` - Validates workspace before launch
- `lib/workspace/config.md` - Validates workspace before launch
- `lib/workspace/init.md` - Checks if workspace already initialized

**Key functions**:
- `detect_workspace()` - Find BitBot workspace from CWD
- `validate_workspace()` - Check if directory is valid BitBot workspace
- `is_workspace_initialized()` - Check for .bitbot/ directory

---

### helpers.md
**Purpose**: Common utility functions (file, JSON, paths, prompts, output)
**Script**: `scripts/lib/util/helpers.sh`
**Used by**: All scripts

**Key functions**:
- **File operations**: `create_directory()`, `file_exists()`, `directory_exists()`, `command_exists()`
- **JSON operations**: `read_json()`, `write_json()`
- **Path operations**: `get_current_directory()`, `get_absolute_path()`, `basename()`, `dirname()`
- **User prompts**: `prompt_yes_no()`
- **Output formatting**: `print_success()`, `print_info()`, `print_warning()`, `print_error()`
- **Timestamps**: `current_timestamp()`, `iso8601_timestamp()`

---

### devcontainer.md
**Purpose**: DevContainer CLI wrapper and launch functions
**Script**: `scripts/lib/util/devcontainer.sh`
**Used by**:
- `lib/workspace/work.md` - Launches work mode devcontainer
- `lib/workspace/config.md` - Launches config mode devcontainer
- `lib/workspace/init.md` - Calls `launch_mode("config")` after init

**Key functions**:
- `launch_mode()` - Main mode launcher (work or config)
- `launch_work_devcontainer()` - Launch workspace's .devcontainer
- `launch_config_devcontainer()` - Launch global config devcontainer
- `devcontainer_up()` - DevContainer CLI wrapper for work mode
- `devcontainer_up_with_config()` - DevContainer CLI wrapper for config mode
- `devcontainer_exec_tmux()` - Execute tmux in devcontainer
- `check_git_uncommitted()` - Git safety check (warning only)

**Note**: UID/GID synchronization is handled natively by DevContainer CLI using `updateRemoteUserUID` and the `common-utils` feature. No separate UID sync module needed.

---

### prerequisites.md
**Purpose**: Dependency checking and validation
**Script**: `scripts/lib/util/prerequisites.sh`
**Used by**:
- `bitbot` (main router) - Validates before all commands
- Doctor command - Shows comprehensive dependency status

**Key functions**:
- `validate_prerequisites()` - Main validation (Docker, DevContainer CLI, WSL integration)
- `check_docker()` - Check Docker installed and running (offers auto-start)
- `start_docker()` - Platform-specific Docker startup
- `check_devcontainer_cli()` - Detect builtin/standalone/none
- `check_vscode_extension()` - Check Dev Containers extension
- `handle_missing_devcontainer_cli()` - Install guidance
- `check_docker_wsl_integration()` - WSL Docker integration check
- `show_doctor()` - Comprehensive dependency status display

---

## Dependency Graph

```
bitbot (main router)
└── lib/util/detect.sh (workspace detection)
    └── lib/util/helpers.sh (file operations)

bitbot (main router)
└── lib/util/prerequisites.sh (dependency validation)
    └── lib/util/helpers.sh (prompts, output)

lib/workspace/work.md
└── lib/util/devcontainer.sh (launch work mode)
    ├── lib/util/helpers.sh (file/output operations)
    └── lib/util/detect.sh (validate workspace)

lib/workspace/config.md
└── lib/util/devcontainer.sh (launch config mode)
    ├── lib/util/helpers.sh (file/output operations)
    └── lib/util/detect.sh (validate workspace)

lib/workspace/init.md
├── lib/util/helpers.sh (file/JSON operations)
└── lib/util/devcontainer.sh (launch config after init)

lib/global/init.md
└── lib/util/helpers.sh (file/directory operations, prompts)

lib/global/config.md
└── lib/util/helpers.sh (file/JSON operations)
```

---

## Script Mapping

| Pseudocode File     | Implementation Script              | Type     |
|---------------------|------------------------------------|----------|
| detect.md           | scripts/lib/util/detect.sh         | Utility  |
| helpers.md          | scripts/lib/util/helpers.sh        | Utility  |
| devcontainer.md     | scripts/lib/util/devcontainer.sh   | Utility  |
| prerequisites.md    | scripts/lib/util/prerequisites.sh  | Utility  |

---

## Implementation Notes

**Sourcing**: All utility scripts should be sourced (not executed):
```bash
source "$SCRIPT_DIR/lib/util/helpers.sh"
source "$SCRIPT_DIR/lib/util/detect.sh"
# etc.
```

**Naming convention**: Functions use snake_case (e.g., `get_uid_gid`, `launch_mode`)

**Error handling**: Utilities use EXIT codes but don't exit themselves - they return error codes for caller to handle

**Platform support**: All utilities handle Linux, macOS, and WSL2 (Windows is deprecated)
