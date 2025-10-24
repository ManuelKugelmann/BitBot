# Git Safety Integration Specification

**Feature ID**: SPEC-02A
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-02 (Security Mode System), SPEC-03 (MCP Services)
**Created**: 2025-10-16
**Last Updated**: 2025-10-17

---

## Executive Summary

Git-based safety system replaces sketch mode concept. Provides startup warnings, MCP tools, and AI agent instructions to protect user code. Uses existing Git workflows (branches, commits) instead of custom permission modes.

**Key Design**: Git status checks + MCP tools + AI instructions = comprehensive safety without added complexity.

---

## 1. Architecture

### 1.1 Core Components

**Startup Warning System**:
- Runs on container start (both work and setup modes)
- Checks git status before AI work begins
- Logs warnings to `.bitbot/logs/git-warnings.log`
- Non-blocking (informational only)

**MCP Tool Integration**:
- `git_status_check` - Check repository state
- `git_create_checkpoint` - Create safety commit
- `git_diff_summary` - Show current changes
- Available in both work and setup modes

**AI Agent Instructions**:
- Pre-loaded context about git safety
- Instructions to check git before major changes
- Experimental branch recommendations
- Commit-before-work suggestions

### 1.2 Safety Model

**Philosophy**: Use Git's native capabilities instead of inventing new modes.

**Advantages**:
- Users already know Git
- Works with existing workflows
- No custom mode complexity
- Better safety through familiarity

**Replaces**: Original sketch mode concept (3-mode system)

---

## 2. Startup Warning System

### 2.1 Check Sequence

On container start:

```bash
# Pseudocode
if not_git_repo:
  warn("Not a git repository, run: git init")

if has_uncommitted_changes:
  warn("Uncommitted changes detected")
  show_git_status()
  prompt("Continue anyway? (y/N)")

if has_unpushed_commits:
  info("N unpushed commits, run: git push")

if no_remote:
  info("No remote configured, consider: git remote add origin <url>")
```

### 2.2 Warning Levels

| Level | Symbol | Meaning | Action |
|-------|--------|---------|--------|
| ERROR | ❌ | Blocking issue | Must fix before continuing |
| WARNING | ⚠️ | Risky state | Should address before AI work |
| INFO | ℹ️ | Informational | Optional, good practice |

**Current Implementation**: Only WARNING and INFO levels (no blocking errors).

### 2.3 Configuration

```yaml
# .bitbot/config.yml
git_safety:
  startup_check: true           # Warn on startup (default)
  require_clean: false          # Block if dirty (opt-in)
  full_status: false            # Show all files vs first 10
```

```bash
# Environment variables
export BITBOT_REQUIRE_CLEAN_GIT=true  # Block if dirty
export BITBOT_SKIP_GIT_CHECK=true     # Skip check (not recommended)
```

---

## 3. MCP Tool Integration

### 3.1 Tool: `git_status_check`

**Purpose**: Check repository status

**Input**:
```json
{
  "path": "/workspace"  // Optional, defaults to workspace root
}
```

**Output**:
```json
{
  "clean": false,
  "uncommitted_files": 5,
  "untracked_files": 2,
  "current_branch": "main",
  "files": [
    {"path": "src/auth.py", "status": "modified"},
    {"path": "newfile.py", "status": "untracked"}
  ],
  "recommendation": "commit_first"
}
```

### 3.2 Tool: `git_create_checkpoint`

**Purpose**: Create safety commit before AI changes

**Input**:
```json
{
  "message": "Checkpoint before AI changes",
  "include_all": true  // git add . before commit
}
```

**Output**:
```json
{
  "success": true,
  "commit_hash": "abc123",
  "files_committed": 7,
  "rollback_command": "git reset --hard abc123"
}
```

### 3.3 Tool: `git_diff_summary`

**Purpose**: Show changes since last commit

**Input**:
```json
{
  "since_commit": "HEAD",       // Optional
  "file_path": "src/auth.py"   // Optional, specific file only
}
```

**Output**:
```json
{
  "files_changed": 3,
  "insertions": 45,
  "deletions": 12,
  "files": [
    {
      "path": "src/auth.py",
      "insertions": 30,
      "deletions": 5
    }
  ]
}
```

### 3.4 MCP Service

**Container**: `mcp-git-safety-${WORKSPACE_HASH}`

