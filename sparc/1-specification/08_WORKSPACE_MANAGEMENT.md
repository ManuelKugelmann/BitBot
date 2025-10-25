# Workspace Management Specification

**Feature ID**: SPEC-08
**Priority**: P2 (Nice to Have - Template System), P1 (Important - State Management)
**Status**: In Progress (Template system design complete, state management MVP pending)
**Depends On**: SPEC-01 (Container Orchestration), SPEC-05 (Cross-Platform CLI), SPEC-06 (VS Code Integration), SPEC-07 (AI Agent Integration)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

Comprehensive workspace management covering two aspects:
1. **Template System** - Quick initialization with pre-configured devcontainer setups
2. **State Management** - Runtime tracking of sessions, metadata, backups, and approvals

**Key Design**: Built-in templates + user templates + CLI wizard + `.bitbot/` state directory + AGENTS.md standard + AI agent configs = fast, modern workspace setup with reliable state tracking.

**2025 Updates**:
- ✅ AGENTS.md universal standard in all templates
- ✅ AI agent configurations (Claude Code, Continue.dev, Cline, VS Code Agent Mode)
- ✅ VS Code Direct DevContainer Opening integration 
- ✅ Modern VS Code dev container features
- ✅ Cross-platform state management (JSON + small files)

---

## Part A: Template System

### A1. Template Sources

**Built-in templates** (`/opt/bitbot/templates/`):
- Official BitBot templates
- Common stacks: Python, Node.js, Go, Rust, Java, C++, C#/.NET, PHP, Ruby
- Maintained by BitBot project

**User templates** (`~/.bitbot/templates/`):
- Personal templates
- Company/team templates
- Custom configurations

**Remote templates** (GitHub, GitLab):
- Community templates: `bitbot init --template gh:user/repo`
- Shared configurations

### A2. Template Structure

```
template-name/
├── template.yml              # Template metadata
│
├── .devcontainer/
│   ├── devcontainer.json     # VS Code config
│   └── Dockerfile            # Container image
│
├── .bitbot/
│   ├── config.yml            # BitBot config
│   ├── docker-compose.work.yml
│   ├── docker-compose.setup.yml
│   └── mcp/
│       └── docker-compose.yml
│
├── AGENTS.md                 # Universal AI agent instructions (2025 standard)
│
├── .claude/                  # Claude Code configuration
│   ├── settings.json
│   └── commands/
│
├── .continue/                # Continue.dev configuration
│   └── config.json
│
├── .cline/                   # Cline configuration
│   └── config.json
│
├── .vscode/
│   ├── settings.json
│   ├── extensions.json
│   ├── launch.json
│   └── agents.json           # VS Code Agent Mode config
│
├── .gitignore
├── .gitattributes            # Line ending enforcement
├── README.md                 # Template documentation
└── files/                    # Optional starter files
    ├── src/
    └── tests/
```

**Key 2025 additions**:
- `AGENTS.md` - Universal AI agent instructions
- `.claude/`, `.continue/`, `.cline/` - AI agent settings
- `.vscode/agents.json` - VS Code Agent Mode config
- `.gitattributes` - Ensures correct line endings (bash=LF, ps1=CRLF)

### A3. Template Metadata (`template.yml`)

```yaml
name: python-fastapi
version: 1.0.0
description: Python FastAPI web development
author: BitBot Team
tags:
  - python
  - web
  - api
  - fastapi

stack:
  language: python
  version: "3.11"
  frameworks:
    - fastapi
    - pydantic
    - sqlalchemy

features:
  - Hot reload
  - Debugging
  - Testing (pytest)
  - Linting (ruff)
  - Type checking (mypy)

ai_agents:
  - claude
  - continue
  - cline

mcp_services:
  - git-safety
  - filesystem

devcontainer_features:
  - ghcr.io/devcontainers/features/python:1
  - ghcr.io/devcontainers/features/git:1
```

### A4. CLI Wizard

**Command**: `bitbot init [--template <name>]`

