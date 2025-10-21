# Cross-Platform CLI Specification

**Feature ID**: SPEC-05
**Priority**: P0 (Critical - Blocking)
**Status**: In Progress (Direct dev container opening implemented for Windows)
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes), SPEC-04 (Session Management)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20 (Added complete workflow documentation)

---

## Executive Summary

Bash-based CLI with minimal Windows launcher. Short command style for common workflows. Platform detection for Linux, macOS, and Windows/WSL2.

**Key Design**: Bash core + Windows .exe launcher + short commands + platform detection = unified cross-platform experience.

---

## 1. Architecture

### 1.1 Implementation Strategy

**Core**: Bash scripts (main implementation)
**Windows**: Minimal .exe launcher → calls bash in WSL2
**macOS/Linux**: Direct bash execution

**Rationale**:
- Simpler to implement than Go/Rust
- Legacy BitBot already 85% complete in bash
- No compilation needed for core
- Windows launcher provides native experience

### 1.2 File Structure

```
/opt/bitbot/
├── bin/
│   ├── bitbot                    # Main bash script
│   ├── bitbot-core.sh            # Core functions
│   ├── bitbot-session.sh         # Session management
│   ├── bitbot-mcp.sh             # MCP commands
│   └── bitbot.exe                # Windows launcher (minimal)
│
├── lib/
│   ├── platform.sh               # Platform detection
│   ├── docker.sh                 # Docker operations
│   ├── workspace.sh              # Workspace management
│   └── utils.sh                  # Utility functions
│
└── config/
    └── default-config.yml        # Default configuration
```

---

## 2. Complete User Workflow

### 2.1 Entry Points

**Windows Entry**:
```powershell
# PowerShell or cmd.exe
C:\> bitbot work

# Calls bitbot.exe launcher
# → Launches WSL Alpine
# → Executes /opt/bitbot/bin/bitbot work
```

**WSL/Linux Entry**:
```bash
# Direct bash execution
$ bitbot work

# Executes /opt/bitbot/bin/bitbot work directly
```

### 2.2 BitBot Launcher Script Flow

**Step 1: Platform Detection & Container Building**

```bash
# bitbot-core.sh

# 1. Detect platform
platform=$(detect_platform)  # wsl2, linux, macos

# 2. Choose devcontainer command
if [[ "$platform" == "wsl2" ]]; then
    # Windows: Use .cmd wrapper (avoids WSL path corruption)
    devcontainer_cmd="devcontainer.cmd"
else
    # macOS/Linux: Use standard devcontainer
    devcontainer_cmd="devcontainer"
fi

# 3. Check if VS Code installed (has builtin devcontainer CLI)
if command -v code &>/dev/null; then
    # VS Code installed: Use builtin CLI
    devcontainer_cli="code --locate-extension ms-vscode-remote.remote-containers"
    # Use VS Code's bundled devcontainer CLI
else
    # No VS Code: Check for standalone devcontainer CLI
    if ! command -v devcontainer &>/dev/null; then
        # Install standalone devcontainer CLI
        npm install -g @devcontainers/cli
    fi
fi

# 4. Build and run devcontainer
$devcontainer_cmd up --workspace-folder "$(pwd)"
```

### 2.3 Launch Mode Selection

**Option A: VS Code Launch** (`bitbot work vscode`):
```bash
# Launch VS Code directly into devcontainer using hex-encoded URI
# (Decision VS Code Direct DevContainer Opening)

workspace_path="$(pwd)"
if [[ "$platform" == "wsl2" ]]; then
    windows_path=$(wslpath -w "$workspace_path")
    hex_path=$(path_to_hex "$windows_path")
    code.exe --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
else
    hex_path=$(path_to_hex "$workspace_path")
    code --folder-uri="vscode-remote://dev-container+${hex_path}/workspace"
fi

# VS Code opens directly in devcontainer (no popup)
# User continues in VS Code integrated terminal
```

