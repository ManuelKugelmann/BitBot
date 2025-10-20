# VS Code DevContainer Integration Specification

**Feature ID**: SPEC-06
**Priority**: P1 (Important)
**Status**: In Progress (Windows implementation complete, macOS/Linux pending)
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes), SPEC-04 (Session Management)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

VS Code Remote Containers integration for BitBot. Single container reusable by both CLI and VS Code. Mode switching works from VS Code terminal. Proper labels for container attachment.

**Key Design**: Direct container opening via hex-encoded URIs + VS Code labels + terminal integration + mode awareness = seamless VS Code experience.

**Breakthrough**: Direct dev container opening via `--folder-uri` eliminates "Reopen in Container" popup, simplifies architecture, and lets VS Code handle all container lifecycle management.

**Cross-Platform**: Helper utilities (`Open-VSCodeDevContainer.ps1`, `vscode-devcontainer-utils.sh`) provide consistent interface across Windows/WSL, macOS, and Linux.

---

## 0. VS Code Direct DevContainer Opening 

**Status**: ✅ **Implemented and tested (Windows)** | ⏳ **Pending (macOS/Linux)**

### 0.1 Overview

BitBot uses VS Code's `--folder-uri` parameter with hex-encoded URIs to open projects directly in dev containers, bypassing the manual "Reopen in Container" popup.

**Format**:
```bash
code --folder-uri="vscode-remote://dev-container+{HEX_ENCODED_PATH}{CONTAINER_PATH}"
```

**Example**:
```bash
# Windows path: C:\Projects\BitBot
# Hex encoded:   433a5c50726f6a656374735c4269744...
# Container:     /workspace

code.exe --folder-uri="vscode-remote://dev-container+433a5c50726f6a656374735c4269744.../workspace"

# Result: VS Code opens DIRECTLY in dev container (no popup!)
```

### 0.2 Benefits Over Manual devcontainer CLI

| Aspect                | Manual Approach         | Direct URI Approach       |
|-----------------------|------------------------|---------------------------|
| User action           | Click "Reopen" popup   | None (automatic)          |
| Containers created    | 2 (CLI + VS Code)      | 1 (VS Code only)          |
| Code complexity       | ~190 lines             | ~100 lines (-47%)         |
| Dependencies          | Docker, Node, CLI      | VS Code only              |
| WSL corruption risk   | Yes (Docker commands)  | No (no Docker commands)   |
| Container reuse       | Different hashes       | Same container reused     |

### 0.3 Cross-Platform Implementation

**Utility Scripts** (Located in `test-windows-launch/`):
- `Open-VSCodeDevContainer.ps1` - PowerShell utility (Windows/Linux/macOS with pwsh)
- `vscode-devcontainer-utils.sh` - Bash utility (WSL/Linux/macOS)

**Platform Compatibility**:

| Platform        | PowerShell Script | Bash Script | Notes                          |
|-----------------|-------------------|-------------|--------------------------------|
| ✅ Windows       | Native            | Via WSL     | PowerShell 5.1+ built-in      |
| ✅ WSL           | Via pwsh          | Native      | Both work, bash preferred      |
| ✅ Linux         | Via pwsh          | Native      | Requires PowerShell Core      |
| ✅ macOS         | Via pwsh          | Native      | Requires PowerShell Core      |

**Hex Encoding (PowerShell)**:
```powershell
# Pure .NET encoding (no bash dependencies)
function Convert-PathToHex {
    param([string]$Path)

    $absPath = [System.IO.Path]::GetFullPath($Path)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($absPath)
    $hexPath = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''

    return $hexPath
}
```

**Hex Encoding (Bash)**:
```bash
# Auto-fallback for Alpine/minimal systems
path_to_hex() {
    local path="$1"

    if command -v xxd &> /dev/null; then
        # Preferred (faster, cleaner)
        printf "%s" "$path" | xxd -p -c 256 | tr -d '\n'
    else
        # Fallback (universal, available in Alpine)
        printf "%s" "$path" | od -A n -t x1 | tr -d ' \n'
    fi
}
```

**Platform-Specific Path Handling**:
```bash
case "$(detect_platform)" in
    wsl)
        # CRITICAL: VS Code expects Windows paths in labels
        windows_path=$(wslpath -w "/mnt/c/Projects/BitBot")  # C:\Projects\BitBot
        hex_path=$(path_to_hex "$windows_path")
        code.exe --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        ;;
    macos|linux)
        # Native Unix paths
        hex_path=$(path_to_hex "$native_path")
        code --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        ;;
esac
```

### 0.4 Container Hash Differences & VS Code Injections

