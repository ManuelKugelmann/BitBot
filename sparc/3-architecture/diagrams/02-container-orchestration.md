# Container Orchestration - Two-Mode Security System

BitBot's dual-mode container system providing security boundaries between development work and infrastructure configuration.

```mermaid
graph TB
    subgraph CMD["User Commands"]
        WORK[bitbot work]
        CFG[bitbot config]
    end

    subgraph WM["Work Mode Container"]
        WC[Work Container]
        WDC[.devcontainer<br/>READ-ONLY]
        WS1[workspace<br/>Read-Write]
        AI[Claude Code]
        TM1[tmux]
    end

    subgraph CM["Config Mode Container"]
        CC[Config Container]
        CDC[.devcontainer<br/>READ-WRITE]
        WS2[workspace<br/>Read-Write]
        AI2[Claude Code<br/>Config-focused]
        TM2[tmux]
    end

    subgraph HOST["Host Resources"]
        HWS[Workspace]
        HDOC[Docker Desktop]
    end

    subgraph SEC["Security"]
        GIT[Git Safety<br/>Warnings]
        RO[Read-only<br/>Protection]
    end

    WORK --> WC
    CFG --> CC

    WC --> WDC
    WC --> WS1
    WC --> AI
    WC --> TM1

    CC --> CDC
    CC --> WS2
    CC --> AI2
    CC --> TM2

    WDC -.->|ro bind| HWS
    WS1 -.->|rw bind| HWS
    CDC -.->|rw bind| HWS
    WS2 -.->|rw bind| HWS

    WORK --> GIT
    CFG --> GIT
    WDC --> RO

    style WC fill:#66bb6a,stroke:#333,stroke-width:3px,color:#333
    style CC fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style WDC fill:#a5d6a7,stroke:#333,stroke-width:2px,color:#333
    style CDC fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style RO fill:#ef5350,stroke:#333,stroke-width:2px,color:#333
    style GIT fill:#4a9eff,stroke:#333,stroke-width:2px
    style WORK fill:#4a9eff,stroke:#333,stroke-width:2px
    style CFG fill:#4a9eff,stroke:#333,stroke-width:2px
```

## Work Mode (Secure Development)

### Purpose

Isolated development environment with AI assistant, protected infrastructure.

### Characteristics

- **Container**: `devcontainer.json` from workspace
- **.devcontainer**: Read-only bind mount (cannot modify infrastructure)
- **Workspace**: Read-write bind mount (can edit code)
- **Tools**: Claude Code AI, tmux session, git
- **Security**: Git safety warnings, no Docker access (by default)
- **Docker-in-Docker**: Optional (⚠️ security trade-off - see SPEC-02 section 2.3)

### Use Cases

- Writing code
- Running tests
- AI-assisted development
- Git operations
- Regular development workflow
- **(Optional)** Docker image building, Docker Compose testing (⚠️ requires trust)

### Mount Configuration

```yaml
Mounts:
  - source: ${localWorkspaceFolder}/.devcontainer
    target: /workspace/.devcontainer
    type: bind
    consistency: cached
    readonly: true              # ← READ-ONLY

  - source: ${localWorkspaceFolder}
    target: /workspace
    type: bind
    consistency: cached
    readonly: false             # ← READ-WRITE
```

---

## Config Mode (Infrastructure Management)

### Purpose

AI-assisted infrastructure configuration environment with write access to `.devcontainer`.

### Prerequisites

- Requires Docker on host (to run the config container)
- Requires DevContainer CLI (to build/launch the config container)

### Characteristics

- **Container**: Config template with config-specific tooling
- **.devcontainer**: Read-write bind mount (can modify infrastructure)
- **Workspace**: Read-write bind mount (can edit everything)
- **AI Agent**: Claude Code AI for assisted configuration changes
- **Tools**: Config-specific tools (devcontainer features, YAML/JSON editors, git, etc.)
- **Access**: No Docker socket mount - config container doesn't run other containers

### Use Cases

- AI-assisted editing of `.devcontainer/devcontainer.json`
- Modifying `Dockerfile` with AI help
- Adding/configuring devcontainer features
- Updating workspace configuration files
- Infrastructure documentation changes

### Mount Configuration

```yaml
Mounts:
  - source: ${localWorkspaceFolder}
    target: /workspace
    type: bind
    consistency: cached
    readonly: false             # ← READ-WRITE (includes .devcontainer)

# No Docker socket mount - config container doesn't run other containers
```

---

## Security Model

### Threat Model

**Problem**: AI agents could accidentally modify infrastructure (devcontainer config), breaking the development environment or introducing vulnerabilities.

