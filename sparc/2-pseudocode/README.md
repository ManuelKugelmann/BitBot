# BitBot Pseudocode

**Status**: Phase 2 (Pseudocode) - Complete
**Created**: 2025-10-20
**Updated**: 2025-10-24
**SPARC Phase**: 2 of 5

---

## Overview

Comprehensive pseudocode for BitBot implementation. Files are organized to mirror the final script structure, providing a 1:1 mapping between pseudocode and implementation.

**Purpose**: Bridge specification and implementation with clear, implementation-ready algorithms
**Platform**: Linux, macOS, Windows (via WSL)

---

## File Structure

```
pseudocode/
├── bitbot.md                    # Main router (bitbot)
├── lib/
│   ├── global/                  # Global context commands
│   │   ├── init.md             → scripts/lib/global/bitbot-init.sh
│   │   └── config.md           → scripts/lib/global/bitbot-config.sh
│   ├── workspace/              # Workspace context commands
│   │   ├── work.md             → scripts/lib/workspace/bitbot-work.sh
│   │   ├── config.md           → scripts/lib/workspace/bitbot-config.sh
│   │   ├── init.md             → scripts/lib/workspace/bitbot-init.sh
│   │   └── help.md             → scripts/lib/workspace/bitbot-help.sh
│   ├── util/                   # Shared utilities
│   │   ├── README.md           # Utilities documentation
│   │   ├── prerequisites.md    → scripts/lib/util/prerequisites.sh
│   │   ├── devcontainer.md     → scripts/lib/util/devcontainer.sh
│   │   ├── detect.md           → scripts/lib/util/detect.sh
│   │   ├── git.md              → scripts/lib/util/git.sh
│   │   └── helpers.md          → scripts/lib/util/helpers.sh
│   └── version.md              → scripts/lib/bitbot-version.sh
└── README.md                   # This file
```

---

## Core Components

### Main Router
**File**: `bitbot.md`
**Script**: `bitbot`
**Purpose**: Entry point, context detection (global vs workspace), command routing

**Key Functions**:
- `main()` - Entry point with argument parsing
- `handle_host_commands()` - Route to workspace or global commands
- `validate_prerequisites()` - Check dependencies before commands
- `show_help()` / `show_version()` - Help and version display

**Commands**: 6 total (work, config, vscode, init, help, version)

---

### Global Context Commands

#### Global Init (lib/global/init.md)
**Purpose**: First-run setup (run `bitbot` from install folder)
**Creates**: config.json in install folder, adds to PATH, sets BITBOT_HOME
**Configures**: Default launch mode (terminal or VS Code)
**MVP**: After init, running from install folder only validates environment

**config.json structure** (global):
```json
{
  "version": "0.1.0-mvp",
  "created": "2025-01-15T10:30:00Z",
  "updated": "2025-01-15T10:30:00Z",
  "launch_mode": "vscode",              // "terminal", "vscode", or future options
  "skip_push_recommendation": false,
  "skip_safety_checks": false
}
```

**Workspace config.json structure** (`.bitbot/config.json`):
```json
{
  "default_mode": "work",
  "workspace_name": "my-project",
  "skip_push_recommendation": false,    // Override global setting
  "skip_safety_checks": false           // Override global setting
}
```

**Config merging**: Workspace settings override global settings (simple top-level merge)

#### Global Config (lib/global/config.md) - MVP+ Future
**Purpose**: Configure global BitBot settings (not in MVP)
**Will manage**: Template selection, MCP configuration, AI agent defaults

---

### Workspace Context Commands

#### Work Mode (lib/workspace/work.md)
**Purpose**: Launch work devcontainer (RO .devcontainer)
**Uses**: Workspace's `.devcontainer/` + RO bind mount
**Flags**: `--vscode` or `--terminal` to override default launch mode

#### Config Mode (lib/workspace/config.md)
**Purpose**: Launch config devcontainer with AI agent (RW .devcontainer)
**Uses**: Workspace-specific `.bitbot/internal/devcontainer.json` (references global `config-devcontainer/Dockerfile`)
**Created**: During `bitbot init` - adjusted copy of global config devcontainer template
**Flags**: `--vscode` or `--terminal` to override default launch mode
**MVP**: AI agent provides guidance and help for .devcontainer setup - no wizard

#### Init (lib/workspace/init.md)
**Purpose**: Initialize new BitBot workspace
**Creates**: `.bitbot/` structure
**Copies**: Base .devcontainer template (if not present)
**Launches**: Config mode after initialization (AI agent configures devcontainer)

