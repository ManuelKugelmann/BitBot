# Git Safety Integration Specification

**Feature ID**: SPEC-02A
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-02 (Security Mode System), SPEC-03 (MCP Services)
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

Git-based safety system that replaces complex mode switching with familiar Git workflows. Provides startup warnings, MCP tools for AI agents, and safety checks before destructive operations. Protects user work through Git's native capabilities rather than custom permission systems.

**Key Decision (D-02)**: Git push/bundle required before destructive operations provides simple, auditable safety without complexity.

---

## 1. Git Safety Architecture

### 1.1 Core Principles

**Git-First Safety**:
- All safety checks use standard Git commands
- Users work with familiar Git workflows (branches, commits, push)
- No custom permission systems or modes
- Protection through Git state requirements, not container restrictions

**Three-Layer Protection**:
1. **Startup Warnings**: Alert on risky Git states at container start
2. **MCP Tool Integration**: AI agents can check Git status before changes
3. **Pre-Destructive Checks**: Required Git safety before infrastructure changes

### 1.2 Safety Model

```
┌─────────────────────────────────────────────────────────────┐
│ Git Safety Layers                                           │
│                                                             │
│ Layer 1: Startup Warnings                                   │
│ ├─ Check: Uncommitted changes                              │
│ ├─ Check: Unpushed commits                                 │
│ ├─ Check: No remote configured                             │
│ └─ Action: Warn user, log to audit                         │
│                                                             │
│ Layer 2: MCP Tool Integration                              │
│ ├─ git_status_check(): Current repository state            │
│ ├─ git_create_checkpoint(): Safety commit before changes   │
│ ├─ git_diff_summary(): Show uncommitted changes           │
│ └─ Available to AI agents via MCP protocol                 │
│                                                             │
│ Layer 3: Pre-Destructive Checks                           │
│ ├─ Setup mode entry: Warn on uncommitted changes          │
│ ├─ Infrastructure changes: Require clean or backup        │
│ ├─ Container rebuilds: Suggest commit first               │
│ └─ Action: Block if unsafe, require user approval         │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Startup Warning System

### 2.1 Container Startup Checks

**Work Mode Startup**:
```bash
#!/bin/bash
# /opt/bitbot/git-startup-check.sh

echo "=== BitBot Git Safety Check ==="

# Check if git repository exists
if [ ! -d ".git" ]; then
    echo "ℹ️ Not a git repository"
    echo "   Recommendation: git init"
    return 0
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️ WARNING: Uncommitted changes detected"
    git status --porcelain | head -10
    if [ "$(git status --porcelain | wc -l)" -gt 10 ]; then
        echo "   ... and $(($(git status --porcelain | wc -l) - 10)) more files"
    fi
    echo ""
    echo "   Recommendation: Commit changes before AI work"
    echo "   AI may create checkpoints automatically"
fi

