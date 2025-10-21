# AI Coding Agent Configuration Standards Research

**Date:** October 2025
**Purpose:** Survey of unified AI coding and CLI agent settings across major tools

## Executive Summary

The AI coding assistant landscape is consolidating around **AGENTS.md** as an emerging universal standard (announced July 2025 by OpenAI, Sourcegraph, and Google). However, most tools still maintain their own proprietary configuration formats alongside support for the emerging standard.

**Key Finding:** Use AGENTS.md as the primary configuration file and maintain tool-specific files (.claude, .github/copilot-instructions.md, etc.) for advanced features.

**New Developments:**
- **VS Code Open Source Initiative:** Microsoft open-sourced GitHub Copilot Chat extension (June 2025)
- **Native Agent Mode:** VS Code now includes built-in agentic capabilities with MCP support (April 2025)
- **Open Source Extensions:** Continue.dev and Cline lead the free, model-agnostic agentic coding space
- **Multi-Agent Orchestration:** Claude Flow enables coordinating multiple AI agents for complex workflows

---

## Universal Standards

### AGENTS.md (Universal Standard - 2025)

**Status:** Emerging industry standard
**Adoption:** 20,000+ GitHub repositories (as of August 2025)
**Location:** `AGENTS.md` (repository root)
**Supported By:** OpenAI Codex, Google Jules, Cursor, Aider, RooCode, Zed, and growing

#### Purpose
- Consolidates AI agent instructions into a single vendor-neutral location
- Provides machine-readable context complementing human-facing README.md
- Replaces fragmented tool-specific configuration files

#### Key Features
- **Portable:** Works across multiple AI coding tools
- **Hierarchical:** Supports nested files for monorepo package-level instructions
- **Natural Language:** Written in Markdown with no proprietary syntax
- **Predictable:** Single standard location for all AI agents

#### Typical Content
- Setup commands and dependencies
- Testing workflows and validation
- Coding style preferences
- Pull request guidelines
- Architecture decisions
- Build and deployment processes

#### Migration Strategy
For tools not yet supporting AGENTS.md, create tool-specific files that reference it:
```markdown
<!-- CLAUDE.md -->
See ./AGENTS.md for project instructions
```

---

## Tool-Specific Configuration Standards

### 1. Claude Code

**Vendor:** Anthropic
**Configuration Hierarchy:** Global → Project → Local

#### File Structure
```
~/.claude/                          # User-level (global)
  ├── settings.json                 # Global settings
  └── agents/                       # User-defined subagents

<project>/.claude/                  # Project-level
  ├── settings.json                 # Team-shared settings (version controlled)
  ├── settings.local.json           # Personal settings (not version controlled)
  ├── agents/                       # Project-specific subagents
  └── commands/                     # Slash commands

<project>/CLAUDE.md                 # Context file (can be nested in subdirectories)
```

#### Key Configuration Files

##### CLAUDE.md
- **Purpose:** Project instructions and context loaded automatically
- **Location:** Repository root or subdirectories
- **Behavior:** Merges upward in directory tree (subdirectory files layer on parent files)
- **Format:** Markdown, natural language
- **Best Practice:** Can reference AGENTS.md for compatibility

##### .claude/settings.json
- **Scope:** Project-wide, version controlled
- **Content:**
  - Permission rules (`permissions.deny`)
  - Environment variables
  - Tool access controls
  - Custom subagent paths

##### .claude/settings.local.json
- **Scope:** Developer-specific, NOT version controlled
- **Content:** Personal preferences and experimental settings
- **Best Practice:** Add to `.gitignore`

##### .claude/agents/*.md
- **Purpose:** Custom AI subagents with specialized capabilities
- **Format:** Markdown with YAML frontmatter
- **Example Structure:**
  ```yaml
  ---
  name: test-runner
  description: Specialized agent for running and fixing tests
  ---
  # Agent instructions here
  ```

#### Configuration Access
- Interactive: `/config` command in REPL
- File-based: Edit JSON files directly

#### Key Settings
- `permissions.deny` - Block file access patterns
- Environment variables
- Custom subagent definitions
- Tool permissions

---

### 2. Cursor AI

**Vendor:** Cursor
**Primary IDE:** VS Code fork

#### File Structure (Modern - Recommended)
```
.cursor/
  ├── index.mdc                     # Main configuration (Rule Type: "Always")
  └── rules/
      ├── coding-standards.mdc
      ├── framework-specific.mdc
      └── testing.mdc
```

#### File Structure (Legacy - Still Supported)
```
.cursorrules                        # Root-level config file
```

#### File Formats

##### .cursor/rules/*.mdc (Recommended)
- **Format:** MDC (Markdown Components)
- **Purpose:** Modular, per-rule configuration
- **Scope:** Project-level
- **Best Practice:** One rule per file for organization

