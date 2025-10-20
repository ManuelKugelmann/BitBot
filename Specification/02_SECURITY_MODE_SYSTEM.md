# Security Mode System Specification

**Feature ID**: SPEC-02
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration)
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

Two-mode security system (work/setup) implemented via separate containers with different mount strategies and git-based protection. Work mode protects infrastructure files from accidental AI changes, while setup mode allows controlled infrastructure modifications with git safety checks.

**Key Decision (D-02)**: Two modes (work/setup) + git-based protection provides simple, auditable safety without complex runtime mode switching.

---

## 1. Security Architecture

### 1.1 Mode Overview

**Work Mode** (Default):
- **Purpose**: Normal development and AI assistance
- **Container**: Managed by `@devcontainers/cli`
- **AI Access**: Can modify workspace code, cannot modify infrastructure
- **Protection**: `.devcontainer` mounted read-only, `.bitbot/setup/` invisible
- **Git Safety**: Warnings on uncommitted/unpushed changes

**Setup Mode**:
- **Purpose**: Infrastructure changes and devcontainer configuration
- **Container**: Custom Docker Compose container
- **AI Access**: Can modify `.devcontainer`, cannot access `.bitbot/setup/`
- **Protection**: Git push/bundle required before destructive operations
- **Docker Access**: Available when explicitly approved

### 1.2 Security Model

```
┌─────────────────────────────────────────────────────────────┐
│ Security Principles                                         │
│                                                             │
│ 1. Work Mode: Protect infrastructure from accidental AI    │
│    changes via read-only mounts                             │
│                                                             │
│ 2. Setup Mode: Protect via Git safety checks and user      │
│    approval for Docker socket access                        │
│                                                             │
│ 3. Both Modes: .bitbot/setup/ never mounted (BitBot        │
│    internals stay on host)                                  │
│                                                             │
│ 4. Git Protection: All infrastructure changes require       │
│    clean git state or explicit backup                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Work Mode Security

### 2.1 Mount Strategy

**Work Container Mounts**:
```yaml
volumes:
  # Workspace code (read-write)
  - "${WORKSPACE_PATH}:/workspace"

  # Infrastructure protection (read-only)
  - "${WORKSPACE_PATH}/.devcontainer:/workspace/.devcontainer:ro"

  # BitBot state (selective read-write)
  - "${WORKSPACE_PATH}/.bitbot/logs:/workspace/.bitbot/logs"
  - "${WORKSPACE_PATH}/.bitbot/sessions:/workspace/.bitbot/sessions"
  - "${WORKSPACE_PATH}/.bitbot/state:/workspace/.bitbot/state"

  # .bitbot/setup/ is NOT mounted (invisible to work container)
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
- ❌ Access Docker socket to create/destroy containers
- ❌ See or modify `.bitbot/setup/` directory
- ❌ Change container configuration without user switching to setup mode

### 2.3 Git Safety Integration

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

## 3. Setup Mode Security

### 3.1 Mount Strategy

**Setup Container Mounts**:
```yaml
volumes:
  # Full workspace access (read-write)
  - "${WORKSPACE_PATH}:/setup/workspace"

  # Docker socket (when explicitly approved)
  - "/var/run/docker.sock:/var/run/docker.sock"

  # .bitbot/setup/ is NOT mounted (managed by host scripts only)
```

### 3.2 Docker Socket Protection

**Approval Required**:
```bash
# Setup mode requires explicit Docker socket approval
bitbot setup --allow-socket --reason "Adding PostgreSQL service"
```

**Approval Process**:
1. User must provide `--reason` for Docker access
2. Git status checked (uncommitted changes warned)
3. Approval logged to `.bitbot/logs/approvals.log`
4. Docker socket mounted only after approval

**Approval Log Format**:
```json
{
  "timestamp": "2025-10-20T14:30:00Z",
  "user": "developer",
  "action": "docker_socket_approval",
  "reason": "Adding PostgreSQL service",
  "workspace_hash": "a1b2c3d4",
  "git_status": "clean"
}
```

### 3.3 Infrastructure Change Safety

**Git Push Requirement**:
```bash
# Before destructive operations
if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
    echo "❌ Uncommitted changes detected"
    echo "   Please commit and push before infrastructure changes"
    echo "   Or create local bundle: git bundle create backup.bundle HEAD"
    exit 1
fi
```

**Safe Infrastructure Workflow**:
1. User commits and pushes current work
2. Enters setup mode with Docker access approval
3. AI/user modifies `.devcontainer` configuration
4. Changes are tested and committed
5. Work container is rebuilt with new configuration

---

## 4. File System Protection

### 4.1 Protected Directories

