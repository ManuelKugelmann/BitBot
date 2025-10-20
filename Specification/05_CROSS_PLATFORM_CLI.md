# Cross-Platform CLI Specification

**Feature ID**: SPEC-05
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: None
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

Context-aware `bitbot` command that behaves differently on host vs inside containers. Bash-based core with Windows launcher that uses dedicated BitBot-Alpine WSL distro to avoid Docker Desktop corruption issues. Inline execution with VS Code detection for seamless development workflow.

**Key Decisions**:
- **D-03**: Context-aware CLI (host vs container behavior)
- **D-04**: Inline WSL execution with VS Code detection  
- **D-12**: BitBot-Alpine WSL distro for Windows corruption immunity

---

## 1. CLI Architecture Overview

### 1.1 Platform-Specific Implementation

```
┌─────────────────────────────────────────────────────────────┐
│ Cross-Platform CLI Architecture                             │
│                                                             │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│ │ Windows     │  │ macOS       │  │ Linux               │ │
│ │             │  │             │  │                     │ │
│ │ bitbot.exe  │  │ bitbot      │  │ bitbot              │ │
│ │ bitbot.ps1  │  │ (bash)      │  │ (bash)              │ │
│ │     ↓       │  │             │  │                     │ │
│ │ BitBot-     │  │             │  │                     │ │
│ │ Alpine WSL  │  │             │  │                     │ │
│ │     ↓       │  │             │  │                     │ │
│ │ bitbot      │  │             │  │                     │ │
│ │ (bash)      │  │             │  │                     │ │
│ └─────────────┘  └─────────────┘  └─────────────────────┘ │
│        │               │                    │              │
│        └───────────────┼────────────────────┘              │
│                        ▼                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Common Bash Core                                        │ │
│ │ • Container orchestration                               │ │
│ │ • Session management                                    │ │
│ │ • Context detection (host vs container)                │ │
│ │ • Command routing                                       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Context-Aware Command Behavior

**Host Context** (Container management):
- `bitbot` → Smart launch (config default)
- `bitbot work` → Launch work container
- `bitbot setup` → Launch setup container  
- `bitbot vscode` → Launch VS Code (config default mode)
- `bitbot done` → Not applicable on host

**Container Context** (AI/workspace management):
- `bitbot` → Launch default AI agent
- `bitbot <agent>` → Launch specific agent (claude, open, custom)
- `bitbot done` → Review changes → git push → exit
- Container management commands → Error (use host)

---

## 2. Windows Implementation

### 2.1 Windows Path Corruption Root Cause

**Problem**: VS Code on Windows expects container labels with Windows path format (`C:\...`), but calling `devcontainer` (Node.js script) from WSL creates WSL path format (`/mnt/c/...`), causing container discovery failures and duplicates.

**Root Cause**:
- `devcontainer` (Node.js script) → WSL paths in labels (`/mnt/c/...`) ❌
- `devcontainer.cmd` (Windows wrapper) → Windows paths in labels (`C:\...`) ✅

**Solution**: Always use `devcontainer.cmd` wrapper on Windows, regardless of WSL distro.

**Critical Understanding**: Path corruption is **NOT** about which WSL distro is used. It happens in ANY WSL distro (Ubuntu, Alpine, Debian) when calling `devcontainer` without the `.cmd` wrapper.

### 2.2 Windows Multi-Entry-Point Strategy

BitBot on Windows supports **three entry points** to accommodate different user workflows:

#### Entry Point 1: PowerShell Launcher (Recommended)

**Use cases**: Native Windows users, PowerShell workflows, automation scripts

**Implementation** (`bitbot.ps1`):
```powershell
#!/usr/bin/env pwsh
# BitBot Windows PowerShell Launcher

param([Parameter(ValueFromRemainingArguments)]$BitBotArgs)

$WorkspacePath = (Get-Location).Path

# Detect execution context
$IsVSCodeTerminal = $env:TERM_PROGRAM -eq "vscode"

# Option 1: VS Code Direct DevContainer Opening (simplest, see SPEC-06 Decision Direct DevContainer Opening)
. "$PSScriptRoot\Open-VSCodeDevContainer.ps1"
Open-VSCodeDevContainer -WorkspacePath $WorkspacePath

