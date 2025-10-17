# VS Code DevContainer Integration Specification

**Feature ID**: SPEC-06
**Priority**: P1 (Important)
**Status**: Draft
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes), SPEC-04 (Session Management)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

VS Code Remote Containers integration for BitBot. Single container reusable by both CLI and VS Code. Mode switching works from VS Code terminal. Proper labels for container attachment.

**Key Design**: Unified container + VS Code labels + terminal integration + mode awareness = seamless VS Code experience.

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
root@work:/workspace$ bitbot setup --vscode

# This:
# 1. Stops work container
# 2. Starts setup container
# 3. Launches VS Code attached to setup container
# 4. Current VS Code window switches to setup container
```

**Implementation**:
```bash
# bitbot setup --vscode (when called from inside container)
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

**Phase 1: Basic Integration**:
- devcontainer.json for work mode
- Container labels for VS Code discovery
- CLI and VS Code attach to same container

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
- User requirement: `--vscode` flag support

---

**Status**: **Draft**
**Implementation Priority**: P1 (Important for user experience)
**Next Steps**: SPEC-07 (AI Agent Integration Framework)
