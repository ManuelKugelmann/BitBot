# AI Agent Integration Framework Specification

**Feature ID**: SPEC-07
**Priority**: P1 (Important)
**Status**: Draft
**Depends On**: SPEC-02 (Security Modes), SPEC-03 (MCP Services), SPEC-04 (Session Management)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

Framework for integrating AI coding agents (Claude Code, OpenCode, others) into BitBot. Provides MCP service discovery, Git safety integration, session awareness, and mode-specific configurations.

**Key Design**: Agent-agnostic framework + MCP integration + Git safety + mode awareness = flexible AI assistant system.

---

## 1. Architecture

### 1.1 Supported Agents

**Primary agents**:
- Claude Code (Anthropic)
- OpenCode (open-source alternative)
- Custom agents (user-provided)

**Agent capabilities**:
- MCP tool discovery and invocation
- Git safety awareness
- Session management
- Mode-specific behavior
- Workspace context

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

**Config location**: `.claude/config.yml`

```yaml
# Claude Code configuration for BitBot

# MCP servers
mcpServers:
  git-safety:
    command: docker
    args: ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"]
    env:
      WORKSPACE_PATH: "${workspaceFolder}"

  filesystem:
    command: docker
    args: ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]

  workspace-discovery:
    command: curl
    args: ["http://mcp-discovery-workspace:8080/api/services"]

# Pre-task hooks
pre_task_hooks:
  - name: git_safety_check
    description: Check Git status before major changes
    trigger:
      keywords: ["refactor", "implement", "change", "update"]
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

# Agent behavior
agent:
  mode_aware: true
  git_safety_enabled: true
  session_aware: true

# Workspace context
workspace:
  bitbot_mode: "${BITBOT_MODE}"  # work or setup
  workspace_hash: "${WORKSPACE_HASH}"
```

### 2.2 OpenCode Integration

**Config location**: `.opencode/config.json`

```json
{
  "mcp": {
    "discovery_url": "http://mcp-discovery-workspace:8080",
    "services": [
      {
        "name": "git-safety",
        "container": "mcp-git-safety-${WORKSPACE_HASH}"
      },
      {
        "name": "filesystem",
        "container": "mcp-filesystem-${WORKSPACE_HASH}"
      }
    ]
  },

  "git_safety": {
    "enabled": true,
    "auto_check": true,
    "checkpoint_prompt": true
  },

  "pre_task_commands": [
    {
      "name": "git_status",
      "tool": "git_status_check",
      "condition": "task_complexity > medium"
    }
  ],

  "agent_behavior": {
    "mode_aware": true,
    "session_management": true
  }
}
```

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
# From inside container
claude-code

# Or via CLI (launches container and agent)
bitbot work --agent claude
```

**OpenCode**:
```bash
# From inside container
opencode

# Or via CLI
bitbot work --agent open
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
# Available agents:
# - claude (Claude Code by Anthropic)
# - open (OpenCode)
# - custom:my-agent (.bitbot/agents/my-agent.sh)
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

**Status**: **Draft**
**Implementation Priority**: P1 (Important for AI workflows)
**Next Steps**: SPEC-08 (Workspace Template System)