# Option 2: Method 3 (bash-centric, CLI builds)
# wsl bash -c "cmd.exe /c 'cd /d $WorkspacePath && devcontainer.cmd up --workspace-folder .'"

# Option 3: Call bash core in any WSL distro
# wsl bash -c "/opt/bitbot/bitbot-core.sh $BitBotArgs"
```

---

#### Entry Point 2: CMD Batch Launcher

**Use cases**: Legacy Windows scripts, batch file integration, simple wrappers

**Implementation** (`bitbot.cmd`):
```batch
@echo off
REM BitBot Windows CMD Launcher

set WORKSPACE=%CD%

REM Method 2: Direct devcontainer.cmd call (Windows paths)
devcontainer.cmd up --workspace-folder "%WORKSPACE%"

REM Launch VS Code
code "%WORKSPACE%"
```

---

#### Entry Point 3: WSL Bash Launcher (BitBot Core)

**Use cases**: Bash-centric users (99% of BitBot), cross-platform consistency, optional Alpine isolation

**Implementation** (`bitbot` bash script in WSL):
```bash
#!/bin/bash
# BitBot Bash Core (runs in ANY WSL distro)

# Get Windows path for devcontainer.cmd
workspace_win=$(wslpath -w "$PWD")

# Option 1: Method 3 (cmd.exe interop for CLI builds)
cmd.exe /c "cd /d $workspace_win && devcontainer.cmd up --workspace-folder ."

# Option 2: Direct URI approach (preferred, see SPEC-06)
# source /opt/bitbot/lib/vscode-devcontainer-utils.sh
# open_vscode_devcontainer "$workspace_win"
```

**Key Insight**: All three entry points use `devcontainer.cmd` wrapper (or Direct URI) to ensure Windows path labels.

### 2.3 BitBot-Alpine: Optional Isolation Layer

**Purpose**: BitBot-Alpine provides a clean, isolated WSL environment for BitBot, but is **optional** - users can run BitBot in their default WSL distro (Ubuntu, Debian, etc.).

**What BitBot-Alpine Provides**:
- ✅ **Isolation**: Separate from user's default WSL distro
- ✅ **Clean environment**: Only BitBot dependencies (~8MB)
- ✅ **Easy reset**: `wsl --unregister BitBot-Alpine` to start fresh
- ✅ **No interference**: User's WSL environment stays untouched
- ✅ **Convenience**: Pre-configured BitBot installation

**What BitBot-Alpine Does NOT Provide**:
- ❌ **Path corruption prevention** (`.cmd` wrapper prevents corruption, not the distro)
- ❌ **Required for Method 3** (Method 3 works in any WSL distro)
- ❌ **Special Docker Desktop handling** (all WSL distros work the same way)

**Installation** (Optional):
```powershell
# Auto-install BitBot-Alpine on first run (if user chooses isolation)
if (!(wsl -l -v | Select-String "BitBot-Alpine")) {
    Write-Host "Installing BitBot isolated environment (8 MB)..."

    # Download Alpine Linux rootfs
    $AlpineUrl = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.0-x86_64.tar.gz"
    $TempFile = "$env:TEMP\alpine-minirootfs.tar.gz"
    Invoke-WebRequest -Uri $AlpineUrl -OutFile $TempFile

    # Install as BitBot-Alpine (non-default)
    wsl --import BitBot-Alpine "$env:USERPROFILE\.bitbot\wsl" $TempFile

    # Configure BitBot environment (minimal - no Docker/Node.js needed!)
    wsl -d BitBot-Alpine sh -c "
        apk add --no-cache bash git coreutils &&
        mkdir -p /opt/bitbot &&
        echo 'export PATH=/opt/bitbot/bin:\$PATH' >> /root/.bashrc
    "

    Remove-Item $TempFile
    Write-Host "✓ BitBot isolated environment ready"
    Write-Host "  Size: ~8MB (no Docker/Node.js - uses Windows devcontainer.cmd)"
}
```

**User Choice**:
```powershell
# Option A: Use BitBot-Alpine (isolation)
wsl -d BitBot-Alpine /opt/bitbot/bitbot work vscode

# Option B: Use default WSL distro (Ubuntu, etc.)
wsl /opt/bitbot/bitbot work vscode