| Directory | Work Mode | Setup Mode | Protection Method |
|-----------|-----------|------------|------------------|
| `.devcontainer/` | Read-only | Read-write | Mount flag `:ro` |
| `.bitbot/setup/` | Invisible | Invisible | Not mounted |
| `.bitbot/logs/` | Read-write | Read-write | Standard mount |
| `.bitbot/sessions/` | Read-write | Read-write | Standard mount |
| `.bitbot/state/` | Read-write | Read-write | Standard mount |
| `src/`, `docs/`, etc. | Read-write | Read-write | Standard mount |

### 4.2 BitBot Internals Protection

**.bitbot/setup/ Contents** (Never mounted in containers):
```
.bitbot/setup/
├── Dockerfile              # Setup container definition
├── docker-compose.yml      # Setup container orchestration
└── scripts/
    ├── entrypoint-setup.sh  # Setup container startup
    ├── setup-audit.sh       # AI safety audit
    └── setup-apply.sh       # Apply infrastructure changes
```

**Why Never Mounted**:
- Prevents AI from modifying its own container environment
- Ensures BitBot control scripts remain tamper-proof
- Maintains separation between user workspace and BitBot internals

---

## 5. Mode Switching Security

### 5.1 Host-Level Mode Management

**Mode switching happens on host** (not inside containers):
```bash
# Safe mode switching
bitbot work    # Start/attach to work container
bitbot setup   # Start/attach to setup container (with approvals)
bitbot done    # Inside container: review changes → commit → exit
```

### 5.2 No Runtime Mode Switching

**Design Decision**: No switching modes within a container
- **Rationale**: Simpler, more predictable security model
- **Implementation**: Each mode is a separate container
- **Benefit**: Clear security boundaries, easier to audit

### 5.3 Parallel Mode Support

Both containers can run simultaneously:
- **Developer workflow**: Code in work container
- **Infrastructure changes**: Configure in setup container
- **No conflicts**: Different mount strategies prevent interference

---

## 6. Audit and Logging

### 6.1 Security Event Logging

**Log Location**: `.bitbot/logs/security.log`

**Logged Events**:
```bash
# Container startup
[2025-10-20T14:30:00Z] WORK_START: workspace_hash=a1b2c3d4 user=developer
[2025-10-20T14:31:00Z] SETUP_START: workspace_hash=a1b2c3d4 user=developer docker_socket=approved

# Git safety events
[2025-10-20T14:32:00Z] GIT_WARNING: uncommitted_changes=5 files=src/main.py,src/utils.py
[2025-10-20T14:33:00Z] GIT_CHECKPOINT: stash_created=stash@{0} reason="AI refactoring"

# Infrastructure changes
[2025-10-20T14:35:00Z] DEVCONTAINER_MODIFIED: file=.devcontainer/devcontainer.json mode=setup
[2025-10-20T14:36:00Z] CONTAINER_REBUILD: container=bitbot-work-a1b2c3d4 reason="devcontainer updated"
```

### 6.2 Approval Audit Trail

**Approval Log**: `.bitbot/logs/approvals.log`
```json
[
  {
    "timestamp": "2025-10-20T14:30:00Z",
    "action": "setup_mode_entry",
    "user": "developer",
    "workspace_hash": "a1b2c3d4",
    "docker_socket_approved": true,
    "reason": "Adding PostgreSQL development database",
    "git_status": "clean"
  }
]
```

---

## 7. Emergency Recovery

### 7.1 Container Recovery

**If work container breaks**:
```bash
# Stop broken container
bitbot stop work

# Enter setup mode to fix .devcontainer
bitbot setup --allow-socket --reason "Fixing broken devcontainer"

# Edit .devcontainer configuration
# Test changes
# Rebuild work container
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

**Nuclear option**:
```bash
# Stop all containers
bitbot kill

# Reset BitBot state
rm -rf .bitbot/sessions/
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

### 8.2 Setup Mode Container Security

```dockerfile
# Setup container has Docker access but requires approval
FROM ubuntu:22.04

# Tools for infrastructure changes
RUN apt-get update && apt-get install -y docker.io docker-compose

# Security: Approval required for Docker socket mount
COPY --from=bitbot-security /opt/bitbot/setup-entrypoint.sh /opt/
ENTRYPOINT ["/opt/setup-entrypoint.sh"]
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

**Security Requirements**:
- [ ] Work mode cannot modify `.devcontainer` files
- [ ] Setup mode requires explicit approval for Docker access
- [ ] `.bitbot/setup/` invisible to both containers
- [ ] All security events logged with timestamps
- [ ] Git safety checks before infrastructure changes
- [ ] Approval audit trail maintained

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