**Interactive flow**:
```
==============================================
  BitBot Workspace Initialization
==============================================

[1/6] Select Template:
  Popular:
    1. Python (FastAPI/Django/Flask)
    2. Node.js (Express/React/Next.js)
    3. Go (Gin/Echo)
    4. Rust (Actix/Axum)
    5. Java (Spring Boot)
    6. Custom template

Your choice: 1

[2/6] Python Configuration:
  Framework:
    1. FastAPI (async API, modern)
    2. Django (full-stack, batteries included)
    3. Flask (lightweight, flexible)

Your choice: 1

[3/6] AI Agent:
  1. Claude Code (commercial, premium)
  2. Continue.dev (open source, multi-model)
  3. Cline (VS Code extension)
  4. VS Code Agent Mode (native)
  5. Skip (configure later)

Your choice: 2

[4/6] Additional Features:
  [x] PostgreSQL database
  [x] Redis cache
  [ ] Celery task queue
  [x] Pytest + coverage

[5/6] Git Configuration:
  Initialize Git repo? Yes
  Add .gitignore? Yes (Python template)
  Initial commit? Yes

[6/6] Creating workspace...
  ✓ Template files copied
  ✓ .bitbot/ structure created
  ✓ AGENTS.md generated
  ✓ AI agent configured (Continue.dev)
  ✓ Git initialized
  ✓ Initial commit created

Workspace ready! Launch with:
  bitbot work vscode
```

### A5. Built-In Templates

**Python Templates**:
- `python-fastapi` - FastAPI web development
- `python-django` - Django full-stack
- `python-flask` - Flask lightweight
- `python-datascience` - Jupyter, pandas, numpy
- `python-ml` - Machine learning (PyTorch/TensorFlow)

**Node.js Templates**:
- `node-express` - Express backend
- `node-react` - React frontend
- `node-nextjs` - Next.js full-stack
- `node-typescript` - TypeScript Node.js

**Other Templates**:
- `go-web` - Go web development
- `rust-actix` - Rust web (Actix)
- `java-spring` - Spring Boot
- `dotnet-web` - ASP.NET Core
- `cpp-cmake` - C++ with CMake
- `ruby-rails` - Ruby on Rails

**Total**: 15-20 built-in templates covering 80% of common use cases

---

## Part B: Workspace State Management

### B1. Directory Structure (`.bitbot/`)

```
.bitbot/
├── metadata.json             # Workspace metadata
├── sessions/                 # Session tracking
│   ├── sess-20251017T1234.json
│   └── sess-20251017T1456.json
├── backups/                  # Git bundles
│   ├── 20251017T123400-main.bundle
│   └── 20251017T145600-feature.bundle
├── approvals.json            # Setup mode approvals
├── audit.log                 # Append-only action log
├── agent.yml                 # AI agent configuration (from wizard)
├── config.yml                # BitBot workspace config
├── docker-compose.work.yml   # Work mode compose
├── docker-compose.setup.yml  # Setup mode compose
├── state/                    # Runtime state
│   ├── workspace-hash        # Unique workspace identifier
│   └── mode.txt              # Current mode (work/setup)
└── mcp/                      # MCP service configs
    └── docker-compose.yml
```

**Security**: `.bitbot/` is NOT mounted into agent containers by default. Only exposed with explicit user confirmation.

### B2. Metadata Schema (`metadata.json`)

```json
{
  "workspace_hash": "a1b2c3d4",
  "created": "2025-10-17T12:00:00Z",
  "last_updated": "2025-10-17T12:34:00Z",
  "current_mode": "work",
  "container_name": "bitbot-dev-a1b2c3d4",
  "default_agent": "continue",
  "vscode_label": {
    "vsc.local.folder": "C:\\Projects\\MyProject",
    "devcontainer.local_folder": "C:\\Projects\\MyProject",
    "devcontainer.config_file": "C:\\Projects\\MyProject\\.devcontainer\\devcontainer.json"
  },
  "template": {
    "name": "python-fastapi",
    "version": "1.0.0",
    "initialized": "2025-10-17T12:00:00Z"
  },
  "git": {
    "remote": "git@github.com:user/repo.git",
    "branch": "main",
    "last_push": "2025-10-17T12:30:00Z"
  }
}
```