#### Help (lib/workspace/help.md)
**Purpose**: Display workspace command help
**Shows**: Commands, modes, examples

---

### Shared Utilities (lib/util/)

See `lib/util/README.md` for detailed documentation.

#### Prerequisites (lib/util/prerequisites.md)
**Purpose**: Dependency checking and validation
**Features**:
- Docker check with auto-start (confirmation)
- DevContainer CLI detection (builtin/standalone)
- VS Code extension check
- WSL Docker integration setup
- Comprehensive dependency status display

**Based on**: test-windows-launch/scripts/bitbot implementation

#### DevContainer (lib/util/devcontainer.md)
**Purpose**: DevContainer CLI wrapper and launch functions
**Functions**:
- `launch_mode()` - Main mode launcher (work or config)
- `devcontainer_up()` - Work mode devcontainer launch
- `devcontainer_up_with_config()` - Config mode devcontainer launch
- `check_git_uncommitted()` - Git safety warnings

**Note**: UID/GID sync handled natively by devcontainer CLI (updateRemoteUserUID + common-utils)

#### Detect (lib/util/detect.md)
**Purpose**: Workspace detection and validation
**Functions**:
- `detect_workspace()` - Find BitBot workspace from CWD
- `validate_workspace()` - Check workspace validity
- `is_workspace_initialized()` - Check for .bitbot/

#### Git (lib/util/git.md)
**Purpose**: Git safety recommendations and checks
**Functions**:
- `recommend_git_push_before_init()` - Recommend git push before init/work/config
- `check_git_safety()` - Warn about uncommitted changes and public repo secrets
**Features**:
- Three scenarios: No repo, no remote, uncommitted/unpushed changes
- Config-based skip options (`skip_push_recommendation`, `skip_safety_checks`)
- Non-blocking 3-choice prompts (exit and fix / skip once / skip permanently)
- Instructions-only (no git automation)

#### Helpers (lib/util/helpers.md)
**Purpose**: Common utilities (file, JSON, path, prompts, output, config merging)
**Used by**: All scripts
**Categories**:
- File ops (create, read, write, check existence)
- JSON ops (read, write, **merge configs**)
- Path ops (current dir, absolute, basename, dirname)
- Prompts (yes/no, user input)
- Output formatting
- Timestamps

**Key Functions**:
- `merge_configs()` - Merge global + workspace configs (simple top-level merge)
- `get_merged_workspace_config()` - Helper for workspace config merging
- `update_workspace_config()` - Update specific config key (for saving user preferences)
- `prompt_choice()` - Multi-choice prompt helper (numbered choices)

---

### Universal Commands

#### Version (lib/version.md)
**Purpose**: Show version and dependency status
**Displays**: Version number + comprehensive dependency check (via show_doctor())

---

## MVP Commands

| Command | Description | Context |
|---------|-------------|---------|
| `bitbot work [vscode]` | Launch work mode | Workspace |
| `bitbot config [vscode]` | Launch config mode | Workspace |
| `bitbot vscode` | Launch VS Code | Workspace |
| `bitbot init` | Initialize workspace | Workspace |
| `bitbot help` | Show help | Workspace |
| `bitbot version` | Version + dependency status | Universal |

**Global context commands** (run from BitBot install folder):
- First run: Global init (creates config.json, adds to PATH, sets BITBOT_HOME)
- Subsequent: Environment validation only (MVP+: config and serve commands)

---

## Dependency Graph

```
bitbot.md (main router)
├── lib/util/prerequisites.sh (dependency validation)
├── lib/util/detect.sh (workspace detection)
└── Command routing:
    ├── Global context
    │   ├── lib/global/init.sh (first run)
    │   └── lib/global/config.sh (settings)
    └── Workspace context
        ├── lib/workspace/work.sh
        │   └── lib/util/devcontainer.sh
        ├── lib/workspace/config.sh
        │   └── lib/util/devcontainer.sh
        ├── lib/workspace/init.sh
        │   └── lib/util/devcontainer.sh (launches config)
        └── lib/workspace/help.sh

All scripts use:
└── lib/util/helpers.sh (common utilities)
```

---

## Key Architecture Decisions

### Platform Support
- **Linux**: Native support
- **macOS**: Native support
- **Windows**: Via WSL (not native) for cross-platform simplicity