**Why VS Code creates different containers than devcontainer CLI**:

**Manual `devcontainer up`**:
- Mounts: `/workspace`, `/workspaces/BitBot`
- Image hash: `vsc-test-78977c62...`

**VS Code build**:
- Mounts: `/workspace`, `/workspaces/BitBot`, `/vscode` (VS Code Server), Wayland socket
- Image hash: `vsc-test-a4656483...` (different!)

**Root cause**: VS Code adds extra configuration during build:
1. `/vscode` volume for VS Code Server installation
2. Wayland/X11 sockets for GUI forwarding
3. Additional labels and environment variables
4. Different base image layers

**Decision**: ✅ Let VS Code build its own container with required mounts. VS Code knows what it needs.

**Testing Result**: Attempting to match VS Code's exact hash is impractical. Instead, use direct URI opening which lets VS Code build once and reuse.

**Future enhancement**: Research hash matching to enable CI/CD pre-builds (see `test-windows-launch/TODO-HASH-MATCHING.md`)

### 0.5 Windows Path Label Strategy (Method 3)

**Critical Finding**: VS Code on Windows uses Windows path format (`C:\...`) in container labels, not WSL paths (`/mnt/c/...`).

**Root Cause of Path Corruption**:
- Calling `devcontainer` (Node.js script) creates WSL paths in labels
- Calling `devcontainer.cmd` (Windows wrapper) creates Windows paths in labels
- **The `.cmd` wrapper is required**, regardless of which WSL distro is used

**Three Methods Tested**:

| Method | Command                                                          | Label Format | VS Code Reuse |
|--------|------------------------------------------------------------------|--------------|---------------|
| 1      | `wsl bash -c "devcontainer up ..."`                             | WSL paths    | ❌ No          |
| 2      | `devcontainer.cmd up --workspace-folder "C:\..."`               | Windows      | ✅ Yes         |
| 3      | `wsl bash -c "cmd.exe /c 'cd /d C:\... && devcontainer.cmd'"` | Windows      | ✅ Yes         |

**Decision**: ✅ Method 3 chosen (bash-centric approach, produces Windows labels)

