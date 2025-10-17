# BitBot Architecture Decisions

**Status**: Approved by User
**Last Updated**: 2025-10-16

---

## Key Architectural Decisions

### D-01: Container Orchestration Strategy

**Decision**: Custom Docker/Compose with Host-Triggered Mode Switching

**Rationale**:
- VS Code and CLI workflows must be identical
- Single devcontainer that restarts with different mode configurations
- Root user in both modes (container is ephemeral)
- Mode set at container start via environment variable

**Alternatives Considered**:
- `@devcontainers/cli` (rejected: unnecessary abstraction layer)
- Docker Compose profiles (rejected: requires managing multiple configs)
- Runtime user switching (rejected: user requested host-triggered mode switching)

**References**: SPEC-01

---

### D-03: Security Mode Enforcement

**Decision**: Selective mounting + per-workspace setup containers

**Rationale**:
- Work container: `.devcontainer` read-only, `.bitbot/setup/` not mounted
- Setup container: separate per-workspace container with full access
- `.bitbot/setup/` never mounted (BitBot internals, managed by host scripts)
- Simpler than bind mount remounting (no CAP_SYS_ADMIN needed)
- Cleaner isolation (setup internals completely invisible to AI)

**Key Points**:
- Work mode: Root user, `.devcontainer` read-only mount, `.bitbot/setup/` invisible
- Setup mode: Root user in separate container, full access except `.bitbot/setup/`
- Both modes can run simultaneously
- VS Code compatible for both modes

**References**: SPEC-01, SPEC-02

---

### D-04: MCP Service Architecture

**Decision**: Sibling containers managed by Docker Compose

**Rationale**:
- MCP services run alongside devcontainer (not inside)
- Simplifies orchestration (no Docker socket needed for users)
- Docker socket only for setup mode (infrastructure management)

**Service Discovery**: Use existing MCP discovery server (not custom implementation)

**References**: SPEC-01:312-395

---

### D-05: Mode Switching Mechanism

**Decision**: Host-triggered via separate containers

**Rationale**:
- Work and setup are separate containers (can run simultaneously)
- Triggered from host via `bitbot work` or `bitbot setup` commands
- Each mode can launch as CLI or VS Code (`--vscode` flag)
- No mode switching inside containers (different containers entirely)
- Cleaner separation: host controls infrastructure, containers execute

**References**: SPEC-01, SPEC-02

---

### D-06: Docker Access Strategy

**Decision**: Host socket for both modes

**Rationale**:
- Container is ephemeral, runs as root
- Both modes have Docker socket access
- Setup mode can rebuild work container
- MCP containers managed via host socket
- Container isolation provides sufficient protection

**References**: SPEC-01

---

### D-07: Implementation Language

**Decision**: Bash scripts with minimal Windows .exe launcher

**Rationale**:
- Simpler to implement and maintain
- No compilation needed
- Legacy_Bitbot already 85% complete in bash
- Windows launcher calls bash in WSL for native Windows use

**Windows Support**:
- Minimal .exe launcher for PowerShell/CMD
- Calls bash script in WSL2 environment
- Consistent behavior across all platforms

**Alternatives Considered**:
- Go/Rust core (rejected: added complexity, can add later if needed)

**References**: Gemini_BITBOT_PLANNING.md:44, User decision

---

### D-08: Command Line Style

**Decision**: Short command style

**Examples**:
```bash
bitbot                # Smart launch (default: work mode)
bitbot work           # Launch in work mode (explicit)
bitbot setup          # Launch in setup mode
bitbot claude         # Launch with Claude Code agent
bitbot open           # Launch with OpenCode agent
```

**Mode Switching** (from host only):
```bash
bitbot setup          # Stop container, restart in setup mode
bitbot work           # Stop container, restart in work mode
```

**Rationale**:
- Simpler, faster UX
- Common workflows are shortest commands
- Consistent with modern CLI tools

**Alternatives Considered**:
- Long commands (`bitbot mode sketch`)
- Hybrid (both short and long)

**References**: Copilot_REQUIREMENTS.md:24-48, User decision

---

### D-09: Default Mode

**Decision**: Work mode (root user with .devcontainer read-only)

**Rationale**:
- Most common use case
- Balanced permissions (write workspace, protect .devcontainer)
- No user action needed for normal development
- Root user acceptable since container is ephemeral

**References**: SPEC-02:53-58, SPEC-02:354-419

---

### D-10: VS Code Integration

**Decision**: Single container reusable by both CLI and VS Code

**Rationale**:
- Unified workflow (identical for CLI and VS Code users)
- VS Code attaches to running container
- Mode switching works from VS Code terminal
- No separate devcontainer vs direct-docker modes