##### .cursorrules (Legacy)
- **Format:** Plain text / Markdown
- **Purpose:** Single-file project configuration
- **Scope:** Project-level
- **Status:** Backward compatible, not recommended for new projects

##### Global Rules
- **Location:** Cursor Settings → General → Rules for AI
- **Scope:** All projects
- **Use Case:** Coding standards and preferences applicable everywhere

#### Best Practices
- Global rules: Universal coding standards
- Project rules: Framework-specific conventions
- Keep rules concise to avoid overwhelming context
- Prefer `.cursor/rules/` structure over legacy `.cursorrules`

---

### 3. GitHub Copilot

**Vendor:** Microsoft/GitHub
**Integration:** GitHub ecosystem

#### File Structure
```
.github/
  ├── copilot-instructions.md       # Primary configuration
  └── instructions/                 # Advanced: Directory-specific configs
      ├── backend.md
      ├── frontend.md
      └── infra.md
```

#### Primary Configuration

##### .github/copilot-instructions.md
- **Purpose:** Repository-wide Copilot instructions
- **Format:** Markdown with natural language
- **Content:**
  - Build and test instructions
  - Coding standards
  - Project context
  - Validation procedures

#### Advanced Configuration

##### .github/instructions/*.md
- **Purpose:** Directory or file-specific instructions
- **Format:** Markdown with YAML frontmatter
- **Frontmatter Spec:**
  ```yaml
  ---
  applies-to:
    - path: "src/backend/**"
    - path: "*.py"
  ---
  ```
- **Behavior:** Different instructions for different codebase areas

#### IDE-Specific

##### JetBrains IDEs
- **Project File:** `.github/copilot-instructions.md`
- **Global File:** `global-copilot-instructions.md` (local storage)

#### Key Features
- Natural language instructions
- Markdown formatting for readability
- Directory-scoped configurations
- Integration with GitHub workflow

---

### 4. Aider

**Vendor:** Aider-AI (Open Source)
**Interface:** Terminal-based

#### File Structure
```
<project>/
  ├── .aider.conf.yml               # Project configuration
  ├── CONVENTIONS.md                # Coding conventions (recommended name)
  └── .env                          # API keys and environment variables
```

#### Configuration Files

##### .aider.conf.yml
- **Purpose:** Command-line defaults and settings
- **Format:** YAML
- **Location:** Repository root or home directory (`~/.aider.conf.yml`)
- **Content:**
  ```yaml
  # Example configuration
  read:
    - CONVENTIONS.md
  auto-commits: true
  model: gpt-4
  ```

##### CONVENTIONS.md
- **Purpose:** Coding standards and style guide
- **Format:** Markdown, natural language
- **Usage:** Load with `/read CONVENTIONS.md` or configure auto-load in YAML
- **Best Practice:** Define in `.aider.conf.yml` for automatic loading

##### .env
- **Purpose:** API keys and sensitive configuration
- **Format:** Environment variable key-value pairs
- **Security:** Never commit to version control

#### Configuration Methods
1. Command-line arguments
2. YAML config file (`.aider.conf.yml`)
3. Environment variables (shell or `.env`)

#### Key Settings
- Model selection
- Auto-commit behavior
- File watch patterns
- Convention file references

---

### 5. Windsurf (Codeium)

**Vendor:** Codeium
**Product:** First "agentic IDE"

#### File Structure
```
.windsurf/
  └── rules/                        # Custom rules files
      ├── always-on-rule.md
      ├── mention-rule.md
      └── glob-pattern-rule.md

~/.codeium/
  └── .codeiumignore                # Enterprise: Global ignore patterns
```

#### Configuration Files

##### .windsurf/rules/*.md
- **Purpose:** Granular AI behavior rules
- **Activation Types:**
  - Always-on rules
  - @mention-able rules
  - Requested by Cascade (AI agent)
  - Attached to file globs (pattern-based)
- **Format:** Markdown
- **Scope:** Workspace-level

##### .codeiumignore
- **Purpose:** Enterprise-wide file/folder exclusions
- **Location:** `~/.codeium/` (global)
- **Scope:** All repositories (enforced)
- **Use Case:** Security, compliance, sensitive files

#### Configuration Access
- **Quick Settings:** Bottom-right "Windsurf - Settings" button
- **Advanced Settings:** Profile dropdown → "Windsurf Settings"
- **Custom API Keys:** Bring your own Anthropic/OpenAI keys

#### Key Features
- **Model Selection:** Configure Claude, GPT, and other providers
- **Memory:** AI remembers custom rules and learned patterns
- **Cascade Settings:** Access to .gitignore, preview controls
- **Rule Flexibility:** Granular control over when rules apply

---

### 6. VS Code Agentic Extensions

**Vendor:** Open Source Community
**Platform:** VS Code / VSCodium
**Status:** Microsoft announced open-sourcing GitHub Copilot Chat extension (June 2025)

