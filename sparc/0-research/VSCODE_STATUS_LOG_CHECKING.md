# VS Code Status and Log Checking from Command Line

**Status:** Research Complete
**Date:** 2025-11-12
**Purpose:** Enable testing of automatic VS Code DevContainer opening from WSL/PowerShell

---

## Overview

This document describes how to check VS Code status, logs, and devcontainer state from the command line (WSL/PowerShell) to test automatic devcontainer opening functionality.

---

## VS Code CLI Status Commands

### Check Process Status

```bash
# Get VS Code process usage and diagnostics
code --status

# Shows:
# - Process information (main, shared process, extensions)
# - CPU and memory usage
# - Active windows
# - Extensions loaded
```

**Output includes:**
- Main process ID
- Window count and IDs
- Extensions host status
- Shared process information
- Performance metrics

### Check Version

```bash
# Get VS Code version info
code --version

# Shows:
# - Version number
# - Commit hash
# - Architecture (x64, arm64, etc.)
```

### Performance Profiling

```bash
# Start with performance monitoring
code --performance

# Profile startup performance
code --prof-startup

# Verbose output (useful for debugging)
code --verbose
```

---

## Checking if VS Code is Running

### PowerShell

```powershell
# Check if VS Code process is running
Get-Process | Where-Object { $_.ProcessName -eq "Code" }

# Get process details
Get-Process Code -ErrorAction SilentlyContinue

# Check for specific window title (workspace)
Get-Process Code | Where-Object { $_.MainWindowTitle -like "*workspace-name*" }

# Count VS Code instances
(Get-Process Code -ErrorAction SilentlyContinue).Count
```

### Bash/WSL

```bash
# Check if VS Code is running
ps aux | grep -i "code" | grep -v grep

# Check for specific workspace
ps aux | grep "code.*workspace-path"

# Count instances
pgrep -c Code
```

---

## Viewing Logs

### VS Code Extension Logs

**From VS Code UI:**
- Open Command Palette (F1)
- Run: `Dev Containers: Show Container Log`
- Run: `Dev Containers: Show All Logs`
- Run: `Remote-SSH: Show Log`
- Run: `WSL: Show Log`

**From Command Palette:**
1. `Output: Focus on Output View`
2. Select from dropdown:
   - `Log (Remote Extension Host)` - Remote extension issues
   - `Dev Containers` - Container operations
   - `Remote - SSH` - SSH connection logs

### Log File Locations

**Windows:**
```powershell
# VS Code logs
$env:APPDATA\Code\logs

# Extension logs
$env:USERPROFILE\.vscode\extensions
```

**Linux/WSL:**
```bash
# VS Code logs
~/.config/Code/logs

# Extension logs
~/.vscode/extensions

# Remote server logs
~/.vscode-server/data/logs
```

---

## Checking DevContainer Status

### Using Docker CLI

```bash
# List all dev containers
docker ps --filter="label=vsch.quality"

# List dev containers with source folder
docker ps -a --filter="label=devcontainer.local_folder=<path>"

# Get specific container info
docker inspect <container-id>

# Check container logs
docker logs <container-id>
```

### Using DevContainer CLI

```bash
# Install devcontainer CLI (from VS Code Command Palette)
# "Dev Containers: Install devcontainer CLI"

# Check configuration
devcontainer read-configuration --workspace-folder <path>

# Execute command in running container
devcontainer exec --workspace-folder <path> <command>
```

**Note:** DevContainer CLI does NOT have a `list-containers` or `status` command. Use Docker CLI for that.

---

## Opening DevContainers from CLI

### Open Folder in DevContainer

```bash
# Open folder in new window with remote (devcontainer)
code --folder-uri vscode-remote://dev-container+<config>/path/to/folder

# Example:
code --folder-uri vscode-remote://dev-container+7b2270617468223a222f686f6d652f757365722f70726f6a656374227d/home/user/project
```

