# BitBot Technical Requirements Specification
**Version 1.0 | October 16, 2025 | SPARC Phase 1**

---

## 📋 Executive Summary

BitBot is a containerized AI development environment that provides secure, cross-platform access to AI coding agents (Claude Code, OpenCode, etc.) through a unified command-line interface. This document specifies functional and non-functional requirements for the fresh implementation using modern container orchestration patterns.

---

## 🎯 Functional Requirements

### FR-1: Universal Command Interface

**FR-1.1 Cross-Platform Entry Point**
- **Requirement**: Single `bitbot` executable works on Windows, macOS, and Linux
- **Implementation**: Polyglot bash/PowerShell script with platform detection
- **Acceptance Criteria**:
  - Works from Command Prompt, PowerShell, WSL, bash, zsh
  - Automatic platform detection and Docker environment validation
  - Consistent behavior across all supported platforms

**FR-1.2 Command Line Arguments**
```bash
# Core Operations
bitbot                    # Smart launch (resume or new session)
bitbot new                # Force new session creation
bitbot resume [name]      # Resume specific session by name
bitbot list               # List all active sessions
bitbot stop [name]        # Stop specific session
bitbot kill               # Stop all BitBot containers

# Quick Mode Selection (short commands)
bitbot sketch             # Launch in sketch mode (restricted)
bitbot work               # Launch in work mode (default)
bitbot setup              # Launch in setup mode (full access)

# Agent Selection (short commands)
bitbot claude             # Launch with Claude Code
bitbot open               # Launch with OpenCode
bitbot custom [name]      # Launch with custom agent

# Configuration & Management  
bitbot config             # Interactive configuration wizard
bitbot install            # Setup PATH and system integrations
bitbot doctor             # System diagnostics and health check
bitbot version            # Version and component information
```

**FR-1.3 First-Run Experience**
- Interactive setup wizard for new workspaces
- Choice between VS Code DevContainer and Direct Docker modes
- AI agent selection and configuration
- Automatic workspace detection and hash generation

### FR-2: Container Lifecycle Management

**FR-2.1 Workspace Isolation**
- **Requirement**: Each workspace gets unique container instance
- **Container Naming**: `bitbot-dev-{workspace-hash}`
- **Workspace Hash**: 8-character SHA-256 from absolute workspace path
- **Persistence**: Container state survives BitBot restarts

**FR-2.2 Session Management**
- **Primary Session**: `tmux` session named `bitbot-{workspace-name}`
- **Additional Sessions**: Auto-incrementing names (`bitbot-{workspace-name}-2`)
- **Resume Capability**: Reconnect to existing detached sessions
- **Multi-Terminal**: Support multiple concurrent terminal connections

**FR-2.3 Container State Tracking**
```
workspace/
├── .bitbot/
│   ├── workspace-hash       # Unique identifier
│   ├── created             # ISO timestamp
│   ├── last-accessed       # ISO timestamp  
│   ├── agent.yml           # AI agent configuration
│   ├── mode                # Current security mode
│   └── sessions/           # Session state tracking
└── .devcontainer/          # (Optional) VS Code mode indicator
    └── devcontainer.json
```

### FR-3: AI Agent Integration

**FR-3.1 Multi-Agent Support**
- **Supported Agents**: claude-code, open-code, custom implementations
- **Configuration**: YAML-based agent settings in `.bitbot/agent.yml`
- **Runtime Switching**: Change agents without container restart
- **Agent Isolation**: Each agent runs in separate process/container

**FR-3.2 Agent Configuration Schema**
```yaml
# .bitbot/agent.yml
agent:
  type: "claude-code"           # Agent type identifier
  version: "latest"             # Version or tag
  config:                       # Agent-specific configuration
    model: "claude-3.5-sonnet"
    max_tokens: 4096
    temperature: 0.1
  mcp_services:                 # Required MCP services
    - file-system
    - git-helper
    - code-analyzer
  environment:                  # Environment variables
    CLAUDE_API_KEY: "${CLAUDE_API_KEY}"
  startup_command: "claude-code --workspace /workspace"
```