### Portable Installation
- **Self-contained**: BitBot folder can be moved anywhere, everything stays in install folder
- **No ~/.bitbot/ directory**: All files including config.json are in the installation folder
- **No absolute paths**: config.json doesn't store install location
- **Auto-detection**: Detects when folder is moved and offers to update PATH/env
- **Environment validation**: All global commands validate and fix environment
- **WSL support**: Updates both WSL shell config AND Windows environment variables
  - Automatically converts WSL paths to Windows paths (e.g., /mnt/c/... → C:\...)
  - Uses PowerShell to set BITBOT_HOME and PATH in Windows User environment
  - Falls back to manual instructions if PowerShell not accessible

### DevContainer Template System
- **Base template**: Global `devcontainer-template/` provides minimal working config
- **Config devcontainer**:
  - Global `config-devcontainer/` contains Dockerfile and resources for AI agent setup
  - Each workspace gets `.bitbot/internal/devcontainer.json` (adjusted copy referencing global Dockerfile)
  - Created during `bitbot init` with workspace-specific mount configuration
- **AI-guided setup**: No interactive wizard in MVP - AI agent provides guidance and help
- **Template copying**: Workspace init copies base template if .devcontainer missing
- **AI agent capabilities**:
  - Runs in devcontainer with tools for devcontainer configuration
  - Provides guidance to configure .devcontainer for your tech stack
  - Helps set up development tools and dependencies
  - Parallel testing: Open another terminal and run `bitbot work` to test workspace devcontainer while config mode is running
- **Exit**: Close VS Code or terminal to finish config mode

### UID/GID Synchronization
- **Handled by**: DevContainer CLI natively
- **Method**: `updateRemoteUserUID: true` + `common-utils` feature
- **No manual sync**: No bash UID sync scripts needed

### Shell History Persistence (Bash)
- **MVP uses bash as default shell** (universal compatibility, pre-installed on all Linux distributions)
- **Work mode history**: `.bitbot/local/.bash_history`
- **Config mode history**: `.bitbot/internal/local/.bash_history`
- **Separate histories per mode**: Work and config have different contexts (development vs setup)
- **DevContainer configuration**: Sets `HISTFILE` environment variable
  - Configured in `remoteEnv` section of devcontainer.json
  - Work mode: `"HISTFILE": "/workspace/.bitbot/local/.bash_history"`
  - Config mode: `"HISTFILE": "/workspace/.bitbot/internal/local/.bash_history"`
- **Persistence**: History files persist across container rebuilds via host mounts
- **Future enhancement**: Zsh support with separate `.zsh_history` files (see FUTURE_FEATURES.md)

### Dependency Checking
- **Runtime**: Validates dependencies at every command invocation
- **Auto-fix**: Offers to start Docker, install devcontainer CLI
- **WSL**: Special Docker integration setup assistance
- **Display**: Comprehensive status in `bitbot version`

### Config Merging System
- **Two-level config**: Global (`{INSTALL}/config.json`) + Workspace (`.bitbot/config.json`)
- **Merge strategy**: Workspace overrides global (simple top-level merge)
- **No dependencies**: Pure bash implementation, no external tools required
- **Settings**:
  - `launch_mode` - Launch mode: "terminal", "vscode", etc. (global default, workspace can override)
  - `skip_push_recommendation` - Disable git push prompts (global or per-workspace)
  - `skip_safety_checks` - Disable git safety warnings (global or per-workspace)
- **Use case**: Set global defaults, override for specific projects
- **Implementation**: `get_merged_workspace_config()` in lib/util/helpers.md

### Mount Structure
- **Work mode**:
  - Workspace mounted (excluding `.bitbot/internal/`)
  - `.devcontainer/` mounted read-only for security
  - Special submounts: `.bitbot/local/.bash_history` → container bash history
- **Config mode**:
  - Workspace mounted (excluding `.bitbot/internal/`)
  - `.devcontainer/` writable (can be edited)
  - Special submounts: `.bitbot/internal/local/.bash_history` → container bash history
- **Exclusions**:
  - `.bitbot/internal/` never mounted in containers (contains config mode devcontainer.json on host)
  - Each mode has separate bash history and local data
- **Default shell**: bash (MVP), zsh support in future (see FUTURE_FEATURES.md)

### Security Model
- **Work mode**: Workspace's .devcontainer (RO bind mount)
- **Config mode**: Uses `.bitbot/internal/devcontainer.json` (references global Dockerfile, RW workspace)
- **Git safety**: Non-blocking warnings (both modes), configurable via `skip_*` settings
- **Simplified**: No approval flow or audit logging in MVP