# Check for unpushed commits
if [ "$(git rev-list HEAD --not --remotes 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "⚠️ WARNING: $(($(git rev-list HEAD --not --remotes | wc -l))) unpushed commits"
    echo "   Recommendation: git push"
fi

# Check for remote configuration
if [ -z "$(git remote 2>/dev/null)" ]; then
    echo "ℹ️ No remote repository configured"
    echo "   Recommendation: git remote add origin <url>"
fi

echo "==============================="
echo ""
```

**Setup Mode Startup**:
```bash
#!/bin/bash
# /opt/bitbot/git-setup-check.sh

echo "=== BitBot Setup Mode - Git Safety ==="

if [ -d ".git" ]; then
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠️ IMPORTANT: Uncommitted changes detected"
        echo ""
        echo "Setup mode can modify .devcontainer and infrastructure."
        echo "Recommend committing current work first:"
        echo ""
        echo "  git add ."
        echo "  git commit -m \"Work in progress\""
        echo ""
        echo "Or create a backup bundle:"
        echo "  git bundle create backup-$(date +%Y%m%d-%H%M%S).bundle HEAD"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup mode cancelled. Commit changes and try again."
            exit 1
        fi
    fi
fi

echo "================================="
echo ""
```

### 2.2 Warning Configuration

**.bitbot/config.yml**:
```yaml
git_safety:
  startup_warnings:
    enabled: true                    # Enable startup Git checks
    show_uncommitted: true           # Warn about uncommitted changes
    show_unpushed: true             # Warn about unpushed commits
    show_no_remote: true            # Info about missing remote
    max_files_shown: 10             # Limit status output

  setup_mode:
    require_confirmation: true       # Require user confirmation if dirty
    block_if_dirty: false           # Optional: block setup if uncommitted changes
    suggest_backup: true            # Suggest git bundle backup

  work_mode:
    auto_checkpoint: true           # AI can create automatic checkpoints
    checkpoint_threshold: 5         # Files changed before checkpoint suggestion
```

### 2.3 Logging and Audit

**Git Safety Log**: `.bitbot/logs/git-safety.log`
```bash
[2025-10-20T14:30:00Z] STARTUP_CHECK: mode=work uncommitted=3 unpushed=1 remote=origin
[2025-10-20T14:30:05Z] WARNING_SHOWN: uncommitted_files=src/main.py,src/utils.py,README.md
[2025-10-20T14:31:00Z] SETUP_MODE_ENTRY: uncommitted=3 user_confirmed=yes
[2025-10-20T14:32:00Z] CHECKPOINT_CREATED: stash_id=stash@{0} reason="AI refactoring checkpoint"
```

---

## 3. MCP Tool Integration

### 3.1 Git Safety MCP Tools

**Available to AI Agents via MCP**:

#### git_status_check
```json
{
  "name": "git_status_check",
  "description": "Check current Git repository status",
  "inputSchema": {
    "type": "object",
    "properties": {
      "verbose": {
        "type": "boolean",
        "description": "Show detailed status information",
        "default": false
      }
    }
  }
}
```

**Implementation**:
```bash
#!/bin/bash
# MCP tool: git_status_check

VERBOSE=${1:-false}

if [ ! -d ".git" ]; then
    echo '{"status": "not_git_repo", "message": "Not a Git repository"}'
    exit 0
fi

UNCOMMITTED=$(git status --porcelain | wc -l)
UNPUSHED=$(git rev-list HEAD --not --remotes 2>/dev/null | wc -l)
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")

if [ "$VERBOSE" = "true" ]; then
    echo "{"
    echo "  \"status\": \"ok\","
    echo "  \"branch\": \"$BRANCH\","
    echo "  \"uncommitted_changes\": $UNCOMMITTED,"
    echo "  \"unpushed_commits\": $UNPUSHED,"
    echo "  \"files_changed\": ["
    git status --porcelain | head -10 | sed 's/.*/"&"/' | paste -sd ',' -
    echo "  ]"
    echo "}"
else
    echo "{"
    echo "  \"status\": \"ok\","
    echo "  \"branch\": \"$BRANCH\","
    echo "  \"uncommitted_changes\": $UNCOMMITTED,"
    echo "  \"unpushed_commits\": $UNPUSHED"
    echo "}"
fi
```

#### git_create_checkpoint
```json
{
  "name": "git_create_checkpoint",
  "description": "Create a safety checkpoint before major changes",
  "inputSchema": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "Checkpoint description",
        "default": "BitBot safety checkpoint"
      },
      "method": {
        "type": "string",
        "enum": ["stash", "commit", "branch"],
        "description": "Checkpoint method",
        "default": "stash"
      }
    }
  }
}
```

**Implementation**:
```bash
#!/bin/bash
# MCP tool: git_create_checkpoint

MESSAGE=${1:-"BitBot safety checkpoint"}
METHOD=${2:-"stash"}
TIMESTAMP=$(date -Iseconds)

case "$METHOD" in
    stash)
        if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
            STASH_ID=$(git stash push -m "$MESSAGE - $TIMESTAMP")
            echo "{"
            echo "  \"status\": \"checkpoint_created\","
            echo "  \"method\": \"stash\","
            echo "  \"stash_id\": \"stash@{0}\","
            echo "  \"message\": \"$MESSAGE\","
            echo "  \"rollback_command\": \"git stash pop\""
            echo "}"
        else
            echo "{"
            echo "  \"status\": \"no_changes\","
            echo "  \"message\": \"No uncommitted changes to checkpoint\""
            echo "}"
        fi
        ;;

    commit)
        if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
            git add .
            COMMIT_ID=$(git commit -m "$MESSAGE - $TIMESTAMP" --quiet && git rev-parse HEAD)
            echo "{"
            echo "  \"status\": \"checkpoint_created\","
            echo "  \"method\": \"commit\","
            echo "  \"commit_id\": \"$COMMIT_ID\","
            echo "  \"message\": \"$MESSAGE\","
            echo "  \"rollback_command\": \"git reset --soft HEAD~1\""
            echo "}"
        else
            echo "{"
            echo "  \"status\": \"no_changes\","
            echo "  \"message\": \"No uncommitted changes to checkpoint\""
            echo "}"
        fi
        ;;

    branch)
        BRANCH_NAME="checkpoint-$(date +%Y%m%d-%H%M%S)"
        git checkout -b "$BRANCH_NAME"
        if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
            git add .
            git commit -m "$MESSAGE - $TIMESTAMP"
        fi
        git checkout -
        echo "{"
        echo "  \"status\": \"checkpoint_created\","
        echo "  \"method\": \"branch\","
        echo "  \"branch_name\": \"$BRANCH_NAME\","
        echo "  \"message\": \"$MESSAGE\","
        echo "  \"rollback_command\": \"git checkout $BRANCH_NAME\""
        echo "}"
        ;;