# Both work identically - choice is preference for isolation

    // Execute and return exit code
    return system(command);
}
```

### 2.3 PATH Integration

**Windows PATH Setup**:
```powershell
# Add BitBot to Windows PATH
$BitBotPath = "$env:USERPROFILE\.bitbot\bin"
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($CurrentPath -notlike "*$BitBotPath*") {
    [Environment]::SetEnvironmentVariable(
        "PATH",
        "$CurrentPath;$BitBotPath",
        "User"
    )
    Write-Host "✓ Added BitBot to PATH"
}
```

**WSL PATH Configuration**:
```bash
# In BitBot-Alpine ~/.bashrc
export PATH="/root/.bitbot/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Prioritize WSL tools over Windows tools
export PATH="/usr/local/bin:/usr/bin:/bin:/mnt/c/Windows/System32:$PATH"
```

---

## 3. macOS and Linux Implementation

### 3.1 Native Bash Implementation

**Installation**:
```bash
#!/bin/bash
# Install BitBot on macOS/Linux

BITBOT_HOME="${HOME}/.bitbot"
BITBOT_BIN="${BITBOT_HOME}/bin"

# Create directory structure
mkdir -p "$BITBOT_BIN"

# Download/clone BitBot
git clone https://github.com/ManuelKugelmann/BitBot.git "$BITBOT_HOME"

# Make executable
chmod +x "$BITBOT_BIN/bitbot"

# Add to PATH (bash/zsh)
if ! grep -q "bitbot" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.bitbot/bin:$PATH"' >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "bitbot" "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.bitbot/bin:$PATH"' >> "$HOME/.zshrc"
    fi
fi

echo "✓ BitBot installed. Reload shell or run: source ~/.bashrc"
```

### 3.2 Platform Detection

**Runtime Platform Detection**:
```bash
#!/bin/bash
# /opt/bitbot/platform-detect.sh

detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /proc/version ] && grep -q "Microsoft\|microsoft" /proc/version; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Container detection
detect_container() {
    if [ -f "/.dockerenv" ]; then
        echo "docker"
    elif [ -n "${BITBOT_MODE}" ]; then
        echo "bitbot-container"
    else
        echo "host"
    fi
}

export BITBOT_PLATFORM=$(detect_platform)
export BITBOT_CONTEXT=$(detect_container)
```

---

## 4. Core Bash Implementation

### 4.1 Main CLI Entry Point

**bitbot command** (`~/.bitbot/bin/bitbot`):
```bash
#!/bin/bash
# BitBot Cross-Platform CLI

set -e

# Source platform detection and utilities
BITBOT_HOME="${BITBOT_HOME:-$HOME/.bitbot}"
source "$BITBOT_HOME/lib/platform.sh"
source "$BITBOT_HOME/lib/utils.sh"

# Determine execution context
CONTEXT=$(detect_container)
PLATFORM=$(detect_platform)

case "$CONTEXT" in
    "host")
        # Host context - container management
        exec "$BITBOT_HOME/lib/host-commands.sh" "$@"
        ;;
    "bitbot-container")
        # Container context - AI/workspace management
        exec "$BITBOT_HOME/lib/container-commands.sh" "$@"
        ;;
    *)
        echo "❌ Unable to determine BitBot context"
        echo "   Platform: $PLATFORM"
        echo "   Context: $CONTEXT"
        exit 1
        ;;
esac
```

### 4.2 Host Commands Implementation

**Host command handler** (`~/.bitbot/lib/host-commands.sh`):
```bash
#!/bin/bash
# BitBot Host Commands

COMMAND="${1:-smart-launch}"
WORKSPACE_PATH="$(pwd)"
WORKSPACE_HASH=$(echo -n "$WORKSPACE_PATH" | sha256sum | cut -c1-8)

export WORKSPACE_PATH WORKSPACE_HASH

