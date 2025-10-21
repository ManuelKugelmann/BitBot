# VS Code DevContainer Integration Specification

**Feature ID**: SPEC-06
**Priority**: P1 (Important)
**Status**: In Progress (Windows implementation complete)
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes), SPEC-04 (Session Management)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20 (Added devcontainer building workflow documentation)

---

## Executive Summary

VS Code Remote Containers integration for BitBot. Single container reusable by both CLI and VS Code. Mode switching works from VS Code terminal. Proper labels for container attachment.

**Key Design**: Unified container + VS Code labels + terminal integration + mode awareness = seamless VS Code experience.

**Breakthrough**: Direct dev container opening via hex-encoded URIs eliminates "Reopen in Container" popup and simplifies architecture.

---

## 0. VS Code Direct DevContainer Opening 

**Status**: ✅ **Implemented and tested (Windows)**

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

### 0.2 Benefits Over Manual devcontainer up

| Aspect | Manual Approach | Direct URI Approach |
|--------|----------------|---------------------|
| User action | Click "Reopen" popup | None (automatic) |
| Containers created | 2 (CLI + VS Code) | 1 (VS Code only) |
| Code complexity | ~190 lines | ~100 lines (-47%) |
| Dependencies | Docker CLI, Node.js, devcontainer CLI | VS Code only |
| WSL corruption risk | Yes (devcontainer commands) | No (no Docker commands) |
| Container reuse | Different hashes | Same container reused |

### 0.3 Cross-Platform Implementation

**Path to Hex Encoding**:
```bash
# Linux/macOS (xxd available)
hex_path=$(printf "%s" "$path" | xxd -p -c 256 | tr -d '\n')

# Alpine/minimal (xxd not available)
hex_path=$(printf "%s" "$path" | od -A n -t x1 | tr -d ' \n')
```

**Platform-Specific Execution**:
```bash
case "$(detect_platform)" in
    wsl)
        # Convert WSL path to Windows path
        windows_path=$(wslpath -w "/mnt/c/Projects/BitBot")  # C:\Projects\BitBot
        hex_path=$(path_to_hex "$windows_path")
        code.exe --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        ;;
    macos|linux)
        hex_path=$(path_to_hex "$native_path")
        code --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        ;;
esac
```

### 0.4 Container Hash Differences

**Why VS Code creates different containers**:

Manual `devcontainer up`:
- Mounts: `/workspace`, `/workspaces/BitBot`
- Image hash: `vsc-test-78977c62...`

VS Code build:
- Mounts: `/workspace`, `/workspaces/BitBot`, `/vscode` (VS Code Server), Wayland socket
- Image hash: `vsc-test-a4656483...` (different!)

**Root cause**: VS Code adds extra configuration during build:
1. `/vscode` volume for VS Code Server installation
2. Wayland/X11 sockets for GUI forwarding
3. Additional labels and environment variables

**Decision**: Let VS Code build its own container with required mounts. VS Code knows what it needs.

**Future enhancement**: Research hash matching to enable CI/CD pre-builds (see `test-windows-launch/TODO-HASH-MATCHING.md`)

### 0.5 Simplified Dependencies

**Before** (devcontainer up approach):
- ❌ Docker CLI in WSL/Alpine
- ❌ Node.js + npm
- ❌ `@devcontainers/cli` package
- ❌ Complex cmd.exe path handling
- ❌ WSL corruption workarounds

**After** (direct URI approach):
- ✅ VS Code with Dev Containers extension (already required)
- ✅ bash + git (for BitBot features)
- ✅ coreutils (`od` for hex encoding)

**BitBot-Alpine size**: ~8MB (was ~200MB+ with Docker/Node.js)

### 0.6 Testing Results

**Test environment**: Windows 11 + WSL2 (Ubuntu-22.04) + BitBot-Alpine

**Scenario 1: Direct PowerShell**
```powershell
.\test-direct-open.ps1
```
- ✅ VS Code opens directly in dev container
- ✅ No "Reopen in Container" popup
- ✅ Terminal at `/workspace`
- ✅ Bottom-left shows "Dev Container: BitBot Test"