#### Overview

VS Code has become a platform for multiple agentic AI extensions. The six most-installed agentic AI tools include: Cline, BLACKBOXAI Agent, Continue, Codex, Roo Code, and Qodo Gen.

**Key Development:** VS Code now includes native Agent Mode (April 2025) supporting Model Context Protocol (MCP), enabling extensions to create autonomous coding agents.

#### Popular Agentic Extensions

##### Continue.dev (Open Source, Recommended)

**Status:** Open source, model-agnostic
**Configuration Location:** VS Code settings + `~/.continue/config.json`

**File Structure:**
```
~/.continue/
  └── config.json                   # Main configuration file
```

**Configuration:**
```json
{
  "models": [
    {
      "title": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "apiKey": "YOUR_API_KEY"
    }
  ],
  "tabAutocompleteModel": {
    "provider": "openai",
    "model": "gpt-4",
    "apiKey": "YOUR_API_KEY"
  },
  "contextProviders": [
    { "name": "code" },
    { "name": "terminal" },
    { "name": "diff" }
  ]
}
```

**Key Features:**
- **Model Agnostic:** OpenAI, Anthropic, local models via Ollama
- **Tool Policies:** Configure automatic vs. permission-based tool usage
- **Agent Mode:** Switch from chat to autonomous agent mode
- **Open Source:** No vendor lock-in, pay only for API calls
- **MCP Integration:** Access to community MCP tools

**Setup:**
1. Install from VS Code Extensions marketplace
2. Open Continue tab, click gear icon → Open Config
3. Configure API keys and model preferences
4. Optionally create tool policies for automation

##### Cline (formerly Claude Dev)

**Status:** Open source, frontier model access
**Configuration:** In-extension settings + workspace configuration

**Key Features:**
- **Plan Mode:** Review multi-step plans before execution
- **MCP Integration:** Create custom tools via Model Context Protocol
- **Zero Vendor Lock-in:** Switch between Claude, Gemini, DeepSeek, GPT
- **Complete Transparency:** Open source, see exactly what it does
- **Free Extension:** Pay only for AI model API usage

**Workspace Configuration:**
Cline doesn't use traditional config files but stores settings in VS Code workspace settings:
```json
{
  "cline.apiProvider": "anthropic",
  "cline.apiKey": "YOUR_API_KEY",
  "cline.model": "claude-3-5-sonnet-20241022"
}
```

**Setup:**
1. Install from VS Code Extensions (search "Cline")
2. Click robot icon in Activity Bar to activate
3. Select "Use your own API key" option
4. Connect preferred model provider

##### Roo Code

**Status:** Commercial + Free tier
**Type:** Autonomous coding agent in VS Code

**Key Features:**
- "Whole dev team of AI agents in your editor"
- Multi-agent collaboration for different coding tasks
- Integration with various AI model providers

**Configuration:** Similar to Cline, uses VS Code settings for API configuration

#### VS Code Agent Mode (Native)

**Introduced:** April 2025
**Status:** Available to all VS Code users

**Features:**
- **Autonomous Pair Programmer:** Multi-step coding tasks
- **Codebase Analysis:** Understanding project structure
- **File Edits:** Proposes and applies changes
- **Terminal Commands:** Executes build, test, deploy operations
- **MCP Support:** Standardized context protocol (inspired by LSP)

**Configuration:**
Agent mode is configured through VS Code settings and the MCP configuration system:

```json
{
  "chat.agent.mode": "enabled",
  "chat.agent.mcpServers": {
    "custom-server": {
      "command": "node",
      "args": ["/path/to/mcp-server.js"]
    }
  }
}
```

**MCP Tools:**
- Run locally or as remote services
- Configured via JSON or programmatically by extensions
- Standard protocol for providing context to LLMs

---

### 7. VSCodium + Agentic Extensions

**Vendor:** Community (VS Code without Microsoft telemetry)
**Key Difference:** Uses Open VSX Registry instead of VS Code Marketplace

#### Compatibility

**Extension Availability:**
- Not all VS Code extensions available directly
- Popular agentic extensions (Continue, Cline) can be installed
- Manual .vsix installation supported

#### Installation Process

**Method 1: Open VSX Registry**
1. Open Extensions panel in VSCodium
2. Search for "Continue" or "Cline"
3. Install if available

**Method 2: Manual .vsix Installation**
1. Download .vsix file from VS Code Marketplace or GitHub releases
2. Navigate to Extensions tab → three dots menu
3. Click "Install from VSIX"

#### Configuration

**Same as VS Code:** Once installed, Continue and Cline use identical configuration:
- `~/.continue/config.json` for Continue
- VSCodium settings for Cline

#### Limitations