**Required fields**:
- `workspace_hash` - Unique 8-12 hex character identifier
- `created`, `last_updated` - ISO8601 timestamps
- `current_mode` - `work` or `setup`
- `container_name` - Last used container

**Optional fields**:
- `default_agent` - Default AI agent
- `vscode_label` - VS Code container labels (Windows paths for compatibility)
- `template` - Template source information
- `git` - Git repository metadata

### B3. Session Tracking (`sessions/*.json`)

```json
{
  "id": "sess-20251017T1234",
  "created": "2025-10-17T12:34:00Z",
  "last_accessed": "2025-10-17T12:45:00Z",
  "user": "alice",
  "container_id": "abcdef123456",
  "attached": true,
  "tmux_session": "work-main",
  "notes": "Working on API endpoint refactor",
  "ai_agent": "continue",
  "mode": "work"
}
```

**Purpose**:
- Track active and historical sessions
- Enable session reattachment
- Audit user activity
- Session persistence across container restarts

### B4. Backup Management (`backups/`)

**File naming**: `<timestamp>-<branch>.bundle`
Example: `20251017T123400-main.bundle`

**Backup policy**:
- Created on demand: `bitbot backup create`
- Created before risky operations (optional)
- Retention: Keep last 10 bundles (configurable)
- NOT mounted into agent containers

**CLI commands**:
```bash
# Create backup
bitbot backup create

# Create and push if remote exists
bitbot backup create --push-if-remote

# List backups
bitbot backup list

# Restore from backup
bitbot backup restore 20251017T123400-main.bundle
```

### B5. Approval Tracking (`approvals.json`)

```json
[
  {
    "ts": "2025-10-17T12:40:00Z",
    "user": "alice",
    "action": "allow-socket-mount",
    "reason": "Need to run Docker Compose stack for testing",
    "approved_by": "alice",
    "expires": null
  },
  {
    "ts": "2025-10-17T13:00:00Z",
    "user": "alice",
    "action": "modify-devcontainer",
    "reason": "Upgrade Python to 3.11",
    "approved_by": "alice",
    "expires": null
  }
]
```

**Purpose**:
- Audit trail for security-sensitive operations
- Setup mode permission tracking
- Compliance and review

### B6. Audit Log (`audit.log`)

```
2025-10-17T12:00:00Z alice workspace-init template=python-fastapi
2025-10-17T12:05:00Z alice mode-switch from=work to=setup reason=upgrade-python
2025-10-17T12:10:00Z alice container-start mode=setup container=bitbot-setup-a1b2c3d4
2025-10-17T12:15:00Z alice devcontainer-edit file=.devcontainer/Dockerfile
2025-10-17T12:20:00Z alice mode-switch from=setup to=work reason=upgrade-complete
2025-10-17T12:25:00Z alice agent-start agent=continue session=work-main
```

**Format**: Human-readable, append-only, timestamp-prefixed
**Purpose**: Historical record of all workspace actions

---

## C. Integration & Workflows

### C1. Initialization Workflow

```
User: bitbot init
  ↓
CLI Wizard (template selection)
  ↓
Template files copied to workspace
  ↓
.bitbot/ structure created
  ↓
metadata.json initialized
  ↓
Git repo initialized (if requested)
  ↓
Initial session created
  ↓
Audit log entry: workspace-init
  ↓
User: bitbot work vscode
  ↓
VS Code opens directly in container 
```

### C2. GitHub Codespaces Integration

**Overview**:

BitBot workspaces work in GitHub Codespaces in two scenarios:

1. **BitBot Development**: Open the BitBot repository itself in Codespaces to develop BitBot features
2. **User Projects**: After `bitbot init`, users can open their own projects in Codespaces with BitBot environment