**Scenario 2: WSL Roundabout**
```powershell
.\test-bitbot-final.ps1  # Calls bitbot-core.sh in BitBot-Alpine
```
- ✅ Hex encoding works in Alpine (using `od`)
- ✅ WSL interop calls Windows code.exe successfully
- ✅ VS Code opens directly in dev container
- ✅ **Container reuse confirmed** (same container ID on subsequent opens)
- ✅ No WSL corruption

**Platforms tested**:
- ✅ Windows 11 + WSL2 (Ubuntu-22.04 default + BitBot-Alpine)
- ⏳ macOS (TODO)
- ⏳ Linux native (TODO)

### 0.7 Implementation References

**Core implementation**: `test-windows-launch/scripts/bitbot-core.sh`
- Platform detection (`detect_platform()`)
- Hex encoding with fallback (`path_to_hex()`)
- Direct URI opening (`bitbot_vscode()`)
- Future location: `/opt/bitbot/bin/bitbot-core.sh`

**Windows entry point**: `test-windows-launch/scripts/Open-VSCodeDevContainer.ps1`
- PowerShell launcher for VS Code Direct DevContainer Opening on Windows

**Test scripts**:
- `test-windows-launch/tests/vscode_devcontainer/test-direct-open.ps1` - Direct PowerShell test
- `test-windows-launch/tests/vscode_devcontainer/test-bitbot-final.ps1` - WSL roundabout test

**Documentation**:
- `test-windows-launch/docs/README.md` - Master guide ⭐
- `test-windows-launch/docs/DIRECT-DEVCONTAINER-FINDINGS.md` - Technical analysis
- `test-windows-launch/docs/FINAL-BITBOT-ARCHITECTURE.md` - Production architecture
- `test-windows-launch/archive/research/TODO-HASH-MATCHING.md` - Future enhancement research

**Decision**: Direct DevContainer Opening (VS Code Direct DevContainer Opening)

---

## 0.8 DevContainer Building Workflow

### 0.8.1 Platform-Specific devcontainer Command

**Challenge**: Different platforms have different optimal devcontainer command execution:

| Platform | Command | Reason |
|----------|---------|--------|
| Windows (WSL) | `devcontainer.cmd` | Avoids WSL path corruption with Docker Desktop |
| macOS | `devcontainer` | Native execution, no path translation needed |
| Linux | `devcontainer` | Native execution, no path translation needed |

**Implementation**:
```bash
# In bitbot-core.sh

detect_devcontainer_command() {
    local platform=$(detect_platform)

    if [[ "$platform" == "wsl2" ]]; then
        # Windows: Use .cmd wrapper
        echo "devcontainer.cmd"
    else
        # macOS/Linux: Use standard command
        echo "devcontainer"
    fi
}

# Usage
devcontainer_cmd=$(detect_devcontainer_command)
$devcontainer_cmd up --workspace-folder "$(pwd)"
```

### 0.8.2 VS Code Builtin vs Standalone CLI

**VS Code includes devcontainer CLI**: When VS Code with Dev Containers extension is installed, it includes a bundled devcontainer CLI that's optimized for VS Code integration.

**Detection strategy**:
```bash
# Check if VS Code is installed
if command -v code &>/dev/null; then
    # VS Code installed: Check for Dev Containers extension
    if code --list-extensions | grep -q "ms-vscode-remote.remote-containers"; then
        # Extension installed: Use VS Code's builtin CLI
        # The devcontainer CLI is bundled with the extension
        USE_BUILTIN_CLI=true
    else
        # VS Code installed but no extension
        echo "Warning: VS Code found but Dev Containers extension not installed"
        echo "Install: code --install-extension ms-vscode-remote.remote-containers"
        USE_BUILTIN_CLI=false
    fi
else
    # No VS Code: Check for standalone devcontainer CLI
    if ! command -v devcontainer &>/dev/null; then
        # Not installed: Offer to install
        echo "devcontainer CLI not found"
        echo "Options:"
        echo "  1. Install VS Code with Dev Containers extension (recommended)"
        echo "  2. Install standalone: npm install -g @devcontainers/cli"
        USE_BUILTIN_CLI=false
    fi
fi
```