- GitHub Copilot's "Set up Copilot for free" doesn't work
- Must use alternative extensions (Continue, Cline)
- Some proprietary extensions unavailable

#### Recommended Setup

1. **Install VSCodium** for privacy-respecting development
2. **Choose Extension:**
   - **Continue** for maximum flexibility and model choice
   - **Cline** for Claude-optimized workflow with MCP
3. **Configure API Keys** from preferred provider (OpenAI, Anthropic, local Ollama)
4. **Optional:** Install local LLMs via Ollama for offline coding assistance

---

### 8. Claude Flow

**Type:** Agent orchestration platform for Claude Code
**Status:** Advanced multi-agent system
**GitHub:** https://github.com/ruvnet/claude-flow

#### Overview

Claude Flow is an orchestration platform that extends Claude Code's capabilities by coordinating multiple Claude AI assistants to work simultaneously on different project tasks. It transforms single-agent coding into multi-agent collaboration.

**Ranking:** #1 in agent-based frameworks for Claude

#### Architecture

**Multi-Agent System:**
- Deploy up to 10 concurrent AI agents
- Specialized agents for different tasks:
  - Research agents
  - Coding agents
  - Testing agents
  - Deployment agents
- Distributed swarm intelligence

#### Configuration Files

##### Project Structure
```
<project>/
  ├── .claude-flow/                 # Claude Flow configuration
  │   ├── config.yml               # Orchestration settings
  │   ├── agents/                  # Agent definitions
  │   └── workflows/               # Multi-agent workflows
  ├── CLAUDE.md                    # Claude Code instructions
  └── AGENTS.md                    # Universal AI instructions
```

##### .claude-flow/config.yml
```yaml
# Example Claude Flow configuration
sparc_mode: true                   # SPARC development environment
max_concurrent_agents: 5
agents:
  - name: researcher
    role: research
    model: claude-3-5-sonnet-20241022
  - name: coder
    role: implementation
    model: claude-3-5-sonnet-20241022
  - name: tester
    role: testing
    model: claude-3-opus-20240229

workflows:
  feature_development:
    - researcher → design
    - coder → implementation
    - tester → validation
```

#### Installation & Setup

**Prerequisites:**
```bash
# Install Claude Code (official from Anthropic)
npm install -g @anthropic/claude-code

# Install Claude Flow
npm install -g claude-flow@alpha
```

**Initialize Project:**
```bash
# Navigate to project
cd /path/to/project

# Initialize Claude Flow with SPARC environment
claude-flow init --sparc
```

**MCP Server Setup:**
```bash
# Add Claude Flow MCP server
claude mcp add claude-flow

# Start MCP server
npx claude-flow@alpha mcp start
```

#### Key Features

**Enterprise-Grade Architecture:**
- Distributed swarm intelligence
- Multi-agent coordination
- Autonomous workflow execution

**RAG Integration:**
- Retrieval-Augmented Generation support
- Context sharing between agents
- Centralized knowledge base

**MCP Protocol Support:**
- Native Model Context Protocol integration
- Standardized agent communication
- Tool and context sharing

**Conversational AI Systems:**
- Natural language task delegation
- Agent-to-agent communication
- Human oversight and intervention points

#### Workflow Example

```yaml
# .claude-flow/workflows/api-development.yml
name: API Development Workflow
trigger: manual
agents:
  - architect: Design API schema
  - backend_dev: Implement endpoints
  - security_reviewer: Audit for vulnerabilities
  - tester: Create and run integration tests
  - documenter: Generate API documentation

sequence:
  1. architect → creates schema
  2. backend_dev → implements (parallel with security_reviewer)
  3. security_reviewer → reviews code
  4. tester → validates functionality
  5. documenter → creates docs
```

#### Integration with Claude Code

Claude Flow **extends** Claude Code, not replaces it:

1. **Claude Code:** Single-agent development, direct file editing
2. **Claude Flow:** Multi-agent orchestration, complex workflows

**Combined Usage:**
```bash
# Use Claude Code for direct development
claude code

# Use Claude Flow for complex multi-step features
claude-flow run workflow feature-name
```

#### Configuration Strategy

**CLAUDE.md Integration:**
```markdown
# CLAUDE.md
See AGENTS.md for general project instructions.

## Claude Flow Configuration
This project uses Claude Flow for multi-agent orchestration.

### Workflows Available:
- `feature-development`: Full feature implementation pipeline
- `bug-fix`: Automated bug triage and resolution
- `refactor`: Code quality improvement workflow

### Agent Roles:
See `.claude-flow/agents/` for specialized agent definitions.
```

#### Best Practices

1. **Agent Specialization:** Define clear roles for each agent
2. **Workflow Documentation:** Document multi-agent workflows in CLAUDE.md
3. **Human Oversight:** Set intervention points for critical decisions
4. **Cost Management:** Monitor API usage across multiple agents
5. **Version Control:** Commit `.claude-flow/` configuration to repository