**URI Format:**
- Protocol: `vscode-remote://`
- Authority: `dev-container+<encoded-config>`
- Path: `/path/to/folder`

### Force Open Folder (vs File)

```bash
# Add trailing slash to force folder opening
code --folder-uri vscode-remote://ssh-remote+server/path/folder/

# Or use explicit flag
code --folder-uri vscode-remote://ssh-remote+server/path/folder
```

---

## Testing DevContainer Opening

### Test Script Approach

```bash
#!/bin/bash
# Test if VS Code opened devcontainer successfully

WORKSPACE_PATH="/path/to/workspace"
TIMEOUT=30  # seconds

# 1. Open devcontainer
code "$WORKSPACE_PATH"

# 2. Wait for container to start
sleep 5

# 3. Check if container is running
CONTAINER=$(docker ps --filter="label=devcontainer.local_folder=$WORKSPACE_PATH" --format "{{.ID}}")

if [ -n "$CONTAINER" ]; then
    echo "✓ DevContainer started: $CONTAINER"

    # 4. Check if VS Code process has the window
    sleep 2
    if ps aux | grep -q "code.*$WORKSPACE_PATH"; then
        echo "✓ VS Code window opened"
        exit 0
    else
        echo "✗ VS Code window not found"
        exit 1
    fi
else
    echo "✗ DevContainer failed to start"
    exit 1
fi
```

### PowerShell Test Script

```powershell
# Test DevContainer opening from PowerShell

$workspacePath = "C:\Projects\workspace"
$timeout = 30

# 1. Launch VS Code
& code $workspacePath

# 2. Wait for process
Start-Sleep -Seconds 5

# 3. Check VS Code is running
$codeProcess = Get-Process Code -ErrorAction SilentlyContinue
if ($codeProcess) {
    Write-Host "✓ VS Code is running"

    # 4. Check container (using WSL docker)
    $container = wsl docker ps --filter="label=devcontainer.local_folder=$workspacePath" --format "{{.ID}}"

    if ($container) {
        Write-Host "✓ DevContainer started: $container"
        exit 0
    } else {
        Write-Host "✗ DevContainer not running"
        exit 1
    }
} else {
    Write-Host "✗ VS Code not running"
    exit 1
}
```

---

## Detecting VS Code Context

### From Within VS Code Terminal

**PowerShell:**
```powershell
# Check if running in VS Code integrated terminal
if ($env:TERM_PROGRAM -eq 'vscode') {
    Write-Host "Running in VS Code terminal"
}

# Check for PowerShell Integrated Console
if ($Host.Name -eq 'Visual Studio Code Host') {
    Write-Host "Running in VS Code PowerShell extension"
}
```

**Bash:**
```bash
# Check environment variable
if [ "$TERM_PROGRAM" = "vscode" ]; then
    echo "Running in VS Code terminal"
fi

# Check for environment resolution
if [ "$VSCODE_RESOLVING_ENVIRONMENT" = "1" ]; then
    echo "VS Code is sourcing environment"
fi
```

---

## Key Log Locations

### Container Logs

```bash
# Show container log from VS Code
# Command Palette: "Dev Containers: Show Container Log"

# Docker logs
docker logs <container-id>

# Docker logs with timestamps
docker logs -t <container-id>

# Follow logs in real-time
docker logs -f <container-id>
```

### VS Code Server Logs (Remote)

```bash
# Remote server log location
~/.vscode-server/data/logs/<session-id>

# Extension host logs
~/.vscode-server/data/logs/<session-id>/exthost/exthost.log

# Connection logs
~/.vscode-server/.connection.log
```

### DevContainer Extension Logs

**Access via Command Palette:**
- `Dev Containers: Show All Logs` - Shows all logging channels
- `Dev Containers: Developer: Show All Logs` - Developer view with more detail

**Manual Access:**
- Extension log files in `~/.vscode/extensions/ms-vscode-remote.remote-containers-*/`

