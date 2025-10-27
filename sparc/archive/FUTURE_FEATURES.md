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

**Default Shell Selection**
- **Cut from**: Global init, workspace init
- **Use case**: User preference for bash vs zsh in devcontainers
- **Implementation**:
  - Add shell selection prompt during global init
  - Store in global config: `"default_shell": "bash"` or `"zsh"`
  - Allow per-workspace override in `.bitbot/config.json`
  - Template devcontainer.json sets shell via `"containerEnv": {"SHELL": "/bin/bash"}` or `/bin/zsh`
  - Adjust history file configuration based on shell choice
- **Alternative for MVP**: Both bash and zsh history supported, user manually sets shell
- **Priority**: Low (nice-to-have, not essential)
- **Config Example**:
  ```json
  {
    "default_shell": "zsh",
    "shell_preferences": {
      "install_oh_my_zsh": false,
      "install_plugins": []
    }
  }
  ```
- **Commands**:
  - `bitbot config shell bash` - Set default shell to bash
  - `bitbot config shell zsh` - Set default shell to zsh
- **Files affected**:
  - Global init (shell preference prompt)
  - DevContainer templates (shell configuration)
  - Workspace init (copy shell preference to workspace)

**Git Worktree Multi-Agent Support**
- **Status**: Removed from implementation (2025-10-27)
- **Use case**: Multiple Claude instances working in isolated git worktrees
- **Reason for removal**: May integrate with ccmanager or similar third-party tool instead
- **Features considered**:
  - Timestamped worktree creation (`claude-YYYYMMDD-HHMMSS`)
  - Branch management for isolated workspaces
  - Sync commands to merge changes from main branch
  - Status tracking across worktrees
  - Automatic cleanup after PR merge
- **Alternative approach**: Use native git worktree commands or integrate with external tools like ccmanager
- **Priority**: Medium (useful for advanced multi-agent workflows)
- **Note**: ccstatusline integration with Git Worktree widget still supported for manual worktree usage

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
- `bitbot stop` - Stop current workspace's devcontainers (work and config)
- `bitbot kill` - Stop all BitBot containers
- `bitbot session` - Session management subcommands
- **Alternative for MVP**: Close VS Code or terminal to exit, use `docker ps`, `docker stop`
- **Priority**: Medium

### Phase 2c: Safety & Audit (Post-MVP)

**Setup Mode Approval Flow**
- **Cut from**: Setup mode (04)
- **Use case**: Audit trail for infrastructure changes
- **Features**:
  - `--allow-socket` and `--reason` flags
  - Approval tracking (`.bitbot/approvals.json`)
  - Prompt for confirmation before config mode
  - Logged reason for each config session
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
- **Alternative for MVP**: Manual `git commit` before config mode
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
- ✓ `bitbot config` - Launch config devcontainer (edit .devcontainer)
- ✓ `bitbot vscode` - Launch VS Code in work container
- ✓ `bitbot init` - Initialize workspace
- ✓ `bitbot help` - Show help
- ✓ `bitbot version` - Show version

**Core Features**:
- ✓ Workspace detection (CWD only, no parent search)
- ✓ Two devcontainers:
  - Work: Workspace's `.devcontainer/` (RO .devcontainer mount)
  - Config: Global `~/.bitbot/config-devcontainer/` (RW workspace)
- ✓ VS Code integration (`bitbot vscode`)
- ✓ Single session (auto-named, auto-attach)
- ✓ Git warnings (non-blocking for both modes)
- ✓ UID sync (host UID = container UID)
- ✓ Basic first-run (prerequisites check)
- ✓ Simple config mode (no approval flow)

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

**Phase 3b** (Week 11-15):
13. VM-based deployment (DevPod integration)
14. Enhanced security isolation (VM-backed containers)
15. Cloud provider support (AWS, GCP, Azure)

---

## Phase 3b: VM-Based Deployment (Post-Phase 3)

### VM Provider Integration (DevPod)

**Priority**: High (security isolation, cloud deployment)
**Depends on**: MVP complete, devcontainer architecture stable

**Goal**: Support VM-backed devcontainer deployment for:
- Enhanced security isolation (VM + container)
- Cloud/remote development workflows
- Multi-provider flexibility (local VMs, AWS, GCP, Azure)

**Implementation Approach**: DevPod Integration (Recommended)

