# AI Agent Integration Framework Specification

**Feature ID**: SPEC-07
**Priority**: P1 (Important)
**Status**: In Progress (Updated with 2025 standards and VS Code Direct DevContainer Opening integration)
**Depends On**: SPEC-02 (Security Modes), SPEC-03 (MCP Services), SPEC-04 (Session Management), SPEC-06 (VS Code Integration)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

Framework for integrating AI coding agents (Claude Code, Continue.dev, Cline, OpenCode, others) into BitBot. Provides MCP service discovery, Git safety integration, session awareness, and mode-specific configurations.

**Key Design**: Agent-agnostic framework + AGENTS.md standard + MCP integration + Git safety + mode awareness + direct dev container opening = flexible AI assistant system.

**2025 Updates**:
- ✅ AGENTS.md universal standard support (industry-wide adoption since July 2025)
- ✅ VS Code native agent mode with MCP (April 2025)
- ✅ VS Code Direct DevContainer Opening integration 
- ✅ Continue.dev and Cline as open-source alternatives
- ✅ Claude Flow multi-agent orchestration

---

## 0. Industry Standards (2025)

### 0.1 AGENTS.md Universal Standard

**Status**: Emerging industry standard (announced July 2025)
**Adoption**: 20,000+ GitHub repositories
**Supported By**: OpenAI Codex, Google Jules, Cursor, Aider, RooCode, Zed, Claude Code, Continue.dev

**Location**: `AGENTS.md` (repository root)

**Purpose**:
- Single vendor-neutral location for AI agent instructions
- Machine-readable context complementing README.md
- Portable across multiple AI coding tools

**BitBot Integration**:
```markdown
# AGENTS.md (repository root)

## Project Setup
...project-specific instructions...

## BitBot Integration

You are operating in a BitBot workspace.

### Mode Detection
Check the current mode via environment:
- `BITBOT_MODE=work` - Normal development (can modify code, read-only .devcontainer)
- `BITBOT_MODE=setup` - Infrastructure mode (can modify .devcontainer)

### Available MCP Tools
Query: `curl http://mcp-discovery-workspace:8080/api/services`

Common tools:
- `git_status_check` - Check Git status
- `git_create_checkpoint` - Create rollback point
- `read_file`, `write_file` - Filesystem operations

### Git Safety Protocol
Before major changes:
1. Run `git_status_check`
2. If uncommitted changes, suggest checkpoint
3. Inform user of rollback option after changes

### Restrictions
- Work mode: Cannot modify .devcontainer/ or .bitbot/setup/
- Setup mode: Cannot see .bitbot/setup/ internals
```

### 0.2 Tool-Specific Configuration

**Hierarchy**: AGENTS.md (primary) + tool-specific files (advanced features)

**Claude Code**: `.claude/settings.json` + `CLAUDE.md`
**Continue.dev**: `.continuerc.json`
**Cline**: `.cline/config.json`
**VS Code Agent Mode**: `.vscode/agents.json`

---

## 1. Architecture

### 1.1 Supported Agents

**Tier 1: First-class support**:
- **Claude Code** (Anthropic) - Commercial, premium features
- **Continue.dev** - Open source, model-agnostic
- **Cline** - Open source, VS Code extension
- **VS Code Agent Mode** - Native VS Code, MCP support

**Tier 2: Community support**:
- **OpenCode** - Terminal-based, open source
- **Claude Flow** - Multi-agent orchestration
- **Custom agents** - User-provided with MCP support

**Agent capabilities**:
- MCP tool discovery and invocation
- Git safety awareness (via AGENTS.md + hooks)
- Session management
- Mode-specific behavior
- Workspace context
- VS Code Direct DevContainer Opening (Decision Direct DevContainer Opening integration)

### 1.2 Integration Layers

```
AI Agent
  ↓
MCP Discovery & Tools (SPEC-03)
  ↓
Git Safety Checks (SPEC-02A)
  ↓
