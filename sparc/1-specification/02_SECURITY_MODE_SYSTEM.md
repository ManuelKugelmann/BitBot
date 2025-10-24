# Security Mode System Specification

**Feature ID**: SPEC-02
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration)
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

Two-mode security system (work/config) implemented via separate containers with different mount strategies and git-based protection. Work mode protects infrastructure files from accidental AI changes, while config mode allows controlled infrastructure modifications with git safety checks.

**Key Decision (D-02)**: Two modes (work/config) + git-based protection provides simple, auditable safety without complex runtime mode switching.

---

## 1. Security Architecture

### 1.1 Mode Overview

**Work Mode** (Default):
- **Purpose**: Normal development and AI assistance
- **Container**: Managed by `@devcontainers/cli`
- **AI Access**: Can modify workspace code, cannot modify infrastructure
- **Protection**: `.devcontainer` mounted read-only, `.bitbot/internal/` invisible
- **Git Safety**: Warnings on uncommitted/unpushed changes

**Config Mode**:
- **Purpose**: Infrastructure changes and devcontainer configuration
- **Container**: Uses global config devcontainer template (templates/bitbot/config/)
- **AI Access**: Can modify `.devcontainer` (workspace mounted with RW access)
- **Protection**: Git warnings on uncommitted changes (non-blocking)
- **Prerequisites**: Docker + DevContainer CLI (to run the config container)
- **Container Contents**: Claude Code AI + config-specific tooling (NO Docker inside container)

### 1.2 Security Model

```
┌─────────────────────────────────────────────────────────────┐
│ Security Principles                                         │
│                                                             │
│ 1. Work Mode: Protect infrastructure from accidental AI    │
│    changes via read-only mounts                             │
│                                                             │
│ 2. Config Mode: Protect via Git safety warnings (non-      │
│    blocking) - simpler for MVP                              │
│                                                             │
│ 3. Both Modes: Separate devcontainer configurations        │
│    (work uses workspace .devcontainer, config uses global)  │
│                                                             │
│ 4. Git Protection: All infrastructure changes require       │
│    clean git state or explicit backup                       │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 User ID Synchronization Strategy

**Decision**: Synced UID/GID (host user UID = container user UID)

**Implementation**:
```bash
# Detect host user UID/GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Pass to container runtime
docker run --user "${HOST_UID}:${HOST_GID}" ...
```

**Rationale**:
- ✅ Seamless file permissions between host and container
- ✅ No ownership mismatches on workspace files
- ✅ Standard devcontainer practice (VS Code compatible)
- ✅ Simpler UX (files created in container owned by host user)

**Trade-offs Accepted**:
- ❌ All modes run as same UID (no UID-based isolation)
- ✅ Security via mount restrictions (not UID separation)
- ✅ Both work and config containers use synced UID

**Alternative Considered**:
- Static UIDs (2001=sketch, 2002=work, 2003=config)
- Rejected: File ownership complexity outweighs security benefit
- Security achieved through mount flags and git protection instead

---

## 2. Work Mode Security

### 2.1 Mount Strategy

**Work Container Mounts** (MVP):
```yaml
# Managed by workspace's .devcontainer/devcontainer.json
# Should include:
volumes:
  # Workspace code (read-write)
  - "${WORKSPACE_PATH}:/workspace"

  # Infrastructure protection (read-only bind mount)
  - "${WORKSPACE_PATH}/.devcontainer:/workspace/.devcontainer:ro"

  # BitBot state (selective read-write for MVP)
  - "${WORKSPACE_PATH}/.bitbot/state:/workspace/.bitbot/state"
