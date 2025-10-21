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

### Commands (6 total)
1. **`bitbot work`** - Launch work container via @devcontainers/cli
2. **`bitbot setup --allow-socket --reason "..."`** - Launch setup container
3. **`bitbot vscode`** - Launch VS Code attached to work container
4. **`bitbot init`** - Initialize workspace (default .devcontainer, no wizard)
5. **`bitbot help`** - Basic help text
6. **`bitbot version`** - Show version

### Core Features
- **Workspace detection**: CWD only (no parent search), prompt for init if not found
- **Container launch**: Work (@devcontainers/cli) and Setup (docker-compose)
- **Single session**: One tmux session per container (auto-named by timestamp)
- **Git safety warnings**: Non-blocking warnings on uncommitted changes
- **Basic first-run**: Check Docker/Git, create `~/.bitbot/` (no template wizard)
- **UID sync**: Host UID = container UID for file permissions
- **VS Code integration**: `bitbot vscode` launches VS Code in work container

### Security
- Work mode: `.devcontainer` read-only, no docker socket
- Setup mode: Requires `--allow-socket` + `--reason` flags
- Setup mode: `.bitbot/setup/` not mounted (invisible to containers)

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
- **First-run wizard**: Check prerequisites → create `~/.bitbot/` → done (no workspace wizard)
- **Workspace init**: Create minimal `.bitbot/` + default `.devcontainer/` → done (no template selection)
- **Git safety**: Warning messages only (not blocking, no checkpoints)
- **Error handling**: Basic error messages, no fancy recovery
- **Session management**: Create one session, attach to it, done

---

## MVP Command Matrix

| Command | MVP | Future | Alternative for MVP |
|---------|-----|--------|---------------------|
| `bitbot work` | ✓ | - | - |
| `bitbot setup --allow-socket --reason "..."` | ✓ | - | - |
| `bitbot init` | ✓ | Enhanced wizard | Manual `.devcontainer` setup |
| `bitbot help` | ✓ | - | - |
| `bitbot version` | ✓ | - | - |
| `bitbot vscode` | ✓ | - | - |
| `bitbot list` | ✗ | ✓ | `docker ps \| grep bitbot` |
| `bitbot stop` | ✗ | ✓ | `docker stop <container>` |
| `bitbot kill` | ✗ | ✓ | `docker stop $(docker ps -q --filter name=bitbot)` |
| `bitbot config` | ✗ | ✓ | Edit `.bitbot/config.yml` manually |
| `bitbot mcp` | ✗ | ✓ | N/A (Phase 2 feature) |
| `bitbot agent` | ✗ | ✓ | N/A (Phase 2 feature) |
| `bitbot backup` | ✗ | ✓ | `git commit && git push` |
| `bitbot metadata` | ✗ | ✓ | `cat .bitbot/metadata.json` |
| `bitbot session` | ✗ | ✓ | N/A (single session MVP) |
| `bitbot doctor` | ✗ | ✓ | Manual checks |

---

## MVP File Structure

**Minimal `.bitbot/` directory:**
```
.bitbot/
├── metadata.json              # Workspace info (workspace_hash, created, mode)
├── docker-compose.work.yml    # Work container (generated)
├── docker-compose.setup.yml   # Setup container (generated)
└── setup/                     # Setup container internals (not mounted)
    ├── Dockerfile
    └── docker-compose.yml
```

**No MVP:**
- `sessions/*.json` - Single session, no tracking
- `backups/` - Use git directly
- `approvals.json` - No audit trail
- `audit.log` - No logging
- `agent.yml` - No AI config
- `mcp/` - No MCP services

---

## MVP Implementation Order

### Week 1: Core Foundation
1. **Workspace detection** (02_workspace-detect.md) - Simplified
2. **Container launch** (03_container-launch.md) - Work and setup only
3. **CLI entry** (01A_cli-entry-host.md) - 5 commands only

### Week 2: Integration
4. **UID sync** (07_uid-sync.md)
5. **Mode system** (04_mode-system.md) - Warnings only
6. **First-run** (06_first-run.md) - Simplified

### Week 3: Testing & Polish
7. Test work/setup modes
8. Test UID sync on different systems
9. Polish error messages
10. Write basic README

---

## Success Metrics (MVP)

- [ ] Can initialize workspace with `bitbot init`
- [ ] Can launch work container with `bitbot work`
- [ ] Can launch setup container with `bitbot setup --allow-socket --reason "..."`
- [ ] Files created in container have correct host UID
- [ ] `.devcontainer` is read-only in work mode
- [ ] `.devcontainer` is read-write in setup mode
- [ ] Git warnings show on uncommitted changes
- [ ] Help and version commands work
- [ ] Works on Linux, macOS, WSL2

---

## Post-MVP Priorities (Future Features)

**Phase 2a: Usability** (Week 4-5)
- Non-interactive mode (`--non-interactive`)
- VS Code integration (`bitbot vscode`)
- Session management (`bitbot list/stop`)
- Workspace override (`--workspace <path>`)

**Phase 2b: Safety** (Week 6-7)
- Audit logging (`.bitbot/audit.log`)
- Approval tracking (`.bitbot/approvals.json`)
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

**Status**: ✅ MVP Scope Defined
**Next**: Simplify pseudocode to match MVP scope
**Target**: Implementation-ready pseudocode for 2-3 week MVP