Session Context (SPEC-04)
  ↓
Mode Awareness (Work/Setup)
  ↓
Workspace Files
```

---

## 2. Agent Configuration

### 2.1 Claude Code Integration

**File structure**:
```
.claude/
├── settings.json          # Team-shared (version controlled)
├── settings.local.json    # Personal (NOT version controlled, .gitignore)
├── agents/                # Custom subagents
└── commands/              # Slash commands

CLAUDE.md                  # Project context (can reference AGENTS.md)
```

**settings.json** (`.claude/settings.json`):
```json
{
  "mcpServers": {
    "git-safety": {
      "command": "docker",
      "args": ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"],
      "env": {
        "WORKSPACE_PATH": "${workspaceFolder}"
      }
    },
    "filesystem": {
      "command": "docker",
      "args": ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]
    }
  },

  "permissions": {
    "deny": [
      ".bitbot/setup/**",
      ".devcontainer/**"
    ]
  },

  "hooks": {
    "preTask": [
      {
        "name": "git_safety_check",
        "trigger": {
          "keywords": ["refactor", "implement", "change", "update"],
          "fileCountThreshold": 3
        },
        "action": "git_status_check"
      }
    ]
  },

  "context": {
    "bitbotMode": "${BITBOT_MODE}",
    "workspaceHash": "${WORKSPACE_HASH}"
  }
}
```

**CLAUDE.md**:
```markdown
# Project Context

See AGENTS.md for project-wide AI agent instructions.

## Claude Code Specific

### Available Slash Commands
- `/bitbot-mode` - Show current BitBot mode
- `/git-checkpoint` - Create Git checkpoint
- `/mcp-tools` - List available MCP tools

### BitBot Integration
This project uses BitBot for container orchestration.
Current mode: ${BITBOT_MODE}
```

### 2.2 Continue.dev Integration

**File structure**:
```
.continue/
├── config.json            # Continue.dev configuration
└── context/              # Context providers

AGENTS.md                  # Primary instructions (Continue.dev reads this)
```

**config.json** (`.continue/config.json`):
```json
{
  "models": [
    {
      "title": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "apiKey": "${ANTHROPIC_API_KEY}"
    }
  ],

  "mcpServers": [
    {
      "name": "git-safety",
      "command": "docker",
      "args": ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"]
    },
    {
      "name": "filesystem",
      "command": "docker",
      "args": ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]
    }
  ],

  "contextProviders": [
    {
      "name": "agents-md",
      "params": {
        "file": "AGENTS.md"
      }
    },
    {
      "name": "bitbot-mode",
      "params": {
        "env": "BITBOT_MODE"
      }
    }
  ],

  "slashCommands": [
    {
      "name": "bitbot-mode",
      "description": "Show current BitBot mode"
    },
    {
      "name": "git-checkpoint",
      "description": "Create Git checkpoint"
    }
  ]
}
```

### 2.3 Cline Integration

**File structure**:
```
.cline/
├── config.json            # Cline-specific configuration
└── prompts/              # Custom prompts

AGENTS.md                  # Primary instructions
```

**config.json** (`.cline/config.json`):
```json
{
  "apiProvider": "anthropic",
  "apiKey": "${ANTHROPIC_API_KEY}",
  "model": "claude-3-5-sonnet-20241022",

  "mcpServers": [
    {
      "name": "git-safety",
      "transport": "docker-exec",
      "container": "mcp-git-safety-${WORKSPACE_HASH}"
    }
  ],

  "contextFiles": [
    "AGENTS.md",
    ".bitbot/state/mode.txt"
  ],

  "customInstructions": "See AGENTS.md for project instructions. Check BITBOT_MODE environment variable for current mode.",

  "autoCheckGit": true,
  "suggestCheckpoint": true
}
```

### 2.4 VS Code Agent Mode Integration

**File structure**:
```
.vscode/
├── agents.json            # VS Code native agent configuration
└── settings.json          # Agent mode settings