**Benefits of builtin CLI**:
- ✅ No separate installation needed
- ✅ Same version as VS Code uses (consistency)
- ✅ Automatic updates with VS Code
- ✅ Better integration with VS Code features

**When to use standalone CLI**:
- ❌ VS Code not desired on system
- ❌ CI/CD pipelines (server environments)
- ❌ Headless container building

### 0.8.3 Complete Build and Launch Flow

**Full workflow with all decisions**:
```bash
#!/usr/bin/env bash
# bitbot-core.sh

bitbot_work() {
    local workspace_path="$(pwd)"
    local platform=$(detect_platform)
    local use_vscode="${1:-false}"  # vscode flag

    # Step 1: Determine devcontainer command
    local devcontainer_cmd
    if [[ "$platform" == "wsl2" ]]; then
        devcontainer_cmd="devcontainer.cmd"
    else
        devcontainer_cmd="devcontainer"
    fi

    # Step 2: Check for VS Code and devcontainer CLI
    local has_vscode=false
    local has_devcontainer=false

    if command -v code &>/dev/null; then
        has_vscode=true
        if code --list-extensions 2>/dev/null | grep -q "ms-vscode-remote.remote-containers"; then
            has_devcontainer=true
        fi
    else
        if command -v devcontainer &>/dev/null || command -v devcontainer.cmd &>/dev/null; then
            has_devcontainer=true
        fi
    fi

    # Step 3: Build container (if using terminal mode or devcontainer CLI available)
    if [[ "$use_vscode" == "false" ]] || [[ "$has_devcontainer" == "true" ]]; then
        # Build using devcontainer CLI
        if [[ "$has_devcontainer" == "false" ]]; then
            echo "Error: devcontainer CLI not found"
            echo "Install: npm install -g @devcontainers/cli"
            echo "Or install VS Code with Dev Containers extension"
            exit 1
        fi

        echo "Building devcontainer..."
        $devcontainer_cmd up --workspace-folder "$workspace_path"
    fi

    # Step 4A: Launch VS Code (if vscode flag)
    if [[ "$use_vscode" == "true" ]]; then
        if [[ "$has_vscode" == "false" ]]; then
            echo "Error: VS Code not found"
            echo "Install from: https://code.visualstudio.com/"
            exit 1
        fi

        # Use Direct DevContainer Opening
        if [[ "$platform" == "wsl2" ]]; then
            local windows_path=$(wslpath -w "$workspace_path")
            local hex_path=$(path_to_hex "$windows_path")
            code.exe --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        else
            local hex_path=$(path_to_hex "$workspace_path")
            code --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
        fi

        echo "VS Code launched in devcontainer"

    # Step 4B: Launch terminal (default)
    else
        local workspace_hash=$(calculate_workspace_hash "$workspace_path")
        local container_name="bitbot-dev-${workspace_hash}"

        echo "Entering devcontainer terminal..."
        docker exec -it "$container_name" /bin/bash -c "cd /workspace && /opt/bitbot/bin/bitbot-session-menu.sh"
    fi
}
```

### 0.8.4 Decision Matrix

**Which approach to use?**

| User Wants | VS Code Installed | devcontainer CLI | Action |
|------------|-------------------|------------------|--------|
| Terminal mode | ✅ Yes (with ext) | ✅ Builtin | Build with builtin → docker exec |
| Terminal mode | ✅ Yes (no ext) | ❌ No | Error: Install extension or standalone CLI |
| Terminal mode | ❌ No | ✅ Standalone | Build with standalone → docker exec |
| Terminal mode | ❌ No | ❌ No | Error: Install standalone CLI |
| VS Code mode | ✅ Yes (with ext) | ✅ Builtin | Direct DevContainer Opening: Direct URI open (VS Code builds) |
| VS Code mode | ✅ Yes (no ext) | N/A | Error: Install Dev Containers extension |
| VS Code mode | ❌ No | N/A | Error: Install VS Code |

