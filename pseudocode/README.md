# BitBot Pseudocode (MVP)

**Status**: Phase 2 (Pseudocode) - Complete
**Created**: 2025-10-20
**Updated**: 2025-10-21
**SPARC Phase**: 2 of 5

---

## Overview

Comprehensive pseudocode for BitBot MVP implementation. Files are organized to mirror the final script structure, providing a 1:1 mapping between pseudocode and implementation.

**Purpose**: Bridge specification and implementation with clear, implementation-ready algorithms
**Platform**: Linux, macOS, Windows (via WSL)

---

## File Structure

```
pseudocode/
├── bitbot.md                    # Main router (scripts/bitbot)
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
│   │   └── helpers.md          → scripts/lib/util/helpers.sh
│   └── version.md              → scripts/lib/bitbot-version.sh
├── MVP_SCOPE.md                # MVP features and scope
├── FUTURE_FEATURES.md          # Post-MVP features
└── README.md                   # This file
```

---

## Core Components

### Main Router
**File**: `bitbot.md`
**Script**: `scripts/bitbot`
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
**Creates**: ~/.bitbot/ structure, adds to PATH, sets BITBOT_HOME
**Calls**: Global config after setup

#### Global Config (lib/global/config.md)
**Purpose**: Configure global BitBot settings (reusable)
**Manages**: ~/.bitbot/config.json, config devcontainer template

---

### Workspace Context Commands

#### Work Mode (lib/workspace/work.md)
**Purpose**: Launch work devcontainer (RO .devcontainer)
**Uses**: Workspace's `.devcontainer/` + RO bind mount
**Modifier**: `vscode` to launch in VS Code

#### Config Mode (lib/workspace/config.md)
**Purpose**: Launch config devcontainer (RW .devcontainer)
**Uses**: Global `~/.bitbot/config-devcontainer/` (RW by default)
**Modifier**: `vscode` to launch in VS Code

#### Init (lib/workspace/init.md)
**Purpose**: Initialize new BitBot workspace
**Creates**: `.bitbot/` structure
**Launches**: Config mode after initialization

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

#### Helpers (lib/util/helpers.md)
**Purpose**: Common utilities (file, JSON, path, prompts, output)
**Used by**: All scripts
**Categories**: File ops, JSON ops, path ops, prompts, output formatting, timestamps

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
- First run: Global init (adds to PATH, creates ~/.bitbot/)
- Subsequent: Global config or serve (future)

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

### UID/GID Synchronization
- **Handled by**: DevContainer CLI natively
- **Method**: `updateRemoteUserUID: true` + `common-utils` feature
- **No manual sync**: No bash UID sync scripts needed

### Dependency Checking
- **Runtime**: Validates dependencies at every command invocation
- **Auto-fix**: Offers to start Docker, install devcontainer CLI
- **WSL**: Special Docker integration setup assistance
- **Display**: Comprehensive status in `bitbot version`

### Security Model
- **Work mode**: Workspace's .devcontainer (RO bind mount)
- **Config mode**: Global devcontainer (RW .devcontainer by default)
- **Git safety**: Non-blocking warnings (both modes)
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
3. CLI entry (scripts/bitbot)

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
   - Config mode devcontainer.json (global template)
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
**Scripts**: 13 total (1 main + 12 lib)