AGENTS.md                  # Primary instructions
```

**agents.json** (`.vscode/agents.json`):
```json
{
  "agents": [
    {
      "id": "bitbot-work",
      "name": "BitBot Work Mode",
      "description": "AI assistant for normal development",
      "contextFiles": ["AGENTS.md"],
      "mcp": {
        "discoveryUrl": "http://mcp-discovery-workspace:8080/api/services"
      },
      "restrictions": {
        "readOnly": [".devcontainer/**", ".bitbot/setup/**"]
      }
    },
    {
      "id": "bitbot-setup",
      "name": "BitBot Setup Mode",
      "description": "AI assistant for infrastructure changes",
      "contextFiles": ["AGENTS.md"],
      "mcp": {
        "discoveryUrl": "http://mcp-discovery-workspace:8080/api/services"
      },
      "restrictions": {
        "hidden": [".bitbot/setup/**"]
      }
    }
  ]
}
```

### 2.5 OpenCode Integration (Tier 2)

**Config location**: `.opencode/config.json`

**Basic config**:
```json
{
  "mcp": {
    "discoveryUrl": "http://mcp-discovery-workspace:8080"
  },
  "contextFile": "AGENTS.md",
  "gitSafety": true
}
```

**See Also**: Research/AI_AGENT_RESEARCH.md for OpenCode details

---

## 3. MCP Service Discovery

### 3.1 Discovery Process

**Agent startup**:
```python
# Pseudocode
def agent_startup():
  workspace_hash = env("WORKSPACE_HASH")

  # Query workspace discovery
  services = http_get(f"http://mcp-discovery-workspace:8080/api/services?workspace={workspace_hash}")

  # Connect to each service
  for service in services:
    mcp_client.connect(service.endpoint)
    tools = mcp_client.list_tools()
    register_tools(tools)

  log(f"Discovered {len(services)} MCP services")
```

### 3.2 Tool Registration

**Available tools** (from MCP services):
- `read_file` (filesystem MCP)
- `write_file` (filesystem MCP)
- `git_status_check` (git-safety MCP)
- `git_create_checkpoint` (git-safety MCP)
- `git_diff_summary` (git-safety MCP)
- Custom tools from user services

**Tool invocation**:
```python
# Agent invokes tool
result = mcp_client.call_tool("read_file", {
  "path": "/workspace/src/main.py"
})

# Result returned to agent
# Agent processes and continues
```

---

## 4. Git Safety Integration

### 4.1 Agent System Prompts

**Work mode prompt addition**:
```markdown
## Git Safety Protocol

You are operating in BitBot work mode. Before making significant changes:

1. Check Git status using git_status_check tool
2. If uncommitted changes exist, create checkpoint using git_create_checkpoint
3. Inform user that rollback is available: git reset --hard <hash>

## When to Check Git

Check git status before:
- Refactoring multiple files (3+)
- Implementing new features
- Architectural changes
- Deleting files
- Renaming across codebase

## User Opt-Out

If user says "skip git check" or "no checkpoint", proceed without checking.
```

**Setup mode prompt addition**:
```markdown
## Setup Mode Context

You are in BitBot setup mode. You can modify:
- .devcontainer/ files
- Docker configuration
- Infrastructure code

You CANNOT modify:
- .bitbot/setup/ (BitBot internals)

After making infrastructure changes, recommend:
- bitbot-audit-setup (review changes)
- bitbot-apply-setup (apply and rebuild)
```

### 4.2 Git Safety Workflow

**Agent decision tree**:
```
User request
  ↓
Analyze task complexity
  ↓
If complex/risky:
  ↓
  git_status_check()
    ↓
  If uncommitted changes:
    ↓
    Prompt user: "Create checkpoint?"
      ↓
    If yes: git_create_checkpoint()
      ↓
    Make changes
      ↓
    Inform user of rollback option
  Else:
    ↓
    Make changes