**Mount**: `/workspace:rw` (needs write for git commits)

**Network**: `mcp-workspace-${WORKSPACE_HASH}` (per SPEC-03)

---

## 4. AI Agent Instructions

### 4.1 System Prompt Addition

Add to AI agent's system prompt:

```markdown
## Git Safety Protocol

Before significant code changes:
1. Check Git status using git_status_check tool
2. Create checkpoint if uncommitted changes exist
3. Proceed with changes
4. Inform user: "Rollback with: git reset --hard <hash>"

## When to Create Checkpoint

Create checkpoint before:
- Refactoring multiple files
- Implementing new features
- Architectural changes
- Any change user might want to undo

## User Opt-Out

If user says "skip git check", proceed without checking.
```

### 4.2 Trigger Conditions

AI should check git status when:

**Major refactoring requests**:
- "Refactor the entire codebase"
- "Restructure project architecture"
- "Migrate to new framework"

**Risky operations**:
- "Delete unused files"
- "Rename classes across codebase"
- "Update all dependencies"

**Session start with complex task**:
- First AI response in new session
- Task involves >10 file modifications

### 4.3 AI Response Templates

**When uncommitted changes detected**:
```
⚠️ I notice you have uncommitted changes. Before we proceed with [task],
I recommend creating a checkpoint:

Would you like me to create a safety checkpoint?

[Yes, create checkpoint] [No, proceed anyway] [Let me commit manually]
```

**When suggesting experimental branch**:
```
This task involves significant changes to [area]. I recommend creating
an experimental branch:

git checkout -b experiment/[task-name]

Shall I proceed on a new branch, or continue on current branch?
```

---

## 5. User Workflows

### 5.1 Safe Experimentation

**User**: "Try implementing feature X, not sure if it'll work"

**AI**:
```
[Uses git_status_check]
Current status: 2 uncommitted files

Recommendation:
1. Commit current changes or create checkpoint
2. Create experiment branch: git checkout -b experiment/feature-x
3. Implement feature
4. Review and merge or discard

Would you like me to:
A) Create checkpoint and experimental branch
B) Proceed on current branch
C) Wait for you to commit manually
```

### 5.2 Major Refactoring

**User**: "Refactor the entire authentication system"

**AI**:
```
[Uses git_status_check]
⚠️ Repository status:
- Uncommitted files: 5
- Branch: main
- Unpushed commits: 2

Before refactoring authentication, I recommend:
1. Commit: git add . && git commit -m "WIP before auth refactor"
2. Push: git push
3. Branch: git checkout -b refactor/auth-system

Proceed with safety steps?
```

### 5.3 Quick Fix (No Check Needed)

**User**: "Fix the typo in src/main.py line 42"

**AI**:
```
[Low-risk change, no git check]
Fixing typo in src/main.py:42...

Done! Would you like to see the diff?
```

---

## 6. Integration Points

### 6.1 Container Startup

**Script location**: `.bitbot/setup/scripts/git-safety-check.sh`

**Work mode**:
```json
// .devcontainer/devcontainer.json
{
  "postStartCommand": "/workspace/.bitbot/setup/scripts/git-safety-check.sh"
}
```

**Setup mode**:
```json
{
  "postStartCommand": "/setup/workspace/.bitbot/setup/scripts/git-safety-check.sh"
}
```

### 6.2 MCP Service

**Compose file**: `.bitbot/mcp/docker-compose.yml`

```yaml
services:
  mcp-git-safety:
    image: bitbot/git-mcp:latest
    container_name: mcp-git-safety-${WORKSPACE_HASH}
    volumes:
      - ${WORKSPACE_PATH}:/workspace:rw
    environment:
      - MCP_WORKSPACE_HASH=${WORKSPACE_HASH}
    networks:
      - mcp-workspace-${WORKSPACE_HASH}
```

### 6.3 AI Agent Config

**Claude Code** (`.claude/config.yml`):
```yaml
mcpServers:
  git-safety:
    command: docker
    args: ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"]

pre_task_hooks:
  - name: git_safety_check
    trigger:
      keywords: ["refactor", "implement", "change"]
      file_count_threshold: 3
    action:
      tool: git_status_check
```

---

## 7. Safety Comparison

### 7.1 Sketch Mode vs Git Safety

