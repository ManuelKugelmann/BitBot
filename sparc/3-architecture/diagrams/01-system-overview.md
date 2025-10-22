# System Overview

High-level architecture of BitBot showing major components and their interactions.

```mermaid
graph TB
    subgraph UI["User Interface"]
        CLI[BitBot CLI]
        VS[VS Code]
    end

    subgraph PLAT["Platform Layer"]
        WIN[Windows+WSL2]
        MAC[macOS]
        LIN[Linux]
    end

    subgraph CORE["Core Components"]
        ROUTER[Router<br/>bitbot]
        GLOBAL[Global<br/>Commands]
        WORK[Workspace<br/>Commands]
        UTIL[Utilities]
    end

    subgraph CONT["Container Orchestration"]
        WMODE[Work Mode<br/>ro .devcontainer]
        CMODE[Config Mode<br/>rw .devcontainer]
    end

    subgraph EXT["External Services"]
        DOC[Docker]
        DC[DevContainer]
        GIT[Git]
    end

    subgraph TMPL["Templates"]
        BASIC[Basic]
        CFG[Config]
    end

    CLI --> ROUTER
    VS --> WMODE
    VS --> CMODE
    ROUTER --> GLOBAL
    ROUTER --> WORK
    GLOBAL --> UTIL
    WORK --> UTIL
    WORK --> WMODE
    WORK --> CMODE
    WORK --> VS
    WMODE --> DOC
    WMODE --> DC
    CMODE --> DC
    UTIL --> GIT
    UTIL --> DOC
    GLOBAL --> BASIC
    GLOBAL --> CFG
    WIN --> ROUTER
    MAC --> ROUTER
    LIN --> ROUTER

    style CLI fill:#4a9eff,stroke:#333,stroke-width:3px
    style VS fill:#4a9eff,stroke:#333,stroke-width:2px
    style WMODE fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style CMODE fill:#ffb6c1,stroke:#333,stroke-width:2px,color:#333
    style ROUTER fill:#ffd700,stroke:#333,stroke-width:3px,color:#333
    style WORK fill:#ffd700,stroke:#333,stroke-width:2px,color:#333
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
- **Work Template**: Ubuntu + workload-specific tools + Claude Code AI
- **Config Template**: Ubuntu + config-specific tools (devcontainer features, YAML/JSON editors) + Claude Code AI (no Docker inside)

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