**Why Method 3**:
- Works from bash scripts (aligns with BitBot's bash-centric design)
- Produces Windows path labels that match VS Code expectations
- Uses VS Code's bundled `devcontainer.cmd` wrapper (critical for correct paths)
- Works from any WSL distro (Ubuntu, Alpine, Debian, etc.)
- Avoids quote escaping hell via `cd /d` pattern
- **Latest tests confirm full interoperability** ✅

**Implementation** (`bitbot-core.sh`):
```bash
# Get VS Code's devcontainer CLI (cross-platform)
get_devcontainer_cli() {
    case "$(detect_platform)" in
        wsl)
            local winuser=$(get_windows_user)
            echo "/mnt/c/Users/$winuser/AppData/Roaming/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer.cmd"
            ;;
        macos)
            echo "$HOME/Library/Application Support/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer"
            ;;
        linux)
            echo "$HOME/.vscode/extensions/ms-vscode-remote.remote-containers-*/dev-containers-user-cli/cli"
            ;;
    esac
}
```

**Note**: Method 3 is primarily for CLI-initiated container builds. The direct URI approach (0.1-0.3) is preferred for BitBot's `bitbot vscode` command as it's simpler and more reliable.

### 0.6 Windows Multi-Entry-Point Strategy

**BitBot on Windows supports three entry points**:

#### Entry Point 1: PowerShell (Native Windows)

```powershell
# bitbot.ps1
$workspacePath = (Get-Location).Path
wsl bash -c "cmd.exe /c 'cd /d $workspacePath && devcontainer.cmd up --workspace-folder .'"
```

**Use case**: Native Windows users, PowerShell workflows, automation scripts

---

#### Entry Point 2: CMD (Native Windows)

```cmd
@echo off
REM bitbot.cmd
set WORKSPACE=%CD%
devcontainer.cmd up --workspace-folder "%WORKSPACE%"
```

**Use case**: Legacy Windows scripts, batch files, Windows-only environments

---

#### Entry Point 3: WSL Bash (Any WSL Distro)

```bash
#!/bin/bash
# bitbot (runs in WSL)
workspace_win=$(wslpath -w "$PWD")
cmd.exe /c "cd /d $workspace_win && devcontainer.cmd up --workspace-folder ."
```

**Use case**: Bash-centric users, cross-platform consistency, BitBot-Alpine (optional isolation)

**Key point**: All three entry points use `devcontainer.cmd` wrapper to ensure Windows path labels.

---

### 0.7 Simplified Dependencies

**Direct URI Approach (Recommended)**:
- ✅ VS Code with Dev Containers extension (already required)
- ✅ bash + git (for BitBot features)
- ✅ coreutils (`od` for hex encoding)
- ✅ No Docker/Node.js in WSL needed

**Method 3 Approach (CLI-initiated builds)**:
- ✅ VS Code with Dev Containers extension
- ✅ bash (any WSL distro or BitBot-Alpine)
- ✅ WSL interop (calls Windows `devcontainer.cmd`)
- ✅ No separate `@devcontainers/cli` installation needed

**BitBot-Alpine (Optional)**:
- Provides **isolation and clean environment** (~8MB)
- Does **not** prevent path corruption (`.cmd` wrapper does)
- Users can choose their own WSL distro

### 0.8 Testing Results

**Test environment**: Windows 11 + WSL2 (Ubuntu-22.04 and BitBot-Alpine)

**Scenario 1: Direct URI (PowerShell)**
```powershell
.\test-direct-open.ps1
```
- ✅ VS Code opens directly in dev container
- ✅ No "Reopen in Container" popup
- ✅ Terminal at `/workspace`
- ✅ Bottom-left shows "Dev Container: BitBot Test"

**Scenario 2: Method 3 (WSL → cmd.exe → devcontainer.cmd)**
```powershell
# Works in ANY WSL distro (Ubuntu, Alpine, Debian, etc.)
wsl bash -c "cmd.exe /c 'cd /d C:\\Projects\\BitBot && devcontainer.cmd up --workspace-folder .'"
```
- ✅ Windows path labels created correctly
- ✅ VS Code discovers and reuses containers
- ✅ No path corruption (`.cmd` wrapper ensures Windows paths)
- ✅ Works from bash scripts
- ✅ **Full interoperability confirmed** ✅

**Scenario 3: Direct URI from WSL**
```bash
# From any WSL distro or BitBot-Alpine
./vscode-devcontainer-utils.sh
open_vscode_devcontainer "C:\Projects\BitBot"
```
- ✅ Hex encoding works in WSL (using `xxd` or `od`)
- ✅ WSL interop calls Windows code.exe successfully
- ✅ VS Code opens directly in dev container
- ✅ **Container reuse confirmed** (same container ID on subsequent opens)

**Scenario 3: Label Discovery & Reuse**
```powershell
.\test-vscode-discovery-final.ps1
```
- ✅ Method 3 produces Windows path labels
- ✅ VS Code detects and reuses same container
- ✅ No rebuild on subsequent opens
- ✅ Container count remains 1 (no duplicates)

**Platforms tested**:
- ✅ Windows 11 + WSL2 (Ubuntu-22.04 default + BitBot-Alpine)
- ⏳ macOS (TODO)
- ⏳ Linux native (TODO)

### 0.8 Implementation References

**Utility Scripts**:
- `test-windows-launch/Open-VSCodeDevContainer.ps1` - PowerShell utility
- `test-windows-launch/vscode-devcontainer-utils.sh` - Bash utility
- `test-windows-launch/README-VSCODE-UTILS.md` - Usage documentation

**Core Implementation**:
- `test-windows-launch/bitbot-core.sh` - BitBot core logic with direct URI opening

**Test Scripts**:
- `test-windows-launch/test-vscode-discovery-final.ps1` - Label discovery validation
- `test-windows-launch/test-vscode-auto.ps1` - Automated VS Code launch
- `test-windows-launch/test-cli-then-vscode-attach.ps1` - CLI→VS Code workflow
- `test-windows-launch/compare-all-methods.ps1` - Method comparison

**Documentation**:
- `test-windows-launch/DEVCONTAINER-CLI-STRATEGY.md` - Method 3 analysis
- `test-windows-launch/DIRECT-DEVCONTAINER-FINDINGS.md` - Technical analysis
- `test-windows-launch/FINAL-BITBOT-ARCHITECTURE.md` - Production architecture
- `test-windows-launch/LABEL-DISCOVERY-FINDINGS.md` - Label strategy findings
- `test-windows-launch/TODO-HASH-MATCHING.md` - Future enhancement research

**Decision**: Direct DevContainer Opening (VS Code Direct DevContainer Opening)

---

## 1. Architecture

### 1.1 Container Reusability

**Principle**: Same container used by CLI and VS Code
- VS Code starts container via direct URI
- CLI can attach to VS Code-started containers (future)
- Or CLI starts container, VS Code can attach (future, requires matching labels)
- No separate devcontainer vs CLI modes

**Current Implementation** (Phase 0):
- VS Code starts and manages container
- CLI tools run inside VS Code's integrated terminal
- Mode switching via `bitbot` commands within container

**Future Enhancement** (Phase 2+):
- CLI can pre-build containers with correct labels
- VS Code detects and reuses CLI-built containers
- Seamless switching between CLI and VS Code workflows

**Benefits**:
- Single source of truth (container)
- Consistent environment
- Mode switching from VS Code terminal
- Session persistence across CLI/VS Code

### 1.2 VS Code Container Labels

**Required labels** (for VS Code discovery):
```yaml
labels:
  - "vsc.local.folder=${WORKSPACE_PATH}"
  - "devcontainer.local_folder=${WORKSPACE_PATH}"
  - "devcontainer.config_file=${WORKSPACE_PATH}/.devcontainer/devcontainer.json"
```

**Path Format Requirements**:
- **Windows/WSL**: Use Windows paths (`C:\Projects\BitBot`)
- **macOS/Linux**: Use native Unix paths (`/Users/user/projects/bitbot`)

**Why labels**:
- VS Code Remote Containers finds containers by these labels
- Allows "Attach to Running Container" feature
- Enables "Reopen in Container" from workspace

**Current Status**: Labels set automatically by VS Code when using direct URI approach. Manual labeling needed only if using Method 3 (devcontainer CLI).

### 1.3 Single Root Devcontainer Policy

**BitBot Policy**: One `.devcontainer/devcontainer.json` per workspace (at root level)

**Rationale**:
- Prevents confusion between multiple container configs
- Ensures CLI and VS Code use same environment
- Simplifies container discovery and attachment
- Aligns with BitBot's "single source of truth" principle

**Subfolder devcontainers**:
- ❌ Not recommended for BitBot-managed workspaces
- ⚠️ If present, BitBot will warn that CLI features may not work
- ✅ Use root devcontainer with runtime env vars for stack-specific behavior

---

## 2. devcontainer.json Configuration

### 2.1 Work Mode devcontainer.json

**Location**: `.devcontainer/devcontainer.json`

```json
{
  "name": "BitBot Work Mode",
  "dockerComposeFile": "../.bitbot/docker-compose.work.yml",
  "service": "bitbot-dev",
  "workspaceFolder": "/workspace",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode-remote.remote-containers",
        "github.copilot",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "terminal.integrated.profiles.linux": {
          "zsh": {
            "path": "/bin/zsh"
          }
        }
      }
    }
  },

  "remoteUser": "root",
  "postStartCommand": ".bitbot/setup/scripts/git-safety-check.sh",
  "shutdownAction": "stopCompose",

  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],

  "features": {},

  "forwardPorts": [],

  "portsAttributes": {}
}
```

**Note**: `dockerComposeFile` can be replaced with `image` for simpler single-container setups:
```json
{
  "image": "bitbot/dev:latest",
  // ... rest of config
}
```

### 2.2 Setup Mode devcontainer.json

**Location**: `.devcontainer/devcontainer.setup.json`

```json
{
  "name": "BitBot Setup Mode",
  "dockerComposeFile": "../.bitbot/docker-compose.setup.yml",
  "service": "bitbot-setup",
  "workspaceFolder": "/setup/workspace",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode-remote.remote-containers",
        "ms-azuretools.vscode-docker"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },

  "remoteUser": "root",
  "postStartCommand": ".bitbot/setup/scripts/git-safety-check.sh",
  "shutdownAction": "stopCompose",

  "mounts": [
    "source=${localWorkspaceFolder},target=/setup/workspace,type=bind,consistency=cached",
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
}
```

**Setup Container Purpose** (inspired by Gemini spec):
- Meta-environment for debugging devcontainer configs
- Has Docker access to launch work containers as siblings
- Iterative workflow: edit config → test launch → verify → iterate
- Recovery mode if work container is broken

**Setup Container Workflow**:
```bash
# 1. Launch setup session
bitbot setup

# 2. Edit work container config
vim /setup/workspace/.devcontainer/devcontainer.json

# 3. Test launch work container (as sibling)
bitbot-test-launch

# 4. Attach VS Code to work container and verify
code --folder-uri="vscode-remote://attached-container+..."

# 5. Iterate: stop, edit, relaunch
bitbot-test-down
```

### 2.3 Composable Setup Scripts

**Concept** (from Copilot spec): Runtime configuration via setup scripts

**Architecture**:
```
.bitbot/
├── setup/
│   └── scripts/
│       ├── install-language.sh      # Stack-specific (Node, Python, etc.)
│       ├── setup-mcp.sh              # MCP service setup
│       ├── git-safety-check.sh       # Security checks
│       └── post-start.sh             # Orchestrator
```

**Container Image Approach**:
- Fixed base image (`bitbot/dev:latest`)
- Runtime stack selection via env vars
- Composable scripts run at `postStartCommand` or `postCreateCommand`

**Example** (`.devcontainer/devcontainer.json`):
```json
{
  "image": "bitbot/dev:latest",
  "containerEnv": {
    "BITBOT_STACK": "python",
    "BITBOT_MODE": "work"
  },
  "postCreateCommand": ".bitbot/setup/scripts/install-language.sh",
  "postStartCommand": ".bitbot/setup/scripts/post-start.sh"
}
```

**Benefits**:
- No rebuild for different stacks
- Flexible, maintainable configuration
- Inspired by legacy_devcontainer_samples patterns

---

## 3. Integration Workflows

### 3.1 VS Code → BitBot CLI Workflow

**Scenario**: User opens VS Code, then uses CLI features

```bash
# 1. Open folder in VS Code with direct URI
bitbot vscode /path/to/workspace

# VS Code opens directly in dev container (no popup)

# 2. Use integrated terminal
# Terminal automatically in container at /workspace

# 3. Use BitBot commands
bitbot status        # Check current mode
bitbot mcp list      # List MCP services
bitbot git push      # Safe git operations

# 4. Switch modes (future)
bitbot setup vscode  # Switch VS Code to setup container
```

**Implementation**:
- Direct URI opening (Section 0)
- Terminal integration (Section 5)
- Mode switching (Section 4, future)

### 3.2 CLI → VS Code Workflow (Future)

**Scenario**: User starts in CLI, then opens VS Code

```bash
# Terminal: Start work container via CLI (future feature)
$ bitbot work
✓ Starting work container...
✓ Container bitbot-dev-abc123 started
root@work:/workspace$

# Open VS Code and attach to running container
$ bitbot vscode .
# VS Code opens attached to same container
```

**Requirements**:
- CLI must build container with correct labels (Section 1.2)
- VS Code detects by `devcontainer.local_folder` label
- Requires Method 3 implementation for label compatibility

**Status**: ⏳ Future (Phase 2+)

### 3.3 Parallel VS Code + CLI (Future)

**Scenario**: VS Code and CLI simultaneously

```bash
# VS Code: Attached to work container
# Terminal inside VS Code: tmux session work-vscode

# External terminal:
$ bitbot work --attach dev
# Attaches to work-dev session in same container

# Both active simultaneously
# Separate tmux sessions, same container
```

**Status**: ⏳ Future (Phase 3+)

---

## 4. Mode Switching from VS Code

### 4.1 Switch to Setup Mode (Future)

**From VS Code integrated terminal**:
```bash
# Currently in work mode container
root@work:/workspace$ bitbot setup vscode

# This:
# 1. Stops work container
# 2. Starts setup container
# 3. Launches VS Code attached to setup container
# 4. Current VS Code window switches to setup container
```

**Implementation**:
```bash
# bitbot setup vscode (when called from inside container)
if in_container; then
  # Signal host to switch
  echo "Switching to setup mode..."

  # Create switch marker
  touch /workspace/.bitbot/state/switch-to-setup

  # VS Code workspace watcher detects marker
  # Prompts user: "Switch to setup mode?"
  # If yes: Reopens in setup container
fi
```

### 4.2 VS Code Workspace Switcher (Future)

**Extension/Script** (`.vscode/bitbot-mode-switcher.js`):
```javascript
// Watch for mode switch markers
const watcher = vscode.workspace.createFileSystemWatcher(
  '**/.bitbot/state/switch-to-*'
);

watcher.onDidCreate(async (uri) => {
  const switchFile = path.basename(uri.fsPath);

  if (switchFile === 'switch-to-setup') {
    const choice = await vscode.window.showInformationMessage(
      'Switch to Setup mode?',
      'Yes', 'No'
    );

    if (choice === 'Yes') {
      // Reopen in setup container
      vscode.commands.executeCommand(
        'remote-containers.reopenInContainer',
        '.devcontainer/devcontainer.setup.json'
      );
    }

    // Clean up marker
    fs.unlinkSync(uri.fsPath);
  }
});
```

**Status**: ⏳ Future (Phase 3)

---

## 5. Terminal Integration

### 5.1 Integrated Terminal

**Default behavior**:
- VS Code integrated terminal uses `/bin/zsh` (work) or `/bin/bash` (setup)
- Automatically attaches to or creates tmux session
- Session name: `work-vscode-${N}` or `setup-vscode-${N}`

**Terminal profile** (`.vscode/settings.json`):
```json
{
  "terminal.integrated.profiles.linux": {
    "BitBot Work": {
      "path": "/bin/zsh",
      "args": ["-c", "tmux attach -t work-vscode-1 || tmux new -s work-vscode-1"]
    },
    "BitBot Setup": {
      "path": "/bin/bash",
      "args": ["-c", "tmux attach -t setup-vscode-1 || tmux new -s setup-vscode-1"]
    }
  },
  "terminal.integrated.defaultProfile.linux": "BitBot Work"
}
```

### 5.2 Multi-Terminal Support

**Multiple integrated terminals**:
```json
// Each new terminal creates/attaches to tmux session
// work-vscode-1, work-vscode-2, work-vscode-3, etc.

// User can also manually attach to existing sessions
// Terminal > New Terminal
// $ tmux attach -t work-main
```

### 5.3 BitBot CLI Auto-Launch (Future)

**Concept** (from Copilot spec): Auto-launch `bitbot` in terminals

**Shell RC Hook** (`.zshrc` or `.bashrc` in container):
```bash
# Auto-attach to BitBot session or launch BitBot
if [ -n "$VSCODE_INJECTION" ]; then
  # Inside VS Code terminal
  if ! tmux has-session -t work-vscode 2>/dev/null; then
    tmux new-session -d -s work-vscode
  fi
  exec tmux attach-session -t work-vscode
fi
```

**Status**: ⏳ Future (Phase 2)

---

## 6. MCP Service Management

### 6.1 MCP as Sibling Services

**Architecture** (from Copilot spec): Keep MCP services outside devcontainer

**Rationale**:
- Separation of concerns (dev environment vs services)
- MCP services can restart independently
- Easier debugging and logs
- Works with both CLI and VS Code workflows

**Docker Compose Structure**:
```
.bitbot/
├── docker-compose.work.yml       # Work container only
├── docker-compose.setup.yml      # Setup container only
└── mcp/
    └── docker-compose.yml         # MCP services (separate)
```

**MCP Compose** (`.bitbot/mcp/docker-compose.yml`):
```yaml
version: '3.8'
services:
  mcp-git:
    image: bitbot/mcp-git:latest
    ports:
      - "9001:9001"
    networks:
      - bitbot-net

  mcp-filesystem:
    image: bitbot/mcp-filesystem:latest
    ports:
      - "9002:9002"
    volumes:
      - ${WORKSPACE_PATH}:/workspace:ro
    networks:
      - bitbot-net

networks:
  bitbot-net:
    external: true
```

**Startup** (automatic via `postStartCommand`):
```bash
# .bitbot/setup/scripts/post-start.sh
docker-compose -f .bitbot/mcp/docker-compose.yml up -d
```

### 6.2 MCP Service Discovery from VS Code

**Environment Variables** (`.devcontainer/devcontainer.json`):
```json
{
  "containerEnv": {
    "MCP_GIT_URL": "http://mcp-git:9001",
    "MCP_FILESYSTEM_URL": "http://mcp-filesystem:9002"
  }
}
```

**BitBot CLI** (inside container):
```bash
# Auto-connects to MCP services via env vars
bitbot mcp list
# → git (http://mcp-git:9001) ✓
# → filesystem (http://mcp-filesystem:9002) ✓
```

---

## 7. Extension Recommendations

### 7.1 Required Extensions

**Work mode** (`.vscode/extensions.json`):
```json
{
  "recommendations": [
    "ms-vscode-remote.remote-containers",
    "github.copilot",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-python.python",
    "ms-vscode.cpptools"
  ]
}
```

**Setup mode**:
```json
{
  "recommendations": [
    "ms-vscode-remote.remote-containers",
    "ms-azuretools.vscode-docker",
    "redhat.vscode-yaml",
    "ms-vscode.makefile-tools"
  ]
}
```

### 7.2 BitBot VS Code Extension (Future)

**Custom extension** (optional future enhancement):
```
bitbot-vscode-extension/
├── package.json
├── src/
│   ├── extension.ts           # Main extension
│   ├── modeSwitcher.ts        # Mode switching UI
│   ├── sessionManager.ts      # Session management UI
│   └── mcpExplorer.ts         # MCP service explorer
```

**Features**:
- Status bar: Current mode indicator
- Command palette: Switch mode
- Sidebar: Session explorer
- Sidebar: MCP service explorer
- Notifications: Git safety warnings

**Status**: ⏳ Future (Phase 4+)

---

## 8. Port Forwarding

### 8.1 Automatic Port Forwarding

**Common development ports**:
```json
{
  "forwardPorts": [3000, 5000, 8000, 8080, 9090],
  "portsAttributes": {
    "3000": {
      "label": "Dev Server",
      "onAutoForward": "notify"
    },
    "8080": {
      "label": "API Server",
      "onAutoForward": "openBrowser"
    }
  }
}
```

### 8.2 Dynamic Port Detection

**Auto-detect and forward**:
```json
{
  "portsAttributes": {
    "3000-9999": {
      "onAutoForward": "notify"
    }
  }
}
```

---

## 9. Container Lifecycle

### 9.1 Container Start

**VS Code starts container** (via direct URI):
1. Reads `.devcontainer/devcontainer.json`
2. Runs `docker-compose up -d` (or `docker run` if using `image`)
3. Waits for container ready
4. Runs `postStartCommand`
5. Attaches VS Code server to container
6. Opens integrated terminal

**postStartCommand**:
```bash
# .devcontainer/devcontainer.json
"postStartCommand": ".bitbot/setup/scripts/post-start.sh"
```

**post-start.sh**:
```bash
#!/usr/bin/env bash

# Restore tmux sessions
if [ -f .bitbot/sessions/work/last.txt ]; then
  tmux-resurrect restore
fi

# Run git safety check
.bitbot/setup/scripts/git-safety-check.sh

# Start MCP services (if not started)
docker-compose -f .bitbot/mcp/docker-compose.yml up -d
```

### 9.2 Container Stop

**shutdownAction**:
```json
{
  "shutdownAction": "stopCompose"
}
```

**Options**:
- `none`: Leave container running
- `stopCompose`: Stop via docker-compose down
- `stopContainer`: Stop container only

**Recommendation**: `stopCompose` for clean shutdown

---

## 10. Debugging Integration

### 10.1 Launch Configurations

**Python debugging** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Python: FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["main:app", "--reload"],
      "jinja": true
    }
  ]
}
```

**Node.js debugging**:
```json
{
  "configurations": [
    {
      "name": "Node: Launch Program",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.js",
      "console": "integratedTerminal"
    }
  ]
}
```

---

## 11. Workspace Settings

### 11.1 Recommended Settings

**Work mode** (`.vscode/settings.json`):
```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/*/**": true,
    "**/.bitbot/sessions/**": true
  },

  "files.associations": {
    "*.yml": "yaml",
    "Dockerfile*": "dockerfile",
    ".devcontainer.json": "jsonc"
  },

  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },

  "terminal.integrated.defaultProfile.linux": "zsh",

  "git.autofetch": true,
  "git.confirmSync": false
}
```

---

## 12. Testing Strategy

### 12.1 Integration Tests

**Implemented** (Windows):
- ✅ VS-01: Direct URI opens VS Code in container
- ✅ VS-02: Hex encoding works (PowerShell + bash)
- ✅ VS-03: Container reuse confirmed (no duplicates)
- ✅ VS-04: Windows path labels match VS Code expectations
- ✅ VS-05: Method 3 produces correct labels

**Pending**:
- ⏳ VS-06: CLI starts container, VS Code attaches
- ⏳ VS-07: VS Code starts container, CLI attaches
- ⏳ VS-08: Mode switch from VS Code terminal
- ⏳ VS-09: Integrated terminal creates tmux session
- ⏳ VS-10: Port forwarding works
- ⏳ VS-11: Extensions install correctly
- ⏳ VS-12: Debugging configurations work

### 12.2 Platform Tests

**Status**:
- ✅ PL-01: VS Code on Windows/WSL2
- ⏳ PL-02: VS Code on macOS
- ⏳ PL-03: VS Code on Linux
- ⏳ PL-04: Remote SSH + BitBot container

---

## 13. Success Criteria

**Functional**:
- [x] Direct URI opening (Windows)
- [x] Hex encoding utilities (PowerShell + bash)
- [x] Container reuse validated
- [ ] Direct URI opening (macOS/Linux)
- [ ] VS Code attaches to CLI-started containers
- [ ] CLI attaches to VS Code-started containers
- [ ] Mode switching from VS Code terminal
- [ ] Integrated terminal uses tmux sessions
- [ ] Port forwarding automatic
- [ ] Extensions install correctly

**Usability**:
- [x] No "Reopen in Container" popup (direct URI)
- [x] Simplified dependencies (no Docker/Node in Alpine)
- [ ] Seamless CLI ↔ VS Code workflow
- [ ] No duplicate containers
- [ ] Fast container attachment (<5s)
- [ ] Terminal feels native (not sluggish)

**Reliability**:
- [x] PowerShell hex encoding (no bash escaping issues)
- [x] Bash hex encoding with fallback (xxd/od)
- [ ] Container labels correct
- [ ] postStartCommand runs reliably
- [ ] Session persistence across VS Code restarts
- [ ] No conflicts between CLI and VS Code

---

## 14. Implementation Phases

**Phase 0: Direct Container Opening** ✅ **COMPLETE (Windows)** | ⏳ **Pending (macOS/Linux)**:
- [x] Research VS Code's `--folder-uri` protocol
- [x] Implement hex encoding (xxd + od fallback)
- [x] Platform detection and path conversion
- [x] Direct URI opening (bypasses popup)
- [x] PowerShell utility (`Open-VSCodeDevContainer.ps1`)
- [x] Bash utility (`vscode-devcontainer-utils.sh`)
- [x] Test on Windows (PowerShell + WSL roundabout)
- [x] Document findings and architecture
- [ ] Test on macOS
- [ ] Test on Linux

**Phase 1: Basic Integration** ⏳ **Pending**:
- [ ] devcontainer.json for work mode
- [ ] Container labels for VS Code discovery (if using CLI build)
- [ ] Simplified: VS Code builds directly via URI

**Phase 2: Terminal Integration** ⏳ **Pending**:
- [ ] Integrated terminal tmux sessions
- [ ] Terminal profiles for work/setup
- [ ] Multi-terminal support
- [ ] BitBot CLI auto-launch in terminals

**Phase 3: Mode Switching** ⏳ **Future**:
- [ ] Mode switch from VS Code terminal
- [ ] Workspace switcher script
- [ ] Setup mode devcontainer.json

**Phase 4: Extensions & Features** ⏳ **Future**:
- [ ] Extension recommendations
- [ ] Port forwarding configuration
- [ ] Debugging launch configs
- [ ] Custom BitBot extension (optional)

**Phase 5: Advanced Features** ⏳ **Future**:
- [ ] Hash matching research (CI/CD pre-builds)
- [ ] Standalone devcontainer CLI support
- [ ] Container sharing across build methods
- [ ] CLI → VS Code seamless handoff

---

## 15. References

**Related Specifications**:
- SPEC-01: Container Orchestration (container management)
- SPEC-02: Security Mode System (mode switching)
- SPEC-04: Session Management (tmux integration)
- SPEC-05: Cross-Platform CLI (CLI integration)
- SPEC-07: AI Agent Integration (agent workflows in containers)

**External Resources**:
- VS Code Remote Containers: https://code.visualstudio.com/docs/remote/containers
- devcontainer.json reference: https://containers.dev/implementors/json_reference/
- VS Code Extension API: https://code.visualstudio.com/api
- Dev Containers CLI: https://github.com/devcontainers/cli

**Research Sources**:
- User decision: Direct URI approach over devcontainer CLI
- User decision: Method 3 (bash-centric, Windows labels)
- Testing findings: test-windows-launch/*.md

**Implementation Files**:
- Core: `test-windows-launch/bitbot-core.sh`
- Utils: `test-windows-launch/Open-VSCodeDevContainer.ps1`
- Utils: `test-windows-launch/vscode-devcontainer-utils.sh`
- Tests: `test-windows-launch/test-*.ps1`
- Docs: `test-windows-launch/README-VSCODE-UTILS.md`
- Docs: `test-windows-launch/DEVCONTAINER-CLI-STRATEGY.md`
- Docs: `test-windows-launch/DIRECT-DEVCONTAINER-FINDINGS.md`
- Docs: `test-windows-launch/FINAL-BITBOT-ARCHITECTURE.md`
- Docs: `test-windows-launch/LABEL-DISCOVERY-FINDINGS.md`

---

**Status**: **In Progress** (Phase 0 complete for Windows, macOS/Linux pending)
**Implementation Priority**: P1 (Important for user experience)
**Current Phase**: Phase 0 - Direct Container Opening (Windows ✅, macOS/Linux ⏳)
**Next Steps**:
1. Test Phase 0 on macOS and Linux
2. Move to Phase 1 (devcontainer.json configuration)
3. Continue to SPEC-07 (AI Agent Integration Framework)

**Related Decisions**: Direct DevContainer Opening (VS Code Direct DevContainer Opening)

**Consolidated From**:
- Claude_Specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md (primary, with testing findings)
- Copilot_Specification/04-Devcontainer-Management.md (composable scripts, single devcontainer policy)
- Copilot_Specification/10-VSCode-Multicontainer-UX.md (MCP sidecars, labels, terminal integration)
- Gemini_Specification/02-Devcontainer-Management.md (setup container concept, hybrid model)