Else (simple task):
  ↓
  Make changes directly
```

---

## 5. Session Awareness

### 5.1 Session Context

**Agent detects session**:
```bash
# Agent reads tmux environment
session_name=$(tmux display-message -p '#S')
# work-main, work-feature-x, etc.

# Extract mode from session name
mode=$(echo "$session_name" | cut -d'-' -f1)
# work or setup
```

**Agent capabilities in session**:
- Create new tmux windows
- Split panes for background tasks
- Run commands in background panes
- Respect session working directory

### 5.2 Multi-Pane Workflows

**Agent creates dev environment**:
```python
# Pseudocode
def setup_dev_environment():
  # Create new window for dev server
  tmux("new-window", "-n", "server")
  tmux("send-keys", "npm run dev", "C-m")

  # Split for logs
  tmux("split-window", "-v")
  tmux("send-keys", "tail -f logs/app.log", "C-m")

  # Return to main window
  tmux("select-window", "-t", "1")

  tell_user("Dev environment setup in window 'server'")
```

---

## 6. Mode-Specific Behavior

### 6.1 Work Mode Agent

**Capabilities**:
- Full workspace read/write
- .devcontainer/ read-only (can view, cannot modify)
- Can run application code
- Can modify source files
- Can run tests

**Restrictions**:
- Cannot modify .devcontainer/
- Cannot see .bitbot/setup/
- Cannot rebuild containers

**Example interaction**:
```
User: "Add a new API endpoint"
Agent:
  [git_status_check] → clean
  [Creates new file src/api/users.py]
  [Modifies src/api/routes.py]
  [Creates test file tests/test_users.py]
  "✓ Created new users API endpoint. Run tests with: pytest tests/test_users.py"
```

### 6.2 Setup Mode Agent

**Capabilities**:
- Full workspace read/write
- .devcontainer/ read/write
- Can modify infrastructure
- Can rebuild containers
- Docker socket access

**Restrictions**:
- Cannot see .bitbot/setup/
- Should be cautious with destructive changes

**Example interaction**:
```
User: "Add Python 3.11 to the devcontainer"
Agent:
  [Reads .devcontainer/Dockerfile]
  [Modifies FROM python:3.10 → FROM python:3.11]
  [Updates .devcontainer/devcontainer.json if needed]
  "✓ Updated to Python 3.11. Recommend running bitbot-audit-setup to review."
```

---

## 7. Agent Lifecycle

### 7.1 Agent Startup

**Initialization**:
```bash
# User starts agent
claude-code

# Agent startup sequence:
# 1. Detect environment
detect_bitbot_environment()
  → mode, workspace_hash, session_name

# 2. Connect to MCP services
discover_mcp_services()
  → Available tools loaded

# 3. Load configuration
load_agent_config()
  → .claude/config.yml or .opencode/config.json

# 4. Run startup hooks
run_startup_hooks()
  → Git safety check, etc.

# 5. Display welcome
show_welcome_message()
  → "Claude Code ready in BitBot work mode"
```

### 7.2 Agent Shutdown

**Cleanup**:
```bash
# Agent shutdown sequence:
# 1. Save session state
save_session_state()

# 2. Run shutdown hooks
run_shutdown_hooks()

# 3. Disconnect from MCP
disconnect_mcp_services()

# 4. Log session summary
log_session_summary()
```

---

## 8. Custom Agent Integration

### 8.1 Agent Requirements

**Minimum requirements for agent**:
- MCP protocol support (tools invocation)
- HTTP/WebSocket client (for MCP discovery)
- Bash/shell access (for tmux, git commands)
- Environment variable access

**Optional features**:
- Git safety awareness
- Session management
- Mode-specific behavior

### 8.2 Integration Template

**Custom agent wrapper** (`.bitbot/agents/my-agent.sh`):
```bash
#!/usr/bin/env bash

# BitBot integration for custom agent

