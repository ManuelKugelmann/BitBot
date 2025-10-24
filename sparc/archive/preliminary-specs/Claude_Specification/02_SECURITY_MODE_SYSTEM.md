# Security Mode System Specification

**Feature ID**: SPEC-02
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration)
**Created**: 2025-10-16
**Last Updated**: 2025-10-17

---

## Executive Summary

Two-mode security system (work/setup) via separate per-workspace containers with selective mounting. Work mode protects `.devcontainer` and `.bitbot/setup/` from AI modification. Git-based safety replaces original sketch mode concept.

**Key Design**: Separate containers + selective mounting = clean isolation without complexity.

---

## 1. Architecture

### 1.1 Two Modes

**Work Mode** (default):
- Container: `bitbot-dev-${WORKSPACE_HASH}`
- Purpose: Normal development
- Mounts:
  - `/workspace` → read-write
  - `/workspace/.devcontainer` → read-only
  - `/workspace/.bitbot/` → read-write (excludes setup/)
- NOT mounted: `.bitbot/setup/`
- Docker socket: Available
- AI access: Can modify workspace code, NOT infrastructure

**Setup Mode**:
- Container: `bitbot-setup-${WORKSPACE_HASH}`
- Purpose: Infrastructure changes
- Mounts:
  - `/setup/workspace` → read-write
  - `/setup/workspace/.bitbot/` → read-write (excludes setup/)
- NOT mounted: `.bitbot/setup/`
- Docker socket: Available (can rebuild containers)
- AI access: Can modify .devcontainer, NOT setup container definition

### 1.2 Folder Structure

```
workspace/
├── .devcontainer/          # Container config
│   ├── devcontainer.json   # RO in work, RW in setup
│   └── Dockerfile
│
├── .bitbot/
│   ├── setup/              # NOT mounted (BitBot internals)
│   │   ├── Dockerfile      # Setup container definition
│   │   └── scripts/
│   ├── logs/               # Mounted in both
│   ├── sessions/           # Mounted in both
│   └── state/              # Mounted in both
│
└── src/                    # Your code
```

### 1.3 Permission Matrix

| Resource | Work Mode | Setup Mode | Managed By |
|----------|-----------|------------|------------|
| `src/` | RW | RW | User/AI |
| `.devcontainer/` | RO | RW | AI in setup mode |
| `.bitbot/logs/` | RW | RW | BitBot + User |
| `.bitbot/sessions/` | RW | RW | BitBot |
| `.bitbot/state/` | RW | RW | BitBot |
| `.bitbot/setup/` | Not visible | Not visible | Host scripts only |

---

## 2. Implementation Concepts

### 2.1 Container Mounts (Pseudocode)

**Work Container**:
```
volumes:
  - workspace:/workspace:rw
  - workspace/.devcontainer:/workspace/.devcontainer:ro
  - workspace/.bitbot:/workspace/.bitbot:rw
  # .bitbot/setup/ excluded by not mounting it
```

**Setup Container**:
```
volumes:
  - workspace:/setup/workspace:rw
  - workspace/.bitbot:/setup/workspace/.bitbot:rw
  # .bitbot/setup/ excluded by not mounting it
```

### 2.2 Mode Switching

**From Host**:
```bash
# Launch work mode (CLI or VS Code)
bitbot work [vscode]

# Launch setup mode (CLI or VS Code)
bitbot setup [vscode]

# Both can run simultaneously
```

**Key Points**:
- No mode switching inside containers
- Each mode is a separate container
- Work and setup can run in parallel
- VS Code can attach to either

### 2.3 Safety Audit Workflow

**Setup Mode Process**:
1. User: `bitbot setup`
2. AI modifies `.devcontainer/`
3. User: `bitbot-audit-setup`
   - Shows git diff
   - AI performs safety check
   - Reports security issues
4. User reviews audit
5. User: `bitbot-apply-setup`
   - Commits changes
   - Rebuilds work container
6. User: `bitbot work` (updated container)

---

## 3. Security Model

### 3.1 Threat Protection

**Protected Against**:
- ✅ AI modifying `.devcontainer` in work mode (read-only mount)
- ✅ AI modifying setup container definition (not mounted)
- ✅ Accidental infrastructure changes (requires explicit `bitbot setup`)
- ✅ AI deleting `.devcontainer` (read-only mount)

**User Responsibility**:
- ⚠️ Setup mode has full access (intentional)
- ⚠️ User must review audit before applying
- ⚠️ Git provides experimental safety (branches)

### 3.2 Defense Layers