**Use Case Flow**:
```
Developer on their project:
1. cd ~/Projects/MyApp
2. bitbot init                    # Creates .devcontainer/ with BitBot
3. git add .devcontainer/ && git commit && git push
4. Open MyApp repo in GitHub Codespaces
5. Codespaces builds devcontainer → Developer is inside BitBot workspace
6. BitBot scripts available at /usr/local/bitbot
7. Start coding!
```

**GitHub Remote Detection**:

When `bitbot init` detects a GitHub remote repository, it provides a Codespaces link:

```bash
$ bitbot init
...
✓ Workspace initialized successfully!

📦 DevContainer Configuration:
  Location: .devcontainer/
  Template: workspace (AI-powered development)

🌐 GitHub Codespaces:
  Remote detected: github.com/username/repo

  Open in Codespaces:
  https://codespaces.new/username/repo?quickstart=1

  Your BitBot workspace works in Codespaces!
  ✓ Container bitbot scripts fully functional at /usr/local/bitbot
  ✓ Same devcontainer configuration
  ✓ You're already inside the container - just start coding!

  💡 Tip: Add Codespaces badge to your README.md:
     [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/username/repo?quickstart=1)
```

**Detection Logic**:
```bash
# Check for GitHub remote
git remote -v | grep -q "github.com"

# Extract user/repo
REMOTE_URL=$(git config --get remote.origin.url)
# Parse: git@github.com:user/repo.git → user/repo
# Or:    https://github.com/user/repo.git → user/repo
```

**Codespaces URL Format**:
```
https://codespaces.new/{user}/{repo}?quickstart=1
```

**Template Configuration**:

User workspace templates should include `postAttachCommand` for better UX:

```json
{
  "postAttachCommand": ".devcontainer/bitbot/bitbot help || echo 'BitBot available at /usr/local/bitbot'"
}
```

**Why `postAttachCommand`?**
- Runs when editor attaches (not on every restart)
- Less intrusive than `postCreateCommand`
- Shows BitBot is available without running full tests
- User-friendly for shared workspaces

**Codespaces Limitations**:
- Docker-in-Docker not available in Codespaces (GitHub security policy)
- Only affects custom devcontainers that explicitly configured Docker-in-Docker
- BitBot standard workspace templates work perfectly in Codespaces
- Most development workflows don't need Docker-in-Docker

**See Also**:
- `sparc/0-research/GITHUB_CODESPACES_TESTING.md` for research
- `dev/tests/CODESPACES-TESTING.md` for testing guide
- `sparc/1-specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md` section 14

### C3. Session Lifecycle

**Session creation**:
```bash
bitbot work --session feature-x
# Creates sessions/sess-<timestamp>.json
# Audit log: session-create
```

**Session reattachment**:
```bash
bitbot work --attach feature-x
# Updates sessions/sess-<id>.json last_accessed
# Audit log: session-attach
```

**Session listing**:
```bash
bitbot session list

# Output:
# Active Sessions:
# ✅ work-main     (alice, 2h ago, container: bitbot-dev-a1b2c3d4)
# ✅ work-feature  (alice, 30m ago, container: bitbot-dev-a1b2c3d4)
#
# Historical Sessions:
# 🕒 work-bugfix   (alice, 2 days ago, ended)
```

### C4. Mode Switching with State

```bash
# Current: work mode
bitbot setup

# Workflow:
# 1. Update metadata.json: current_mode=setup
# 2. Stop work container
# 3. Start setup container
# 4. Create session in sessions/
# 5. Audit log: mode-switch from=work to=setup
# 6. User makes infrastructure changes
# 7. bitbot work (switch back)
# 8. Update metadata.json: current_mode=work
# 9. Audit log: mode-switch from=setup to=work
```

---

## D. CLI Commands

### D1. Template Management

```bash
# List templates
bitbot template list

# Show template details
bitbot template show python-fastapi

# Init from template
bitbot init --template python-fastapi

# Create custom template from current workspace
bitbot template create --name my-template

# Add remote template
bitbot template add gh:user/repo

# Update templates
bitbot template update
```

### D2. Metadata Management