---

## Troubleshooting Commands

### Kill/Restart VS Code Server

```bash
# From Command Palette
# "Remote-SSH: Kill VS Code Server on Host..."

# Manual (SSH/WSL)
kill <vscode-server-pid>
rm -rf ~/.vscode-server
```

### Clean Docker DevContainers

```bash
# Remove all dev containers
docker ps -a --filter="label=vsch.quality" -q | xargs docker rm -f

# Prune unused images
docker image prune -f

# Full cleanup (careful!)
docker system prune --all
```

### Check DevContainer Configuration

```bash
# Read and validate devcontainer.json
devcontainer read-configuration --workspace-folder <path>

# Check logs for configuration errors
# Command Palette: "Dev Containers: Show All Logs"
```

---

## Testing Strategy for BitBot

### Automated Test Approach

1. **Launch VS Code** with workspace path
2. **Poll for process** (check if `Code` process exists)
3. **Check container** (use `docker ps` with label filter)
4. **Verify window** (check process window title or status)
5. **Check logs** if failure (parse VS Code and Docker logs)

### Test Assertions

```bash
# 1. VS Code launched
code --status | grep -q "Version"

# 2. Process running
pgrep -x Code > /dev/null

# 3. Container running
docker ps --filter="label=devcontainer.local_folder=..." --format "{{.ID}}" | grep -q .

# 4. VS Code connected to container
# Check via logs or extension host process
```

### Alternative: Use Tmux for Testing

Similar to the interactive container test, use tmux to:
1. Start VS Code in tmux session
2. Capture output/logs via tmux pane
3. Check status via tmux capture
4. Verify completion

---

## Investigating VS Code State (From Outside)

### Storage Database Locations

**Windows:**
```powershell
# Global state database
$env:APPDATA\Code\User\globalStorage\state.vscdb

# Workspace storage
$env:APPDATA\Code\User\workspaceStorage\<workspace-hash>\state.vscdb
$env:APPDATA\Code\User\workspaceStorage\<workspace-hash>\workspace.json
```

**Linux/macOS:**
```bash
# Global state database
~/.config/Code/User/globalStorage/state.vscdb  # Linux
~/Library/Application Support/Code/User/globalStorage/state.vscdb  # macOS

# Workspace storage
~/.config/Code/User/workspaceStorage/<workspace-hash>/
~/Library/Application Support/Code/User/workspaceStorage/<workspace-hash>/
```

### Workspace Storage Structure

Each workspace gets a folder named with a hash (MD5 of workspace path + creation time):

```
workspaceStorage/
└── <workspace-hash>/
    ├── workspace.json       # Contains workspace URI
    ├── state.vscdb          # SQLite database with workspace state
    └── state.vscdb.backup   # Backup of state database
```

### Inspecting SQLite Databases

**Using sqlite3 CLI:**

```bash
# Open global state database
sqlite3 ~/.config/Code/User/globalStorage/state.vscdb

# List all tables
.tables

# Query ItemTable (main storage table)
SELECT key, value FROM ItemTable;

# Search for specific keys
SELECT * FROM ItemTable WHERE key LIKE '%history.recent%';

# Get recent workspaces
SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList';
```

**Using Python:**

```python
import sqlite3
import json

# Connect to database
conn = sqlite3.connect('~/.config/Code/User/globalStorage/state.vscdb')
cursor = conn.cursor()

# Query all data
cursor.execute("SELECT key, value FROM ItemTable")
for key, value in cursor.fetchall():
    print(f"{key}: {value[:100]}...")  # First 100 chars

# Get recent workspaces
cursor.execute("SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'")
result = cursor.fetchone()
if result:
    workspaces = json.loads(result[0])
    print(json.dumps(workspaces, indent=2))

conn.close()
```

### Finding Active Workspace

**From workspace hash:**