**Option B: Terminal Launch** (`bitbot work`):
```bash
# Attach to devcontainer terminal
container_name="bitbot-dev-${workspace_hash}"
docker exec -it "$container_name" /bin/bash -c "cd /workspace && exec bash"

# User lands in devcontainer terminal
```

### 2.4 BitBot Agent Execution

**Inside devcontainer terminal**:
```bash
# Terminal is now in devcontainer
root@bitbot:/workspace$

# BitBot agent script runs automatically or via prompt
# Shows session management menu
```

### 2.5 Session Management Choice

**Interactive menu**:
```
BitBot Session Manager

Choose an option:
  1) Resume active detached session (tmux)
  2) Resume inactive AI session (claude --resume)
  3) Start new AI session (claude)
  4) Exit to shell

Choice: _
```

**Implementation**:
```bash
# bitbot-session-menu.sh

show_session_menu() {
    echo "BitBot Session Manager"
    echo ""
    echo "Choose an option:"
    echo "  1) Resume active detached session (tmux)"
    echo "  2) Resume inactive AI session (claude --resume)"
    echo "  3) Start new AI session (claude)"
    echo "  4) Exit to shell"
    echo ""
    read -p "Choice: " choice

    case "$choice" in
        1)
            # Show tmux sessions and let user choose
            tmux list-sessions
            read -p "Session name: " session_name
            tmux attach -t "$session_name"
            ;;
        2)
            # Resume last Claude session
            claude --resume
            ;;
        3)
            # Start new Claude session
            read -p "Session name (optional): " session_name
            if [[ -n "$session_name" ]]; then
                claude --session "$session_name"
            else
                claude
            fi
            ;;
        4)
            # Exit to shell
            echo "Exiting to shell..."
            exit 0
            ;;
        *)
            echo "Invalid choice"
            show_session_menu
            ;;
    esac
}

# Run menu
show_session_menu
```

### 2.6 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Entry Points                                               │
├─────────────────────────────────────────────────────────────┤
│  PowerShell/cmd → WSL Alpine    OR    WSL Terminal         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  BitBot Launcher Script (/opt/bitbot/bin/bitbot)           │
├─────────────────────────────────────────────────────────────┤
│  • Detect platform (wsl2/linux/macos)                      │
│  • Choose devcontainer command (devcontainer.cmd or         │
│    devcontainer)                                            │
│  • Check VS Code installation (builtin CLI vs standalone)  │
│  • Build and run devcontainer                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Launch Mode Selection                                      │
├─────────────────────────────────────────────────────────────┤
│  A) VS Code Launch (vscode flag)                         │
│     └─ Open using hex-encoded folder URI                   │
│        (VS Code Direct DevContainer Opening)          │
│                                                             │
│  B) Terminal Launch (default)                              │
│     └─ docker exec into devcontainer terminal              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Inside Devcontainer                                        │
├─────────────────────────────────────────────────────────────┤
│  • Run BitBot agent script                                  │
│  • Show session management menu                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Session Management Choice                                  │
├─────────────────────────────────────────────────────────────┤
│  1) Resume detached tmux session                           │
│     └─ tmux attach -t <session>                            │
│                                                             │
│  2) Resume inactive AI session                             │
│     └─ claude --resume                                     │
│                                                             │
│  3) Start new AI session                                   │
│     └─ claude [--session <name>]                           │
│                                                             │
│  4) Exit to shell                                          │
│     └─ Drop to bash prompt                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Command Structure

### 3.1 Short Command Style

**Primary commands**:
```bash
bitbot                  # Smart launch (work mode, CLI)
bitbot work             # Launch work mode (CLI)
bitbot setup            # Launch setup mode (CLI)
bitbot work vscode    # Launch work mode (VS Code)
bitbot setup vscode   # Launch setup mode (VS Code)
```

