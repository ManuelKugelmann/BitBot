# CLI UX & Onboarding Specification

**Feature ID**: SPEC-09
**Priority**: P1 (Important)
**Status**: Draft (Design complete, implementation pending)
**Depends On**: SPEC-05 (Cross-Platform CLI), SPEC-08 (Workspace Management), SPEC-10 (Installation)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

Comprehensive CLI user experience covering first-run onboarding and ongoing command usage. Interactive wizard for new users, scriptable commands for automation, auditable actions.

**Key Design**: Prerequisite checks + interactive onboarding + minimal command surface + clear contracts + audit trail = smooth UX for humans and scripts.

---

## Part A: First-Run Experience

### A1. First-Run Detection

**Triggers first-run wizard**:
- No `~/.bitbot/` directory exists
- No `.bitbot/` in current workspace
- `~/.bitbot/first-run` marker file absent

**Flow**:
```bash
$ bitbot

# First run detected → launches wizard
# Subsequent runs → normal smart-launch behavior
```

### A2. First-Run Sequence

```
bitbot (first run)
  ↓
Prerequisite Checks (Docker, Docker Compose, WSL2)
  ↓
Welcome & Introduction
  ↓
Environment Setup (~/.bitbot/ creation)
  ↓
Workspace Initialization (optional)
  ↓
Quick Start Guide
  ↓
Mark first-run complete (~/.bitbot/first-run)
  ↓
Launch workspace (if initialized)
```

### A3. Prerequisite Checks

**Required tools**:

```bash
# Docker
if ! command -v docker &>/dev/null; then
  error "Docker not found"
  echo "Install: https://www.docker.com/products/docker-desktop"
  exit 1
fi

# Docker running
if ! docker ps &>/dev/null; then
  error "Docker is not running. Start Docker Desktop."
  exit 1
fi

# Docker Compose
if ! docker compose version &>/dev/null; then
  error "Docker Compose not found (usually bundled with Docker)"
  exit 1
fi

# WSL2 (Windows only)
if [[ "$OS" == "windows" ]]; then
  if ! command -v wsl &>/dev/null; then
    error "WSL2 required on Windows: https://aka.ms/wsl2"
    exit 1
  fi
fi
```

**Optional tools** (warnings only):
- VS Code (for `bitbot vscode`)
- Git (for version control)
- tmux (for session management)

### A4. Welcome & Environment Setup

```
==============================================
  Welcome to BitBot!
==============================================

BitBot is a secure development environment manager.

Checking prerequisites...
  ✓ Docker installed (v24.0.6)
  ✓ Docker running
  ✓ Docker Compose v2 installed
  ⚠ VS Code not found (optional, install for full experience)

Setting up BitBot...
  ✓ Created ~/.bitbot/
  ✓ Created ~/.bitbot/templates/
  ✓ Downloaded built-in templates (15 templates)
  ✓ Created ~/.bitbot/secrets.enc (secure API key storage)

BitBot is ready!

Would you like to initialize a workspace now? (y/N): y

# Launches workspace init wizard (SPEC-08)
```

### A5. Quick Start Guide

```
==============================================
  Quick Start Guide
==============================================

Your workspace is ready! Here's how to get started:

🚀 Launch development environment:
   bitbot work vscode

📝 Common commands:
   bitbot work          # Start work mode
   bitbot setup         # Infrastructure changes
   bitbot list          # Show sessions
   bitbot stop          # Stop current session

🤖 AI Agents:
   Your workspace is configured with Continue.dev
   Launch VS Code and the agent will auto-activate

📚 Learn more:
   bitbot help
   https://docs.bitbot.dev/

Press ENTER to launch VS Code in your new workspace...
```

---

## Part B: Workspace Discovery

### B0. Workspace Detection Algorithm

**Trigger**: Every `bitbot` command execution (except help/version)

**Logic**:
```
1. Check current directory (CWD) for .bitbot/
   ↓ Found → Use CWD as workspace
   ↓ Not found → Continue to step 2

2. No .bitbot/ found in CWD
   → Prompt to initialize new workspace (see B0.1)
```