case "$COMMAND" in
    # Smart launch - use config default or work mode
    smart-launch|"")
        DEFAULT_MODE=$(get_config "default_mode" "work")
        DEFAULT_INTERFACE=$(get_config "default_interface" "cli")

        if [ "$DEFAULT_INTERFACE" = "vscode" ]; then
            exec "$0" "$DEFAULT_MODE" vscode
        else
            exec "$0" "$DEFAULT_MODE"
        fi
        ;;

    # Work container management
    work)
        if [ "$2" = "vscode" ]; then
            start_work_container_vscode
        else
            start_work_container_cli
        fi
        ;;

    # Setup container management  
    setup)
        check_setup_safety || exit 1

        if [ "$2" = "vscode" ]; then
            start_setup_container_vscode
        else
            start_setup_container_cli
        fi
        ;;

    # VS Code launcher
    vscode)
        MODE="${2:-$(get_config "default_mode" "work")}"
        exec "$0" "$MODE" vscode
        ;;

    # CLI launcher
    cli)
        MODE="${2:-$(get_config "default_mode" "work")}"
        exec "$0" "$MODE"
        ;;

    # Container status and management
    status)
        show_container_status
        ;;

    stop)
        stop_containers "$2"
        ;;

    kill)
        kill_all_containers
        ;;

    # Configuration
    config)
        run_configuration_wizard "$@"
        ;;

    # First-run setup
    install)
        run_first_time_setup
        ;;

    # System diagnostics
    doctor)
        run_system_diagnostics
        ;;

    # Container context error
    done)
        echo "❌ 'bitbot done' only available inside containers"
        echo "   Use 'bitbot stop' to stop containers from host"
        exit 1
        ;;

    *)
        echo "❌ Unknown command: $COMMAND"
        echo ""
        echo "BitBot Host Commands:"
        echo "  bitbot                 Smart launch (config default)"
        echo "  bitbot work            Launch work container"
        echo "  bitbot setup           Launch setup container"
        echo "  bitbot vscode [mode]   Launch VS Code"
        echo "  bitbot status          Show container status"
        echo "  bitbot config          Configuration wizard"
        echo "  bitbot doctor          System diagnostics"
        echo ""
        exit 1
        ;;
esac
```

### 4.3 Container Commands Implementation

**Container command handler** (`~/.bitbot/lib/container-commands.sh`):
```bash
#!/bin/bash
# BitBot Container Commands

COMMAND="${1:-default-agent}"
MODE="${BITBOT_MODE:-work}"

case "$COMMAND" in
    # Launch default AI agent
    default-agent|"")
        DEFAULT_AGENT=$(get_config "default_agent" "none")

        if [ "$DEFAULT_AGENT" = "none" ]; then
            echo "No default AI agent configured."
            echo "Available agents:"
            list_available_agents
            echo ""
            echo "Configure: bitbot config"
        else
            launch_ai_agent "$DEFAULT_AGENT"
        fi
        ;;

    # Launch specific AI agents
    claude)
        launch_ai_agent "claude-code"
        ;;

    open)
        launch_ai_agent "opencode"
        ;;

    custom)
        AGENT_NAME="$2"
        if [ -z "$AGENT_NAME" ]; then
            echo "Usage: bitbot custom <agent-name>"
            echo "Available custom agents:"
            list_custom_agents
            exit 1
        fi
        launch_custom_agent "$AGENT_NAME"
        ;;

    # Session management
    session)
        exec /opt/bitbot/session-manager.sh "${@:2}"
        ;;

    # Git safety and workspace commands
    status)
        show_workspace_status
        ;;

    git)
        exec /opt/bitbot/git-commands.sh "${@:2}"
        ;;

    # Container exit with safety checks
    done)
        exec /opt/bitbot/container-exit.sh
        ;;

    # Host context error
    work|setup|vscode|install|doctor)
        echo "❌ '$COMMAND' only available on host"
        echo "   Exit container with 'bitbot done' first"
        exit 1
        ;;

    *)
        echo "❌ Unknown command: $COMMAND"
        echo ""
        echo "BitBot Container Commands ($MODE mode):"
        echo "  bitbot                 Launch default AI agent"
        echo "  bitbot claude          Launch Claude Code"
        echo "  bitbot open            Launch OpenCode"
        echo "  bitbot custom <name>   Launch custom agent"
        echo "  bitbot session         Session management"
        echo "  bitBot done            Review changes and exit"
        echo ""
        exit 1
        ;;
esac
```

---

## 5. Command Examples and Workflows

### 5.1 Typical Development Workflows

**Windows Development Workflow**:
```powershell
# From PowerShell or Command Prompt
PS C:\Projects\MyProject> bitbot