**Key insight**: For VS Code mode with Direct DevContainer Opening, we DON'T pre-build the container. VS Code builds it directly when opening the URI, ensuring all VS Code-specific mounts and configuration are included.

---

## 1. Architecture

### 1.1 Container Reusability

**Principle**: Same container used by CLI and VS Code
- CLI starts container via `bitbot work`
- VS Code attaches to running container
- Or VS Code starts container directly
- No separate devcontainer vs CLI modes

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

**Why labels**:
- VS Code Remote Containers finds containers by these labels
- Allows "Attach to Running Container" feature
- Enables "Reopen in Container" from workspace

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
    "source=${localWorkspaceFolder},target=/setup/workspace,type=bind,consistency=cached"
  ]
}
```

---

## 3. Integration Workflows

### 3.1 CLI → VS Code Workflow

**Scenario**: User starts in CLI, then opens VS Code

```bash
# Terminal 1: Start work container via CLI
$ bitbot work
✓ Starting work container...
✓ Container bitbot-dev-abc123 started
root@work:/workspace$

# Terminal 2: Open VS Code
$ code .
# VS Code detects running container
# Shows: "Container bitbot-dev-abc123 is running. Attach?"
# User clicks "Attach"
# VS Code opens in same container
```

**Implementation**:
- Container has proper VS Code labels
- VS Code detects by `vsc.local.folder` label
- VS Code attaches to running container
- Shared tmux sessions visible

### 3.2 VS Code → CLI Workflow

**Scenario**: User starts in VS Code, then uses CLI

```bash
# VS Code: Open folder in container
# File > Open Folder in Container
# Selects work mode devcontainer.json
# Container starts