### B0.1 No Workspace Found

**Prompt** (interactive mode):
```
No BitBot workspace found.

Initialize workspace in current directory?
  /home/user/projects/subfolder

(Y/n):
```

**User responses**:
- `Y` or Enter → Run `bitbot init` (creates .bitbot/, launches config)
- `n` → Exit with code 4

**Alternative** (user runs init explicitly):
```bash
bitbot init
# Creates .bitbot/config.json, always launches config mode
```

### B0.2 Edge Cases

**Symlinks in path**:
- Follow symlinks (use resolved path for workspace detection)

**Workspace on temporary filesystem** (/tmp, /dev/shm):
- Allow but show warning: "⚠ Workspace on temporary filesystem"

**Different filesystem/mount**:
- Allow (no special handling)

---

## Part C: CLI Command Reference

### C1. Command Design Principles

**Minimal surface**: One-word verbs for common operations
**Scriptable**: Non-interactive mode for automation
**Auditable**: All actions logged to `.bitbot/audit.log`
**Clear contracts**: Documented inputs, outputs, side-effects, exit codes

### C2. Top-Level Commands

**Core Commands**:
```bash
bitbot               # Default: launch work mode
bitbot work          # Start/attach work mode
bitbot config        # Start config mode
bitbot vscode        # Launch VS Code in work container
bitbot init          # Initialize workspace (creates .bitbot/, launches config)
bitbot help          # Show help
bitbot version       # Show version
```

**Planned Commands**:
```bash
bitbot list          # List sessions and containers
bitbot stop          # Stop current session
bitbot kill          # Stop all BitBot containers
bitbot mcp           # Manage MCP services
bitbot agent         # Manage AI agents
bitbot doctor        # Run diagnostics
bitbot session       # Session management
bitbot backup        # Backup management
```

### C3. Command Contracts

**Contract format**:
- **Inputs**: Arguments, flags, environment
- **Behavior**: What the command does
- **Outputs**: stdout, stderr, return data
- **Side-effects**: Files written, containers started, state changes
- **Audit**: Entries written to audit.log
- **Exit codes**: 0=success, 1=generic error, 2=usage error, 3=security check failed, 4=not initialized

---

#### `bitbot`

**Inputs**: None

**Behavior**:
- Detect workspace (CWD only)
- If no workspace: prompt for init
- If workspace exists: launch work mode (same as `bitbot work`)

**Outputs**: Container name

**Side-effects**:
- May launch work container
- Updates `config.json` last_accessed

**Exit codes**: 0=success, 4=workspace not initialized, 1=error

**Example**:
```bash
bitbot
# → Launching work mode...
# → [+] Container launched successfully
```

---

#### `bitbot work`

**Inputs**: None

**Behavior**:
- Validate workspace exists (.bitbot/config.json)
- Git warning if uncommitted changes (non-blocking)
- Launch/attach to work container via devcontainer CLI
- Uses workspace's .devcontainer/devcontainer.json
- Attach to tmux session

**Outputs**: Container name

**Side-effects**:
- Starts/attaches to Docker container
- Creates tmux session inside container

**Exit codes**: 0=success, 4=not initialized, 1=error

**Example**:
```bash
bitbot work
# → [>] Launching work mode...
# → [+] Container launched successfully
# → [attached to tmux session]
```

---

#### `bitbot config`

**Inputs**: None

**Behavior**:
- Validate workspace exists (.bitbot/config.json)
- Git warning if uncommitted changes (non-blocking)
- Launch config container using BitBot's templates/bitbot/config/
- Workspace mounted at /workspace (RW access to .devcontainer)
- Attach to tmux session

**Outputs**: Container name

**Side-effects**:
- Starts/attaches to config container

**Exit codes**: 0=success, 4=not initialized, 1=error

**Example**:
```bash
bitbot config
# → [!] Uncommitted changes detected (non-blocking warning)
# → [>] Launching config mode...
# → [+] Container launched successfully
```

