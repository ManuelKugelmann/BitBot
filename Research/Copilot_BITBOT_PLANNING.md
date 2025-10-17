# BitBot Planning Document
**AI-Powered Development Environment with Containerized Claude Code + MCP Services**

*Planning Date: October 16, 2025*
*Status: SPARC Phase 0-1 (Research & Specification)*

---

## 🎯 Project Vision

BitBot is a reasonably safe containerized environment for working with CLI AI agents (including in `yolo` or `dangerouslyskippermissions` mode). It provides a universal setup for claude-code, claude-flow, open-code, and other AI agents across Windows, Linux, and Mac platforms.

### Core Principles
- **Universal Cross-Platform**: Single `bitbot` command works everywhere
- **Safe Containerization**: Isolated workspace environments with configurable restrictions  
- **AI Agent Agnostic**: Supports multiple AI agents through MCP architecture
- **Developer Experience First**: Seamless VS Code integration + powerful CLI workflows
- **Composable Architecture**: Extensible components and services

---

## 📋 SPARC Implementation Status

### ✅ Phase 0: Research & Discovery (IN PROGRESS)

#### Current AI Agent Landscape Research
**Claude Code Integration:**
- Standard MCP interface patterns
- VS Code extension compatibility requirements
- Container networking for localhost connections
- Session persistence and resumability patterns

**OpenCode & Alternative Agents:**
- Common CLI interfaces and configuration patterns
- Docker networking requirements for agent communication
- Standard MCP service discovery protocols

**Modern Container Orchestration:**
- Docker Compose multi-service patterns
- DevContainer specification compliance
- Cross-platform volume mounting strategies
- Container lifecycle management

#### Legacy BitBot Analysis
**Strengths Identified:**
- ✅ Polyglot bash/PowerShell entry script
- ✅ Dual MCP service architecture (global + workspace)
- ✅ Robust platform detection and Docker validation
- ✅ DevContainer template system with variable substitution
- ✅ Tmux session management with resumability
- ✅ Comprehensive test suite with real service validation

**Gaps & Improvement Areas:**
- ⚠️ Limited AI agent configurability (hardcoded for Claude Code)
- ⚠️ No built-in security mode restrictions (sketch/work/setup modes)
- ⚠️ Docker-in-Docker pattern needs refinement for user workflows
- ⚠️ PATH setup automation not implemented
- ⚠️ Workspace inheritance from parent directories missing

### 🔄 Phase 1: Specification (NEXT)

---

## 🏗️ Architecture Analysis (Based on Legacy)

### Current Implementation Strengths

#### 1. **Universal Entry Point**
```bash
# Polyglot script works on all platforms
bitbot                    # Launches into current workspace
bitbot --resume           # Resumes existing session
bitbot --mode sketch      # Restricted sketch mode
```

#### 2. **Dual MCP Architecture**
- **Global Services** (8080, 8090): Shared across workspaces
- **Workspace Services** (9080, 9090): Per-workspace isolation
- **Service Registry**: Auto-discovery and health monitoring

#### 3. **DevContainer Integration**
- Template-based `.devcontainer/devcontainer.json` generation
- Variable substitution (`${WORKSPACE_HASH}`)
- Full VS Code integration with custom terminal profiles

#### 4. **Container Session Management**
- Tmux-based multi-terminal access
- Workspace-specific container naming (`bitbot-dev-${WORKSPACE_HASH}`)
- Automatic session resumption

### Proposed Enhancements

#### 1. **AI Agent Configuration System**
```yaml
# .bitbot/agent.yml
agent:
  type: "claude-code"        # claude-code, open-code, custom
  version: "latest"
  mcp_services:
    - file-system
    - git-helper
    - code-analyzer
  custom_tools:
    - ./workspace-tools/*
```

#### 2. **Security Mode Implementation**
```bash
bitbot --mode sketch       # Only /sketch write access
bitbot --mode work         # .devcontainer read-only (default)
bitbot --mode setup        # Full container write access
```

#### 3. **Docker-in-Docker Separation**
- **BitBot Docker**: For MCP services and agent containers
- **User Docker**: For user workflows and development containers
- Network bridge with access controls

---

## 🎯 MVP Feature Specification

### Core Features

#### 1. **Universal Command Interface**
```bash
# Installation & Setup
bitbot install           # Sets up PATH, creates shortcuts
bitbot version          # Version info
bitbot help             # Usage help

# Workspace Operations  
bitbot                  # Smart launch (first run menu, or resume)
bitbot new              # Force new session
bitbot list             # List all sessions
bitbot stop             # Stop current session
bitbot kill             # Stop all BitBot containers

# Mode Controls (short commands)
bitbot sketch           # Restricted mode
bitbot work             # Default mode  
bitbot setup            # Full access mode

# Agent Selection (short commands)
bitbot claude           # Claude Code agent
bitbot open             # OpenCode agent
bitbot config           # Configure default agent
```

#### 2. **First-Run Experience**
```
BitBot - First Run Setup
Workspace: my-project
========================================

How would you like to configure BitBot?

[1] VS Code DevContainer (Recommended)
    ✓ Full VS Code integration
    ✓ DevContainer with IntelliSense
    ✓ Integrated terminal with AI agent
    
[2] Direct Docker Launch  
    ✓ Immediate container startup
    ✓ Tmux-based terminal sessions
    ✓ Command-line focused workflow
    
[3] Configure AI Agent
    ✓ Choose: claude-code, open-code, custom
    ✓ Select MCP services
    ✓ Set workspace preferences

Choose option [1-3]:
```

#### 3. **Container Security Modes**

**Sketch Mode (`--mode sketch`)**:
- Write access only to `/workspace/sketch/`
- No access to `.devcontainer` or BitBot configs
- Limited network access (AI agent + essential services only)
- Docker-in-Docker disabled