# BitBot detects Windows, launches via BitBot-Alpine WSL
# Auto-detects VS Code terminal, stays inline
# Launches work container, attaches to session

# Inside container - AI agent commands available
bitbot claude        # Launch Claude Code
bitbot done         # Review changes, commit, exit
```

**macOS/Linux Development Workflow**:
```bash
# From Terminal
$ cd ~/projects/myproject
$ bitbot

# Direct bash execution on host
# Launches work container
# Attaches to session

# Inside container
$ bitbot open       # Launch OpenCode
$ bitbot done      # Exit with safety checks
```

### 5.2 VS Code Integration Examples

**VS Code Terminal (Windows)**:
```powershell
# Detected automatically as VS Code terminal
PS C:\Projects\MyProject> bitbot vscode work
# Launches work container + opens VS Code DevContainer
```

**VS Code DevContainer Attachment**:
```bash
# From host terminal
$ bitbot work vscode

# BitBot:
# 1. Starts work container
# 2. Launches: code --remote "attach-container+bitbot-work-a1b2c3d4" /workspace
# 3. VS Code opens with full DevContainer integration
```

### 5.3 Setup Mode Examples

**Infrastructure Changes**:
```bash
# Host - enter setup mode
$ bitbot setup
# Git safety check: warns about uncommitted changes
# Prompts for confirmation
# Launches setup container with Docker socket access

# Inside setup container
$ bitbot status      # Shows workspace and git status  
$ code .devcontainer/devcontainer.json
$ bitbot done       # Commits changes, rebuilds work container, exits
```

---

## 6. Configuration and Defaults

### 6.1 User Configuration

**BitBot Config** (`~/.bitbot/config.yml`):
```yaml
# BitBot User Configuration

# Default behavior
default_mode: "work"              # work, setup
default_interface: "cli"          # cli, vscode
default_agent: "claude-code"      # claude-code, opencode, none, custom:name

# Platform-specific settings
windows:
  wsl_distro: "BitBot-Alpine"     # WSL distro to use
  vs_code_detection: true         # Auto-detect VS Code terminals
  inline_execution: true          # Stay in same terminal

macos:
  use_iterm_integration: false    # iTerm2 integration

linux:
  prefer_system_docker: true      # Use system Docker over Docker Desktop

# AI agent settings
agents:
  claude_code:
    model: "claude-3-5-sonnet"
    config_file: ".claude/config.yml"

  opencode:
    config_file: ".opencode/config.json"

# Session settings
sessions:
  auto_timestamp: true            # Use timestamp-based session names
  tmux_config: "work"            # tmux config profile (work, setup, custom)

# Git safety settings
git_safety:
  require_clean_for_setup: false # Block setup mode if uncommitted changes
  auto_checkpoint_threshold: 5   # Files changed before suggesting checkpoint
```

### 6.2 Workspace-Specific Config

**Workspace Config** (`.bitbot/config.yml`):
```yaml
# Workspace-specific BitBot configuration

# Workspace defaults
workspace:
  default_mode: "work"
  default_agent: "claude-code"

# Custom agents for this workspace
custom_agents:
  project_helper:
    command: "python .bitbot/agents/project_helper.py"
    description: "Project-specific AI helper"

# Session templates
session_templates:
  frontend:
    windows: ["main", "server", "tests"]
    commands:
      server: "npm run dev"
      tests: "npm test -- --watch"
```

---

## 7. Error Handling and Diagnostics

### 7.1 System Diagnostics

**BitBot Doctor** (`bitbot doctor`):
```bash
#!/bin/bash
# System diagnostics and health check

echo "=== BitBot System Diagnostics ==="
echo ""

# Platform detection
echo "[Platform Detection]"
echo "Platform: $(detect_platform)"
echo "Context: $(detect_container)"
echo "Shell: $SHELL"
echo ""

# Dependencies check
echo "[Dependencies]"
check_dependency "docker" "Docker" "https://docker.com/get-started"
check_dependency "git" "Git" "https://git-scm.com/downloads"

if [ "$BITBOT_PLATFORM" = "windows" ] || [ "$BITBOT_PLATFORM" = "wsl" ]; then
    check_wsl_integration