---

#### `bitbot vscode`

**Inputs**: None

**Behavior**:
- Validate workspace exists
- Launch VS Code with `code <workspace-path>`
- VS Code's devcontainer extension handles container attachment

**Outputs**: None (VS Code launched)

**Side-effects**:
- Launches VS Code application
- VS Code starts/attaches to work container automatically

**Exit codes**: 0=success, 4=not initialized, 1=error

**Example**:
```bash
bitbot vscode
# → [>] Launching VS Code...
# → [+] VS Code launched
```

---

#### `bitbot init`

**Inputs**: None

**Behavior**:
- Check if .bitbot/ already exists (error if so)
- Create .bitbot/ directory structure
- Create config.json with workspace name
- Always launch config mode to configure .devcontainer

**Outputs**: Confirmation message

**Side-effects**:
- Creates .bitbot/ directory
- Creates .bitbot/internal/global/.claude/ directory
- Creates .bitbot/config.json
- Launches config mode

**Exit codes**: 0=success, 1=already initialized or error

**Example**:
```bash
bitbot init
# → [>] Initializing BitBot workspace: /home/user/project
# → [+] Workspace initialized
# →
# → Launching config mode to configure workspace...
# → (Use config mode to create/modify .devcontainer for bitbot)
```

---

#### `bitbot help`

**Inputs**: None

**Behavior**: Display help text

**Outputs**: Help text

**Side-effects**: None

**Exit codes**: 0=success

---

#### `bitbot version`

**Inputs**: None

**Behavior**: Display version

**Outputs**: Version string (e.g., "BitBot v0.1.0")

**Side-effects**: None

**Exit codes**: 0=success

---

## Planned Commands

#### `bitbot list`

**Inputs**: Optional `--format <json|table>` (default: table)

**Behavior**:
- Enumerate `sessions/*.json`
- Query running BitBot containers
- Show session status (attached/detached)

**Outputs**: Table or JSON of sessions

**Side-effects**: None (read-only)

**Audit**: None (read-only)

**Exit codes**: 0=success

**Example**:
```bash
bitbot list

# Output:
# Active Sessions:
# ✅ work-main     (alice, 2h ago, attached)
# ✅ work-feature  (alice, 30m ago, detached)
#
# Containers:
# • bitbot-dev-a1b2c3d4 (running, work mode)
```

---

#### `bitbot stop`

**Inputs**: Optional `--session <id>`, `--container` (stop container too)

**Behavior**:
- Stop tmux session
- Optionally stop container (with `--container`)
- Update `sessions/<id>.json` (attached=false)
- Update `metadata.json` last_updated

**Outputs**: Confirmation message

**Side-effects**:
- Stops tmux session
- May stop container
- Updates session metadata

**Audit**: `stop session=<id> container_stopped=<bool>`

**Exit codes**: 0=success, 4=session not found, 1=error

**Example**:
```bash
bitbot stop
# → Stopped session work-main

bitbot stop --container
# → Stopped session work-main and container bitbot-dev-a1b2c3d4
```

---

#### `bitbot kill`

**Inputs**: Optional `--confirm`, `--non-interactive`

**Behavior**:
- Prompt for confirmation (interactive)
- Stop ALL BitBot-managed containers
- Update all session metadata (attached=false)

**Outputs**: List of stopped containers

**Side-effects**:
- Stops all BitBot containers
- Updates all session metadata

**Audit**: `kill containers=<list>`

**Exit codes**: 0=success, 1=error

**Example**:
```bash
bitbot kill

# Prompt:
# This will stop ALL BitBot containers. Continue? (y/N): y
# → Stopped 3 containers: bitbot-dev-a1b2c3d4, mcp-git-a1b2c3d4, mcp-filesystem-a1b2c3d4
```

---

#### `bitbot config`

**Inputs**: Interactive wizard or flags (`--agent <name>`, `--memory <limit>`, etc.)

**Behavior**:
- Launch interactive configuration wizard
- Or apply flags directly
- Write to `.bitbot/metadata.json` and `.bitbot/agent.yml`

