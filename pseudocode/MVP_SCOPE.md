# BitBot MVP Scope

**Created**: 2025-10-20
**Purpose**: Define minimal viable product to validate core architecture

---

## MVP Philosophy

**Goal**: Prove the two-container security model works with minimal features
**Timeline**: 2-3 weeks implementation
**Success Criteria**: Can launch work/setup containers, basic safety works

---

## ✓ MVP Core Features (Keep)

### Commands (5 total + vscode modifier)
1. **`bitbot work [vscode]`** - Launch work devcontainer (optionally in VS Code)
2. **`bitbot config [vscode]`** - Launch config devcontainer (optionally in VS Code)
3. **`bitbot init`** - Initialize workspace → launches config mode
4. **`bitbot help`** - Basic help text
5. **`bitbot version`** - Show version

**Note**: `vscode` is a modifier, not a command (e.g., `bitbot work vscode`)

### Core Features
- **Workspace detection**: CWD only (no parent search), prompt for init if not found
- **Two devcontainers**:
  - Work: Uses workspace's `.devcontainer/`
  - Config: Uses global `~/.bitbot/config-devcontainer/`
- **Single session**: One tmux session per container (auto-named by timestamp)
- **Git safety warnings**: Non-blocking warnings on uncommitted changes (both modes)
- **Global init**: First run in BitBot folder adds to PATH, creates `~/.bitbot/`
- **UID sync**: Host UID = container UID for file permissions
- **VS Code integration**: `bitbot vscode` launches VS Code in work container

### Security (Simplified)
- **Work mode**: Workspace's `.devcontainer` + RO bind mount for .devcontainer folder
- **Config mode**: Global devcontainer + workspace at /workspace (RW by default)
- **Both modes**: Git warnings prevent accidents (non-blocking)
- **AI agent tuning**: Config devcontainer has docs on devcontainers, features, etc.

### Architecture
```
/opt/bitbot/  (or user's install location)
├── scripts/
│   ├── bitbot                   # Main entry script (bash)
│   ├── bitbot.ps1               # PowerShell wrapper
│   └── bitbot.bat               # Batch wrapper
└── pseudocode/                  # Documentation

~/.bitbot/  (created after global init)
├── config-devcontainer/         # Global config mode devcontainer
│   ├── devcontainer.json        # Mounts any workspace via env var
│   └── Dockerfile
├── config.json                  # Global BitBot config (PATH, BITBOT_HOME)
└── first-run                    # Marker file

<workspace>/
├── .devcontainer/               # Work mode config
│   ├── devcontainer.json        # Includes RO mount for .devcontainer
│   └── Dockerfile
└── .bitbot/
    ├── config.json              # Workspace config
    ├── state/                   # Runtime state (empty for MVP)
    └── internal/                # BitBot internals (not mounted)
        └── devcontainer.json    # Per-workspace config mode config
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
- **Global init** (first run in BitBot folder): Add to PATH → set BITBOT_HOME → create ~/.bitbot/
- **Workspace init**: Create `.bitbot/` → always launch config mode to configure .devcontainer
- **Git safety**: Warning messages only (non-blocking for both work and config)
- **Config mode**: Just another devcontainer (no approval flow, flags, or audit)
- **Error handling**: Basic error messages, no fancy recovery
- **Session management**: Create one session, attach to it, done

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
| `bitbot doctor`   | ✗   | ✓      | Manual checks                                  |

---

## MVP File Structure

**Minimal `.bitbot/` directory:**
```
.bitbot/
├── config.json                # Workspace config (name, default_mode)
├── state/                     # Runtime state (empty for MVP)
└── internal/                  # BitBot internals (not mounted)
    └── devcontainer.json      # Per-workspace config mode config
```

**No MVP:**
- `sessions/*.json` - Single session, no tracking
- `backups/` - Use git directly
- `approvals.json` - No audit trail
- `audit.log` - No logging
- `agent.yml` - No AI config
- `mcp/` - No MCP services
- `metadata.json` - Replaced by config.json

---

## MVP Implementation Order

### Week 1: Core Foundation
1. **Global init** (06_first-run.md) - Add to PATH, create ~/.bitbot/
2. **Workspace detection** (02_workspace-detect.md) - CWD only
3. **Container launch** (03_container-launch.md) - Work and config only
4. **CLI entry** (01A_cli-entry-host.md) - 6 commands

### Week 2: Integration
5. **UID sync** (07_uid-sync.md)
6. **Mode system** (04_mode-system.md) - Git warnings only
7. **VS Code integration** - Simple code launch

### Week 3: Testing & Polish
7. Test work/setup modes
8. Test UID sync on different systems
9. Polish error messages
10. Write basic README

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
- [ ] Works on Linux, macOS, WSL2

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