# Detect environment
export BITBOT_MODE=$(tmux display-message -p '#S' | cut -d'-' -f1)
export WORKSPACE_HASH=$(cat .bitbot/state/workspace-hash)

# Discover MCP services
MCP_SERVICES=$(curl -s "http://mcp-discovery-workspace:8080/api/services?workspace=${WORKSPACE_HASH}")

# Set agent config
export MCP_SERVICES_JSON="$MCP_SERVICES"
export AGENT_CONFIG=".bitbot/agents/my-agent-config.json"

# Run agent
/path/to/my-agent --config "$AGENT_CONFIG"
```

---

## 9. Agent Commands

### 9.1 Launch Commands

**Claude Code**:
```bash
# CLI: Launch work mode in VS Code with Claude Code
bitbot work vscode --agent claude
# Uses VS Code Direct DevContainer Opening + launches Claude Code

# From inside container
claude-code
```

**Continue.dev**:
```bash
# CLI: Launch work mode in VS Code with Continue.dev
bitbot work vscode --agent continue
# Opens VS Code dev container, Continue.dev extension auto-activates

# From inside container (Continue.dev is VS Code extension)
# Already active in VS Code
```

**Cline**:
```bash
# CLI: Launch work mode in VS Code with Cline
bitbot work vscode --agent cline
# Opens VS Code dev container, Cline extension auto-activates

# From inside container (Cline is VS Code extension)
# Already active in VS Code
```

**VS Code Agent Mode**:
```bash
# CLI: Launch work mode in VS Code (native agent mode)
bitbot work vscode
# Native VS Code agent mode available via Command Palette

# From inside VS Code
# Ctrl+Shift+P → "Agent: Start Session"
```

**OpenCode** (Tier 2):
```bash
# From inside container (terminal-based)
opencode

# Or via CLI
bitbot work --agent opencode
```

**Custom agent**:
```bash
# From inside container
.bitbot/agents/my-agent.sh

# Or via CLI
bitbot work --agent custom:my-agent
```

### 9.2 Agent Management

**List available agents**:
```bash
bitbot agent list

# Output:
# Tier 1: First-class support
# ✅ claude        - Claude Code by Anthropic (CLI + VS Code)
# ✅ continue      - Continue.dev (VS Code extension, open source)
# ✅ cline         - Cline (VS Code extension, open source)
# ✅ vscode        - VS Code native agent mode (April 2025+)
#
# Tier 2: Community support
# ⏳ opencode      - OpenCode (terminal-based, open source)
# ⏳ claude-flow   - Claude Flow (multi-agent orchestration)
#
# Custom:
# 📦 custom:my-agent (.bitbot/agents/my-agent.sh)
```

**Configure agent**:
```bash
bitbot agent config claude
# Opens .claude/config.yml in editor