**Outputs**: Saved configuration location

**Side-effects**:
- Updates `metadata.json`
- Updates `agent.yml`

**Audit**: `config updated fields=<list>`

**Exit codes**: 0=success, 1=error

**Example**:
```bash
bitbot config
# → Launches interactive wizard

bitbot config --agent claude --memory 4g
# → Configuration saved to .bitbot/
```

---

#### `bitbot mcp <subcommand>`

**Subcommands**: `list`, `start`, `stop`, `logs`, `restart`

**Behavior**:
- `list`: Show MCP services from `.bitbot/mcp/docker-compose.yml` and their status
- `start`: Run `docker-compose -f .bitbot/mcp/docker-compose.yml up -d`
- `stop`: Run `docker-compose -f ... down`
- `logs`: Show logs for service (`docker-compose -f ... logs --tail=200 <service>`)
- `restart`: Stop then start

**Side-effects**:
- May start/stop MCP service containers
- Writes to audit.log

**Audit**: `mcp <action> services=<list>`

**Exit codes**: 0=success, 4=compose file not found, 1=error

**Examples**:
```bash
bitbot mcp list
# → git-safety: running, filesystem: stopped

bitbot mcp start
# → Started 2 MCP services

bitbot mcp logs git-safety
# → <last 200 lines of logs>
```

---

#### `bitbot agent <subcommand>`

**Subcommands**: `list`, `config`, `start`, `stop`

**Behavior**:
- `list`: Show available and configured agents
- `config`: Launch agent configuration wizard (SPEC-07)
- `start`: Start AI agent in container
- `stop`: Stop AI agent

**See**: SPEC-07 for full agent management details

**Example**:
```bash
bitbot agent list
# → Configured: continue (Continue.dev)
#   Available: claude, cline, vscode

bitbot agent config
# → Launches interactive agent configuration wizard
```

---

#### `bitbot doctor`

**Inputs**: None

**Behavior**:
- Check Docker daemon reachable
- Check `.bitbot/` directory health
- Check MCP services health
- Check disk space
- Check workspace integrity

**Outputs**: JSON or human-readable diagnostics

**Side-effects**: None (read-only)

**Audit**: None (read-only)

**Exit codes**: 0=all checks passed, non-zero=checks failed

**Example**:
```bash
bitbot doctor

# Output:
# ✓ Docker daemon reachable
# ✓ .bitbot/ directory healthy
# ✓ MCP services reachable
# ⚠ Disk space low (10GB free)
# ✓ Workspace integrity OK
#
# 1 warning, 4 checks passed
```

---

### C4. Interactive vs Non-Interactive Modes

**Interactive mode** (default):
- Prompts for user input
- Asks for confirmation on risky operations
- Shows progress spinners and friendly messages
- Suitable for terminal usage

**Non-interactive mode** (`--non-interactive` or `-n`):
- Never prompts for input
- Fails early if input required
- Suitable for scripts and automation
- Requires all necessary flags

**Example**:
```bash
# Interactive (prompts)
bitbot setup
# → Prompt: "This requires Docker socket access. Continue? (y/N)"

# Non-interactive (requires flags)
bitbot setup --non-interactive --allow-socket --reason "CI/CD pipeline"
# → No prompts, fails if flags missing
```

### C5. Exit Codes

**Standard exit codes**:
- `0` - Success
- `1` - Generic error
- `2` - Usage error (invalid arguments)
- `3` - Security check failed (missing approval, unsafe operation)
- `4` - Workspace not initialized (run `bitbot init` first)
- `5` - Docker error (daemon not running, container failed)
- `6` - Concurrency error (lock acquisition failed)

**Usage**:
```bash
bitbot work
echo $?  # 0 if successful
```

### C6. Concurrency & Locking

**Problem**: Multiple `bitbot` processes modifying state simultaneously

**Solution**: Atomic lockfile mechanism