```
Layer 1: Selective Mounting
  ↓ .devcontainer read-only in work, .bitbot/setup/ never mounted
  
Layer 2: Separate Containers  
  ↓ Work and setup are different containers
  
Layer 3: Git Safety (SPEC-02A)
  ↓ Startup warnings, MCP tools, AI instructions
  
Layer 4: Audit Logging
  ↓ All mode switches and changes logged
```

---

## 4. Git-Based Safety

**Replaces Sketch Mode** (see SPEC-02A for details):

### 4.1 Startup Warnings

- Check git status on container start
- Warn if uncommitted changes
- Info if unpushed commits
- Info if no remote configured

### 4.2 MCP Tools

- `git_status_check` - Check repo status
- `git_create_checkpoint` - Create safety commit
- `git_diff_summary` - Show current changes

### 4.3 AI Instructions

- Check git before major refactoring
- Create experimental branches for risky changes
- Recommend commits before starting work

### 4.4 Workflow

**Instead of sketch mode**:
```bash
# Create experimental branch
git checkout -b experiment/new-feature

# Let AI work
claude-code "implement feature"

# Review
git diff

# Keep or discard
git merge experiment/new-feature  # or
git branch -D experiment/new-feature
```

---

## 5. User Workflows

### 5.1 Normal Development

```bash
$ bitbot work

# Inside container:
root@work:/workspace$ ls .bitbot/
logs/  sessions/  state/
# setup/ not visible ✓

root@work:/workspace$ vim src/main.py
# ✓ Can edit

root@work:/workspace$ vim .devcontainer/devcontainer.json
# Read-only error ✓
```

### 5.2 Infrastructure Changes

```bash
$ bitbot setup

# Inside container:
root@setup:/setup/workspace$ ls .bitbot/
logs/  sessions/  state/
# setup/ not visible ✓

root@setup:/setup/workspace$ vim .devcontainer/devcontainer.json
# ✓ Can edit

root@setup:/setup/workspace$ bitbot-audit-setup
# AI reviews changes

root@setup:/setup/workspace$ bitbot-apply-setup
# Rebuilds work container
```

### 5.3 Parallel Sessions

```bash
# Terminal 1: Development
$ bitbot work
# Code changes...

# Terminal 2: Infrastructure (simultaneously)
$ bitbot setup
# Infrastructure changes...

# Terminal 3: Setup in VS Code (simultaneously)
$ bitbot setup vscode
# Multiple people can work on setup
```

---

## 6. Testing Strategy

### 6.1 Filesystem Tests

- FP-01: Work mode can write `src/`
- FP-02: Work mode cannot write `.devcontainer/` (read-only error)
- FP-03: Work mode cannot see `.bitbot/setup/`
- FP-04: Setup mode can write `.devcontainer/`
- FP-05: Setup mode cannot see `.bitbot/setup/`

### 6.2 Mode Tests

- MT-01: `bitbot work` starts work container
- MT-02: `bitbot setup` starts setup container
- MT-03: Both containers can run simultaneously
- MT-04: VS Code can attach to both containers
- MT-05: Mode switches are logged

### 6.3 Safety Tests

- ST-01: Git warnings appear at startup
- ST-02: Audit detects security issues
- ST-03: Apply rebuilds work container
- ST-04: Changes are logged with timestamps

---

## 7. Success Criteria

**Functional**:
- [ ] Work mode: `.devcontainer` read-only
- [ ] Work mode: `.bitbot/setup/` invisible
- [ ] Setup mode: Can modify `.devcontainer`
- [ ] Setup mode: `.bitbot/setup/` invisible
- [ ] Parallel work + setup sessions
- [ ] VS Code compatible (both modes)

**Security**:
- [ ] AI cannot modify `.devcontainer` in work mode
- [ ] AI cannot modify setup container definition
- [ ] Audit workflow detects issues
- [ ] All changes logged

**Usability**:
- [ ] `bitbot work` default workflow
- [ ] `bitbot setup` for infrastructure
- [ ] `vscode` flag works for both
- [ ] Git warnings clear and actionable

---

## 8. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-03, D-05, D-11, D-12)
- SPEC-01: Container Orchestration (mounts, containers)
- SPEC-02A: Git Safety Integration (replaces sketch mode)
- SPEC-03: MCP Service Architecture (git tools)

**Research Sources**:
- User decision: "setup folder not mounted, managed by BitBot scripts"
- User decision: "both modes should support vscode flag"
- User decision: "remove sketch mode, Git protection is better"

---

**Status**: **Approved**
**Implementation Priority**: P0 (Blocking for MVP)
**Next Steps**: SPEC-02A (Git Safety), SPEC-03 (MCP Services)