esac
```

#### git_diff_summary
```json
{
  "name": "git_diff_summary",
  "description": "Show summary of current uncommitted changes",
  "inputSchema": {
    "type": "object",
    "properties": {
      "max_lines": {
        "type": "integer",
        "description": "Maximum lines of diff to show",
        "default": 50
      }
    }
  }
}
```

### 3.2 AI Agent Integration

**System Prompt Addition**:
```markdown
## Git Safety Instructions

Before making significant changes to the codebase:

1. Check Git status: Use git_status_check() to understand current state
2. If uncommitted changes exist, consider creating a checkpoint: git_create_checkpoint()
3. For major refactoring (>5 files), always create a checkpoint first
4. If experimental changes, suggest user creates a branch: `git checkout -b experiment-feature`

Safety reminders:
- Uncommitted work can be lost - always checkpoint before major changes
- User may want to push current work before starting new features
- Be helpful about Git workflows - many users appreciate guidance
```

**Example AI Workflow**:
```bash
# AI agent workflow for major refactoring
1. git_status_check() -> 3 uncommitted files detected
2. AI: "I notice uncommitted changes. Should I create a checkpoint before refactoring?"
3. User: "Yes"
4. git_create_checkpoint(message="Before refactoring authentication system", method="stash")
5. AI proceeds with refactoring
6. AI: "Refactoring complete. Your checkpoint is available via 'git stash pop' if needed."
```

---

## 4. Pre-Destructive Operation Checks

### 4.1 Setup Mode Entry Protection

**Before entering setup mode**:
```bash
#!/bin/bash
# Setup mode git safety check

check_setup_safety() {
    if [ ! -d ".git" ]; then
        echo "ℹ️ Not a git repository - setup mode available"
        return 0
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠️ IMPORTANT: Setup mode with uncommitted changes"
        echo ""
        echo "Setup mode can modify .devcontainer and infrastructure files."
        echo "Recommend committing current work or creating a backup:"
        echo ""
        echo "Option 1 - Commit current work:"
        echo "  git add ."
        echo "  git commit -m \"WIP: current work\""
        echo ""
        echo "Option 2 - Create backup bundle:"
        echo "  git bundle create backup-$(date +%Y%m%d-%H%M%S).bundle HEAD"
        echo ""

        # Log the decision
        TIMESTAMP=$(date -Iseconds)
        echo "[$TIMESTAMP] SETUP_MODE_ENTRY: uncommitted_changes=true" >> .bitbot/logs/git-safety.log

        read -p "Continue with setup mode anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup mode cancelled."
            echo "[$TIMESTAMP] SETUP_MODE_CANCELLED: user_choice=safety_first" >> .bitbot/logs/git-safety.log
            return 1
        fi

        echo "[$TIMESTAMP] SETUP_MODE_CONTINUED: user_choice=accept_risk" >> .bitbot/logs/git-safety.log
    fi

    return 0
}
```

### 4.2 Infrastructure Change Protection

**Before modifying .devcontainer**:
```bash
#!/bin/bash
# Infrastructure change safety check

check_infrastructure_safety() {
    local CHANGE_TYPE="$1"  # "devcontainer", "dockerfile", "compose"

    if [ ! -d ".git" ]; then
        echo "ℹ️ No git repository - infrastructure changes allowed"
        return 0
    fi

    # For infrastructure changes, require clean state or explicit approval
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "❌ Infrastructure change blocked: uncommitted changes"
        echo ""
        echo "Infrastructure changes ($CHANGE_TYPE) require a clean git state"
        echo "or explicit backup to prevent conflicts."
        echo ""
        echo "Options:"
        echo "1. Commit current work: git add . && git commit -m \"Current work\""
        echo "2. Create backup bundle: git bundle create backup.bundle HEAD"
        echo "3. Use --force flag to override (not recommended)"
        echo ""
        return 1
    fi

    # Check for unpushed commits
    if [ "$(git rev-list HEAD --not --remotes 2>/dev/null | wc -l)" -gt 0 ]; then
        echo "⚠️ Warning: Unpushed commits detected"
        echo "Consider pushing before infrastructure changes:"
        echo "  git push"
        echo ""
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Log infrastructure change approval
    TIMESTAMP=$(date -Iseconds)
    echo "[$TIMESTAMP] INFRASTRUCTURE_CHANGE: type=$CHANGE_TYPE git_state=clean" >> .bitbot/logs/git-safety.log

    return 0
}
```

### 4.3 Container Rebuild Safety

**Before rebuilding containers**:
```bash
#!/bin/bash
# Container rebuild safety check