**FR-3.3 Agent Lifecycle**
- **Startup**: Automatic agent launch on container start
- **Health Monitoring**: Agent process monitoring and auto-restart
- **Graceful Shutdown**: Proper cleanup on container stop
- **Log Management**: Agent logs accessible via `bitbot logs` command

### FR-4: Security Mode Implementation

**FR-4.1 Sketch Mode (`bitbot sketch`)**
- **Write Access**: Only `/workspace/sketch/` directory
- **Read Access**: Full workspace read-only access
- **Network**: AI agent + essential MCP services only
- **Docker**: No Docker-in-Docker access
- **Use Case**: Experimental AI work without risk

**FR-4.2 Work Mode (`bitbot work` or default)**
- **Write Access**: Full workspace except `.devcontainer/` (read-only)
- **Read Access**: Complete workspace access
- **Network**: Standard network access with MCP services
- **Docker**: User Docker network isolated from BitBot Docker
- **Use Case**: Normal development workflow

**FR-4.3 Setup Mode (`bitbot setup`)**
- **Write Access**: Complete container write access
- **Read Access**: Full system access
- **Network**: Unrestricted network access
- **Docker**: Full Docker-in-Docker capabilities
- **Use Case**: BitBot configuration and system setup

**FR-4.4 Mode Enforcement**
- **File System**: Linux file permissions and mount restrictions
- **Network**: iptables rules and container network policies
- **Process**: User namespace and capability restrictions
- **Audit**: All mode violations logged for security review

### FR-5: MCP Service Architecture

**FR-5.1 Global Services**
- **Purpose**: Shared services across all workspaces
- **Network**: `mcp-global-network` (172.20.0.0/16)
- **Ports**: 8080 (registry), 8090 (gateway)
- **Services**: Registry, authentication, shared tools
- **Lifecycle**: Independent of workspace containers

**FR-5.2 Workspace Services**  
- **Purpose**: Workspace-specific service instances
- **Network**: `mcp-workspace-{hash}-network` (172.21.x.0/24)
- **Ports**: 9080 (registry), 9090 (gateway)
- **Services**: File ops, git, project-specific tools
- **Lifecycle**: Tied to workspace container lifecycle

**FR-5.3 Service Discovery**
- **Registry API**: RESTful service for registration/discovery
- **Health Checks**: Automated service health monitoring
- **Load Balancing**: Round-robin for multiple service instances
- **Failover**: Automatic service restart on failure

**FR-5.4 Custom MCP Services**
```
workspace/
├── .bitbot/
│   └── services/
│       ├── my-service/
│       │   ├── Dockerfile
│       │   ├── requirements.txt
│       │   └── server.py
│       └── docker-compose.workspace.yml
```

### FR-6: DevContainer Integration

**FR-6.1 Template System**
- **Base Template**: `devcontainer-base/devcontainer.json`
- **Variable Substitution**: `${WORKSPACE_HASH}`, `${BITBOT_ROOT}`
- **Path Resolution**: Absolute paths to BitBot installation
- **Feature Integration**: VS Code extensions and customizations

**FR-6.2 VS Code Integration**
- **Command**: `code .` opens workspace in DevContainer
- **Terminal Profiles**: Custom profiles with BitBot integration
- **Extensions**: Pre-configured development extensions
- **Settings**: Workspace-specific VS Code settings

**FR-6.3 Development Workflow**
```bash
# VS Code DevContainer Mode
bitbot                    # First run: choose DevContainer
# Creates .devcontainer/ and .bitbot/
# Launches VS Code with "Reopen in Container"

# Subsequent runs
bitbot                    # Detects .devcontainer/, launches VS Code
code .                    # Direct VS Code launch also works
```

### FR-7: Docker-in-Docker Architecture