**Session commands**:
```bash
bitbot session new <name>
bitbot session attach <name>
bitbot session list
bitbot session kill <name>
bitbot session save
bitbot session restore
```

**MCP commands**:
```bash
bitbot mcp list
bitbot mcp logs <service>
bitbot mcp restart <service>
bitbot mcp start
bitbot mcp stop
```

**Utility commands**:
```bash
bitbot status           # Show workspace/container status
bitbot stop             # Stop workspace containers
bitbot restart          # Restart workspace
bitbot logs             # Show BitBot logs
bitbot version          # Show version
bitbot help             # Show help
```

### 3.2 Command Routing

**Main dispatcher** (`bin/bitbot`):
```bash
#!/usr/bin/env bash

# Load core
source /opt/bitbot/bin/bitbot-core.sh

# Parse command
COMMAND="${1:-}"
shift

case "$COMMAND" in
  ""|work|setup)
    cmd_mode "$COMMAND" "$@"
    ;;
  session)
    cmd_session "$@"
    ;;
  mcp)
    cmd_mcp "$@"
    ;;
  status|stop|restart|logs|version|help)
    cmd_utility "$COMMAND" "$@"
    ;;
  *)
    error "Unknown command: $COMMAND"
    show_help
    exit 1
    ;;
esac
```

---

## 3. Platform Detection

### 3.1 Platform Identification

**Detection** (`lib/platform.sh`):
```bash
#!/usr/bin/env bash

detect_platform() {
  local os=$(uname -s)
  local arch=$(uname -m)

  case "$os" in
    Linux*)
      if grep -qi microsoft /proc/version; then
        echo "wsl2"
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

BITBOT_PLATFORM=$(detect_platform)
```

### 3.2 Platform-Specific Paths

**Path translation** (Windows/WSL):
```bash
# Windows path to WSL path
translate_path() {
  local path="$1"
  local platform="$2"

  if [[ "$platform" == "wsl2" ]]; then
    # C:\Projects\MyApp → /mnt/c/Projects/MyApp
    if [[ "$path" =~ ^[A-Za-z]:\\ ]]; then
      local drive="${path:0:1}"
      local rest="${path:3}"
      echo "/mnt/${drive,,}/${rest//\\//}"
    else
      echo "$path"
    fi
  else
    echo "$path"
  fi
}
```

**Docker socket path**:
```bash
get_docker_socket() {
  case "$BITBOT_PLATFORM" in
    wsl2)
      echo "/var/run/docker.sock"
      ;;
    macos)
      echo "/var/run/docker.sock"
      ;;
    linux)
      echo "/var/run/docker.sock"
      ;;
  esac
}
```

---

## 4. Windows Integration

### 4.1 Windows Launcher

**Purpose**: Minimal .exe to call bash in WSL2