---

## AI Agent Execution in Devcontainers

**Critical Consideration for Container-Based Development**

When using AI coding assistants with devcontainers, understanding where agents execute (host vs. container) is essential for proper file access, tooling, and security.

### VS Code Extension Architecture

VS Code uses an "inside/outside" architecture for extensions in remote environments (devcontainers, SSH, Codespaces):

#### Extension Types

**1. UI Extensions (Execute OUTSIDE Container)**

- **Location:** Run on local machine
- **Purpose:** User interface contributions
- **Access:** Local files only
- **Cannot:**
  - Access files in remote workspace
  - Run scripts/tools installed in container
  - Execute container commands

**Examples:**
- Themes
- Snippets
- Language grammars
- Keymaps

**2. Workspace Extensions (Execute INSIDE Container)**

- **Location:** Run where workspace is located
- **Purpose:** Workspace manipulation and tooling
- **Access:** Full workspace files and container environment
- **Can:**
  - Access all files in workspace
  - Invoke container scripts/tools
  - Provide language services using container dependencies
  - Execute debuggers and build tools

**Examples:**
- Language servers
- Debuggers
- Linters
- AI coding agents (GitHub Copilot, Cline, Continue.dev)

### AI Agent Execution Behavior

#### GitHub Copilot Chat Agent

**Default Execution:** INSIDE devcontainer (as Workspace Extension)

**Configuration Required:**
```json
// devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "GitHub.copilot",
        "GitHub.copilot-chat"
      ]
    }
  }
}
```

**Settings Configuration:**
```json
// settings.json
{
  "chat.agent.enabled": true,
  "chat.mcp.discovery.enabled": true,
  "github.copilot.chat.agent.autoFix": true,
  "github.copilot.chat.agent.runTasks": true
}
```

**Known Issues:**
- Bug reported where agent mode accessed **host filesystem** instead of **container filesystem**
- Issue tracked: Agent created files on host even when devcontainer was active
- Workaround: Explicitly verify file operations target container paths

#### GitHub Copilot Coding Agent (Cloud-Based)

**Execution:** OUTSIDE local environment entirely

- Runs in **GitHub Actions environment** (cloud)
- Temporary isolated dev environment
- Not on local machine or devcontainer
- Can explore codebase, make changes, build, test

**Use Cases:**
- Background feature implementation
- Automated pull request creation
- Independent from local development environment

#### Continue.dev & Cline

**Execution:** INSIDE devcontainer (as Workspace Extensions)

**Installation:**
- Must be listed in `devcontainer.json` extensions
- Configuration files accessible from container

**Example Configuration:**
```json
// devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "Continue.continue",
        "saoudrizwan.claude-dev"
      ]
    }
  }
}
```

### MCP Server Execution Locations

MCP servers have **flexible execution options**:

#### Option 1: Host Machine (Local)
```json
// mcp.json (on host)
{
  "mcpServers": {
    "host-server": {
      "command": "node",
      "args": ["/host/path/to/server.js"]
    }
  }
}
```

**Pros:**
- Survives container rebuilds
- Access to host resources
- Single configuration

**Cons:**
- Cannot access container-specific tools
- Different environment than workspace

#### Option 2: Inside Devcontainer
```json
// .vscode/mcp.json (in workspace)
{
  "mcpServers": {
    "container-server": {
      "command": "node",
      "args": ["/workspace/mcp/server.js"]
    }
  }
}
```

**Pros:**
- Access to container environment
- Uses container-installed dependencies
- Same environment as code

**Cons:**
- Lost on container rebuild (unless in Dockerfile)
- Requires installation in container

#### Option 3: Separate Docker Container
```json
{
  "mcpServers": {
    "docker-mcp": {
      "command": "docker",
      "args": ["run", "--rm", "mcp-server-image"]
    }
  }
}
```

**Pros:**
- Isolated from both host and devcontainer
- Consistent environment
- Easy distribution

**Cons:**
- Network communication overhead
- Docker-in-Docker complexity

#### Option 4: Remote SSE Server
```json
{
  "mcpServers": {
    "remote-mcp": {
      "url": "https://mcp-server.example.com/sse",
      "transport": "sse"
    }
  }
}
```

**Pros:**
- Centralized service
- No local installation
- Shared across team

**Cons:**
- Network dependency
- Security considerations
- Latency

### MCP Discovery Across Environments

VS Code can **auto-discover** MCP servers configured in other tools:

```json
// settings.json
{
  "chat.mcp.discovery.enabled": true  // Detects Claude Desktop MCP configs
}
```

**Discovered Locations:**
- Claude Desktop: `~/Library/Application Support/Claude/`
- Custom: `.vscode/mcp.json`
- Native: `mcp.json` in project root