```bash
# List all workspace storage dirs
ls ~/.config/Code/User/workspaceStorage/

# Check workspace.json for each
for dir in ~/.config/Code/User/workspaceStorage/*/; do
    echo "=== $dir ==="
    cat "$dir/workspace.json" 2>/dev/null
done
```

**workspace.json format:**

```json
{
  "folder": "file:///path/to/workspace"
}
```

### Checking Recent Workspaces

**Query global state:**

```bash
# Extract recent workspaces from SQLite
sqlite3 ~/.config/Code/User/globalStorage/state.vscdb \
  "SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'" \
  | jq .
```

**Output format:**

```json
{
  "entries": [
    {
      "folderUri": {
        "$mid": 1,
        "path": "/home/user/project",
        "scheme": "file"
      },
      "label": "project"
    }
  ]
}
```

### Workspace Storage Database Schema

**ItemTable structure:**

```sql
CREATE TABLE ItemTable (
    key TEXT NOT NULL,
    value TEXT
);
```

**Common keys:**
- `workbench.panel.opened` - Panel state
- `workbench.sidebar.hidden` - Sidebar visibility
- `workbench.activity.pinnedViewlets` - Pinned views
- `terminal.integrated.tabs.hidden` - Terminal state
- Extension-specific keys (e.g., `extension.gitlens.state`)

### Checking if DevContainer is Open

**Method 1: Check workspace state for remote info:**

```bash
# Find workspace storage for your project
WORKSPACE_PATH="/path/to/project"
WORKSPACE_HASH=$(find ~/.config/Code/User/workspaceStorage/ -name "workspace.json" \
  -exec grep -l "$WORKSPACE_PATH" {} \; | head -1 | xargs dirname | xargs basename)

if [ -n "$WORKSPACE_HASH" ]; then
    echo "Found workspace storage: $WORKSPACE_HASH"

    # Check state database for remote connection
    sqlite3 ~/.config/Code/User/workspaceStorage/$WORKSPACE_HASH/state.vscdb \
      "SELECT * FROM ItemTable WHERE key LIKE '%remote%' OR key LIKE '%container%'"
fi
```

**Method 2: Check global state for active remote:**

```bash
# Query for remote/container keys in global state
sqlite3 ~/.config/Code/User/globalStorage/state.vscdb \
  "SELECT key, value FROM ItemTable WHERE key LIKE '%remote%' OR key LIKE '%devcontainer%'"
```

### VS Code Window State Files

**Window state location:**

```bash
# Windows
%APPDATA%\Code\User\windowState.vscdb

# Linux
~/.config/Code/User/windowState.vscdb
```

**Contains:**
- Open windows
- Window positions and sizes
- Recent folders per window

### Extension Global Storage

Extensions store global data in:

```bash
~/.config/Code/User/globalStorage/<extension-id>/
```

**DevContainer extension:**

```bash
~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers*/
```

### Practical Testing Script

```bash
#!/bin/bash
# Check if VS Code has a devcontainer open

WORKSPACE=$1
VSCODE_USER_DIR="$HOME/.config/Code/User"

echo "Checking VS Code state for workspace: $WORKSPACE"

# 1. Find workspace storage hash
echo -e "\n[1] Looking for workspace storage..."
STORAGE_DIRS=$(find "$VSCODE_USER_DIR/workspaceStorage" -name "workspace.json" \
  -exec grep -l "$(echo $WORKSPACE | sed 's/\//\\\//g')" {} \; 2>/dev/null)

if [ -z "$STORAGE_DIRS" ]; then
    echo "✗ No workspace storage found"
    exit 1
fi

WORKSPACE_HASH=$(dirname "$STORAGE_DIRS" | head -1 | xargs basename)
echo "✓ Found workspace hash: $WORKSPACE_HASH"

# 2. Check workspace state database
echo -e "\n[2] Checking workspace state..."
STATE_DB="$VSCODE_USER_DIR/workspaceStorage/$WORKSPACE_HASH/state.vscdb"

if [ ! -f "$STATE_DB" ]; then
    echo "✗ State database not found"
    exit 1
fi

# Check for remote/container indicators
REMOTE_KEYS=$(sqlite3 "$STATE_DB" \
  "SELECT key FROM ItemTable WHERE key LIKE '%remote%' OR key LIKE '%container%'" 2>/dev/null)

if [ -n "$REMOTE_KEYS" ]; then
    echo "✓ Remote/container keys found:"
    echo "$REMOTE_KEYS"
else
    echo "ℹ No remote/container keys (might be local workspace)"
fi

# 3. Check Docker for running container
echo -e "\n[3] Checking for Docker container..."
CONTAINER=$(docker ps --filter="label=devcontainer.local_folder=$WORKSPACE" --format "{{.ID}}")

if [ -n "$CONTAINER" ]; then
    echo "✓ DevContainer running: $CONTAINER"
    exit 0
else
    echo "✗ No DevContainer found"
    exit 1
fi
```