bitbot agent config open
# Opens .opencode/config.json in editor
```

---

## 10. Testing Strategy

### 10.1 Integration Tests

- AI-01: Agent discovers MCP services on startup
- AI-02: Agent invokes git_status_check before major changes
- AI-03: Agent creates checkpoint when uncommitted changes
- AI-04: Agent respects work mode restrictions (.devcontainer read-only)
- AI-05: Agent can modify .devcontainer in setup mode
- AI-06: Agent creates tmux panes/windows correctly

### 10.2 Agent-Specific Tests

**Claude Code**:
- CC-01: .claude/config.yml loaded correctly
- CC-02: Pre-task hooks execute
- CC-03: MCP tools available

**OpenCode**:
- OC-01: .opencode/config.json loaded
- OC-02: Git safety integration works
- OC-03: Mode awareness functions

---

## 11. Success Criteria

**Functional**:
- [ ] Claude Code discovers and uses MCP services
- [ ] OpenCode integration works
- [ ] Git safety prompts before risky changes
- [ ] Agents respect mode restrictions
- [ ] Session awareness functional
- [ ] Custom agents can be integrated

**Usability**:
- [ ] Easy agent launch (single command)
- [ ] Clear mode indication to agent
- [ ] Helpful prompts for Git safety
- [ ] Agent behavior intuitive

**Reliability**:
- [ ] MCP service discovery always works
- [ ] Git safety checks reliable
- [ ] No conflicts between agents and CLI
- [ ] Session state persists across agent restarts

---

## 12. Implementation Phases

**Phase 1: MCP Integration**:
- MCP service discovery on agent startup
- Tool registration and invocation
- Agent config file support

**Phase 2: Git Safety**:
- System prompt additions
- git_status_check integration
- Checkpoint creation workflow
- User prompts

**Phase 3: Session & Mode Awareness**:
- Session detection
- Mode-specific prompts
- Restriction enforcement
- tmux integration

**Phase 4: Agent Ecosystem**:
- Claude Code full integration
- OpenCode support
- Custom agent template
- Agent management commands

---

## 13. References

**Related Specifications**:
- SPEC-02: Security Mode System (mode restrictions)
- SPEC-02A: Git Safety Integration (git tools)
- SPEC-03: MCP Service Architecture (service discovery)
- SPEC-04: Session Management (tmux integration)

**External Resources**:
- MCP Specification: https://modelcontextprotocol.io/
- Claude Code: https://www.anthropic.com/claude/code
- OpenCode: https://github.com/opencode-ai

**Research Sources**:
- User requirement: AI agent integration
- Git safety as replacement for sketch mode

---

**Status**: **In Progress** (Updated with 2025 standards)
**Implementation Priority**: P1 (Important for AI workflows)

**Recent Updates (2025-10-20)**:
- ✅ Added AGENTS.md universal standard (Section 0.1)
- ✅ Updated Claude Code configuration to current structure
- ✅ Added Continue.dev integration (Section 2.2)
- ✅ Added Cline integration (Section 2.3)
- ✅ Added VS Code Agent Mode support (Section 2.4)
- ✅ Updated agent tiers (Tier 1: First-class, Tier 2: Community)
- ✅ Integrated VS Code Direct DevContainer Opening 
- ✅ Updated launch commands for all agents

**Implementation Phases Updated**:

**Phase 0: Standards & Configuration** ✅ **DOCUMENTED**:
- [x] AGENTS.md standard integration
- [x] Tool-specific configuration files
- [x] Agent tier structure
- [x] VS Code Direct DevContainer Opening integration points 

**Phase 1: MCP Integration**:
- [ ] MCP service discovery on agent startup
- [ ] Tool registration and invocation
- [ ] Agent config file support (Claude Code, Continue.dev, Cline)

**Phase 2: Git Safety**:
- [ ] System prompt additions via AGENTS.md
- [ ] git_status_check integration
- [ ] Checkpoint creation workflow
- [ ] User prompts

**Phase 3: Session & Mode Awareness**:
- [ ] Session detection
- [ ] Mode-specific prompts (work/setup)
- [ ] Restriction enforcement
- [ ] tmux integration

**Phase 4: Agent Ecosystem**:
- [ ] Claude Code full integration
- [ ] Continue.dev full support
- [ ] Cline full support
- [ ] VS Code Agent Mode integration
- [ ] OpenCode support (Tier 2)
- [ ] Custom agent template
- [ ] Agent management commands

**Phase 5: Advanced Features** (Future):
- [ ] Claude Flow multi-agent orchestration
- [ ] Agent collaboration workflows
- [ ] Cross-agent session sharing

**Next Specifications**: SPEC-08 (Workspace Template System)

**Related Decisions**: Direct DevContainer Opening (VS Code Direct DevContainer Opening)

**See Also**:
- Research/AI_AGENT_CONFIGURATION_STANDARDS.md - 2025 agent configuration standards
- Research/AI_AGENT_RESEARCH.md - Claude Flow and OpenCode details
- SPEC-06 Section 0 - Direct dev container opening integration