```

### 2.2 AI Agent Restrictions

**What AI can do in Work Mode**:
- ✅ Modify source code (`src/`, `docs/`, etc.)
- ✅ Create/edit configuration files (`package.json`, `tsconfig.json`, etc.)
- ✅ Install dependencies and run build commands
- ✅ Access git for version control
- ✅ Use MCP services for development tasks

**What AI cannot do in Work Mode**:
- ❌ Modify `.devcontainer/devcontainer.json`
- ❌ Edit Dockerfile or docker-compose files
- ❌ Access Docker socket to create/destroy containers (default)
- ❌ See or modify `.bitbot/internal/` directory
- ❌ Change container configuration without user switching to config mode

**Note on Docker-in-Docker:** Some workspace templates may include Docker for building images or running containers. This is an advanced feature with security implications - see section 2.4.

### 2.3 Docker-in-Docker Support (Optional, ⚠️ Security Trade-off)

**Use Case:**
Some workflows require Docker inside the work container (e.g., building Docker images, running Docker Compose services, testing container deployments).

**Current Implementation (Interim):**
- **Approach**: Rootless Docker-in-Docker (no privileged mode required)
- **Isolation Level**: Limited - container escape possible by design
- **Security Model**: Trust-based - suitable only for trusted AI agents and code

**Security Limitations:**
- ⚠️ **Container breakout possible**: Rootless Docker shares host kernel, escapes are feasible
- ⚠️ **AI has Docker access**: Can create/destroy containers, access Docker socket
- ⚠️ **Not for untrusted code**: Should not be used with malicious code or adversarial AI testing
- ⚠️ **Trust requirement**: Only use with AI agents and codebases you fully trust

**When to Use:**
- ✅ Building Docker images for deployment
- ✅ Testing Docker Compose configurations
- ✅ Local multi-container development (databases, services)
- ✅ CI/CD pipeline testing
- ❌ **NOT** for running untrusted code
- ❌ **NOT** for adversarial AI agent testing
- ❌ **NOT** for security-critical isolation

**Future Enhancement (Planned):**
- Full VM-based sandboxing (Docker-in-VM architecture)
- Complete isolation between host and work environment
- Safe for untrusted code and experimental AI agents
- Timeline: Post-MVP (Phase 3 roadmap)

**Recommendation:** Until VM isolation is implemented, prefer work mode **without** Docker-in-Docker for maximum safety. Only enable Docker access in work containers for trusted development workflows.

### 2.4 Git Safety Integration

**Git Status Checks**:
```bash
# Before AI makes significant changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠ WARNING: Uncommitted changes detected"
    echo "  Recommendation: Commit changes before proceeding"
    echo "  Continue anyway? (y/N)"
fi
```

**Automatic Checkpoint Creation**:
```bash
# AI-triggered checkpoint before major refactoring
git stash push -m "BitBot checkpoint: $(date -Iseconds)"
echo "✓ Created checkpoint: git stash pop to restore"
```

---

## 3. Config Mode Security (MVP Simplified)

### 3.1 Config Devcontainer Architecture

**Global Template Location**: `templates/bitbot/config/`
```
templates/bitbot/config/
├── devcontainer.json        # Global config mode config
└── Dockerfile               # Config container (Claude Code AI + config tools, no Docker inside)
```

**Note**: Config mode container includes Claude Code AI and config-specific tools, but NO Docker inside - it's for editing .devcontainer files with AI assistance, not running containers.

**Per-Workspace Config**: `.bitbot/internal/devcontainer.json`
- Created on first `bitbot config` launch
- References global Dockerfile
- Configures workspace-specific mounts

**Config Container Mounts** (MVP):
```yaml
# Managed by global config devcontainer
# Parameterized with BITBOT_WORKSPACE env var
volumes:
  # Full workspace access (read-write, no RO .devcontainer mount)
  - "${BITBOT_WORKSPACE}:/workspace"
```

### 3.2 Git Safety (Non-Blocking Warnings)

**Git Status Check** (MVP):
```bash
# Before launching config mode
if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
    echo "⚠ WARNING: Uncommitted changes detected"
    echo "  Files modified: $(git status --porcelain | wc -l)"
    echo "  Recommendation: Commit before infrastructure changes"
    echo ""
