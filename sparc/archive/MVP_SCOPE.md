# BitBot MVP Scope

**Created**: 2025-10-20
**Purpose**: Define minimal viable product to validate core architecture

---

## MVP Philosophy

**Goal**: Prove the two-container security model works with minimal features
**Timeline**: 2-3 weeks implementation
**Success Criteria**: Can launch work/config containers, basic safety works
**Platform Strategy**: Linux, macOS, and Windows (via WSL) for cross-platform simplicity
**Installation**: Portable - self-contained folder that can be moved anywhere

---

## ✓ MVP Core Features (Keep)

### Commands (6 total)
1. **`bitbot work [vscode]`** - Launch work devcontainer (optionally in VS Code)
2. **`bitbot config [vscode]`** - Launch config devcontainer (optionally in VS Code)
3. **`bitbot vscode`** - Launch VS Code in work container
4. **`bitbot init`** - Initialize workspace → launches config mode
5. **`bitbot help`** - Basic help text
6. **`bitbot version`** - Show version + dependency status

**Note**: `vscode` can be used as both a command and a modifier

### Core Features
- **Workspace detection**: CWD only (no parent search), prompt for init if not found
- **Two devcontainers**:
  - Work: Uses workspace's `.devcontainer/` (read-only mount)
  - Config: Uses global `templates/bitbot/config/`
- **Single session**: One tmux session per container (auto-named)
- **Git safety warnings**: Non-blocking warnings on uncommitted changes (both modes)
- **Global init**: First run creates `config.json` in install folder, adds to PATH, sets BITBOT_HOME
- **UID sync**: Handled natively by devcontainer CLI (updateRemoteUserUID + common-utils)
- **VS Code integration**: `bitbot vscode` launches VS Code in work container
- **Dependency checking**: Runtime validation of Docker, DevContainer CLI, VS Code extension
  - Auto-start Docker if not running (with confirmation)
  - Detect and offer to install missing devcontainer CLI
  - WSL Docker integration setup assistance
  - Comprehensive status in `bitbot version` command

### Security (Simplified)
- **Work mode**: Workspace's `.devcontainer` + RO bind mount for .devcontainer folder
- **Config mode**: Global devcontainer + workspace at /workspace (RW by default)
- **Both modes**: Git warnings prevent accidents (non-blocking)
- **AI agent tuning**: Config devcontainer has docs on devcontainers, features, etc.

### Architecture
```
{INSTALL_BASE_PATH}/bitbot/  (e.g., ~/bitbot, /opt/bitbot, etc.)
├── bitbot                           # Main entry script (bash)
├── bitbot.ps1                       # PowerShell wrapper
├── bitbot.bat                       # Batch wrapper
├── core/
│   ├── global/                      # Global context commands
│   │   ├── bitbot-init.sh
│   │   └── bitbot-config.sh
│   ├── workspace/                   # Workspace context commands
│   │   ├── bitbot-work.sh
│   │   ├── bitbot-config.sh
│   │   ├── bitbot-init.sh
│   │   └── bitbot-help.sh
│   ├── util/                        # Shared utilities
│   │   ├── prerequisites.sh         # Dependency checking
│   │   ├── devcontainer.sh          # DevContainer launch
│   │   ├── detect.sh                # Workspace detection
│   │   ├── git.sh                   # Git safety utilities
│   │   └── helpers.sh               # Common utilities
│   └── bitbot-version.sh            # Version command (universal)
├── templates/
│   └── bitbot/
│       ├── config/                  # Global config mode devcontainer
│       │   ├── devcontainer.json    # Mounts any workspace via env var
│       │   └── Dockerfile
│       └── workspace/               # Base template for workspace .devcontainer
│           ├── devcontainer.json    # Minimal template with BitBot defaults
│           └── Dockerfile           # Base Alpine/Ubuntu image
├── config.json                      # Global BitBot config (created during global init)
└── pseudocode/                      # Documentation

Note: NO ~/.bitbot/ directory - everything stays in installation folder (portable design)

<workspace>/
├── .devcontainer/                   # Work mode config
│   ├── devcontainer.json            # Includes RO mount for .devcontainer
│   └── Dockerfile
└── .bitbot/
    ├── config.json                  # Workspace config
    ├── local/                       # Local runtime data (gitignored - history, cache, locks)
    │   └── .bash_history            # Persistent bash history mountpoint
    └── internal/                    # BitBot internals (not mounted)
        └── devcontainer.json        # Per-workspace config mode config
```