**FR-7.1 Separated Docker Networks**
- **BitBot Network**: For MCP services and agent containers
- **User Network**: For user development containers and workflows
- **Bridge Network**: Controlled communication between networks
- **Isolation**: User containers cannot access BitBot infrastructure

**FR-7.2 Docker Daemon Access**
- **BitBot Docker**: Access to host Docker for BitBot services
- **User Docker**: Isolated Docker-in-Docker for user workflows
- **Socket Mounting**: Selective Docker socket access by mode
- **Permission Control**: User cannot modify BitBot containers

---

## 🔧 Non-Functional Requirements

### NFR-1: Performance

**NFR-1.1 Startup Time**
- **Target**: BitBot command completes within 5 seconds
- **Container Start**: New container ready within 15 seconds
- **Session Resume**: Existing session connection within 2 seconds
- **Service Discovery**: MCP service registration within 10 seconds

**NFR-1.2 Resource Usage**
- **Memory**: Base container uses <500MB RAM
- **Storage**: BitBot overhead <2GB per workspace
- **CPU**: Background services use <5% CPU when idle
- **Network**: MCP traffic optimized for local connections

**NFR-1.3 Scalability**
- **Concurrent Workspaces**: Support 10+ active workspaces
- **Session Limits**: 5+ concurrent sessions per workspace
- **Service Instances**: 20+ MCP services per workspace
- **Container Lifetime**: Stable operation for 24+ hours

### NFR-2: Reliability

**NFR-2.1 Fault Tolerance**
- **Service Recovery**: Auto-restart failed MCP services
- **Container Recovery**: Detect and restart crashed containers
- **Session Persistence**: tmux sessions survive reconnections
- **Data Persistence**: Workspace data survives container restarts

**NFR-2.2 Error Handling**
- **Graceful Degradation**: Core functionality works with service failures
- **Error Messages**: Clear, actionable error messages
- **Log Management**: Structured logging for troubleshooting
- **Recovery Procedures**: Documented recovery from common failures

### NFR-3: Security

**NFR-3.1 Container Isolation**
- **User Namespaces**: Non-root execution within containers
- **Capability Restrictions**: Minimal required capabilities only
- **Mount Restrictions**: Read-only mounts where appropriate
- **Network Policies**: Restricted network access by mode

**NFR-3.2 Secrets Management**
- **Environment Variables**: Secure injection of API keys
- **File Permissions**: Restricted access to sensitive files
- **Audit Logging**: Security-relevant events logged
- **Secret Rotation**: Support for API key rotation

### NFR-4: Usability

**NFR-4.1 Cross-Platform Consistency**
- **Command Interface**: Identical behavior on all platforms
- **Path Handling**: Transparent Windows/Unix path conversion
- **Prerequisites**: Clear installation and setup instructions
- **Documentation**: Platform-specific usage examples

**NFR-4.2 Developer Experience**
- **Quick Start**: Working environment within 5 minutes
- **Discoverability**: Built-in help and command suggestions
- **Configuration**: Sensible defaults with easy customization
- **Debugging**: Tools for troubleshooting issues

### NFR-5: Maintainability

**NFR-5.1 Code Quality**
- **Test Coverage**: >90% test coverage for core functionality
- **Static Analysis**: shellcheck, hadolint, security scanners
- **Documentation**: Architecture decision records and API docs
- **Version Control**: Semantic versioning and change logs

**NFR-5.2 Extensibility**
- **Plugin Architecture**: Easy addition of new MCP services
- **Agent Framework**: Support for custom AI agent implementations
- **Configuration System**: Extensible YAML-based configuration
- **API Stability**: Backwards-compatible APIs between versions

---

## 🌐 Platform Compatibility Matrix