fi

if command -v devcontainer >/dev/null 2>&1; then
    echo "✓ @devcontainers/cli: $(devcontainer --version)"
else
    echo "⚠ @devcontainers/cli: Not installed (will use fallback)"
fi

echo ""

# BitBot installation check
echo "[BitBot Installation]"
echo "BITBOT_HOME: ${BITBOT_HOME:-$HOME/.bitbot}"
echo "Config file: $([ -f ~/.bitbot/config.yml ] && echo "✓ Found" || echo "⚠ Missing")"
echo "Templates: $([ -d ~/.bitbot/templates ] && echo "✓ Found" || echo "⚠ Missing")"
echo ""

# Workspace check
echo "[Current Workspace]"
if [ -d ".bitbot" ]; then
    echo "✓ BitBot workspace detected"
    echo "Workspace hash: $(echo -n "$(pwd)" | sha256sum | cut -c1-8)"

    if [ -f ".devcontainer/devcontainer.json" ]; then
        echo "✓ DevContainer configuration found"
    else
        echo "ℹ No DevContainer configuration"
    fi
else
    echo "ℹ Not a BitBot workspace (run 'bitbot' to initialize)"
fi

echo ""

# Container status
echo "[Container Status]"
show_container_status

echo ""
echo "=== Diagnostics Complete ==="
```

### 7.2 Common Error Scenarios

**Windows Docker Desktop Issues**:
```bash
# Error: Docker Desktop not running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker Desktop not running"
    echo "   Start Docker Desktop and try again"
    echo "   If issues persist: wsl --shutdown && start Docker Desktop"
    exit 1
fi

# Error: WSL integration disabled
if [ "$BITBOT_PLATFORM" = "wsl" ] && ! docker info >/dev/null 2>&1; then
    echo "❌ Docker WSL integration disabled"
    echo "   Enable WSL integration in Docker Desktop settings:"
    echo "   Settings → Resources → WSL Integration → Enable for BitBot-Alpine"
    exit 1
fi
```

**BitBot-Alpine Corruption Recovery**:
```powershell
# If BitBot-Alpine becomes corrupted
Write-Host "Resetting BitBot environment..."
wsl --unregister BitBot-Alpine
Remove-Item -Recurse -Force "$env:USERPROFILE\.bitbot\wsl"

# Re-run BitBot installer
& $env:USERPROFILE\.bitbot\bin\bitbot.ps1 install
```

---

## 8. Success Criteria

**Cross-Platform Requirements**:
- [ ] Single `bitbot` command works on Windows, macOS, Linux
- [ ] Context-aware behavior (host vs container commands)
- [ ] Windows launcher uses BitBot-Alpine WSL distro
- [ ] macOS/Linux use native bash implementation
- [ ] VS Code terminal detection works on all platforms

**Windows-Specific Requirements**:
- [ ] BitBot-Alpine distro auto-installs on first run
- [ ] Immune to Docker Desktop working directory corruption
- [ ] Inline execution preserves terminal session
- [ ] PowerShell, Command Prompt, and executable launchers work
- [ ] PATH integration allows global `bitbot` access

**Command Interface Requirements**:
- [ ] Host commands manage containers (work, setup, vscode)
- [ ] Container commands manage AI agents and workspace
- [ ] Error messages clearly indicate required context
- [ ] Configuration system allows user customization
- [ ] System diagnostics help troubleshoot issues

---

## 9. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-03, D-04, D-12: CLI decisions)
- SPEC-01: Container Orchestration (container lifecycle management)
- SPEC-02: Security Mode System (mode-specific commands)
- SPEC-07: AI Agent Integration (agent launch commands)

**External References**:
- WSL Documentation: https://docs.microsoft.com/en-us/windows/wsl/
- Docker Desktop WSL Integration: https://docs.docker.com/desktop/wsl/
- VS Code Remote Development: https://code.visualstudio.com/docs/remote/remote-overview

**Windows Corruption Analysis**:
- test-windows-launch/DOCKER-DESKTOP-CORRUPTION-ANALYSIS.md

---

**Status**: **Approved**
**Implementation Priority**: P0 (Critical - Blocking)
**Next Steps**: Implement SPEC-06 (VS Code DevContainer Integration)