---

## ✗ Cut from MVP (Future Features)

### Commands (Cut)
- `bitbot list/stop/kill` - Use `docker ps`, `docker stop` for now
- `bitbot config` - Manual `.bitbot/config.yml` editing for MVP
- `bitbot mcp` - MCP services are future feature
- `bitbot agent` - AI agent config is future feature
- `bitbot backup` - Manual git commits for MVP
- `bitbot metadata` - Use `cat .bitbot/metadata.json`
- `bitbot session` - Single session only in MVP
- `bitbot doctor` - Manual checks for MVP
- Container `bitbot done` - Manual `exit` for MVP

### Features (Cut)
- **Non-interactive mode** (`--non-interactive`) - Interactive only for MVP
- **Workspace flag** (`--workspace <path>`) - CWD-based only for MVP
- **Parent workspace search** - CWD only, no parent directory search
- **Session selection menu** - Single session, no selection needed
- **Session naming** - Auto-timestamped only (e.g., `work-20251020-143022`)
- **Audit logging** (`.bitbot/audit.log`) - Future compliance feature
- **Approval tracking** (`.bitbot/approvals.json`) - Future audit trail
- **Backup management** - Use `git commit && git push` manually
- **Template wizard** - Use default `.devcontainer` or copy manually
- **MCP services** - Phase 2 feature (not in MVP)
- **AI agent integration** - Phase 2 feature (not in MVP)
- **Multi-container scenarios** - Work and setup only for MVP

### Simplified Behaviors
- **Global init** (first run in BitBot folder): Create config.json → add to PATH → set BITBOT_HOME
- **Workspace init**: Create `.bitbot/` → always launch config mode to configure .devcontainer
- **Git safety**: Warning messages only (non-blocking for both work and config)
- **Config mode**: Just another devcontainer (no approval flow, flags, or audit)
- **Error handling**: Basic error messages, no fancy recovery
- **Session management**: Create one session, attach to it, done
- **Platform support**: Windows supported via WSL (not native) for cross-platform simplicity

---

## MVP Command Matrix

| Command                 | MVP | Future | Alternative for MVP                            |
|-------------------------|-----|--------|------------------------------------------------|
| `bitbot work [vscode]`  | ✓   | -      | -                                              |
| `bitbot config [vscode]`| ✓   | -      | -                                              |
| `bitbot init`           | ✓   | ✓      | Manual `.devcontainer` setup                   |
| `bitbot help`           | ✓   | -      | -                                              |
| `bitbot version`        | ✓   | -      | -                                              |
| `bitbot list`     | ✗   | ✓      | `docker ps \| grep bitbot`                     |
| `bitbot stop`     | ✗   | ✓      | `docker stop <container>`                      |
| `bitbot kill`     | ✗   | ✓      | `docker stop $(docker ps -q --filter name=...)`|
| `bitbot mcp`      | ✗   | ✓      | N/A (Phase 2 feature)                          |
| `bitbot agent`    | ✗   | ✓      | N/A (Phase 2 feature)                          |
| `bitbot backup`   | ✗   | ✓      | `git commit && git push`                       |
| `bitbot session`  | ✗   | ✓      | N/A (single session MVP)                       |
| `bitbot doctor`   | ✗   | ✓      | Use `bitbot version` (shows dependency status) |

---

## MVP File Structure

**Minimal `.bitbot/` directory:**
```
.bitbot/
├── config.json                # Workspace config (name, default_mode)
├── local/                     # Local runtime data (gitignored - history, cache, locks)
│   └── .bash_history          # Persistent bash history
└── internal/                  # BitBot internals (not mounted)
    └── devcontainer.json      # Per-workspace config mode config
```