### Implications for BitBot

As BitBot manages devcontainers with AI agent integration, consider:

#### 1. **File Access Boundaries**

**Problem:** AI agents must access files in managed devcontainers, not host

**Solution:**
- Document which agents execute where
- Test file operation paths explicitly
- Provide clear configuration examples

#### 2. **MCP Server Architecture**

**Design Decision Required:**

```
Option A: MCP Servers on Host
  ✓ Simple configuration
  ✓ Persistent across container lifecycles
  ✗ Cannot use container-specific tools

Option B: MCP Servers in Devcontainer
  ✓ Access to container environment
  ✓ Consistent with workspace
  ✗ Requires Dockerfile setup

Option C: Hybrid Approach
  ✓ Host servers for persistent services
  ✓ Container servers for workspace tools
  ✗ More complex configuration
```

**Recommendation for BitBot:** Hybrid approach with clear documentation

#### 3. **Configuration Propagation**

**Challenge:** Ensure AI agent configs available in managed containers

**BitBot Should:**
- Include AI agent extensions in generated `devcontainer.json`
- Provide templates for MCP server configurations
- Document where to place AGENTS.md, CLAUDE.md, etc.

**Example BitBot-Generated devcontainer.json:**
```json
{
  "name": "BitBot Managed Container",
  "image": "bitbot/base:latest",

  "customizations": {
    "vscode": {
      "extensions": [
        // Recommended AI agents
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "Continue.continue",
        "saoudrizwan.claude-dev"
      ],
      "settings": {
        "chat.agent.enabled": true,
        "chat.mcp.discovery.enabled": true
      }
    }
  },

  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },

  "mounts": [
    // BitBot could mount MCP configs from host
    "source=${localEnv:HOME}/.config/bitbot/mcp.json,target=/workspace/.vscode/mcp.json,type=bind"
  ],

  "postCreateCommand": "bash .devcontainer/setup-ai-agents.sh"
}
```

#### 4. **Security Boundaries**

**Workspace Extensions Security:**
- Run with full container permissions
- Can execute arbitrary code in container
- Should be restricted in untrusted containers

**BitBot Security Modes:**
```yaml
# .bitbot/config.yml
security_mode: sandbox

ai_agents:
  allow_workspace_extensions: false  # Disable for untrusted code
  allow_ui_extensions: true

  mcp_servers:
    execution: host_only              # Prevent container MCP servers

  file_access:
    deny_patterns:
      - "**/.env"
      - "**/*.key"
      - "**/credentials.json"
```

#### 5. **Testing AI Agent Integration**

**BitBot Should Test:**
1. ✓ AI agent can access container files
2. ✓ AI agent uses container tools (not host tools)
3. ✓ MCP servers communicate with agents
4. ✓ File edits appear in correct location (container, not host)
5. ✓ Terminal commands execute in container shell

**Test Script Example:**
```bash
#!/bin/bash
# BitBot AI Agent Integration Test

# Test 1: Verify agent file access
echo "Test 1: Agent file access boundary"
# Ask agent to create /workspace/test.txt
# Verify file exists in container, not on host

# Test 2: Verify tool execution
echo "Test 2: Container tool usage"
# Ask agent to run 'which python'
# Verify returns container python, not host python

# Test 3: MCP server connectivity
echo "Test 3: MCP server communication"
# Invoke MCP tool
# Verify response from correct MCP server (host vs container)
```

### Summary: Execution Locations

| Component                  | Default Location     | Configurable? | Access Scope          |
|----------------------------|----------------------|---------------|-----------------------|
| **UI Extensions**          | Host                | No            | Local files only      |
| **Workspace Extensions**   | Devcontainer        | No            | Container workspace   |
| **GitHub Copilot Chat**    | Devcontainer        | Via config    | Container workspace   |
| **Continue.dev**           | Devcontainer        | Via config    | Container workspace   |
| **Cline**                  | Devcontainer        | Via config    | Container workspace   |
| **MCP Servers (stdio)**    | Host or Container   | Yes           | Depends on location   |
| **MCP Servers (SSE)**      | Remote/Docker       | Yes           | Network-accessible    |
| **GitHub Coding Agent**    | GitHub Cloud        | No            | Temporary cloud env   |

### Best Practices for Container-Based AI Development

1. **Explicit Extension Configuration:**
   - Always list AI extensions in `devcontainer.json`
   - Don't rely on auto-installation

2. **Test File Operations:**
   - Verify agents create files in container, not host
   - Check terminal command execution location

3. **Document MCP Architecture:**
   - Clearly state where MCP servers run
   - Provide setup instructions for each location

4. **Security Boundaries:**
   - Restrict workspace extensions in untrusted containers
   - Use sandboxed execution for unknown code

5. **Version Control:**
   - Commit `devcontainer.json` with AI agent configs
   - Exclude `.vscode/settings.local.json` (personal prefs)