```bash
# Show workspace metadata
bitbot metadata

# Show workspace hash
bitbot workspace hash

# Show current mode
bitbot mode

# Switch mode
bitbot setup
bitbot work
```

### D3. Session Management

```bash
# List sessions
bitbot session list

# Create new session
bitbot work --session feature-x

# Attach to session
bitbot work --attach feature-x

# End session
bitbot session end feature-x

# Clean old sessions
bitbot session clean --older-than 7d
```

### D4. Backup Management

```bash
# Create backup
bitbot backup create

# List backups
bitbot backup list

# Restore backup
bitbot backup restore 20251017T123400-main.bundle

# Clean old backups
bitbot backup clean --keep 10
```

### D5. Audit & Approval

```bash
# Show audit log
bitbot audit show

# Show approvals
bitbot approval list

# Request approval (interactive)
bitbot approval request --reason "Need socket mount for testing"
```

---

## E. Testing Strategy

### E1. Template Tests

- T-01: Template wizard completes successfully
- T-02: All built-in templates initialize correctly
- T-03: Custom template creation works
- T-04: Remote template download works
- T-05: Template validation catches errors

### E2. State Management Tests

- S-01: metadata.json created on init
- S-02: Session tracking works correctly
- S-03: Backup creation and restoration works
- S-04: Approval tracking records correctly
- S-05: Audit log is append-only
- S-06: State persists across container restarts

### E3. Integration Tests

- I-01: Template init → session start → VS Code launch
- I-02: Mode switching updates metadata
- I-03: Backup created before risky operations
- I-04: Approval required for setup mode actions

---

## F. Success Criteria

**Functional**:
- [ ] Template wizard generates valid workspaces
- [ ] All 15+ built-in templates work
- [ ] Custom templates can be created
- [ ] Metadata tracking accurate
- [ ] Session reattachment works
- [ ] Backups can be created and restored
- [ ] Approval workflow functional
- [ ] Audit log captures all actions

**Usability**:
- [ ] Template selection intuitive
- [ ] Wizard fast (<30 seconds)
- [ ] Clear feedback on all operations
- [ ] Session list easy to understand

**Reliability**:
- [ ] State persists across restarts
- [ ] No state corruption
- [ ] Audit log integrity maintained
- [ ] Cross-platform compatibility (Windows/Linux/macOS)

---

## G. Implementation Phases

**Phase 1: Template System Foundation**:
- [ ] Template structure definition
- [ ] Template metadata schema
- [ ] Built-in template library (5-10 initial templates)
- [ ] Template wizard CLI

**Phase 2: State Management MVP**:
- [ ] `.bitbot/` directory structure
- [ ] metadata.json implementation
- [ ] Session tracking
- [ ] Audit log (basic)

**Phase 3: Backup & Approval**:
- [ ] Git bundle backup system
- [ ] Approval tracking
- [ ] Backup retention policy
- [ ] Audit log (comprehensive)

**Phase 4: Advanced Features**:
- [ ] Remote template support
- [ ] Custom template creation
- [ ] Template marketplace
- [ ] Advanced session management

---

## H. References

**Related Specifications**:
- SPEC-01: Container Orchestration (container lifecycle)
- SPEC-02: Security Mode System (mode switching, approvals)
- SPEC-04: Session Management (tmux integration)
- SPEC-05: Cross-Platform CLI (CLI commands)
- SPEC-06: VS Code Integration (devcontainer configs)
- SPEC-07: AI Agent Integration (agent configs in templates)

**External Resources**:
- DevContainer Templates: https://containers.dev/templates
- GitHub Codespaces Templates: https://github.com/devcontainers
- AGENTS.md Standard: https://agents.md/

---

**Status**: **In Progress** (Template system design complete, state management MVP pending)
**Implementation Priority**: P2 (Template), P1 (State)
**Current Phase**: Phase 1 & 2 (Foundation)

**Consolidated From**:
- Claude_Specification/08_WORKSPACE_TEMPLATE_SYSTEM.md (template system, 2025 standards)
- Copilot_Specification/08-Workspace-State-and-Metadata.md (state management, metadata)