**Local directory contents** (gitignored):
- `.bash_history` - Persistent shell history mountpoint
- Lock files (future) - Prevent concurrent operations
- Cache (future) - Temporary runtime data

**No MVP:**
- `sessions/*.json` - Single session, no metadata tracking
- `backups/` - Use git directly
- `approvals.json` - No audit trail
- `audit.log` - No logging
- `agent.yml` - No AI config
- `mcp/` - No MCP services
- `metadata.json` - Replaced by config.json

---

## MVP Implementation Order

### Week 1: Core Foundation
1. **Shared utilities** (core/util/*.sh)
   - helpers.sh - Common utilities (file, JSON, path, prompts)
   - detect.sh - Workspace detection (CWD only)
   - prerequisites.sh - Dependency checking + Docker auto-start
   - devcontainer.sh - DevContainer CLI wrapper
2. **Global init** (core/global/bitbot-init.sh) - Create config.json, add to PATH, set env
3. **CLI entry** (bitbot) - Main router (6 commands)

### Week 2: Commands
4. **Work mode** (core/workspace/bitbot-work.sh) - Launch work devcontainer
5. **Config mode** (core/workspace/bitbot-config.sh) - Launch config devcontainer
6. **Init command** (core/workspace/bitbot-init.sh) - Initialize workspace
7. **Help/Version** (core/workspace/bitbot-help.sh, core/bitbot-version.sh)
8. **VS Code integration** - Launch via `bitbot vscode`

### Week 3: Testing & Polish
9. Test work/config modes on WSL2, Linux, macOS
10. Test dependency checking (missing Docker, devcontainer CLI, etc.)
11. Test WSL Docker integration setup
12. Polish error messages
13. Write basic README

---

## Success Metrics (MVP)

- [ ] Global init adds bitbot to PATH (first run in install folder)
- [ ] Can initialize workspace with `bitbot init`
- [ ] Can launch work container with `bitbot work`
- [ ] Can launch config container with `bitbot config`
- [ ] Files created in container have correct host UID
- [ ] `.devcontainer` is read-only in work mode
- [ ] `.devcontainer` is read-write in config mode
- [ ] Git warnings show on uncommitted changes
- [ ] Help and version commands work
- [ ] `bitbot vscode` launches VS Code
- [ ] Works on Linux, macOS, WSL2 (Windows support via WSL for simplicity)
- [ ] Dependency checking validates Docker, DevContainer CLI, VS Code extension
- [ ] Auto-starts Docker if not running (with confirmation)
- [ ] WSL Docker integration setup assistance works

---

## Post-MVP Priorities (Future Features)

**Phase 2a: Usability** (Week 4-5)
- Non-interactive mode (`--non-interactive`)
- Session management (`bitbot list/stop`)
- Workspace override (`--workspace <path>`)
- Parent directory workspace search
- Global service compose (launch from BitBot folder)

**Phase 2b: Safety** (Week 6-7)
- Audit logging (`.bitbot/audit.log`)
- Approval tracking for config mode (`.bitbot/approvals.json`)
- Config mode approval flow (`--allow-socket`, `--reason`)
- Git checkpoints (automatic stash before changes)
- Backup management (`bitbot backup`)

**Phase 3: Advanced** (Week 8+)
- Template wizard (`bitbot init --template`)
- MCP service management (`bitbot mcp`)
- AI agent integration (`bitbot agent`)
- Diagnostics (`bitbot doctor`)
- Multi-session support

---

## Validation Checklist

Before moving to implementation:
- [ ] MVP scope covers core use case (work + setup modes)
- [ ] All cut features have alternatives for MVP
- [ ] No blocking dependencies on cut features
- [ ] Timeline realistic (2-3 weeks)
- [ ] Can demonstrate value with MVP features only

---

**Status**: ✅ MVP Scope Defined and Simplified
**Next**: Implement MVP bash scripts
**Target**: 2-3 week MVP validating two-devcontainer architecture