**DevPod Provider Support**
- **Cut from**: MVP, Phase 2
- **Use case**: VM-level isolation, cloud deployment
- **Solution**: DevPod (https://github.com/loft-sh/devpod)
- **Features**:
  - Multi-provider architecture (Multipass, AWS, GCP, Azure, K8s, Docker)
  - Standard `devcontainer.json` support (no custom config)
  - Client-agent model with SSH tunneling
  - VS Code + JetBrains IDE support
  - Multipass provider: https://github.com/minhio/devpod-provider-multipass
- **Alternative for MVP**: Docker on host only
- **Priority**: High (security + cloud-ready)
- **Research**: `Research/VM_WRAPPER_SOLUTIONS_RESEARCH.md`

**Commands**:
```bash
bitbot init --provider devpod-multipass    # Init with Multipass VM
bitbot init --provider devpod-aws          # Init with AWS EC2
bitbot init --provider docker              # Default (no VM)

bitbot work --provider devpod-multipass    # Launch in Multipass VM
bitbot config --provider devpod-multipass  # Config mode in VM

bitbot provider list                       # List available providers
bitbot provider info multipass             # Show provider details
bitbot provider install multipass          # Install provider

bitbot cloud deploy --provider aws         # Deploy to AWS
bitbot cloud cost                          # Estimate cloud costs
bitbot cloud destroy                       # Tear down cloud resources
```

**Implementation Tasks**:

1. **Provider Detection** (Week 11)
   - Detect if DevPod is installed
   - Check available DevPod providers
   - Add `bitbot provider` commands
   - Add provider selection to `bitbot init` wizard

2. **DevPod Integration** (Week 12-13)
   - Wrap DevPod CLI for workspace creation
   - Pass BitBot's devcontainer.json to DevPod
   - Handle provider-specific configuration
   - Support `MULTIPASS_MOUNTS` for Multipass provider
   - Test work/config container separation in VM

3. **Provider Management** (Week 13-14)
   - `bitbot provider list` - Show available providers
   - `bitbot provider info <name>` - Show provider details
   - `bitbot provider install <name>` - Install provider (wraps `devpod provider add`)
   - Provider validation and health checks

4. **Hybrid Fallback** (Week 14)
   - Auto-detect: DevPod → Docker
   - Graceful fallback if DevPod not available
   - Warning messages for security implications
   - `bitbot doctor` diagnostics for VM backends

5. **Cloud Provider Support** (Week 15+)
   - Test AWS provider (EC2)
   - Test GCP provider (Compute Engine)
   - Test Azure provider (VMs)
   - Add cost estimation warnings
   - Document cloud setup for teams
   - Add `bitbot cloud` command group

**Files Affected**:
- `bitbot` (main CLI) - Add `--provider` flag
- `lib/global/init.md` - Provider detection
- `lib/workspace/init.md` - Provider-aware workspace init
- `lib/workspace/work.md` - Provider-aware container launch
- New: `lib/provider/` - Provider management logic
- New: `lib/cloud/` - Cloud-specific commands

**Configuration**:
```yaml
# .bitbot/config.yml
provider:
  default: docker                        # docker, devpod-multipass, devpod-aws, etc.
  devpod:
    multipass:
      mounts: []                         # MULTIPASS_MOUNTS option
    aws:
      region: us-east-1
      instance_type: t3.medium
      disk_size: 50                      # GB
    gcp:
      region: us-central1
      machine_type: e2-medium
      disk_size: 50
```

**Security Benefits**:

| Solution              | Isolation Level      | Container Escape Risk | Use Case                |
|-----------------------|----------------------|-----------------------|-------------------------|
| Docker (MVP)          | Namespace/cgroups    | Medium                | Fast local dev          |
| VM + Docker (DevPod)  | VM + namespace       | Low                   | Security-critical work  |
| Kata Containers       | Micro-VM per container| Very Low             | Maximum isolation       |

**Alternative Approaches Considered**:

1. **Direct VM Management** (Multipass/Lima)
   - ❌ More custom setup logic
   - ❌ Less cloud-ready
   - ❌ Team patterns need custom implementation
   - ✅ Simpler for single-user
   - **Decision**: Not chosen (DevPod is more mature)

2. **Kata Containers Integration**
   - ✅ Excellent isolation (micro-VM per container)
   - ❌ No specific VS Code devcontainer integration found
   - ❌ High complexity
   - ❌ Performance overhead
   - **Decision**: Future consideration (Phase 4+)

3. **Hybrid Strategy** (DevPod + Direct VM)
   - ✅ Best of both worlds
   - ✅ Graceful fallback
   - ⚠️  Increased maintenance
   - **Decision**: Chosen for Phase 3b

**Testing Plan**:
- [ ] Validate DevPod with BitBot's work/config containers
- [ ] Test Multipass provider (Ubuntu VMs)
- [ ] Test AWS provider (EC2 instances)
- [ ] Benchmark performance: Docker vs VM+Docker
- [ ] Security testing: Container escape attempts
- [ ] Multi-user team workflow testing
- [ ] Cross-platform testing (Windows, macOS, Linux)

**Documentation Requirements**:
- User guide: Choosing a provider
- User guide: Setting up Multipass/Lima
- User guide: Cloud provider setup (AWS, GCP, Azure)
- Admin guide: Team deployment patterns
- Admin guide: Cost optimization for cloud providers
- Security guide: VM isolation benefits

**Migration Path from MVP**:
1. MVP users continue using Docker (default)
2. Add `--provider` flag (backward compatible)
3. Users opt-in to VM providers
4. No breaking changes to existing workflows

---

## Migration Path

**From MVP to Full Feature Set:**

1. **Add non-interactive mode** - Add flag handling, no breaking changes
2. **Add session management** - Backward compatible, single session still works
3. **Add audit logging** - Append-only log, no breaking changes
4. **Add template system** - Optional during init, manual config still works
5. **Add advanced commands** - New commands, don't affect existing workflows

**No Breaking Changes Expected**: MVP will be a true subset of full feature set

---

**Status**: ✅ Backlog Created
**Next**: Implement MVP, validate architecture, then incrementally add features
**Timeline**: MVP (3 weeks) → Phase 2a (2 weeks) → Phase 2b (3 weeks) → Phase 3 (ongoing)