**Solution**: Separate work and configuration into different containers with different permission models.

### Isolation Layers

```mermaid
graph LR
    subgraph "Layer 1: Physical"
        HOST[Host Machine]
    end

    subgraph "Layer 2: Virtual"
        DOCKER[Docker Engine]
    end

    subgraph "Layer 3: Container"
        WORK[Work Container]
        CONFIG[Config Container]
    end

    subgraph "Layer 4: Filesystem"
        WORKRO[Read-only .devcontainer]
        CONFIGRW[Read-write .devcontainer]
    end

    subgraph "Layer 5: Application"
        AI[AI Agent]
        HUMAN[Agent + Human Review]
    end

    HOST --> DOCKER
    DOCKER --> WORK
    DOCKER --> CONFIG
    WORK --> WORKRO
    CONFIG --> CONFIGRW
    WORKRO --> AI
    CONFIGRW --> HUMAN

    style WORKRO fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style CONFIGRW fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
```

### Permission Matrix

| Resource                | Work Mode                | Config Mode                  |
| ----------------------- | ------------------------ | ---------------------------- |
| Source code (workspace) | Read-Write               | Read-Write                   |
| .devcontainer files     | Read-Only                | Read-Write                   |
| Docker socket           | Optional (⚠️)           | No Access                    |
| DevContainer CLI        | No Access                | No Access                    |
| Workload/Config tools   | Workload-specific        | Config-specific (YAML, JSON) |
| Claude Code AI          | Available (code-focused) | Available (config-focused)   |
| Git operations          | Available                | Available                    |

**Note**: Docker socket access in work mode is optional and template-dependent. When enabled, uses rootless Docker-in-Docker with limited isolation (⚠️ security trade-off). See SPEC-02 section 2.3 for details.

---

## Container Lifecycle

```mermaid
sequenceDiagram
    participant User
    participant BitBot
    participant Docker
    participant WorkContainer
    participant ConfigContainer

    User->>BitBot: bitbot work
    BitBot->>Docker: Check for work container
    alt Container exists
        Docker->>WorkContainer: Reuse existing
    else Container doesn't exist
        Docker->>WorkContainer: Build new
    end
    WorkContainer->>User: tmux session (read-only .devcontainer)

    User->>BitBot: bitbot config
    BitBot->>Docker: Check for config container
    alt Container exists
        Docker->>ConfigContainer: Reuse existing
    else Container doesn't exist
        Docker->>ConfigContainer: Build new (with AI + config tools, no Docker inside)
    end
    ConfigContainer->>User: tmux session (AI-assisted config, read-write .devcontainer)

    Note over WorkContainer,ConfigContainer: Both can run simultaneously!
```

---

## Simultaneous Operation

### Both Modes Active

Work and config mode containers **can run at the same time**:

- Separate container instances
- Shared workspace on host
- No conflicts (different tmux sessions)

### Use Case

1. **Terminal 1**: `bitbot work` - Coding with AI
2. **Terminal 2**: `bitbot config` - Editing Dockerfile
3. **Result**: Safe infrastructure changes without disrupting development

---

## Git Safety Integration

Both modes integrate git safety checks:

```mermaid
flowchart TD
    START[bitbot work/config]
    GITCHECK{Git status<br/>check}
    UNCOMMITTED{Uncommitted<br/>changes?}
    WARN[Display warning]
    SKIP{Skip flag<br/>set?}
    LAUNCH[Launch container]

    START --> GITCHECK
    GITCHECK --> UNCOMMITTED
    UNCOMMITTED -->|Yes| WARN
    UNCOMMITTED -->|No| LAUNCH
    WARN --> SKIP
    SKIP -->|--skip-git-check| LAUNCH
    SKIP -->|No flag| LAUNCH

    style WARN fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
```

**Protection**: Non-blocking warnings prevent accidental loss of uncommitted work

---

## Design Decisions

### Why Two Separate Containers?

- **Security**: AI cannot accidentally modify infrastructure
- **Simplicity**: Clear separation of concerns
- **Flexibility**: Can run both simultaneously
- **Safety**: Infrastructure changes are intentional, not accidental

### Why Read-Only Mount?

- **Protection**: Filesystem-level enforcement (not just convention)
- **Reliability**: Cannot be bypassed by AI or user error
- **Visibility**: Clear error messages if write attempted

### Why Not Runtime Mode Switching?

- **Complexity**: Runtime switching adds state management
- **Security**: Mode boundaries less clear
- **Simplicity**: Separate containers = separate contexts

---

## References

- **SPEC-02**: Security Mode System specification
- **SPEC-02A**: Git Safety Integration
- **D-11**: Decision to use containers instead of sketch mode