**VS Code Labels**:
```yaml
labels:
  - "vsc.local.folder=${WORKSPACE_PATH}"
  - "devcontainer.local_folder=${WORKSPACE_PATH}"
```

**References**: SPEC-01:358-360, SPEC-02:IT-01 to IT-03

---

## Decision Impact Matrix

| Decision | SPEC-01 | SPEC-02 | SPEC-02A | SPEC-03 | SPEC-04 | SPEC-05 | SPEC-06 |
|----------|---------|---------|----------|---------|---------|---------|---------|
| D-01: Custom Docker/Compose | ✅ Core | ✅ | - | - | - | ✅ | - |
| D-03: Security enforcement | - | ✅ Core | - | - | - | - | - |
| D-04: MCP siblings | ✅ Core | ✅ | - | ✅ | - | - | - |
| D-05: Mode switching | ✅ Core | ✅ Core | - | - | ✅ | ✅ | ✅ |
| D-06: Docker strategy | ✅ Core | ✅ Core | - | - | - | - | - |
| D-07: Bash implementation | - | - | - | - | - | ✅ Core | - |
| D-08: Short commands | - | - | - | - | - | ✅ Core | - |
| D-09: Default mode | ✅ | ✅ | - | - | - | - | - |
| D-10: VS Code integration | ✅ | ✅ | - | - | - | - | ✅ Core |
| D-11: Two modes, Git safety | - | ✅ Core | ✅ Core | - | - | - | - |
| D-12: .bitbot folder structure | ✅ Core | ✅ Core | - | - | - | - | - |

**Legend**:
- ✅ Core: Decision is central to this spec
- ✅: Decision impacts this spec
- \-: No impact on this spec

---

### D-11: Mode Count and Sketch Mode

**Decision**: Two modes only (work/setup), sketch mode removed

**Rationale**:
- Git-based safety provides better protection than sketch mode permissions
- Sketch mode added complexity without sufficient value
- Git status warnings + MCP tools + AI agent instructions = comprehensive safety
- Users can create experimental branches for sketching
- Simpler mental model: "normal" and "setup"

**Key Points**:
- Git safety integration replaces sketch mode (see SPEC-02A)
- Startup warnings check for uncommitted/unpushed changes
- MCP tools provide git_status_check, git_create_checkpoint
- AI agents instructed to check git status before major changes

**References**: SPEC-02A, User decision 2025-10-16

---

### D-12: .bitbot Folder Structure

**Decision**: `.bitbot/setup/` for internals, rest accessible

**Rationale**:
- Simple, flat structure: `.bitbot/logs/`, `.bitbot/sessions/`, `.bitbot/state/`
- Exception: `.bitbot/setup/` not mounted (BitBot internals)
- Less nesting than `.bitbot/protected/` and `.bitbot/public/`
- More intuitive: "everything in .bitbot is accessible except setup/"
- Setup container definition can't be modified by AI

**Key Points**:
- `.bitbot/setup/` - Setup container definition (Dockerfile, scripts)
- `.bitbot/logs/` - Mode changes, git warnings (mounted)
- `.bitbot/sessions/` - Session state (mounted)
- `.bitbot/state/` - BitBot state (mounted)

**References**: SPEC-01, SPEC-02

---

## Open Questions (Resolved)

| Question | Resolution | Date | Reference |
|----------|-----------|------|-----------|
| Q3: Implementation language | Bash with Windows .exe launcher | 2025-10-16 | D-07 |
| Q4: Command line style | Short commands | 2025-10-16 | D-08 |
| Q5: MCP registry implementation | Use existing MCP server | 2025-10-16 | D-04 |
| Q6: Mode count and sketch mode | Two modes (work/setup), Git-based safety instead | 2025-10-16 | D-11 |
| Q7: Mode switching location | Host-triggered only (not inside container) | 2025-10-16 | D-05 |

---

## Next Specifications to Create

Based on these decisions, the remaining specifications are:

### Immediate Priority
- **SPEC-03**: MCP Service Architecture
  - Sibling container orchestration
  - Service discovery (existing MCP server)
  - Global vs workspace services

- **SPEC-04**: Session Management
  - tmux session orchestration
  - Session persistence
  - Multi-session support

- **SPEC-05**: Cross-Platform CLI
  - Bash implementation
  - Windows .exe launcher for WSL
  - Short command routing
  - Platform detection

### Secondary Priority
- **SPEC-06**: VS Code DevContainer Integration
- **SPEC-07**: AI Agent Integration Framework
- **SPEC-08**: Workspace Template System
- **SPEC-09**: First-Run Experience & Wizard
- **SPEC-10**: Installation & Distribution

---

**Status**: All critical architectural decisions resolved and documented
**Blockers**: None
**Ready for**: Implementation specification creation