check_rebuild_safety() {
    local CONTAINER_TYPE="$1"  # "work", "setup"

    echo "=== Container Rebuild Safety Check ==="

    if [ -d ".git" ]; then
        # Suggest committing recent work
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo "💡 Suggestion: Commit recent work before rebuild"
            echo "   Rebuilds can take time - save your progress:"
            echo "   git add . && git commit -m \"Work in progress\""
            echo ""
        fi

        # Show what will be rebuilt
        echo "Container rebuild: $CONTAINER_TYPE"
        echo "This will:"
        echo "  - Stop current container"
        echo "  - Rebuild from .devcontainer configuration"
        echo "  - Start new container with same mounts"
        echo "  - Preserve .bitbot/ state and sessions"
        echo ""

        read -p "Continue with rebuild? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Rebuild cancelled."
            return 1
        fi
    fi

    # Log rebuild decision
    TIMESTAMP=$(date -Iseconds)
    echo "[$TIMESTAMP] CONTAINER_REBUILD: type=$CONTAINER_TYPE user_approved=true" >> .bitbot/logs/git-safety.log

    return 0
}
```

---

## 5. Recovery and Rollback

### 5.1 Checkpoint Recovery

**Automatic checkpoint recovery instructions**:
```bash
#!/bin/bash
# /opt/bitbot/show-recovery-options.sh

show_recovery_options() {
    echo "=== BitBot Recovery Options ==="
    echo ""

    # Show stashes (checkpoints)
    if [ "$(git stash list | wc -l)" -gt 0 ]; then
        echo "Available checkpoints (stashes):"
        git stash list --oneline | head -5
        if [ "$(git stash list | wc -l)" -gt 5 ]; then
            echo "... and $(($(git stash list | wc -l) - 5)) more"
        fi
        echo ""
        echo "Restore latest checkpoint: git stash pop"
        echo "List all checkpoints: git stash list"
        echo ""
    fi

    # Show recent commits
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null || echo "No commits found"
    echo ""
    echo "Undo last commit (keep changes): git reset --soft HEAD~1"
    echo "Undo last commit (discard changes): git reset --hard HEAD~1"
    echo ""

    # Show backup bundles
    if ls backup-*.bundle >/dev/null 2>&1; then
        echo "Available backup bundles:"
        ls -la backup-*.bundle
        echo ""
        echo "Restore from bundle: git bundle verify <bundle> && git pull <bundle> main"
        echo ""
    fi

    echo "============================="
}
```

### 5.2 Emergency Reset

**Complete workspace reset**:
```bash
#!/bin/bash
# /opt/bitbot/emergency-reset.sh

emergency_reset() {
    echo "⚠️ EMERGENCY RESET - This will:"
    echo "  - Reset all uncommitted changes"
    echo "  - Return to last committed state"
    echo "  - Preserve .bitbot/ logs and sessions"
    echo ""
    echo "This cannot be undone!"
    echo ""
    read -p "Type 'RESET' to confirm: " -r
    if [ "$REPLY" != "RESET" ]; then
        echo "Reset cancelled."
        return 1
    fi

    # Create emergency backup first
    BACKUP_NAME="emergency-backup-$(date +%Y%m%d-%H%M%S).bundle"
    if [ -d ".git" ]; then
        git bundle create "$BACKUP_NAME" HEAD 2>/dev/null && \
        echo "✓ Emergency backup created: $BACKUP_NAME"
    fi

    # Reset to clean state
    git reset --hard HEAD 2>/dev/null
    git clean -fd 2>/dev/null

    # Log emergency reset
    TIMESTAMP=$(date -Iseconds)
    echo "[$TIMESTAMP] EMERGENCY_RESET: backup=$BACKUP_NAME" >> .bitbot/logs/git-safety.log

    echo "✓ Workspace reset to last commit"
    echo "✓ Emergency backup available: $BACKUP_NAME"
}
```

---

## 6. Integration with AI Agents

### 6.1 Claude Code Integration

**.claude/config.yml additions**:
```yaml
# Git safety integration for Claude Code
mcpServers:
  git-safety:
    command: docker
    args: ["exec", "bitbot-work-${WORKSPACE_HASH}", "/opt/bitbot/mcp/git-safety-server"]
    env:
      WORKSPACE_PATH: "${workspaceFolder}"