fi
# Non-blocking - continues after warning
```

**TODO: Config Mode Warning** (Post-MVP):
Add comprehensive warning on config mode entry that explains:
- Config mode defines the workspace environment for AI agents
- AI will have access to modify critical infrastructure files:
  - `.devcontainer` configuration
  - `.github` workflows
  - `.gitignore` patterns
  - Docker configs
  - Secrets and environment files
- Users should carefully review all changes before committing
- Recommend reviewing points from README "The Problem" section
- Consider showing example of what AI can modify in this mode

**Safe Infrastructure Workflow** (MVP):
1. User runs `bitbot config`
2. Git warning shown if uncommitted changes (non-blocking)
3. Config devcontainer launches with RW access to .devcontainer
4. AI/user modifies `.devcontainer` configuration
5. Changes are tested and committed
6. Work container rebuilt via devcontainer CLI

### 3.3 MVP Simplifications

**Removed from MVP** (Future Features):
- Docker socket mounting approval flow
- `--allow-socket` and `--reason` flags
- Approval tracking and audit logging
- Blocking git checks
- `.bitbot/logs/approvals.log`

**Key Insight**: Config is just another devcontainer with different configuration:
- Work: Uses workspace's `.devcontainer/` + RO bind mount
- Config: Uses global `templates/bitbot/config/` + no RO mount

---

## 4. File System Protection

### 4.1 Protected Directories

| Directory            | Work Mode  | Config Mode | Protection Method                  |
|----------------------|------------|-------------|------------------------------------|
| `.devcontainer/`     | Read-only  | Read-write  | RO bind mount (work only)          |
| `.bitbot/config.json`| Read-write | Read-write  | Standard mount                     |
| `.bitbot/state/`     | Read-write | Read-write  | Standard mount (MVP)               |
| `.bitbot/internal/`  | N/A        | Config only | Per-workspace config mode settings |
| `src/`, `docs/`, etc.| Read-write | Read-write  | Standard mount                     |

### 4.2 Global Config Template Protection

**templates/bitbot/config/ Contents** (In BitBot installation):
```
templates/bitbot/config/
├── devcontainer.json        # Global config mode template
└── Dockerfile               # Config container image (no Docker inside)
```

**Per-Workspace Config Settings**:
```
.bitbot/internal/
└── devcontainer.json        # Links to global template, workspace mounts
```

**Why Separate**:
- Shared config mode image across all workspaces
- Per-workspace mount configuration
- Config container can work on any workspace via workspace mount

---

## 5. Mode Switching Security

### 5.1 Host-Level Mode Management (MVP)

**Mode switching happens on host** (not inside containers):
```bash
# MVP commands
bitbot        # Default: launch work mode
bitbot work   # Start/attach to work container
bitbot config # Start/attach to config container (simplified, no approval)
bitbot vscode # Launch VS Code in work container
```

### 5.2 No Runtime Mode Switching

**Design Decision**: No switching modes within a container
- **Rationale**: Simpler, more predictable security model
- **Implementation**: Each mode is a separate container
- **Benefit**: Clear security boundaries, easier to audit

### 5.3 Parallel Mode Support

Both containers can run simultaneously:
- **Developer workflow**: Code in work container
- **Infrastructure changes**: Configure in config container
- **No conflicts**: Different mount strategies prevent interference

---

## 6. Audit and Logging (Future Feature - Not in MVP)

### 6.1 MVP Logging (Minimal)

**MVP**: No audit logging or approval tracking
- Git warnings printed to console (non-blocking)
- Future: Add comprehensive logging post-MVP

**Future Logging** (Post-MVP):
```bash
# Container startup
[2025-10-20T14:30:00Z] WORK_START: container=bitbot-work user=developer
[2025-10-20T14:31:00Z] CONFIG_START: container=bitbot-config user=developer

# Git safety events
[2025-10-20T14:32:00Z] GIT_WARNING: uncommitted_changes=5

