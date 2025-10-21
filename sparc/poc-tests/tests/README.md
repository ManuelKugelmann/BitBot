# BitBot Test Launcher Scripts

**Status**: Prototype implementation for testing the complete BitBot workflow

## Overview

These scripts implement the full BitBot workflow documented in the specifications:
- Entry points (Windows/WSL)
- Platform detection
- DevContainer CLI detection/installation
- Container building
- VS Code or terminal launching

## Files

### Entry Points (in `../scripts/`)

| File | Purpose | Platform |
|------|---------|----------|
| `bitbot.ps1` | PowerShell entry point | Windows (PowerShell 5+) |
| `bitbot.bat` | Batch entry point | Windows (cmd.exe) |
| `bitbot` | Main launcher script | WSL/Linux/macOS (bash) |
| `bitbot-debug.ps1` | Debug version (shows execution details) | Windows (PowerShell) |

**Note**: These launcher scripts are now in `scripts/` for production use.

### Architecture

```
┌─────────────────────────────────────────────────┐
│  Windows Entry Points                           │
├─────────────────────────────────────────────────┤
│  scripts/bitbot.ps1  or  scripts/bitbot.bat    │
│         ↓                                       │
│    WSL BitBot-Alpine                           │
│         ↓                                       │
│    scripts/bitbot (bash)                       │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  BitBot Launcher (bash)                         │
├─────────────────────────────────────────────────┤
│  1. Detect platform (wsl/macos/linux)          │
│  2. Check for VS Code + Dev Containers ext     │
│  3. Check for devcontainer CLI                 │
│  4. Build devcontainer (terminal mode only)    │
│  5. Launch VS Code (Direct DevContainer Opening method) or terminal   │
└─────────────────────────────────────────────────┘
```

## Clean Slate Testing

Before running tests, you may want to reset the environment to a fresh state.

### Clean Slate Scripts

| File | Purpose | Platform |
|------|---------|----------|
| `clean-slate.ps1` | Reset testing environment | Windows (PowerShell) |
| `clean-slate.sh` | Reset testing environment | WSL/Linux (bash) |

### What Gets Cleaned

1. **Docker**: Stops Docker Desktop/daemon
2. **Containers**: Removes all BitBot and test devcontainers
3. **DevContainer CLI**: Uninstalls standalone CLI (via npm)
4. **BitBot Cache**: Removes cache directories
5. **BitBot-Alpine**: Optionally removes WSL distribution

### Usage Examples

**Windows PowerShell**:
```powershell
# Interactive (prompts for Alpine removal)
.\clean-slate.ps1

# Full clean (removes everything without prompts)
.\clean-slate.ps1 -Full

# Keep Alpine WSL (don't remove it)
.\clean-slate.ps1 -KeepAlpine

# Only stop Docker (useful for testing auto-start)
.\clean-slate.ps1 -StopDockerOnly
```

**WSL/Linux Bash**:
```bash
# Interactive
./clean-slate.sh

# Full clean
./clean-slate.sh --full

# Keep Alpine
./clean-slate.sh --keep-alpine

# Only stop Docker
./clean-slate.sh --stop-docker-only
```

### Typical Testing Workflow

1. **Reset environment**:
   ```powershell
   .\clean-slate.ps1 -Full
   ```

2. **Test fresh installation**:
   ```powershell
   ..\scripts\bitbot.ps1 version
   # Should prompt to install BitBot-Alpine
   ```

3. **Test auto-start** (if Docker stopped):
   ```powershell
   ..\scripts\bitbot.ps1 work
   # Should auto-start Docker
   ```

4. **Test devcontainer build**:
   ```powershell
   ..\scripts\bitbot.ps1 work
   # Should build and enter container
   ```

---

## Usage

### From Windows (PowerShell)

```powershell
# Terminal mode (builds container, enters terminal)
..\scripts\bitbot.ps1
..\scripts\bitbot.ps1 work

# VS Code mode (launches VS Code directly in container)
..\scripts\bitbot.ps1 work vscode

# Version info
..\scripts\bitbot.ps1 version

# Help
..\scripts\bitbot.ps1 help
```

