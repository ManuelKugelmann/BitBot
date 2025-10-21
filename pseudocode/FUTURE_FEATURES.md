# Future Features Backlog

**Created**: 2025-10-20
**Purpose**: Track features cut from MVP for future implementation

---

## Features Cut from MVP

### Phase 2a: Automation & Usability (Post-MVP)

**Non-Interactive Mode** (`--non-interactive`)
- **Cut from**: All commands
- **Use case**: CI/CD pipelines, automation scripts
- **Implementation**: Add flag handling, disable all prompts, fail on ambiguous situations
- **Files affected**: 01A, 02, 05
- **Priority**: High (needed for automation)

**Workspace Override** (`--workspace <path>`)
- **Cut from**: Workspace detection (02)
- **Use case**: Work with workspace outside CWD
- **Implementation**: Add flag parsing, path validation
- **Alternative for MVP**: `cd` to workspace directory
- **Priority**: Medium

**Parent Workspace Search**
- **Cut from**: Workspace detection (02)
- **Use case**: Auto-use parent directory workspace
- **Implementation**: Check parent → prompt user → auto-use or init in CWD
- **Alternative for MVP**: Must run `bitbot` from workspace directory
- **Priority**: Medium

### Phase 2b: Session Management (Post-MVP)

**Multi-Session Support**
- **Cut from**: Session management (05)
- **Use case**: Multiple parallel work sessions
- **Features**:
  - Session listing (`bitbot list`)
  - Session selection menu
  - Custom session names/tags
  - Session metadata (`.bitbot/sessions/`)
- **Alternative for MVP**: One session per container, use separate containers for parallel work
- **Priority**: Medium

**Session Commands**
- `bitbot list` - List active sessions
- `bitbot stop --session <name>` - Stop specific session
- `bitbot kill` - Stop all BitBot containers
- `bitbot session` - Session management subcommands
- **Alternative for MVP**: Use `docker ps`, `docker stop`
- **Priority**: Low

### Phase 2c: Safety & Audit (Post-MVP)

**Setup Mode Approval Flow**
- **Cut from**: Setup mode (04)
- **Use case**: Audit trail for infrastructure changes
- **Features**:
  - `--allow-socket` and `--reason` flags
  - Approval tracking (`.bitbot/approvals.json`)
  - Prompt for confirmation before setup mode
  - Logged reason for each setup session
- **Alternative for MVP**: Setup is just another devcontainer (no approval)
- **Priority**: Medium (nice for audit, not essential)

**Audit Logging**
- **Cut from**: All commands
- **File**: `.bitbot/audit.log`
- **Use case**: Compliance, debugging, security review
- **Features**:
  - Command logging with timestamps
  - Mode switches logged
  - Git operations logging
- **Alternative for MVP**: Manual git commits for audit trail
- **Priority**: High (compliance requirement)

**Git Safety Enhancements**
- **Cut from**: Mode system (04)
- **Features**:
  - Blocking checks (not just warnings)
  - Automatic git checkpoints/stash before changes
  - Git bundle backup before risky operations
  - Uncommitted changes protection (strict mode)
- **Alternative for MVP**: Manual `git commit` before setup mode
- **Priority**: High (data loss prevention)

**Backup Management** (`bitbot backup`)
- **Cut from**: CLI commands
- **Use case**: Automated workspace backups
- **Features**:
  - Git bundle creation
  - Backup listing/restore
  - Scheduled backups
- **Alternative for MVP**: `git commit && git push`
- **Priority**: Medium

### Phase 3: Advanced Features (Post-MVP)

**Template System**
- **Cut from**: Workspace init (02), first-run (06)
- **Use case**: Quick project initialization with templates
- **Features**:
  - Template wizard during `bitbot init`
  - Template repository (`~/.bitbot/templates/`)
  - Stack templates (Python, Node.js, Go, etc.)
  - `bitbot template` management commands
- **Alternative for MVP**: Manual `.devcontainer` setup or copy from examples
- **Priority**: Low

**Configuration Management** (`bitbot config`)
- **Cut from**: CLI commands
- **Use case**: Interactive BitBot configuration
- **Features**:
  - Interactive wizard for `.bitbot/config.yml`
  - Default mode selection
  - Memory/CPU limits
  - Network settings
- **Alternative for MVP**: Manual YAML editing
- **Priority**: Low

**MCP Service Management** (`bitbot mcp`)
- **Cut from**: CLI commands (Phase 2 feature)
- **Use case**: Manage MCP sidecar services
- **Features**:
  - `bitbot mcp list/start/stop/logs/restart`
  - Service health monitoring
  - `.bitbot/mcp/docker-compose.yml` management
- **Alternative for MVP**: Not available (Phase 2)
- **Priority**: Phase 2 (not MVP)

**AI Agent Integration** (`bitbot agent`)
- **Cut from**: CLI commands, container commands (01B)
- **Use case**: Configure and launch AI agents
- **Features**:
  - Agent selection wizard
  - Configuration management (`.bitbot/agent.yml`)
  - Agent lifecycle commands
  - `bitbot done` workflow (review → commit → exit)