### Session Management
- **Single session**: One tmux session per container
- **Auto-named**: Timestamp-based naming
- **Auto-attach**: Attach to existing or create new

---

## Implementation Order

### Week 1: Core Foundation
1. Shared utilities (lib/util/*.sh)
   - helpers.sh, detect.sh, prerequisites.sh, devcontainer.sh
2. Global init (lib/global/bitbot-init.sh)
3. CLI entry (bitbot)

### Week 2: Commands
4. Work mode (lib/workspace/bitbot-work.sh)
5. Config mode (lib/workspace/bitbot-config.sh)
6. Init command (lib/workspace/bitbot-init.sh)
7. Help/Version (lib/workspace/bitbot-help.sh, lib/bitbot-version.sh)
8. VS Code integration

### Week 3: Testing & Polish
9. Test work/config modes (WSL2, Linux, macOS)
10. Test dependency checking
11. Test WSL Docker integration
12. Polish error messages
13. Write README

---

## Pseudocode Conventions

### Control Flow
- `IF ... THEN ... ELSE ... END IF`
- `FOR EACH ... IN ... END FOR`
- `WHILE ... END WHILE`
- `SWITCH ... CASE ... DEFAULT ... END SWITCH`

### Functions
- `FUNCTION name(params) → return_type:`
- `CALL function(args) → result`
- `RETURN value`

### Operations
- `SET variable = value`
- `APPEND item to list`
- `EXECUTE command → output`
- `PRINT message`
- `ERROR message` / `WARN message`

### Comments
- `# Single-line comment`

---

## Testing Strategy

### Unit Tests
- Individual function logic
- Edge case handling
- Error conditions

### Integration Tests
- Component interactions
- Data flow between functions
- Dependency checking

### End-to-End Tests
- Complete user workflows
- First-run experience
- Mode switching (work ↔ config)
- VS Code integration

### Platform Tests
- Linux native
- macOS native
- WSL2 (Windows)
- Docker auto-start
- DevContainer CLI detection

---

## Success Metrics (MVP)

- [ ] Global init adds bitbot to PATH
- [ ] Can initialize workspace with `bitbot init`
- [ ] Can launch work container with `bitbot work`
- [ ] Can launch config container with `bitbot config`
- [ ] Files in container have correct host ownership (native UID sync)
- [ ] `.devcontainer` is read-only in work mode
- [ ] `.devcontainer` is read-write in config mode
- [ ] Git warnings show on uncommitted changes
- [ ] Help and version commands work
- [ ] `bitbot vscode` launches VS Code
- [ ] Works on Linux, macOS, WSL2
- [ ] Dependency checking validates Docker, DevContainer CLI
- [ ] Auto-starts Docker if not running
- [ ] WSL Docker integration setup works

---

## Next Steps (SPARC Phase 3: Architecture)

1. **Bash Script Implementation**
   - Translate pseudocode to bash
   - Add platform-specific handling
   - Implement error handling

2. **DevContainer Configurations**
   - Work mode devcontainer.json (RO mount)
   - Config mode devcontainer.json (workspace-specific, references global Dockerfile)
   - Feature configuration (common-utils for UID sync)

3. **Testing Framework**
   - Unit tests for utilities
   - Integration tests for commands
   - End-to-end workflow tests
   - Platform-specific tests (WSL, Linux, macOS)

4. **Documentation**
   - User guide
   - Installation instructions
   - Troubleshooting guide
   - Development guide

---

## Contributing

When modifying pseudocode:

1. **Follow conventions** (see above)
2. **Update mappings** (pseudocode file → script file)
3. **Document functions** (purpose, params, returns)
4. **Handle errors** (validate inputs, clear messages)
5. **Update README** (this file) and lib/util/README.md

---

## References

- **MVP Scope**: `MVP_SCOPE.md`
- **Future Features**: `FUTURE_FEATURES.md`
- **Utilities**: `lib/util/README.md`
- **Test Implementation**: `../test-windows-launch/scripts/bitbot`
- **Specifications**: `../Copilot_Specification/*.md`

---

**Status**: ✅ Phase 2 Complete - Ready for Implementation
**Next Phase**: Bash script implementation (Phase 3)
**Platform**: Linux, macOS, Windows (via WSL)
**Commands**: 6 total
**Scripts**: 14 total (1 main + 13 lib)
