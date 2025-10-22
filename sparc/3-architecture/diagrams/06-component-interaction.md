# Component Interaction

How BitBot's core components interact to deliver functionality.

```mermaid
graph TB
    subgraph ENTRY["Entry"]
        BITBOT[bitbot]
    end

    subgraph HAND["Handlers"]
        GLOBAL[Global]
        WORKSPACE[Workspace]
    end

    subgraph GCMD["Global Cmds"]
        GINIT[init.sh]
        VERSION[version.sh]
    end

    subgraph WCMD["Workspace Cmds"]
        WINIT[init.sh]
        WWORK[work.sh]
        WCONFIG[config.sh]
        WHELP[help.sh]
        WVSCODE[vscode.sh]
    end

    subgraph UTIL["Utilities"]
        DETECT[detect.sh]
        GIT[git.sh]
        HELPERS[helpers.sh]
        PREREQ[prereq.sh]
        DEVCON[devcontainer.sh]
        LOGO[logo.sh]
    end

    BITBOT --> GLOBAL
    BITBOT --> WORKSPACE

    GLOBAL --> GINIT
    GLOBAL --> VERSION

    WORKSPACE --> WINIT
    WORKSPACE --> WWORK
    WORKSPACE --> WCONFIG
    WORKSPACE --> WHELP
    WORKSPACE --> WVSCODE

    GINIT --> PREREQ
    GINIT --> HELPERS
    GINIT --> LOGO

    WINIT --> DETECT
    WINIT --> HELPERS

    WWORK --> DETECT
    WWORK --> GIT
    WWORK --> DEVCON
    WWORK --> HELPERS

    WCONFIG --> DETECT
    WCONFIG --> GIT
    WCONFIG --> DEVCON
    WCONFIG --> HELPERS

    WHELP --> LOGO
    WHELP --> HELPERS

    WVSCODE --> DETECT
    WVSCODE --> HELPERS

    VERSION --> HELPERS

    style BITBOT fill:#ffd700,stroke:#333,stroke-width:3px,color:#333
    style WWORK fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style WCONFIG fill:#ffb6c1,stroke:#333,stroke-width:2px,color:#333
    style DETECT fill:#4a9eff,stroke:#333,stroke-width:2px
    style GIT fill:#ef5350,stroke:#333,stroke-width:2px,color:#333
    style DEVCON fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style HELPERS fill:#ffd700,stroke:#333,stroke-width:2px,color:#333
```

## Component Responsibilities

### Main Router (bitbot)

**File**: `/bitbot`
**Purpose**: Route commands to appropriate handlers
**Dependencies**: None (sources handlers as needed)

```bash
# Routes commands
case "$COMMAND" in
    init)      # Global or workspace?
    work)      # Workspace command
    config)    # Workspace command
    vscode)    # Workspace command
    help)      # Workspace command
    version)   # Global command
esac
```

---

### Global Commands

#### bitbot-init.sh (Global)
**File**: `/core/global/bitbot-init.sh`
**Purpose**: First-run system-wide setup
**Dependencies**: `prerequisites.sh`, `helpers.sh`, `logo.sh`

**Responsibilities**:
- Check prerequisites (Docker, VS Code, WSL)
- Display welcome message
- Guide user through setup
- No actual installation (just validation)

---

#### bitbot-version.sh
**File**: `/core/bitbot-version.sh`
**Purpose**: Display version information
**Dependencies**: `helpers.sh`

**Responsibilities**:
- Read VERSION file
- Display formatted version
- Show system information

---

### Workspace Commands

#### bitbot-init.sh (Workspace)
**File**: `/core/workspace/bitbot-init.sh`
**Purpose**: Initialize new workspace
**Dependencies**: `detect.sh`, `helpers.sh`

**Responsibilities**:
- Detect if workspace already exists
- Prompt for template selection
- Copy template files
- Create `.devcontainer/` structure

---

#### bitbot-work.sh
**File**: `/core/workspace/bitbot-work.sh`
**Purpose**: Launch work mode container
**Dependencies**: `detect.sh`, `git.sh`, `devcontainer.sh`, `helpers.sh`

**Responsibilities**:
- Detect workspace
- Run git safety checks
- Launch work mode container (read-only `.devcontainer`)
- Attach to tmux session

---

#### bitbot-config.sh
**File**: `/core/workspace/bitbot-config.sh`
**Purpose**: Launch config mode container
**Dependencies**: `detect.sh`, `git.sh`, `devcontainer.sh`, `helpers.sh`

**Responsibilities**:
- Detect workspace
- Run git safety checks
- Launch config mode container (read-write `.devcontainer`)
- Attach to tmux session

---