# Infrastructure changes
[2025-10-20T14:35:00Z] DEVCONTAINER_MODIFIED: file=.devcontainer/devcontainer.json
```

### 6.2 Future: Approval Audit Trail (Post-MVP)

**Not in MVP**: Approval tracking and audit logs cut for simplification
**Future**: Add comprehensive audit trail when config mode gets approval flow

---

## 7. Emergency Recovery

### 7.1 Container Recovery

**If work container breaks** (MVP):
```bash
# Stop broken container
docker stop <container-name>

# Enter config mode to fix .devcontainer
bitbot config

# Edit .devcontainer configuration
# Exit and rebuild work container
bitbot work
```

### 7.2 Git Recovery

**If changes need to be rolled back**:
```bash
# Inside container: rollback to last checkpoint
git stash pop                    # Restore last checkpoint
git reset --hard HEAD~1         # Undo last commit
git bundle verify backup.bundle # Verify backup integrity
```

### 7.3 Complete Reset

**Nuclear option** (MVP):
```bash
# Stop all containers
docker stop $(docker ps -q --filter name=bitbot)

# Reset BitBot state
rm -rf .bitbot/state/

# Rebuild from clean .devcontainer
bitbot work
```

---

## 8. Implementation Examples

### 8.1 Work Mode Container Security

```dockerfile
# Work container runs as root but with limited mounts
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu

# AI agents run inside this container
RUN npm install -g @anthropic/claude-code

# Security: .devcontainer mounted read-only
# AI cannot accidentally break infrastructure
COPY --from=bitbot-security /opt/bitbot/work-entrypoint.sh /opt/
ENTRYPOINT ["/opt/work-entrypoint.sh"]
```

### 8.2 Config Mode Container Security

```dockerfile
# Config container includes AI + config-specific tools (no Docker inside)
FROM ubuntu:22.04

# Claude Code AI + config-specific tools (no Docker needed)
RUN apt-get update && apt-get install -y \
    git \
    vim \
    jq \
    curl

# Note: No Docker installation - config mode only edits files
COPY --from=bitbot-security /opt/bitbot/config-entrypoint.sh /opt/
ENTRYPOINT ["/opt/config-entrypoint.sh"]
```

### 8.3 Git Safety Script

```bash
#!/bin/bash
# /opt/bitbot/git-safety-check.sh

check_git_safety() {
    if [ ! -d ".git" ]; then
        echo "ℹ No git repository found"
        return 0
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠ WARNING: Uncommitted changes detected"
        echo "Files modified:"
        git diff --name-only HEAD
        echo ""
        echo "Recommend committing before infrastructure changes"
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Check for unpushed commits
    if [ "$(git rev-list HEAD --not --remotes | wc -l)" -gt 0 ]; then
        echo "⚠ WARNING: Unpushed commits detected"
        echo "Consider pushing before infrastructure changes"
    fi

    return 0
}
```

---

## 9. Success Criteria

**Security Requirements** (MVP):
- [ ] Work mode cannot modify `.devcontainer` files (RO bind mount)
- [ ] Config mode allows `.devcontainer` modification (no RO mount)
- [ ] Git warnings shown on uncommitted changes (both modes, non-blocking)
- [ ] Config uses global template (templates/bitbot/config/)
- [ ] DevContainer CLI handles container naming automatically

**Usability Requirements**:
- [ ] Clear indication of current mode
- [ ] Easy mode switching via host commands
- [ ] Helpful warnings for git safety
- [ ] Recovery procedures documented and tested

**Reliability Requirements**:
- [ ] Mode switching never fails silently
- [ ] Container mounts are exactly as specified
- [ ] Log files persist across container restarts
- [ ] Emergency recovery procedures work

---

## 10. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-02: Security strategy)
- SPEC-01: Container Orchestration (mount implementations)
- SPEC-02A: Git Safety Integration (detailed git workflows)
- SPEC-05: Cross-Platform CLI (mode switching commands)

**Security Research**:
- Research/CONTAINER_ISOLATION_RESEARCH.md
- Research/AI_AGENT_SAFETY_ARCHITECTURE.md

---

**Status**: **Approved**
**Implementation Priority**: P0 (Critical - Blocking)
**Next Steps**: Implement SPEC-02A (Git Safety Integration)