| Aspect | Sketch Mode (Removed) | Git Safety (Current) |
|--------|----------------------|----------------------|
| Learning curve | New concept | Uses existing Git |
| Protection level | Medium (permissions) | High (version control) |
| Rollback | Mode switch | Git reset/revert/branch |
| Complexity | 3 modes + switching | 2 modes + git tools |
| User familiarity | Unfamiliar | Familiar (Git) |
| Recovery | Limited | Full Git history |
| Collaboration | Unclear | Standard Git workflows |

**Decision**: Git safety provides better protection with less complexity.

### 7.2 Defense Layers

```
Layer 1: Startup Warnings
  ↓ Alerts to uncommitted/unpushed changes

Layer 2: AI Instructions
  ↓ AI proactively suggests git safety

Layer 3: MCP Tools
  ↓ Easy checkpoint creation and status

Layer 4: Git History
  ↓ Full version control rollback

Layer 5: Experimental Branches
  ↓ Isolate risky changes
```

---

## 8. Testing Strategy

### 8.1 Startup Warning Tests

- GS-01: Warn on uncommitted changes
- GS-02: Info on unpushed commits
- GS-03: Info when no remote configured
- GS-04: No warnings on clean repo
- GS-05: Warnings logged to `.bitbot/logs/git-warnings.log`
- GS-06: `BITBOT_REQUIRE_CLEAN_GIT=true` blocks dirty state

### 8.2 MCP Tool Tests

- MCP-01: `git_status_check` returns accurate status
- MCP-02: `git_create_checkpoint` creates commit
- MCP-03: `git_diff_summary` shows correct changes
- MCP-04: Tools work in both work and setup modes
- MCP-05: Error handling for non-git repositories

### 8.3 AI Instruction Tests

- AI-01: AI checks git before major refactoring
- AI-02: AI suggests checkpoint for risky changes
- AI-03: AI recommends branches for experiments
- AI-04: AI skips check for trivial changes
- AI-05: AI provides clear user choices (A/B/C)

### 8.4 Integration Tests

- INT-01: Startup warnings in both modes
- INT-02: MCP tools accessible from AI agents
- INT-03: Git safety doesn't block normal work
- INT-04: Warnings persist across restarts
- INT-05: Works with/without git remote

---

## 9. Success Criteria

**Functional**:
- [ ] Startup warnings detect uncommitted changes
- [ ] Startup warnings detect unpushed commits
- [ ] MCP tools work in both modes
- [ ] AI checks git before major changes
- [ ] Checkpoint creation works correctly

**Safety**:
- [ ] Users warned before risky operations
- [ ] Experimental branch workflow documented
- [ ] Git safety superior to sketch mode
- [ ] No blocking errors (warnings only)

**Usability**:
- [ ] Warnings clear and actionable
- [ ] AI suggestions helpful, not intrusive
- [ ] Works with existing Git workflows
- [ ] Doesn't slow container startup
- [ ] Logs accessible for debugging

---

## 10. Implementation Phases

**Phase 1: Startup Warnings (MVP)**:
- Basic git status check script
- Warning output to console
- Logging to `.bitbot/logs/`

**Phase 2: MCP Tools (Core)**:
- `git_status_check` implementation
- `git_create_checkpoint` implementation
- `git_diff_summary` implementation
- MCP server containerization

**Phase 3: AI Integration (Enhancement)**:
- System prompt additions
- Trigger condition logic
- Response templates

**Phase 4: Polish (Future)**:
- Rich formatting (colors, icons)
- Interactive prompts
- Git hook integration
- Advanced safety policies

---

## 11. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-11: Git safety replaces sketch mode)
- SPEC-02: Security Mode System (uses git safety)
- SPEC-03: MCP Service Architecture (git-mcp service)
- SPEC-01: Container Orchestration (startup integration)

**Research Sources**:
- User decision: "remove sketch mode, Git protection is better" (2025-10-16)
- MCP protocol: https://modelcontextprotocol.io/

**Design Decisions**:
- Non-blocking warnings (informational only)
- Standard Git workflows over custom modes
- Defense in depth with multiple layers
- AI proactive but not intrusive

---

**Status**: **Approved**
**Implementation Priority**: P0 (Blocking for MVP)
**Next Steps**: SPEC-03 (MCP Service Architecture)