**Implementation** (C# or Go):
```csharp
// bitbot.exe (minimal C# launcher)
using System;
using System.Diagnostics;

class BitBotLauncher {
    static void Main(string[] args) {
        // Check WSL installed
        if (!IsWSLInstalled()) {
            Console.Error.WriteLine("Error: WSL2 not installed");
            Console.Error.WriteLine("Install: https://aka.ms/wsl2");
            Environment.Exit(1);
        }

        // Build command
        var command = "bash /opt/bitbot/bin/bitbot " + string.Join(" ", args);

        // Execute in WSL
        var psi = new ProcessStartInfo {
            FileName = "wsl.exe",
            Arguments = $"-e {command}",
            UseShellExecute = false
        };

        var process = Process.Start(psi);
        process.WaitForExit();
        Environment.Exit(process.ExitCode);
    }

    static bool IsWSLInstalled() {
        try {
            var psi = new ProcessStartInfo {
                FileName = "wsl.exe",
                Arguments = "--status",
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            var process = Process.Start(psi);
            process.WaitForExit();
            return process.ExitCode == 0;
        } catch {
            return false;
        }
    }
}
```

### 4.2 Windows Installation

**Installation script** (`install.ps1`):
```powershell
# BitBot Windows Installation
Write-Host "Installing BitBot for Windows..."

# Check WSL2
if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Error "WSL2 not found. Install from: https://aka.ms/wsl2"
    exit 1
}

# Copy bitbot.exe to PATH
$installPath = "$env:LOCALAPPDATA\BitBot"
New-Item -ItemType Directory -Force -Path $installPath
Copy-Item "bitbot.exe" "$installPath\bitbot.exe"

# Add to PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($path -notlike "*$installPath*") {
    [Environment]::SetEnvironmentVariable(
        "PATH",
        "$path;$installPath",
        "User"
    )
}

# Install bash scripts in WSL
wsl -e bash -c "curl -fsSL https://bitbot.sh/install.sh | bash"

Write-Host "BitBot installed! Run: bitbot"
```

---

## 5. Core Commands Implementation

### 5.1 Mode Launch Commands

**bitbot work** (`bitbot-core.sh`):
```bash
cmd_mode() {
  local mode="${1:-work}"  # Default to work
  shift

  # Parse flags
  local vscode=false
  local attach_session=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      vscode)
        vscode=true
        shift
        ;;
      --attach)
        attach_session="$2"
        shift 2
        ;;
      *)
        error "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  # Get workspace hash
  local workspace_hash=$(calculate_workspace_hash "$(pwd)")

  # Start MCP services
  start_workspace_mcp_services "$workspace_hash"

  # Start container
  if [[ "$mode" == "work" ]]; then
    start_work_container "$workspace_hash" "$vscode" "$attach_session"
  elif [[ "$mode" == "setup" ]]; then
    start_setup_container "$workspace_hash" "$vscode" "$attach_session"
  fi
}
```

**start_work_container**:
```bash
start_work_container() {
  local workspace_hash="$1"
  local vscode="$2"
  local attach_session="$3"

  local container_name="bitbot-dev-${workspace_hash}"

  # Check if container exists
  if ! docker ps -a --filter "name=$container_name" --format '{{.Names}}' | grep -q "^${container_name}$"; then
    # Create container
    docker-compose -f .bitbot/docker-compose.work.yml up -d
  fi

  # Start if stopped
  if ! docker ps --filter "name=$container_name" --format '{{.Names}}' | grep -q "^${container_name}$"; then
    docker start "$container_name"
  fi

  # Attach
  if [[ "$vscode" == "true" ]]; then
    # Launch VS Code directly in dev container (Decision VS Code Direct DevContainer Opening)
    # Uses hex-encoded URI to bypass "Reopen in Container" popup
    local workspace_path="$(pwd)"
    open_vscode_devcontainer "$workspace_path"
  else
    # Attach to tmux session
    local session="${attach_session:-main}"
    docker exec -it "$container_name" tmux attach -t "work-${session}"
  fi
}
```

### 5.2 Session Commands

**bitbot session** (`bitbot-session.sh`):
```bash
cmd_session() {
  local subcommand="$1"
  shift

  case "$subcommand" in
    new)
      session_new "$@"
      ;;
    attach)
      session_attach "$@"
      ;;
    list)
      session_list "$@"
      ;;
    kill)
      session_kill "$@"
      ;;
    save)
      session_save "$@"
      ;;
    restore)
      session_restore "$@"
      ;;
    *)
      error "Unknown session command: $subcommand"
      exit 1
      ;;
  esac
}
```

**session_new**:
```bash
session_new() {
  local name="$1"
  local mode=$(get_current_mode)

  if [[ -z "$name" ]]; then
    error "Usage: bitbot session new <name>"
    exit 1
  fi

  local session_name="${mode}-${name}"

  # Create tmux session
  tmux new-session -d -s "$session_name" -c /workspace

  echo "Created session: $session_name"
  echo "Attach with: bitbot session attach $name"
}
```

### 5.3 MCP Commands

**bitbot mcp** (`bitbot-mcp.sh`):
```bash
cmd_mcp() {
  local subcommand="$1"
  shift

  case "$subcommand" in
    list)
      mcp_list "$@"
      ;;
    logs)
      mcp_logs "$@"
      ;;
    restart)
      mcp_restart "$@"
      ;;
    start)
      mcp_start "$@"
      ;;
    stop)
      mcp_stop "$@"
      ;;
    *)
      error "Unknown mcp command: $subcommand"
      exit 1
      ;;
  esac
}
```

**mcp_list**:
```bash
mcp_list() {
  local workspace_hash=$(calculate_workspace_hash "$(pwd)")

  echo "Global MCP Services:"
  curl -s http://localhost:8080/api/services?scope=global | jq -r '.services[] | "\(.name)\t\(.health)"'

  echo ""
  echo "Workspace MCP Services:"
  curl -s "http://localhost:9080/api/services?workspace=${workspace_hash}" | jq -r '.services[] | "\(.name)\t\(.health)"'
}
```

### 5.5 VS Code Direct DevContainer Opening 

**Implementation** (`lib/vscode.sh`):
```bash
#!/usr/bin/env bash

# Open VS Code directly in dev container using hex-encoded URI
# Bypasses "Reopen in Container" popup
open_vscode_devcontainer() {
    local workspace_path="$1"
    local platform=$(detect_platform)

    case "$platform" in
        wsl2)
            # Convert WSL path to Windows path
            local windows_path=$(wslpath -w "$workspace_path")
            # Encode to hex
            local hex_path=$(path_to_hex "$windows_path")
            # Build URI
            local uri="vscode-remote://dev-container+${hex_path}/workspace"
            # Open in VS Code
            code.exe --folder-uri="$uri"
            ;;

        macos|linux)
            # Native execution
            local hex_path=$(path_to_hex "$workspace_path")
            local uri="vscode-remote://dev-container+${hex_path}/workspace"
            code --folder-uri="$uri"
            ;;

        windows)
            # Windows native (rare - usually via WSL)
            error "Windows native not supported. Use WSL2."
            return 1
            ;;
    esac
}

# Convert path to hexadecimal for VS Code URI
path_to_hex() {
    local path="$1"

    # Try xxd first (common on Linux/macOS)
    if command -v xxd &> /dev/null; then
        printf "%s" "$path" | xxd -p -c 256 | tr -d '\n'
    else
        # Fallback: use od (universal, available in Alpine)
        printf "%s" "$path" | od -A n -t x1 | tr -d ' \n'
    fi
}
```

**Benefits**:
- ✅ No "Reopen in Container" popup
- ✅ VS Code opens directly in dev container
- ✅ Container reuse on subsequent opens
- ✅ Simplified dependencies (no devcontainer CLI needed)
- ✅ No WSL corruption (no Docker commands through WSL)

**See Also**:
- Direct DevContainer Opening (VS Code Direct DevContainer Opening)
- SPEC-06 Section 0 (VS Code Direct DevContainer Opening details)
- `test-windows-launch/FINAL-BITBOT-ARCHITECTURE.md`

---

## 6. Workspace Detection

### 6.1 Workspace Hash Calculation

**Generate workspace hash**:
```bash
calculate_workspace_hash() {
  local workspace_path="$1"

  # Normalize path
  local normalized=$(realpath "$workspace_path")

  # Calculate SHA-256 hash (first 8 chars)
  echo -n "$normalized" | sha256sum | cut -c1-8
}
```

### 6.2 Workspace Validation

**Check if in workspace**:
```bash
validate_workspace() {
  local workspace_path="$(pwd)"

  # Check for .bitbot directory
  if [[ ! -d ".bitbot" ]]; then
    error "Not in a BitBot workspace"
    echo "Initialize with: bitbot init"
    exit 1
  fi

  # Check for .devcontainer
  if [[ ! -d ".devcontainer" ]]; then
    warn "No .devcontainer found, using default"
  fi
}
```

**Initialize workspace**:
```bash
cmd_init() {
  local workspace_path="$(pwd)"

  echo "Initializing BitBot workspace..."

  # Create .bitbot structure
  mkdir -p .bitbot/{setup,logs,sessions,state,mcp}

  # Copy default configs
  cp /opt/bitbot/templates/docker-compose.work.yml .bitbot/
  cp /opt/bitbot/templates/docker-compose.setup.yml .bitbot/
  cp /opt/bitbot/templates/mcp-docker-compose.yml .bitbot/mcp/docker-compose.yml

  # Copy default .devcontainer if not exists
  if [[ ! -d ".devcontainer" ]]; then
    cp -r /opt/bitbot/templates/devcontainer .devcontainer
  fi

  echo "✓ BitBot workspace initialized"
  echo "Run: bitbot work"
}
```

---

## 7. Error Handling

### 7.1 Error Types

**User errors**:
```bash
# Missing argument
error "Usage: bitbot session new <name>"

# Invalid workspace
error "Not in a BitBot workspace. Run: bitbot init"

# Container not running
error "Container not running. Start with: bitbot work"
```

**System errors**:
```bash
# Docker not running
if ! docker ps &>/dev/null; then
  error "Docker is not running"
  echo "Start Docker and try again"
  exit 1
fi

# WSL not installed (Windows)
if ! command -v wsl &>/dev/null; then
  error "WSL2 not installed"
  echo "Install from: https://aka.ms/wsl2"
  exit 1
fi
```

### 7.2 Error Messages

**Format**:
```bash
error() {
  echo "Error: $*" >&2
}

warn() {
  echo "Warning: $*" >&2
}

info() {
  echo "$*"
}

success() {
  echo "✓ $*"
}
```

---

## 8. Help System

### 8.1 Command Help

**Main help**:
```bash
show_help() {
  cat <<EOF
BitBot - AI-Assisted Development Environment

Usage:
  bitbot [command] [options]

Commands:
  work              Launch work mode (default)
  setup             Launch setup mode
  session           Manage tmux sessions
  mcp               Manage MCP services
  status            Show workspace status
  stop              Stop workspace
  restart           Restart workspace
  init              Initialize workspace
  version           Show version
  help              Show this help

Options:
  vscode          Launch in VS Code
  --attach <name>   Attach to specific session

Examples:
  bitbot                    # Start work mode
  bitbot work vscode      # Start work mode in VS Code
  bitbot setup              # Start setup mode
  bitbot session list       # List sessions
  bitbot mcp list           # List MCP services

Documentation: https://docs.bitbot.dev
EOF
}
```

**Session help**:
```bash
show_session_help() {
  cat <<EOF
bitbot session - Manage tmux sessions

Usage:
  bitbot session <command> [options]

Commands:
  new <name>        Create new session
  attach <name>     Attach to session
  list              List all sessions
  kill <name>       Kill session
  save              Save session state
  restore           Restore session state

Examples:
  bitbot session new feature-x
  bitbot session attach main
  bitbot session list
EOF
}
```

---

## 9. Configuration

### 9.1 Config File Locations

**Priority** (first found wins):
1. `.bitbot/config.yml` (workspace-specific)
2. `~/.bitbot/config.yml` (user-specific)
3. `/opt/bitbot/config/default-config.yml` (system default)

### 9.2 Config Format

**Example config** (`.bitbot/config.yml`):
```yaml
# BitBot Configuration

# Default mode
default_mode: work

# Platform-specific settings
platform:
  wsl2:
    docker_socket: /var/run/docker.sock
  macos:
    docker_socket: /var/run/docker.sock

# Session settings
sessions:
  autosave: true
  autosave_interval_minutes: 15
  default_shell: /bin/zsh

# MCP settings
mcp:
  global_discovery_url: http://localhost:8080
  workspace_discovery_port: 9080

# Container settings
containers:
  work:
    image: bitbot/devcontainer:latest
    shell: /bin/zsh
  setup:
    image: bitbot/setup-container:latest
    shell: /bin/bash

# Logging
logging:
  level: info
  file: .bitbot/logs/bitbot.log
```

### 9.3 Config Loading

**Load config**:
```bash
load_config() {
  local config_file=""

  # Find config file
  if [[ -f ".bitbot/config.yml" ]]; then
    config_file=".bitbot/config.yml"
  elif [[ -f "$HOME/.bitbot/config.yml" ]]; then
    config_file="$HOME/.bitbot/config.yml"
  else
    config_file="/opt/bitbot/config/default-config.yml"
  fi

  # Parse YAML (using yq or simple grep)
  BITBOT_DEFAULT_MODE=$(yq e '.default_mode' "$config_file")
  BITBOT_AUTOSAVE=$(yq e '.sessions.autosave' "$config_file")
  # ... etc
}
```

---

## 10. Testing Strategy

### 10.1 Platform Tests

- PT-01: Detect Linux platform
- PT-02: Detect macOS platform
- PT-03: Detect WSL2 platform
- PT-04: Translate Windows paths to WSL
- PT-05: Docker socket detection per platform

### 10.2 Command Tests

- CT-01: `bitbot work` starts work container
- CT-02: `bitbot setup` starts setup container
- CT-03: `bitbot vscode` launches VS Code
- CT-04: `bitbot session new` creates session
- CT-05: `bitbot mcp list` shows services
- CT-06: `bitbot status` shows workspace state

### 10.3 Integration Tests

- INT-01: Windows .exe calls bash in WSL
- INT-02: Config loading from multiple locations
- INT-03: Workspace initialization
- INT-04: Error handling for invalid commands
- INT-05: Help system displays correctly

---

## 11. Success Criteria

**Functional**:
- [ ] CLI works on Linux, macOS, WSL2
- [ ] Windows .exe launcher works
- [ ] Short commands route correctly
- [ ] Platform detection accurate
- [ ] Config loading works
- [ ] Error messages helpful

**Cross-Platform**:
- [ ] Same commands on all platforms
- [ ] Path translation for WSL
- [ ] Docker socket detection
- [ ] Native experience (Windows .exe)

**Usability**:
- [ ] Simple command syntax
- [ ] Clear help messages
- [ ] Fast execution (<1s for status commands)
- [ ] Good error messages

---

## 12. Implementation Phases

**Phase 1: Core Bash CLI**:
- Platform detection
- Command routing
- Mode launch commands (work/setup)
- Basic error handling

**Phase 2: Session Commands**:
- Session management commands
- Integration with tmux
- Session persistence commands

**Phase 3: MCP Commands**:
- MCP service management
- Service listing and logs
- Integration with discovery server

**Phase 4: Windows Launcher**:
- C# .exe launcher
- WSL integration
- Windows installation script
- PATH setup

**Phase 5: Config & Help**:
- Config file loading
- Help system
- Workspace initialization
- Full error handling

---

## 13. References

**Related Specifications**:
- SPEC-01: Container Orchestration (container management)
- SPEC-02: Security Mode System (mode switching)
- SPEC-03: MCP Service Architecture (mcp commands)
- SPEC-04: Session Management (session commands)

**External Tools**:
- Bash: https://www.gnu.org/software/bash/
- yq (YAML parser): https://github.com/mikefarah/yq
- WSL2: https://docs.microsoft.com/windows/wsl/

**Research Sources**:
- User decision: Bash implementation (D-07)
- User decision: Short commands (D-08)
- Legacy BitBot: 85% complete bash implementation

---

**Status**: **Draft**
**Implementation Priority**: P0 (Blocking for MVP)
**Next Steps**: SPEC-06 (VS Code DevContainer Integration)