#### bitbot-help.sh
**File**: `/core/workspace/bitbot-help.sh`
**Purpose**: Display help information
**Dependencies**: `logo.sh`, `helpers.sh`

**Responsibilities**:
- Display BitBot logo
- Show command reference
- Display examples
- Show version info

---

#### bitbot-vscode.sh
**File**: `/core/workspace/bitbot-vscode.sh`
**Purpose**: Open VS Code in container
**Dependencies**: `detect.sh`, `helpers.sh`

**Responsibilities**:
- Detect workspace
- Detect platform (Windows/macOS/Linux)
- Hex-encode workspace path
- Launch VS Code with container URI

---

### Utilities

#### detect.sh
**File**: `/core/util/detect.sh`
**Purpose**: Workspace detection
**Dependencies**: None

**Functions**:
```bash
detect_workspace()         # Find .devcontainer in CWD or parent
validate_workspace()       # Validate .devcontainer structure
get_workspace_path()       # Return workspace absolute path
```

**Used by**:
- `bitbot-init.sh` (workspace)
- `bitbot-work.sh`
- `bitbot-config.sh`
- `bitbot-vscode.sh`

---

#### git.sh
**File**: `/core/util/git.sh`
**Purpose**: Git safety checks
**Dependencies**: None

**Functions**:
```bash
check_git_safety()         # Check for uncommitted changes
warn_uncommitted()         # Display warning message
should_skip_git_check()    # Check for skip flags
```

**Used by**:
- `bitbot-work.sh`
- `bitbot-config.sh`

---

#### helpers.sh
**File**: `/core/util/helpers.sh`
**Purpose**: Common utility functions
**Dependencies**: None

**Functions**:
```bash
log_info()                 # Info message
log_warn()                 # Warning message
log_error()                # Error message
check_command()            # Check if command exists
get_platform()             # Detect OS platform
```

**Used by**: All components

---

#### prerequisites.sh
**File**: `/core/util/prerequisites.sh`
**Purpose**: Dependency validation
**Dependencies**: `helpers.sh`

**Functions**:
```bash
check_docker()             # Verify Docker available
check_vscode()             # Verify VS Code installed
check_wsl()                # Verify WSL2 (Windows only)
check_devcontainer_ext()   # Verify Dev Containers extension
check_all_prerequisites()  # Run all checks
```

**Used by**:
- `bitbot-init.sh` (global)

---

#### devcontainer.sh
**File**: `/core/util/devcontainer.sh`
**Purpose**: DevContainer CLI wrapper
**Dependencies**: `helpers.sh`

**Functions**:
```bash
launch_devcontainer()      # Build and start container
attach_devcontainer()      # Attach to running container
stop_devcontainer()        # Stop container
get_container_id()         # Get container ID for workspace
```

**Used by**:
- `bitbot-work.sh`
- `bitbot-config.sh`

---

#### logo.sh
**File**: `/core/util/logo.sh`
**Purpose**: ASCII logo display
**Dependencies**: None

**Functions**:
```bash
print_bitbot_logo()        # Display ASCII logo
```

**Used by**:
- `bitbot-init.sh` (global)
- `bitbot-help.sh`

---

## Data Flow

### work Command Flow

```mermaid
sequenceDiagram
    participant User
    participant bitbot
    participant detect
    participant git
    participant devcontainer
    participant Docker

    User->>bitbot: bitbot work
    bitbot->>detect: detect_workspace()
    detect-->>bitbot: path
    bitbot->>git: check_safety()
    git-->>bitbot: warnings
    bitbot->>devcontainer: launch(work)
    devcontainer->>Docker: run (ro .devcontainer)
    Docker-->>devcontainer: id
    devcontainer->>Docker: exec tmux
    Docker-->>User: session
```

---

### config Command Flow

```mermaid
sequenceDiagram
    participant User
    participant bitbot
    participant detect
    participant git
    participant devcontainer
    participant Docker

    User->>bitbot: bitbot config
    bitbot->>detect: detect_workspace()
    detect-->>bitbot: path
    bitbot->>git: check_safety()
    git-->>bitbot: warnings
    bitbot->>devcontainer: launch(config)
    devcontainer->>Docker: run (rw .devcontainer)
    Docker-->>devcontainer: id
    devcontainer->>Docker: exec tmux
    Docker-->>User: session
```

---

### vscode Command Flow

```mermaid
sequenceDiagram
    participant User
    participant bitbot
    participant detect
    participant vscode
    participant VSCode

    User->>bitbot: bitbot vscode
    bitbot->>detect: detect_workspace()
    detect-->>bitbot: path
    bitbot->>vscode: open_devcontainer()
    vscode->>vscode: detect_platform()
    vscode->>vscode: hex_encode()
    vscode->>vscode: build_uri()
    vscode->>VSCode: code --folder-uri
    VSCode-->>User: Opens ✓
```