### PowerShell Version

```powershell
# Check VS Code workspace state from PowerShell

param(
    [string]$WorkspacePath
)

$vsCodeUserDir = "$env:APPDATA\Code\User"

Write-Host "Checking VS Code state for: $WorkspacePath"

# 1. Find workspace storage
Write-Host "`n[1] Looking for workspace storage..."
$workspaceFiles = Get-ChildItem -Path "$vsCodeUserDir\workspaceStorage" -Recurse -Filter "workspace.json" |
    Where-Object { (Get-Content $_.FullName) -match [regex]::Escape($WorkspacePath) }

if (-not $workspaceFiles) {
    Write-Host "✗ No workspace storage found"
    exit 1
}

$workspaceHash = Split-Path -Parent $workspaceFiles[0].FullName | Split-Path -Leaf
Write-Host "✓ Found workspace hash: $workspaceHash"

# 2. Check state database
Write-Host "`n[2] Checking workspace state..."
$stateDb = "$vsCodeUserDir\workspaceStorage\$workspaceHash\state.vscdb"

if (Test-Path $stateDb) {
    # Query using sqlite3 or other tool
    Write-Host "✓ State database exists"
    # Note: Would need sqlite3.exe or similar to query
} else {
    Write-Host "✗ State database not found"
}

# 3. Check Docker container
Write-Host "`n[3] Checking for Docker container..."
$container = wsl docker ps --filter="label=devcontainer.local_folder=$WorkspacePath" --format "{{.ID}}"

if ($container) {
    Write-Host "✓ DevContainer running: $container"
    exit 0
} else {
    Write-Host "✗ No DevContainer found"
    exit 1
}
```

---

## References

- [VS Code Command Line Interface](https://code.visualstudio.com/docs/configure/command-line)
- [Dev Containers Tips and Tricks](https://code.visualstudio.com/docs/devcontainers/tips-and-tricks)
- [Remote Development Troubleshooting](https://code.visualstudio.com/docs/remote/troubleshooting)
- [DevContainer CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)
- [DevContainers CLI GitHub](https://github.com/devcontainers/cli)

---

## Summary

**Key Commands:**
- `code --status` - Process and diagnostics info
- `code --version` - Version information
- `Get-Process Code` (PowerShell) - Check if running
- `docker ps --filter="label=vsch.quality"` - List dev containers
- `Dev Containers: Show Container Log` (UI) - View container logs
- `docker logs <container-id>` - View container output

**No Built-in Commands For:**
- Listing all devcontainers (use Docker CLI)
- Checking if specific devcontainer is open (check Docker + process)
- DevContainer-specific status (must combine Docker + VS Code process checks)

**Best Testing Approach:**
Combine multiple checks:
1. VS Code process running (`code --status` or `Get-Process`)
2. Container running (`docker ps` with filters)
3. Logs available (`docker logs` + VS Code extension logs)
4. Window title check (PowerShell `MainWindowTitle`)