6. **BitBot-Specific:**
   - Generate devcontainer configs with AI agent support
   - Provide templates for common AI toolchains
   - Document execution boundaries clearly in AGENTS.md

---

## Comparison Matrix

| Tool              | Primary Config File(s)                  | Format        | Hierarchy   | AGENTS.md Support | Version Control |
|-------------------|-----------------------------------------|---------------|-------------|-------------------|-----------------|
| **AGENTS.md**     | `AGENTS.md`                            | Markdown      | Nested      | Native            | Yes             |
| **Claude Code**   | `CLAUDE.md`, `.claude/settings.json`   | MD + JSON     | Merging     | Via reference     | Partial*        |
| **Cursor**        | `.cursor/rules/*.mdc`                  | MDC           | Flat        | Planned           | Yes             |
| **GitHub Copilot**| `.github/copilot-instructions.md`      | Markdown      | Nested      | Planned           | Yes             |
| **Aider**         | `.aider.conf.yml`, `CONVENTIONS.md`    | YAML + MD     | Single      | Manual            | Yes (YAML), Rec (MD) |
| **Windsurf**      | `.windsurf/rules/*.md`                 | Markdown      | Glob-based  | Planned           | Yes             |
| **Continue.dev**  | `~/.continue/config.json`              | JSON          | Global only | Manual            | Optional        |
| **Cline**         | VS Code workspace settings             | JSON          | Workspace   | Manual            | Yes             |
| **VSCodium**      | Same as VS Code extensions             | JSON          | Same as ext | Same as ext       | Same as ext     |
| **Claude Flow**   | `.claude-flow/config.yml`              | YAML          | Hierarchical| Via CLAUDE.md     | Yes             |

\* `.claude/settings.json` is version controlled; `.claude/settings.local.json` is not

---

## Common Patterns Across Tools

### 1. Markdown for Human-Readable Instructions
- All tools support natural language Markdown for instructions
- No proprietary syntax required
- Easy to read and maintain

### 2. Hierarchical Configuration
- Global (user-level) settings
- Project (team-shared) settings
- Local (developer-specific) settings

### 3. Separation of Concerns
```
Instructions:    AGENTS.md, CLAUDE.md, CONVENTIONS.md
Settings:        .claude/settings.json, .aider.conf.yml
Secrets:         .env, API key prompts
Ignore Patterns: .gitignore integration, custom ignore files
```

### 4. Tool-Specific Advanced Features
- **Subagents:** Claude Code, Windsurf
- **Multi-agent orchestration:** Claude Flow
- **Directory-scoped rules:** GitHub Copilot, Windsurf
- **Custom model selection:** Aider, Windsurf, Continue.dev, Cline
- **MCP Integration:** VS Code Agent Mode, Cline, Continue.dev, Claude Flow
- **Local LLM support:** Continue.dev, Cline (via Ollama)

---

## Recommendations for BitBot Project

### 1. Adopt AGENTS.md as Primary Standard
```markdown
# AGENTS.md
# AI Agent Instructions for BitBot

## Project Overview
BitBot is a container orchestration and devcontainer management CLI...

## Build Instructions
...

## Testing
...

## Coding Standards
...
```

### 2. Maintain Tool-Specific Files for Advanced Features

#### For Claude Code Support
```
CLAUDE.md                           # Reference to AGENTS.md + Claude-specific notes
.claude/
  ├── settings.json                 # Team permissions, env vars
  └── settings.local.json           # In .gitignore
```

#### For Cursor Users
```
.cursor/
  └── rules/
      └── bitbot-standards.mdc
```

#### For GitHub Copilot
```
.github/
  └── copilot-instructions.md       # Can reference AGENTS.md
```

#### For VS Code Extension Users (Continue/Cline)
```
~/.continue/
  └── config.json                   # Continue configuration (global)

.vscode/
  └── settings.json                 # Cline settings (workspace)
```

#### For Claude Flow (Advanced Multi-Agent)
```
.claude-flow/
  ├── config.yml                    # Orchestration settings
  ├── agents/                       # Agent definitions
  └── workflows/                    # Multi-agent workflows
```

### 3. Update .gitignore
```gitignore
# AI Agent Local Settings
.claude/settings.local.json
.env
.aider.env
```

### 4. Documentation Strategy
- **AGENTS.md:** Machine-readable project instructions
- **README.md:** Human-readable project introduction and quick start
- **CLAUDE.md:** Optional, references AGENTS.md with Claude-specific additions
- **Contributing guidelines:** Reference AGENTS.md for AI-assisted contributions

---

## Migration Path for Existing Projects

### Phase 1: Create AGENTS.md
1. Consolidate common instructions from tool-specific files
2. Write in natural, clear Markdown
3. Focus on: setup, testing, standards, architecture