| Platform | Shell | Docker | Support Level | Notes |
|----------|-------|---------|---------------|-------|
| Windows 11 | WSL2 | Docker Desktop | ✅ Primary | Recommended setup |
| Windows 11 | PowerShell | Docker Desktop | ✅ Supported | Native Windows |
| Windows 10 | WSL2 | Docker Desktop | ✅ Supported | Requires WSL2 |
| macOS | bash/zsh | Docker Desktop | ✅ Primary | Intel & Apple Silicon |
| Ubuntu 20.04+ | bash | Docker Engine | ✅ Primary | Native Linux |
| CentOS/RHEL 8+ | bash | Docker Engine | ✅ Supported | Enterprise Linux |
| Debian 11+ | bash | Docker Engine | ✅ Supported | Standard Debian |

### Platform-Specific Requirements

**Windows:**
- WSL2 installed and enabled (recommended)
- Docker Desktop with WSL2 backend
- Windows Terminal (optional, improved experience)

**macOS:**
- Docker Desktop for Mac
- Homebrew for additional tools (optional)
- Terminal.app or iTerm2

**Linux:**
- Docker Engine or Docker Desktop
- systemd for service management
- Standard GNU userland tools

---

## 🧪 Testing Requirements

### TR-1: Automated Testing

**TR-1.1 Unit Tests**
- **Script Validation**: Syntax checking for all shell scripts
- **Docker Validation**: Dockerfile and compose file validation
- **Configuration Tests**: YAML schema validation
- **Component Tests**: Individual component functionality

**TR-1.2 Integration Tests**
- **End-to-End Workflows**: Complete BitBot usage scenarios
- **Platform Tests**: Validation on all supported platforms
- **Service Communication**: MCP service interaction tests
- **Container Lifecycle**: Start/stop/resume workflow validation

**TR-1.3 Performance Tests**
- **Startup Benchmarks**: Timing for various operations
- **Resource Monitoring**: Memory and CPU usage validation
- **Stress Testing**: Multiple concurrent workspaces
- **Load Testing**: High-frequency command execution

### TR-2: Quality Gates

**TR-2.1 Continuous Integration**
- **Syntax Checks**: shellcheck, hadolint, YAML lint
- **Security Scans**: Container vulnerability scanning
- **Platform Matrix**: Test on Windows, macOS, Linux
- **Performance Regression**: Benchmark comparison

**TR-2.2 Release Criteria**
- **Zero Critical Issues**: No security or data loss bugs
- **Platform Validation**: All platforms pass integration tests
- **Documentation Complete**: User guides and API docs updated
- **Backwards Compatibility**: No breaking changes without major version bump

---

## 📊 Implementation Priorities

### Priority 1 (MVP): Core Functionality
- Universal `bitbot` command with basic arguments
- Container lifecycle management with session persistence
- Claude Code integration with basic MCP services
- VS Code DevContainer integration
- Basic security mode implementation (work mode only)

### Priority 2: Enhanced Features
- OpenCode and custom agent support
- Complete security mode implementation (sketch, setup)
- Docker-in-Docker separation
- Advanced MCP service ecosystem
- Configuration management system

### Priority 3: Advanced Capabilities
- Workspace inheritance from parent directories
- Multi-agent workflow orchestration
- Remote development support
- Plugin marketplace and templates
- Advanced monitoring and analytics

---

## 📋 Acceptance Criteria Summary

### Core User Stories

**As a developer, I want to:**
1. Run `bitbot` in any project directory and get a containerized AI coding environment
2. Choose between VS Code integration and terminal-based workflows
3. Work safely with AI agents in restricted environments
4. Resume my work sessions after disconnection
5. Use the same workflow on Windows, macOS, and Linux

**As a security-conscious user, I want to:**
1. Restrict AI agent access to specific directories (sketch mode)
2. Prevent accidental modification of configuration files
3. Isolate BitBot infrastructure from my development workflows
4. Audit AI agent actions for security compliance

**As a team lead, I want to:**
1. Standardize development environments across team members
2. Share workspace configurations and templates
3. Monitor resource usage and performance
4. Customize AI agent configurations for different projects

---

*This requirements specification serves as the foundation for SPARC Phase 2 (Pseudocode) and Phase 3 (Architecture) development.*