**Work Mode (default)**:
- Full workspace read access  
- Write access except `.devcontainer/` (read-only)
- Standard network access
- Docker-in-Docker with user network separation

**Setup Mode (`--mode setup`)**:
- Full container write access
- Can modify `.devcontainer` and BitBot configs
- Full network access
- Full Docker-in-Docker capabilities

#### 4. **AI Agent Management**
```bash
# Inside container
ai-agent status           # Current agent status
ai-agent switch claude-code   # Switch agents  
ai-agent logs            # View agent logs
ai-agent restart         # Restart current agent
```

#### 5. **MCP Service Ecosystem**

**Global Services** (Shared):
- Service Registry (discovery)
- Authentication/Security Gateway
- Shared development tools
- Global configuration management

**Workspace Services** (Isolated):
- File system operations
- Git integration  
- Project-specific tools
- Workspace state management

**Custom Services**:
- User-defined MCP services
- Project-specific integrations
- Third-party service connectors

### Advanced Features (Post-MVP)

#### 1. **Workspace Inheritance**
```bash
# Parent workspace context available in subfolders
/projects/my-app/           # BitBot workspace
  ├── .bitbot/
  ├── frontend/            # Inherits parent config
  └── backend/             # Inherits parent config
```

#### 2. **Multi-Agent Workflows**
```yaml
# .bitbot/workflow.yml
agents:
  - name: "coder"
    type: "claude-code"
    role: "development"
  - name: "reviewer"  
    type: "open-code"
    role: "code-review"
workflow:
  - stage: "development"
    agent: "coder"
  - stage: "review"
    agent: "reviewer"
```

#### 3. **Remote Development Support**
```bash
# Connect to remote BitBot instances
bitbot --remote ssh://user@server/workspace
bitbot --remote docker://container-id
```

---

## 🛠️ Technical Implementation Plan

### Development Phases

#### Phase 1: Core Infrastructure (Weeks 1-2)
- [ ] Universal `bitbot` command with platform detection
- [ ] Container lifecycle management
- [ ] Basic security mode implementation
- [ ] MCP service orchestration

#### Phase 2: AI Agent Integration (Weeks 3-4)  
- [ ] Claude Code integration and configuration
- [ ] OpenCode support framework
- [ ] Agent switching and management
- [ ] MCP service communication

#### Phase 3: Developer Experience (Weeks 5-6)
- [ ] VS Code DevContainer integration
- [ ] Session management and resumption
- [ ] Configuration management system
- [ ] Documentation and examples

#### Phase 4: Security & Polish (Weeks 7-8)
- [ ] Docker-in-Docker separation
- [ ] Security audit and hardening
- [ ] Performance optimization
- [ ] Comprehensive testing

### Quality Gates
- **Syntax Validation**: All scripts pass `shellcheck` and `bash -n`
- **Docker Validation**: All containers build and run successfully
- **Integration Testing**: Full workflow tests with real services
- **Cross-Platform Testing**: Windows (WSL), macOS, Linux validation
- **Security Review**: Container isolation and permission verification

---

## 📊 Proposed Command Line Arguments

### Basic Operations
```bash
bitbot                    # Smart launch (resume or new)
bitbot --new              # Force new session
bitbot --resume [session] # Resume specific session  
bitbot --list             # List all sessions/containers
bitbot --stop [session]   # Stop specific session
bitbot --stop-all         # Stop all BitBot containers
```

### Configuration
```bash
bitbot --config           # Interactive configuration
bitbot --agent <type>     # Set/override agent type
bitbot --mode <mode>      # Security mode (sketch/work/setup)
bitbot --workspace <path> # Explicit workspace path
```

### Management
```bash
bitbot --install          # Setup PATH and integrations
bitbot --uninstall        # Remove BitBot integrations
bitbot --update           # Update BitBot components
bitbot --doctor           # Diagnose issues
```

### Development
```bash
bitbot --debug            # Debug mode with verbose logging
bitbot --no-mcp           # Skip MCP service startup
bitbot --shell-only       # Shell access without AI agent
```

---

## 🔍 Missing Features Analysis

### Features from Original Vision Not in Legacy:
1. **`bb` shorthand command** - Would be nice alias
2. **Automatic PATH setup** - Currently manual
3. **Parent workspace context** - Inheritance system  
4. **Multiple AI agent support** - Currently Claude Code only
5. **Docker workflow separation** - User vs BitBot containers
6. **Time/timezone matching** - Partially implemented
7. **Comprehensive security modes** - Only basic restrictions

### Recommended Additions for MVP:
1. **Health checking system** - Service monitoring and auto-restart
2. **Backup/restore functionality** - Workspace state management
3. **Plugin system** - Easy extension framework
4. **Metrics and monitoring** - Usage analytics and performance
5. **Template marketplace** - Shareable workspace templates

---

## 🚀 Next Steps

### Immediate Actions (This Week):
1. **Complete research phase** - Finish AI agent landscape analysis
2. **Requirements specification** - Formal functional/non-functional requirements  
3. **Architecture refinement** - Detailed component design
4. **Development environment setup** - Fresh implementation workspace

### Sprint 1 (Weeks 1-2):
1. **Core `bitbot` command** - Universal entry point implementation
2. **Container management** - Lifecycle and session handling
3. **Basic MCP integration** - Service orchestration framework
4. **Testing infrastructure** - Automated validation suite

### Success Metrics:
- [ ] Single `bitbot` command works on Windows, macOS, Linux
- [ ] Claude Code runs successfully in container
- [ ] MCP services auto-start and communicate
- [ ] VS Code DevContainer integration functional
- [ ] Security modes restrict access appropriately

---

*This planning document will be updated as we progress through SPARC phases.*