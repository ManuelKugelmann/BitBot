# Container BitBot

Container-side BitBot scripts that run inside devcontainers to assist AI agents with session management and workspace tasks.

## Overview

Container BitBot provides the same `bitbot` command inside containers, creating a **transparent user experience**:
- **On Host**: `bitbot` orchestrates containers (launch/enter containers)
- **In Container**: `bitbot` manages sessions (start/resume Claude Code)

Same command name, context-aware behavior!

## Purpose

- **Session Management**: Start and resume Claude Code in tmux sessions
- **Workspace Analysis**: Detect tech stack and project structure
- **Environment Status**: Show container configuration and tools
- **DevContainer Config**: Assist with .devcontainer setup (config mode)

## Structure

Mirrors outer bitbot structure for consistency:

```
container/bitbot/              # Source (copied to container)
├── bitbot                     # Entry point (same name as host)
└── core/                      # Mirrors outer core/ structure
    ├── commands/              # Command implementations
    │   ├── start.sh           # Start Claude session in tmux
    │   ├── resume.sh          # Resume existing tmux session
    │   ├── analyze.sh         # Analyze workspace
    │   ├── status.sh          # Show container status
    │   └── configure.sh       # DevContainer configuration helper
    └── util/                  # Shared utilities
        ├── helpers.sh         # Common functions (colors, errors, etc.)
        └── tmux-utils.sh      # tmux session management
```

## Installation

Container BitBot is automatically installed during container build:

```dockerfile
# In container/templates/base/Dockerfile (or custom template)
COPY container/bitbot/ /opt/bitbot/
RUN chmod +x /opt/bitbot/bitbot /opt/bitbot/core/commands/*.sh
ENV PATH="/opt/bitbot:${PATH}"
```

Once installed, users can run `bitbot` directly inside containers.

## Usage

### Session Management

```bash
# Start new Claude Code session (with launch mode choice)
bitbot start

# Resume existing session (auto-select or menu)
bitbot resume

# Resume specific session
bitbot resume claude-20251022-1430
```

### Workspace Analysis

```bash
# Analyze workspace tech stack
bitbot analyze

# Show container environment status
bitbot status
```

### DevContainer Configuration

```bash
# Get devcontainer configuration help (config mode)
bitbot configure
```

### Help

```bash
# Show available commands
bitbot help
```

## Session Management Features

**Start Command**:
1. Checks for existing tmux sessions
2. Offers to resume or create new
3. Asks for launch mode:
   - `--resume`: Resume previous Claude session
   - Interactive: Fresh interactive session
   - Custom: User-specified command
4. Creates tmux session and launches Claude
5. Attaches to session

**Resume Command**:
1. Lists existing tmux sessions
2. If name provided: attaches to that session
3. If one session: auto-attaches
4. If multiple sessions: shows selection menu

## Transparent Behavior

The `bitbot` command adapts to its environment:

| Location    | Command         | Behavior                          |
|-------------|-----------------|-----------------------------------|
| **Host**    | `bitbot`        | Enter work mode container         |
| **Host**    | `bitbot work`   | Launch work mode container        |
| **Host**    | `bitbot config` | Launch config mode container      |
| **Host**    | `bitbot init`   | Initialize workspace              |
| **Container** | `bitbot`      | Start Claude session (= `bitbot start`) |
| **Container** | `bitbot start`| Create new Claude session in tmux |
| **Container** | `bitbot resume`| Resume existing tmux session     |
| **Container** | `bitbot analyze`| Analyze workspace               |
| **Container** | `bitbot status`| Show container status            |

## Mode-Specific Behavior

**Work Mode** (default):
- Workspace analysis and git status
- Start/resume Claude Code sessions
- Read-only access to .devcontainer
- Focus: application development

**Config Mode** (infrastructure):
- DevContainer configuration assistance
- Tech stack detection and recommendations
- Read-write access to .devcontainer
- Focus: infrastructure setup

## Design Principles

- **Transparent**: Same command name on host and container
- **Non-intrusive**: Helpers are optional, never required
- **Simple**: Plain bash scripts, minimal dependencies
- **Safe**: No destructive operations without confirmation
- **Helpful**: Clear prompts and sensible defaults

## Dependencies

- **tmux**: Session management (installed in container)
- **Claude Code**: AI assistant (installed in container)
- **bash**: Script runtime (standard)

## Implementation Status

**Implemented**:
- ✅ Core structure (bitbot + core/)
- ✅ Analyze command (workspace detection)
- ✅ Status command (environment info)
- ✅ Configure command (devcontainer help)
- ✅ Utility functions (helpers, tmux)

**TODO** (see `sparc/2-pseudocode/INNER_BITBOT.md`):
- [ ] Start command (full implementation)
- [ ] Resume command (full implementation)
- [ ] Container entrypoint script
- [ ] Session persistence across restarts

## Documentation

- **Pseudocode**: `sparc/2-pseudocode/INNER_BITBOT.md`
- **Flow Diagrams**: `sparc/2-pseudocode/FLOW_INNER_BITBOT.md`
- **Architecture**: `sparc/3-architecture/`

## See Also

- **Outer BitBot**: `bitbot` (host-side entry point)
- **Core Implementation**: `core/` (host-side scripts)
- **Templates**: `container/templates/` (devcontainer templates)
- **Specifications**: `sparc/1-specification/`
