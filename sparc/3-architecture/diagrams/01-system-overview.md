# System Overview

High-level architecture of BitBot showing major components and their interactions.

```mermaid
graph TB
    subgraph "User Interface"
        CLI[BitBot CLI Entry Point]
        VSCODE[VS Code IDE]
    end

    subgraph "Platform Layer"
        WINDOWS[Windows + WSL2]
        MACOS[macOS Native]
        LINUX[Linux Native]
    end

    subgraph "Core Components"
        ROUTER[Command Router<br/>bitbot script]
        GLOBAL[Global Commands<br/>init, version]
        WORKSPACE[Workspace Commands<br/>work, config, help]
        UTILS[Utilities<br/>detect, git, helpers]
    end

    subgraph "Container Orchestration"
        WORKMODE[Work Mode Container<br/>Read-only .devcontainer]
        CONFIGMODE[Config Mode Container<br/>Read-write .devcontainer]
    end

    subgraph "External Services"
        DOCKER[Docker Desktop<br/>Container Runtime]
        DEVCONTAINER[DevContainer Spec<br/>Configuration]
        GIT[Git Repository<br/>Version Control]
    end

    subgraph "Templates"
        BASIC[Basic Template<br/>Minimal setup]
        CONFIG[Config Template<br/>Infrastructure tools]
    end

    CLI --> ROUTER
    VSCODE --> WORKMODE
    VSCODE --> CONFIGMODE

    ROUTER --> GLOBAL
    ROUTER --> WORKSPACE
    GLOBAL --> UTILS
    WORKSPACE --> UTILS

    WORKSPACE --> WORKMODE
    WORKSPACE --> CONFIGMODE
    WORKSPACE --> VSCODE

    WORKMODE --> DOCKER
    CONFIGMODE --> DOCKER
    WORKMODE --> DEVCONTAINER
    CONFIGMODE --> DEVCONTAINER

    UTILS --> GIT
    UTILS --> DOCKER

    GLOBAL --> BASIC
    GLOBAL --> CONFIG

    WINDOWS --> ROUTER
    MACOS --> ROUTER
    LINUX --> ROUTER

    style CLI fill:#4a9eff,stroke:#333,stroke-width:3px
    style VSCODE fill:#0078d4,stroke:#333,stroke-width:2px
    style WORKMODE fill:#90ee90,stroke:#333,stroke-width:2px
    style CONFIGMODE fill:#ffb6c1,stroke:#333,stroke-width:2px
    style ROUTER fill:#ffd700,stroke:#333,stroke-width:2px
```

## Key Components

### User Interface
- **BitBot CLI**: Command-line entry point for all BitBot operations
- **VS Code IDE**: Direct container opening via hex-encoded URIs

### Platform Layer
- **Windows + WSL2**: BitBot runs in Alpine WSL distro, launches Windows VS Code
- **macOS Native**: Direct bash execution
- **Linux Native**: Direct bash execution

### Core Components
- **Command Router**: Routes commands to appropriate handlers (global vs workspace)
- **Global Commands**: System-wide operations (first-run init, version)
- **Workspace Commands**: Workspace-specific operations (work, config, help, init)
- **Utilities**: Shared functionality (workspace detection, git safety, helpers)

### Container Orchestration
- **Work Mode**: Development container with read-only .devcontainer (secure)
- **Config Mode**: Configuration container with read-write .devcontainer (infrastructure)

### External Services
- **Docker Desktop**: Provides container runtime
- **DevContainer Spec**: Configuration standard for development containers
- **Git Repository**: Version control and safety checks

### Templates
- **Basic Template**: Minimal Ubuntu + Node.js + Claude Code
- **Config Template**: Basic + Docker CLI + DevContainer CLI

## Information Flow

1. **User invokes BitBot CLI** → Platform-specific execution (WSL/native bash)
2. **Router analyzes command** → Global or workspace context
3. **Command handler executes** → Uses utilities for common operations
4. **Container operations** → Work or config mode based on command
5. **VS Code integration** → Direct container opening (no manual popup)

## Design Principles

- **Separation of Concerns**: Global vs workspace, work vs config modes
- **Security First**: Read-only .devcontainer in work mode
- **Cross-Platform**: Same codebase works on Windows/macOS/Linux
- **Simple Entry Point**: Single `bitbot` command for all operations
- **No Globals**: All state in workspace, no global configuration
