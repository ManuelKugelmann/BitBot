# BitBot Container Templates

Developer documentation for BitBot's container template system.

## Overview

BitBot uses DevContainer templates to provide consistent, isolated development environments.
All templates are in `container/templates/` and share a common structure.

---

## Template Structure

Each template contains:
- `Dockerfile` - Container image definition
- `devcontainer.json` - VS Code DevContainer configuration
- `details.devcontainer.json` - Template-specific settings
- Optional: `scripts/` - Post-create and setup scripts
- Optional: `home/` - Shared home folder configurations

Templates are merged with `container/templates/bitbot-base/devcontainer.json` during build.

---

## Base Template

**Location**: `container/templates/base/`
**Purpose**: Minimal Ubuntu-based environment with essential tools

### What's Included
- Ubuntu 22.04 LTS
- Git, curl, Node.js LTS
- Claude Code CLI
- tmux with BitBot status bar
- Root user (development mode)

### Usage
Automatically copied during `bitbot init`. Users customize by editing `.devcontainer/` in their workspace.

### Customization Examples

**Add packages**:
```dockerfile
RUN apt-get update && apt-get install -y \
    python3 python3-pip build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Add VS Code extensions** (`devcontainer.json`):
```json
{
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python", "dbaeumer.vscode-eslint"]
    }
  }
}
```

---

## BitBot Dev Template

**Location**: `container/templates/bitbotdev/`
**Purpose**: Development environment for BitBot itself (dogfooding)

### What's Included
- Base template features
- **MinGW-w64** - Windows cross-compiler
- gcc, make, build tools
- C/C++ VS Code extensions
- Shared AI config folders (`.claude/`, `.claude-flow/`, `.opencode/`)

### Cross-Compilation

**Compile Windows launcher**:
```bash
cd dev/src/launcher_windows
./build.sh

# Or manually
x86_64-w64-mingw32-gcc launcher.c -o launcher.exe -Os -s
```

**Verify**:
```bash
file launcher.exe  # Should show: PE32+ executable (console) x86-64
ls -lh launcher.exe  # Should be ~38KB
```

### Shared Home Folders

Persistent AI tool configurations mounted to `/root/`:
```
.devcontainer/home/
  .claude/       → /root/.claude
  .claude-flow/  → /root/.claude-flow
  .opencode/     → /root/.opencode
```

Benefits:
- Survive container rebuilds
- Shared across BitBot dev sessions
- Version-controlled (optional)

### Building BitBot

```bash
# Build launcher
cd dev/src/launcher_windows && ./build.sh

# Run tests
cd dev/tests && ./run-tests.sh

# Run specific test
dev/tests/test-container-bitbot.sh
```

---

## Shared Resources

**Location**: `container/templates/shared/`
**Purpose**: Scripts and configs used by all templates

### Contents

- `scripts/` - Build and setup automation
  - `install-dev-tools.sh` - Development tools
  - `install-ai-tools.sh` - AI tool installation (optional)
  - `merge-devcontainer.sh` - Template merge utility
  - `merge-all.sh` - Regenerate all templates

### Template Merging

Templates use `merge-devcontainer.sh` to combine base and template-specific configs:

```bash
# Merge base + bitbotdev details → bitbotdev/devcontainer.json
container/templates/scripts/merge-devcontainer.sh container/templates/bitbotdev

# This merges:
# - bitbot-base/devcontainer.json (common settings)
# - bitbotdev/details.devcontainer.json (template-specific)
# → bitbotdev/devcontainer.json (final)
```

**Why merge?**
- DRY: Common settings defined once in `bitbot-base/devcontainer.json`
- Maintainability: Update base settings, regenerate all templates
- Flexibility: Each template adds its specific features via `details.devcontainer.json`

### JQ Installation

`INSTALL_JQ.md` documents jq installation (needed for JSON merging). Used by merge scripts.

---

## Container BitBot Runtime

**Location**: `container/bitbot/`
**Purpose**: Container-side BitBot scripts (commands, utilities)

### Structure

```
container/bitbot/
├── bitbot                   # Entry point (same name as host)
└── core/
    ├── commands/            # Command implementations
    │   ├── start.sh        # Start Claude session in tmux
    │   ├── resume.sh       # Resume existing tmux session
    │   ├── analyze.sh      # Analyze workspace
    │   ├── status.sh       # Show container status
    │   └── configure.sh    # DevContainer configuration helper
    └── util/                # Shared utilities
        ├── helpers.sh      # Common functions (colors, errors)
        └── tmux-utils.sh   # tmux session management
```

### Installation in Templates

```dockerfile
# Dockerfile - Copy BitBot runtime to container
COPY container/bitbot/ /opt/bitbot/
RUN chmod +x /opt/bitbot/bitbot /opt/bitbot/core/commands/*.sh
ENV PATH="/opt/bitbot:${PATH}"
```

### Transparent Behavior

Same command name, context-aware behavior:

| Location | Command | Behavior |
|----------|---------|----------|
| **Host** | `bitbot` | Enter work mode container |
| **Host** | `bitbot work` | Launch work mode container |
| **Host** | `bitbot config` | Launch config mode container |
| **Container** | `bitbot` | Start Claude session |
| **Container** | `bitbot start` | Create new Claude session in tmux |
| **Container** | `bitbot resume` | Resume existing tmux session |
| **Container** | `bitbot analyze` | Analyze workspace tech stack |
| **Container** | `bitbot status` | Show container status |

### Mode-Specific Behavior

**Work Mode** (default):
- Workspace analysis and git status
- Start/resume Claude Code sessions
- Read-only `.devcontainer` access
- Focus: application development

**Config Mode** (infrastructure):
- DevContainer configuration assistance
- Tech stack detection
- Read-write `.devcontainer` access
- Focus: infrastructure setup

### Design Principles

- **Transparent**: Same command name on host and container
- **Non-intrusive**: Helpers optional, never required
- **Simple**: Plain bash, minimal dependencies
- **Safe**: No destructive operations without confirmation

---

## Adding New Templates

1. **Create template directory**: `container/templates/mytemplate/`
2. **Create Dockerfile**: Based on base template, add your customizations
3. **Create details.devcontainer.json**: Template-specific features/extensions
4. **Generate devcontainer.json**: Run `scripts/merge-devcontainer.sh`
5. **Test**: Build container and validate functionality
6. **Document**: Add template overview to this file

---

## See Also

- **Specifications**: `sparc/1-specification/` - Requirements and design
- **Pseudocode**: `sparc/2-pseudocode/` - Algorithm implementations
- **Architecture**: `sparc/3-architecture/` - System design diagrams
- **User Docs**: Root `README.md` - End-user documentation