### From Windows (cmd.exe)

```batch
REM Terminal mode
..\scripts\bitbot.bat
..\scripts\bitbot.bat work

REM VS Code mode
..\scripts\bitbot.bat work vscode

REM Version info
..\scripts\bitbot.bat version
```

### From WSL/Linux

```bash
# Terminal mode
../scripts/bitbot
../scripts/bitbot work

# VS Code mode
../scripts/bitbot work vscode

# Version info
../scripts/bitbot version

# Help
../scripts/bitbot help
```

## Workflow Details

### Terminal Mode (`bitbot work`)

1. **Platform Detection**: Detects WSL/macOS/Linux
2. **Docker Check**:
   - Checks if Docker is running
   - Auto-starts Docker Desktop (Windows/Mac) or daemon (Linux) if needed
   - Waits up to 30 seconds for Docker to be ready
3. **CLI Detection**:
   - Checks for VS Code with Dev Containers extension (builtin CLI)
   - Falls back to standalone `devcontainer` CLI
   - Offers to install if not found
4. **Container Building**:
   - WSL: Uses `devcontainer.cmd` (avoids path corruption)
   - macOS/Linux: Uses `devcontainer`
   - Builds from `.devcontainer/devcontainer.json`
5. **Terminal Launch**:
   - Uses `docker exec` to enter container
   - Opens bash shell at `/workspace`
   - Future: Will show session management menu

### VS Code Mode (`bitbot work vscode`)

1. **Platform Detection**: Same as terminal mode
2. **Docker Check**: Auto-starts if needed (same as terminal mode)
3. **VS Code Check**: Verifies VS Code is installed
4. **Direct Opening** :
   - Skips container pre-building
   - Converts workspace path to hex encoding
   - Opens VS Code with `--folder-uri` parameter
   - VS Code builds container with correct configuration
5. **Result**:
   - No "Reopen in Container" popup
   - Opens directly in devcontainer
   - Includes VS Code Server and required mounts

## Prerequisites

### Required

- **Windows**: WSL2 with a Linux distribution
- **All platforms**: Docker Desktop or Docker Engine
- **⚠️ CRITICAL (Windows)**: Docker Desktop WSL Integration enabled for BitBot-Alpine

### Docker WSL Integration Setup (Windows Only)

**After installing BitBot-Alpine**, enable it in Docker Desktop:

**Auto**:
```powershell
cd test-windows-launch/tests
.\enable-docker-wsl-integration.ps1
```

**Manual**:
1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable "BitBot-Alpine"
4. Apply & Restart

**Verify**:
```powershell
wsl -d BitBot-Alpine docker ps
# Must show containers, NOT "Cannot connect to Docker daemon"
```

See `DOCKER-WSL-INTEGRATION.md` for details.

### Optional (at least one required)

**Option 1** (Recommended):
- VS Code with Dev Containers extension
- Provides builtin devcontainer CLI

**Option 2**:
- Node.js + npm
- Install standalone: `npm install -g @devcontainers/cli`

## Testing

### Test Terminal Mode

```bash
# From Windows PowerShell
cd test-windows-launch/tests
.\bitbot.ps1 work

# Expected:
# - Detects platform and CLI
# - Builds devcontainer
# - Enters container terminal at /workspace
```

### Test VS Code Mode

```bash
# From Windows PowerShell
cd test-windows-launch/tests
.\bitbot.ps1 work vscode

# Expected:
# - Detects VS Code installation
# - Generates hex-encoded URI
# - Launches VS Code
# - VS Code opens directly in devcontainer (no popup)
```

### Test Version Detection

```bash
.\bitbot.ps1 version

# Shows:
# - Entry point (Windows PowerShell / cmd.exe)
# - WSL distribution (BitBot-Alpine)
# - BitBot version
# - Platform detection
# - Dependencies with color-coded status:
#   - VS Code installed
#   - Dev Containers extension
#   - DevContainer CLI (builtin/standalone)
#   - Docker installed
```