### Phase 2: Update Tool-Specific Files
1. Keep existing files for backward compatibility
2. Add references to AGENTS.md
3. Retain only tool-specific advanced features

### Phase 3: Team Communication
1. Document in README that project uses AGENTS.md
2. Guide developers to configure their preferred tools
3. Maintain AGENTS.md as single source of truth

---

## Future Trends

### Industry Direction
- **Consolidation:** Movement toward AGENTS.md as universal standard
- **Interoperability:** Tools adding AGENTS.md support incrementally
- **Vendor Neutrality:** Resistance to tool lock-in

### Expected Timeline
- **2025 Q4:** Major tools add AGENTS.md support
- **2026:** AGENTS.md becomes de facto standard
- **2026+:** Tool-specific files become optional/advanced-only

### Watch List
- OpenAI, Sourcegraph, Google spec updates
- Claude Code AGENTS.md integration
- Cursor AGENTS.md roadmap
- Community adoption metrics

---

## References

### Official Documentation

#### Core Tools
- [Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings)
- [GitHub Copilot Instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Aider Documentation](https://aider.chat/docs/)
- [Cursor Rules](https://docs.cursor.com/context/rules)
- [Windsurf Documentation](https://docs.windsurf.com/)

#### VS Code Agentic Extensions
- [Continue.dev Documentation](https://docs.continue.dev/)
- [Cline Documentation](https://docs.cline.bot/)
- [VS Code Agent Mode](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
- [VS Code MCP Integration](https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview)
- [VS Code Remote Development](https://code.visualstudio.com/api/advanced-topics/remote-extensions)
- [VS Code Devcontainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [VS Code MCP Servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)

#### Claude Flow
- [Claude Flow GitHub Repository](https://github.com/ruvnet/claude-flow)
- [Claude Flow Tutorial](https://deeplearning.fr/claude-flow-the-complete-beginners-guide-to-ai-powered-development/)

### AGENTS.md Resources
- [AGENTS.md Specification (InfoQ)](https://www.infoq.com/news/2025/08/agents-md/)
- [Builder.io AGENTS.md Guide](https://www.builder.io/blog/agents-md)
- [Complete Guide to AGENTS.md](https://www.remio.ai/post/what-is-agents-md-a-complete-guide-to-the-new-ai-coding-agent-standard-in-2025)

### Community Resources
- [Awesome Cursor Rules](https://github.com/PatrickJS/awesome-cursorrules)
- [Claude Code Settings Examples](https://github.com/feiskyer/claude-code-settings)
- [.claude Community Guide](https://dotclaude.com/)
- [Continue.dev + Open WebUI](https://docs.openwebui.com/tutorials/integrations/continue-dev/)
- [VSCodium Extension Installation Guide](https://milicendev.netlify.app/article/install-vs-codium-and-integrate-vs-code-extensions/)

---

## Appendix: Example Configuration Files

### Example AGENTS.md
```markdown
# AI Agent Instructions - BitBot

## Overview
BitBot is a cross-platform CLI for managing devcontainers with AI agent integration.

## Architecture
- Go-based CLI (cross-platform: Windows, macOS, Linux)
- Docker/Podman container orchestration
- MCP (Model Context Protocol) for AI integration

## Build & Test
```bash
# Build
go build -o bitbot ./cmd/bitbot

# Test
go test ./...

# Integration tests
./tests/integration.sh
```

## Coding Standards
- Language: Go 1.21+
- Style: gofmt, golangci-lint
- Testing: Table-driven tests preferred
- Documentation: Godoc comments for public APIs

## Security Guidelines
- No credentials in code
- Container isolation required
- Validate all user inputs
- Follow least-privilege principle

## Pull Request Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Follows project conventions
```

### Example CLAUDE.md
```markdown
# Claude Code Instructions for BitBot

See AGENTS.md for general project instructions.

## Claude-Specific Notes
- Use Go subagent for Go-related tasks
- Docker knowledge available via MCP server
- Security reviews required for container operations

## Custom Subagents
Located in `.claude/agents/` for specialized tasks.
```

### Example .claude/settings.json
```json
{
  "permissions": {
    "deny": [
      "**/.env",
      "**/credentials.json",
      "**/*.key",
      "**/*.pem"
    ]
  },
  "environment": {
    "BITBOT_ENV": "development"
  }
}
```

---

**Document Version:** 1.2
**Last Updated:** October 2025
**Changelog:**
- v1.2: Added AI agent execution in devcontainers (inside/outside architecture), MCP server execution locations, BitBot-specific implications
- v1.1: Added VS Code agentic extensions (Continue.dev, Cline, Roo Code), VSCodium support, Claude Flow multi-agent orchestration
- v1.0: Initial research covering AGENTS.md standard and major AI coding tools

**Maintained By:** BitBot Project Team