```bash
# Before writing to .bitbot/
flock -w 10 .bitbot/lock -c "
  # Critical section
  # Update metadata.json, sessions/, etc.
"

# If lock acquisition fails (timeout):
error "Another BitBot process is running. Retry in a moment."
exit 6
```

**Protected operations**:
- Writing `metadata.json`
- Creating/updating `sessions/*.json`
- Modifying `approvals.json`
- Writing to `audit.log`

---

## C. Testing Strategy

### C1. First-Run Tests

- FR-01: First-run wizard completes successfully
- FR-02: Prerequisite checks detect missing Docker
- FR-03: Environment setup creates `~/.bitbot/`
- FR-04: Quick start guide displays correctly
- FR-05: First-run marker prevents re-run

### C2. Command Tests

**For each command**:
- Happy path (normal input, expected behavior)
- Edge case 1: Workspace uninitialized → exit code 4
- Edge case 2: Non-interactive without required flags → exit code 2 or 3
- Edge case 3: Concurrency (simultaneous processes) → one succeeds, others fail gracefully

**Example test cases**:
```bash
# bitbot (smart-launch)
Test: No sessions exist → starts work session
Test: Multiple sessions → prompts to choose (interactive)
Test: Multiple sessions + non-interactive → fails with code 2

# bitbot setup
Test: Missing --reason → fails with exit code 3
Test: Valid approval → writes approvals.json
Test: Non-interactive without flags → fails

# bitbot mcp start
Test: Missing compose file → exit code 4
Test: Valid compose → starts services
```

### C3. Audit Trail Tests

- A-01: All commands write correct audit entries
- A-02: Audit log is append-only
- A-03: Timestamps are accurate
- A-04: Sensitive data not logged (API keys, passwords)

---

## D. Success Criteria

**Functional**:
- [ ] First-run wizard completes successfully
- [ ] All prerequisite checks work
- [ ] All top-level commands work as specified
- [ ] Exit codes correct
- [ ] Audit trail accurate
- [ ] Concurrency handled safely

**Usability**:
- [ ] First-run experience clear and helpful
- [ ] Interactive mode intuitive
- [ ] Non-interactive mode scriptable
- [ ] Error messages actionable
- [ ] Help text comprehensive

**Reliability**:
- [ ] No data corruption from concurrent processes
- [ ] Audit trail integrity maintained
- [ ] State recovery after crashes
- [ ] Cross-platform consistency (Windows/Linux/macOS)

---

## E. Implementation Phases

**Phase 1: First-Run Foundation**:
- [ ] Prerequisite checks
- [ ] First-run detection
- [ ] Environment setup
- [ ] Welcome wizard
- [ ] Quick start guide

**Phase 2: Core Commands**:
- [ ] `bitbot`, `bitbot work`, `bitbot stop`
- [ ] Smart-launch logic
- [ ] Session management basics
- [ ] Audit logging

**Phase 3: Advanced Commands**:
- [ ] `bitbot setup` with approval flow
- [ ] `bitbot mcp` service management
- [ ] `bitbot agent` management
- [ ] `bitbot doctor` diagnostics

**Phase 4: Polish & Safety**:
- [ ] Concurrency locking
- [ ] Non-interactive mode support
- [ ] Comprehensive error handling
- [ ] Help documentation

---

## F. References

**Related Specifications**:
- SPEC-05: Cross-Platform CLI (CLI implementation)
- SPEC-07: AI Agent Integration (agent commands)
- SPEC-08: Workspace Management (init/template commands)
- SPEC-10: Installation & Distribution (prerequisite checks)

**External Resources**:
- Click (Python CLI framework): https://click.palletsprojects.com/
- Rich (terminal formatting): https://rich.readthedocs.io/

---

**Status**: **Draft** (Design complete, implementation pending)
**Implementation Priority**: P1 (Critical for UX)
**Current Phase**: Planning

**Consolidated From**:
- Claude_Specification/09_FIRST_RUN_EXPERIENCE.md (onboarding wizard)
- Copilot_Specification/09-CLI-UX-and-Commands.md (command reference, contracts)