## Differences from Production

| Aspect | Test Version | Production Version |
|--------|--------------|-------------------|
| Location | `test-windows-launch/tests/` | `/opt/bitbot/bin/` |
| WSL distro | Default distro | BitBot-Alpine |
| Session menu | Not implemented | Full interactive menu |
| Setup mode | Not implemented | Full setup container |
| Installation | Manual testing | System-wide installation |

## Implementation Notes

### Platform Detection

Uses `detect_platform()` from `scripts/bitbot-core.sh`:
- WSL: Checks `/proc/version` for "microsoft"
- macOS: Checks `$OSTYPE` for "darwin"
- Linux: Default

### DevContainer CLI Detection

Three possible states:
1. **builtin**: VS Code with Dev Containers extension (best)
2. **standalone**: Separate `devcontainer` CLI installation
3. **none**: Not found, offers to install

### Hex Encoding

Uses `path_to_hex()` from `scripts/bitbot-core.sh`:
- Primary: `xxd -p -c 256` (Linux/macOS)
- Fallback: `od -A n -t x1` (Alpine/minimal)

### Container Naming

Uses workspace hash for unique container names:
```bash
workspace_hash=$(calculate_workspace_hash "$(pwd)")
container_name="bitbot-dev-${workspace_hash}"
```

## Related Documentation

- **Specs**: `Claude_Specification/05_CROSS_PLATFORM_CLI.md` - Section 2 (Complete Workflow)
- **Specs**: `Claude_Specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md` - Section 0.8 (DevContainer Building)
- **Core**: `scripts/bitbot-core.sh` - Shared functions
- **Tests**: `tests/vscode_devcontainer/test-direct-open.ps1` - Direct DevContainer Opening pure test
- **Docs**: `docs/README.md` - Master documentation

## Troubleshooting

### "WSL not found"
```
Error: WSL not found. Install from: https://aka.ms/wsl2
```
**Fix**: Install WSL2 on Windows

### "DevContainer CLI not found"
```
DevContainer CLI not found.
Options:
  1. Install VS Code with Dev Containers extension (recommended)
  2. Install standalone: npm install -g @devcontainers/cli
```
**Fix**: Choose one of the two options

### "VS Code not found" (with vscode)
```
Error: VS Code not found
Install from: https://code.visualstudio.com/
```
**Fix**: Install VS Code

### "Container not running"
```
Error: Container not running
The devcontainer should have been started by 'devcontainer up'
```
**Fix**: Check if `devcontainer up` succeeded. Look for errors in build output.

### "Failed to build devcontainer"

Possible causes:
1. `.devcontainer/devcontainer.json` missing or invalid
2. Docker not running
3. Insufficient permissions
4. Network issues (pulling images)

**Debug**:
```bash
# Check Docker status
docker ps

# Check devcontainer config
cat .devcontainer/devcontainer.json

# Try manual build
devcontainer up --workspace-folder "$(pwd)"
```

## Next Steps

To convert to production:

1. **Create BitBot-Alpine distribution**
   - Lightweight WSL distro
   - Pre-installed: bash, git, coreutils
   - BitBot scripts at `/opt/bitbot/bin/`

2. **Install bitbot.exe in PATH**
   - Minimal Windows launcher
   - Calls BitBot-Alpine directly
   - Located in `%LOCALAPPDATA%\BitBot`

3. **Implement session menu**
   - Create `bitbot-session-menu.sh`
   - Integration with tmux
   - Claude Code integration

4. **Add setup mode**
   - Separate container with elevated permissions
   - Infrastructure modification support

5. **System-wide installation**
   - Windows: PowerShell install script
   - WSL/Linux: Bash install script
   - macOS: Homebrew formula

## Version

**Current**: 0.1.0-test (Prototype)
**Next**: 0.2.0 (BitBot-Alpine integration)
**Future**: 1.0.0 (Production release)