# Pre-task hooks for git safety
pre_task_hooks:
  - name: git_safety_check
    description: Check Git status before major changes
    trigger:
      keywords: ["refactor", "implement", "change", "update", "modify"]
      file_count_threshold: 3
    action:
      tool: git_status_check
      on_uncommitted:
        suggest_checkpoint: true
        message: "I notice uncommitted changes. Create checkpoint before proceeding?"

# Post-task actions
post_task_actions:
  - name: git_rollback_info
    description: Provide rollback instructions
    condition: checkpoint_created
    message: "Changes complete. To undo: {rollback_command}"
```

### 6.2 System Prompt Integration

**AI Agent System Prompt**:
```markdown
You are working in a BitBot development environment with Git safety features.

IMPORTANT Git Safety Guidelines:
1. Before major changes (>3 files), check git status with git_status_check()
2. If uncommitted changes exist, suggest creating a checkpoint
3. For experimental features, recommend creating a branch
4. Always inform user about rollback options after changes

Available Git Safety Tools:
- git_status_check(): Check repository state
- git_create_checkpoint(): Create safety checkpoint (stash/commit/branch)
- git_diff_summary(): Show current changes

Example workflow:
User: "Refactor the authentication system"
You:
1. Call git_status_check()
2. If uncommitted changes: "I see uncommitted changes. Shall I create a checkpoint first?"
3. If approved: Call git_create_checkpoint()
4. Proceed with refactoring
5. After completion: "Refactoring complete. If issues occur, restore with: git stash pop"
```

---

## 7. Configuration and Customization

### 7.1 User Configuration

**.bitbot/git-safety.yml**:
```yaml
# Git Safety Configuration

startup_checks:
  enabled: true
  warn_uncommitted: true
  warn_unpushed: true
  warn_no_remote: true
  max_status_lines: 10

checkpoints:
  auto_suggest_threshold: 5      # Files changed before suggesting checkpoint
  default_method: "stash"        # stash, commit, or branch
  include_untracked: false       # Include untracked files in checkpoints

setup_mode:
  require_clean_git: false       # Block setup if uncommitted changes
  require_confirmation: true     # Require user confirmation
  suggest_backup: true          # Suggest git bundle backup

infrastructure_changes:
  require_clean_git: true        # Block infrastructure changes if dirty
  warn_unpushed: true           # Warn about unpushed commits
  create_backup: true           # Auto-create backup bundle

logging:
  enabled: true
  log_file: ".bitbot/logs/git-safety.log"
  log_level: "info"             # debug, info, warn, error
```

### 7.2 Environment Variables

```bash
# Git Safety Environment Variables
export BITBOT_GIT_SAFETY_ENABLED=true           # Enable git safety features
export BITBOT_REQUIRE_CLEAN_GIT=false           # Require clean git for setup
export BITBOT_AUTO_CHECKPOINT_THRESHOLD=5       # Auto-suggest checkpoint threshold
export BITBOT_GIT_SAFETY_LOG_LEVEL=info         # Logging level
```

---

## 8. Success Criteria

**Functional Requirements**:
- [ ] Startup warnings show uncommitted/unpushed changes
- [ ] MCP tools available to AI agents for git status checks
- [ ] Checkpoint creation works (stash, commit, branch methods)
- [ ] Setup mode warns and requires confirmation for dirty git state
- [ ] Infrastructure changes blocked if git state unsafe
- [ ] Recovery options clearly displayed to users

**Usability Requirements**:
- [ ] Clear, actionable warnings and suggestions
- [ ] AI agents understand and use git safety tools appropriately
- [ ] Recovery instructions are easy to follow
- [ ] Configuration options allow user customization

**Safety Requirements**:
- [ ] No automatic destructive operations without user consent
- [ ] All safety decisions logged for audit trail
- [ ] Emergency reset preserves user work in backup bundles
- [ ] Git safety checks never corrupt repository state

---

## 9. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-02: Git-based safety)
- SPEC-02: Security Mode System (integration with modes)
- SPEC-03: MCP Service Architecture (git safety MCP tools)
- SPEC-07: AI Agent Integration (system prompt additions)

**Git Safety Research**:
- Git documentation: https://git-scm.com/docs
- Git best practices for development environments
- AI agent safety patterns and workflows

---

**Status**: **Approved**
**Implementation Priority**: P0 (Critical - Blocking)
**Next Steps**: Implement SPEC-03 (MCP Service Architecture)