---

### init Command Flow (Workspace)

```mermaid
sequenceDiagram
    participant User
    participant bitbot
    participant detect
    participant init
    participant Templates

    User->>bitbot: bitbot init
    bitbot->>detect: detect_workspace()
    detect-->>bitbot: not found
    bitbot->>init: initialize()
    init->>User: Select template
    User-->>init: basic
    init->>Templates: Copy basic
    Templates-->>init: created
    init-->>User: Initialized!
```

---

## Dependency Graph

```mermaid
graph TB
    subgraph L0["Level 0"]
        DETECT[detect.sh]
        GIT[git.sh]
        LOGO[logo.sh]
    end

    subgraph L1["Level 1"]
        HELPERS[helpers.sh]
    end

    subgraph L2["Level 2"]
        PREREQ[prereq.sh]
        DEVCON[devcontainer]
    end

    subgraph L3["Level 3"]
        GINIT[Global init]
        VERSION[Version]
        WINIT[WS init]
        WORK[Work]
        CONFIG[Config]
        HELP[Help]
        VSCODE[VS Code]
    end

    subgraph L4["Level 4"]
        BITBOT[bitbot]
    end

    DETECT -.-> HELPERS
    GIT -.-> HELPERS
    LOGO -.-> HELPERS

    PREREQ --> HELPERS
    DEVCON --> HELPERS

    GINIT --> PREREQ
    GINIT --> HELPERS
    GINIT --> LOGO

    VERSION --> HELPERS

    WINIT --> DETECT
    WINIT --> HELPERS

    WORK --> DETECT
    WORK --> GIT
    WORK --> DEVCON
    WORK --> HELPERS

    CONFIG --> DETECT
    CONFIG --> GIT
    CONFIG --> DEVCON
    CONFIG --> HELPERS

    HELP --> LOGO
    HELP --> HELPERS

    VSCODE --> DETECT
    VSCODE --> HELPERS

    BITBOT --> GINIT
    BITBOT --> VERSION
    BITBOT --> WINIT
    BITBOT --> WORK
    BITBOT --> CONFIG
    BITBOT --> HELP
    BITBOT --> VSCODE

    style HELPERS fill:#ffd700,stroke:#333,stroke-width:2px,color:#333
    style BITBOT fill:#4a9eff,stroke:#333,stroke-width:3px
    style WORK fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style CONFIG fill:#ffb6c1,stroke:#333,stroke-width:2px,color:#333
    style GIT fill:#ef5350,stroke:#333,stroke-width:2px,color:#333
```

---

## Shared State

### No Global State
BitBot avoids global configuration files:
- No `~/.bitbot` config
- No global workspace registry
- All state in workspace directory

### Workspace State
All configuration stored in workspace:
```
workspace/
├── .devcontainer/
│   ├── devcontainer.json    # Container config
│   └── Dockerfile           # Build instructions
└── .bitbot/                 # (future) workspace metadata
    └── config.json
```

---

## Environment Variables

### Used by BitBot

| Variable         | Purpose                    | Set by           |
|------------------|----------------------------|------------------|
| `BITBOT_HOME`    | BitBot installation path   | Entry script     |
| `WORKSPACE_PATH` | Current workspace          | detect.sh        |
| `PLATFORM`       | OS platform (wsl/macos/linux) | helpers.sh    |
| `SKIP_GIT_CHECK` | Skip git safety            | User (flag)      |

### Not Modified
BitBot does not modify:
- `PATH`
- `HOME`
- `USER`
- Any global environment variables

---

## Error Propagation

```bash
# Commands return non-zero on error
detect_workspace || exit 1

# Errors bubble up through call stack
bitbot work
  → detect_workspace  # Error: no workspace
    → exit 1
  → (bitbot exits)
```

**Error Handling Strategy**:
- Functions return non-zero on error
- Calling code checks return values
- User-friendly error messages displayed
- No silent failures

---

## Design Principles

### Modularity
- Each script has single responsibility
- Clear interfaces between components
- Minimal dependencies

### Reusability
- Utilities shared across commands
- Common patterns in helpers.sh
- No code duplication

### Testability
- Functions can be tested independently
- Clear inputs and outputs
- Minimal side effects

### Maintainability
- Clear component boundaries
- Well-documented interfaces
- Predictable behavior

---

## References

- **Specifications**: `../1-specification/`
- **Pseudocode**: `../2-pseudocode/`
- **Implementation**: `/core/`