# Terminal: Attach to same container
$ bitbot work --attach main
# Attaches to work-main session in VS Code's container
```

**Implementation**:
- Container started by VS Code has labels
- CLI detects running container by name
- CLI attaches without recreating

### 3.3 Parallel VS Code + CLI

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

---

## 4. Mode Switching from VS Code

### 4.1 Switch to Setup Mode

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

### 4.2 VS Code Workspace Switcher

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

---

## 6. Extension Recommendations

### 6.1 Required Extensions

**Work mode**:
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

### 6.2 BitBot VS Code Extension

**Custom extension** (optional future enhancement):
```
bitbot-vscode-extension/
├── package.json
├── src/
│   ├── extension.ts           # Main extension
│   ├── modeSwicher.ts         # Mode switching UI
│   ├── sessionManager.ts      # Session management UI
│   └── mcpExplorer.ts         # MCP service explorer
```

**Features**:
- Status bar: Current mode indicator
- Command palette: Switch mode
- Sidebar: Session explorer
- Sidebar: MCP service explorer
- Notifications: Git safety warnings

---

## 7. Port Forwarding

### 7.1 Automatic Port Forwarding

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

### 7.2 Dynamic Port Detection

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

## 8. Container Lifecycle

### 8.1 Container Start

**VS Code starts container**:
1. Reads `.devcontainer/devcontainer.json`
2. Runs `docker-compose up -d`
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

### 8.2 Container Stop

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

## 9. Debugging Integration

### 9.1 Launch Configurations

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

## 10. Workspace Settings

### 10.1 Recommended Settings

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

## 11. Multi-Root Workspaces

### 11.1 Multiple Workspaces

**Scenario**: Multiple projects in BitBot

**Workspace file** (`bitbot.code-workspace`):
```json
{
  "folders": [
    {
      "name": "Project A (Work)",
      "path": "/workspace/project-a"
    },
    {
      "name": "Project B (Work)",
      "path": "/workspace/project-b"
    },
    {
      "name": "Infrastructure (Setup)",
      "path": "/setup/workspace"
    }
  ],
  "settings": {
    "terminal.integrated.cwd": "${workspaceFolder}"
  }
}
```

---

## 12. Testing Strategy

### 12.1 Integration Tests

- VS-01: CLI starts container, VS Code attaches
- VS-02: VS Code starts container, CLI attaches
- VS-03: Mode switch from VS Code terminal
- VS-04: Integrated terminal creates tmux session
- VS-05: Port forwarding works
- VS-06: Extensions install correctly
- VS-07: Debugging configurations work

### 12.2 Platform Tests

- PL-01: VS Code on Windows/WSL2
- PL-02: VS Code on macOS
- PL-03: VS Code on Linux
- PL-04: Remote SSH + BitBot container

---

## 13. Success Criteria

**Functional**:
- [ ] VS Code attaches to CLI-started containers
- [ ] CLI attaches to VS Code-started containers
- [ ] Mode switching from VS Code terminal
- [ ] Integrated terminal uses tmux sessions
- [ ] Port forwarding automatic
- [ ] Extensions install correctly

**Usability**:
- [ ] Seamless CLI ↔ VS Code workflow
- [ ] No duplicate containers
- [ ] Fast container attachment (<5s)
- [ ] Terminal feels native (not sluggish)

**Reliability**:
- [ ] Container labels correct
- [ ] postStartCommand runs reliably
- [ ] Session persistence across VS Code restarts
- [ ] No conflicts between CLI and VS Code

---

## 14. Implementation Phases

**Phase 0: Direct Container Opening** ✅ **COMPLETE (Windows)**:
- [x] Research VS Code's `--folder-uri` protocol
- [x] Implement hex encoding (xxd + od fallback)
- [x] Platform detection and path conversion
- [x] Direct URI opening (bypasses popup)
- [x] Test on Windows (PowerShell + WSL roundabout)
- [x] Document findings and architecture
- [ ] Test on macOS
- [ ] Test on Linux

**Phase 1: Basic Integration**:
- devcontainer.json for work mode
- Container labels for VS Code discovery
- ~~CLI and VS Code attach to same container~~ (Simplified: VS Code builds directly)

**Phase 2: Terminal Integration**:
- Integrated terminal tmux sessions
- Terminal profiles for work/setup
- Multi-terminal support

**Phase 3: Mode Switching**:
- Mode switch from VS Code terminal
- Workspace switcher script
- Setup mode devcontainer.json

**Phase 4: Extensions & Features**:
- Extension recommendations
- Port forwarding configuration
- Debugging launch configs
- Custom BitBot extension (optional)

**Phase 5: Advanced Features** (Future):
- Hash matching research (CI/CD pre-builds)
- Standalone devcontainer CLI support
- Container sharing across build methods

---

## 15. References

**Related Specifications**:
- SPEC-01: Container Orchestration (container management)
- SPEC-02: Security Mode System (mode switching)
- SPEC-04: Session Management (tmux integration)
- SPEC-05: Cross-Platform CLI (CLI integration)

**External Resources**:
- VS Code Remote Containers: https://code.visualstudio.com/docs/remote/containers
- devcontainer.json reference: https://containers.dev/implementors/json_reference/
- VS Code Extension API: https://code.visualstudio.com/api

**Research Sources**:
- User decision: Single container for CLI and VS Code (D-10)
- User requirement: `vscode` flag support

---

**Status**: **In Progress** (Phase 0 complete for Windows)
**Implementation Priority**: P1 (Important for user experience)
**Current Phase**: Phase 0 - Direct Container Opening (Windows ✅, macOS/Linux pending)
**Next Steps**:
1. Test Phase 0 on macOS and Linux
2. Move to Phase 1 (devcontainer.json configuration)
3. Continue to SPEC-07 (AI Agent Integration Framework)

**Related Decisions**: Direct DevContainer Opening (VS Code Direct DevContainer Opening)

**Implementation References**:
- Core: `test-windows-launch/bitbot-core.sh`
- Tests: `test-windows-launch/test-*.ps1`
- Docs: `test-windows-launch/DIRECT-DEVCONTAINER-FINDINGS.md`
- Docs: `test-windows-launch/FINAL-BITBOT-ARCHITECTURE.md`