- **Alternative for MVP**: Manual AI agent setup
- **Priority**: Phase 2 (not MVP)

**Diagnostics** (`bitbot doctor`)
- **Cut from**: CLI commands
- **Use case**: Troubleshooting and health checks
- **Features**:
  - Docker daemon check
  - Workspace integrity check
  - MCP service health
  - Disk space warnings
  - Configuration validation
- **Alternative for MVP**: Manual checks
- **Priority**: Low

**Metadata Display** (`bitbot metadata`)
- **Cut from**: CLI commands
- **Use case**: Show workspace information
- **Alternative for MVP**: `cat .bitbot/metadata.json`
- **Priority**: Low

### Phase 3b: Platform-Specific

**Windows Integration**
- **Features**:
  - PowerShell launcher (`bitbot.ps1`)
  - Batch launcher (`bitbot.bat`)
  - WSL2 detection and setup
  - BitBot-Alpine distribution
- **Alternative for MVP**: Run from WSL manually
- **Priority**: High (Windows support)

**First-Run Wizard Enhancements**
- **Cut from**: First-run (06)
- **Features**:
  - Template selection during first run
  - Workspace initialization wizard
  - MCP service setup
  - AI agent configuration
- **Alternative for MVP**: Basic prerequisite checks only
- **Priority**: Low

---

## Simplifications Summary

### Removed from MVP:

**Commands** (10 removed, 6 kept):
- ✗ `bitbot list` → Use `docker ps`
- ✗ `bitbot stop` → Use `docker stop`
- ✗ `bitbot kill` → Use `docker stop $(docker ps -q --filter name=bitbot)`
- ✗ `bitbot config` → Edit `.bitbot/config.yml` manually
- ✗ `bitbot mcp` → Phase 2 feature
- ✗ `bitbot agent` → Phase 2 feature
- ✗ `bitbot backup` → Use `git commit && git push`
- ✗ `bitbot metadata` → Use `cat .bitbot/metadata.json`
- ✗ `bitbot session` → Single session only
- ✗ `bitbot doctor` → Manual checks

**Flags/Options** (2 removed):
- ✗ `--non-interactive` → Interactive only for MVP
- ✗ `--workspace <path>` → CWD-based only for MVP

**Features**:
- ✗ Multi-session support → Single session per container
- ✗ Session selection menu → Auto-attach to existing
- ✗ Session metadata tracking → No `.bitbot/sessions/`
- ✗ Audit logging → No `.bitbot/audit.log`
- ✗ Approval tracking → No `.bitbot/approvals.json`
- ✗ Git strict checks → Warnings only
- ✗ Template wizard → Requires existing `.devcontainer`
- ✗ Parent workspace search → CWD only
- ✗ Smart launch logic → Default to `bitbot work`

### Kept in MVP:

**Commands** (6 total):
- ✓ `bitbot [work]` - Launch work devcontainer (default)
- ✓ `bitbot setup` - Launch setup devcontainer (edit .devcontainer)
- ✓ `bitbot vscode` - Launch VS Code in work container
- ✓ `bitbot init` - Initialize workspace
- ✓ `bitbot help` - Show help
- ✓ `bitbot version` - Show version

**Core Features**:
- ✓ Workspace detection (CWD only, no parent search)
- ✓ Two devcontainers (work: `.devcontainer/`, setup: `.devcontainer-setup/`)
- ✓ VS Code integration (`bitbot vscode`)
- ✓ Single session (auto-named, auto-attach)
- ✓ Git warnings (non-blocking for both modes)
- ✓ UID sync (host UID = container UID)
- ✓ Basic first-run (prerequisites check)
- ✓ Simple setup mode (no approval flow)

---

## Implementation Priority

**Immediate Post-MVP** (Week 4-5):
1. Non-interactive mode (automation)
2. Windows launchers (cross-platform)
3. VS Code integration (usability)

**Phase 2a** (Week 6-7):
4. Session management (list/stop)
5. Audit logging (compliance)
6. Workspace override flag

**Phase 2b** (Week 8-10):
7. Template system (onboarding)
8. Git safety enhancements (data loss prevention)
9. Backup management

**Phase 3** (Week 11+):
10. MCP services (Phase 2 architecture)
11. AI agent integration (Phase 2 architecture)
12. Advanced features (config, doctor, metadata)

---

## Migration Path

**From MVP to Full Feature Set:**

1. **Add non-interactive mode** - Add flag handling, no breaking changes
2. **Add session management** - Backward compatible, single session still works
3. **Add audit logging** - Append-only log, no breaking changes
4. **Add template system** - Optional during init, manual setup still works
5. **Add advanced commands** - New commands, don't affect existing workflows

**No Breaking Changes Expected**: MVP will be a true subset of full feature set

---

**Status**: ✅ Backlog Created
**Next**: Implement MVP, validate architecture, then incrementally add features
**Timeline**: MVP (3 weeks) → Phase 2a (2 weeks) → Phase 2b (3 weeks) → Phase 3 (ongoing)
