# Clean Slate Testing Guide

**Purpose**: Reset the BitBot testing environment to a fresh state

---

## Overview

The clean-slate scripts provide a reliable way to reset your testing environment before running tests. This is especially useful for:

- Testing fresh installations
- Testing Docker auto-start feature
- Testing Alpine WSL auto-install
- Verifying clean devcontainer builds
- Troubleshooting issues

---

## Scripts

### clean-slate.ps1 (Windows PowerShell)

**Location**: `test-windows-launch/tests/clean-slate.ps1`

**Features**:
- Stops Docker Desktop
- Removes all devcontainers (BitBot and test containers)
- Uninstalls DevContainer CLI (standalone)
- Cleans BitBot cache directories
- Optionally removes BitBot-Alpine WSL

**Parameters**:
- `-Full` - Clean everything without prompts
- `-KeepAlpine` - Keep BitBot-Alpine WSL distribution
- `-StopDockerOnly` - Only stop Docker (skip other cleanup)

**Examples**:
```powershell
# Interactive mode
.\clean-slate.ps1

# Full clean (no prompts)
.\clean-slate.ps1 -Full

# Keep Alpine
.\clean-slate.ps1 -KeepAlpine

# Only stop Docker (for testing auto-start)
.\clean-slate.ps1 -StopDockerOnly
```

---

### clean-slate.sh (WSL/Linux Bash)

**Location**: `test-windows-launch/tests/clean-slate.sh`

**Features**:
- Stops Docker Desktop (WSL) or daemon (Linux)
- Removes all devcontainers
- Uninstalls DevContainer CLI (standalone)
- Cleans BitBot cache (both WSL and Windows locations)
- Optionally removes BitBot-Alpine WSL (WSL only)

**Parameters**:
- `--full` - Clean everything without prompts
- `--keep-alpine` - Keep BitBot-Alpine WSL distribution
- `--stop-docker-only` - Only stop Docker (skip other cleanup)

**Examples**:
```bash
# Interactive mode
./clean-slate.sh

# Full clean (no prompts)
./clean-slate.sh --full

# Keep Alpine
./clean-slate.sh --keep-alpine

# Only stop Docker
./clean-slate.sh --stop-docker-only
```

---

## What Gets Cleaned

### 1. Docker ✅

**Windows (WSL)**:
- Stops "Docker Desktop" process
- Stops `com.docker.service` service

**Linux**:
- Stops Docker daemon via `systemctl` or `service`

**Why**: Allows testing Docker auto-start feature

---

### 2. DevContainers ✅

**Removes**:
- All containers with name pattern `bitbot-dev-*`
- All containers with label `devcontainer.local_folder`

**Commands**:
```bash
docker ps -a --filter "name=bitbot-dev-" --format '{{.Names}}' | xargs docker rm -f
docker ps -a --filter "label=devcontainer.local_folder" --format '{{.Names}}' | xargs docker rm -f
```

**Why**: Ensures clean container builds without name conflicts

---

### 3. DevContainer CLI ✅

**Removes**:
- Standalone `@devcontainers/cli` npm package

**Command**:
```bash
npm uninstall -g @devcontainers/cli
```

**Note**: Does NOT remove VS Code or the Dev Containers extension (only standalone CLI)

**Why**: Allows testing CLI installation workflow

---

### 4. BitBot Cache ✅

**Windows Locations**:
- `%LOCALAPPDATA%\BitBot`
- `%LOCALAPPDATA%\Temp\devcontainercli`

**WSL/Linux Locations**:
- `~/.bitbot`
- `/mnt/c/Users/<username>/AppData/Local/BitBot` (WSL only)
- `/mnt/c/Users/<username>/AppData/Local/Temp/devcontainercli` (WSL only)

**Why**: Removes any cached state that might affect tests

---

### 5. BitBot-Alpine WSL (Optional) ⚠️

**Removes**:
- BitBot-Alpine WSL distribution

**Command**:
```powershell
wsl --unregister BitBot-Alpine
```

**Behavior**:
- **Interactive mode**: Prompts user (Y/n)
- **Full mode**: Removes without prompt (unless `-KeepAlpine`)
- **KeepAlpine mode**: Always keeps Alpine

**Why**: Allows testing fresh Alpine installation

---

## Testing Workflows

### Workflow 1: Complete Fresh Test

Test everything from scratch, including Alpine installation:

```powershell
# 1. Reset environment
.\clean-slate.ps1 -Full

# 2. Test version (should prompt to install Alpine)
..\scripts\bitbot.ps1 version

# 3. Install Alpine when prompted (Y)

# 4. Check version again
..\scripts\bitbot.ps1 version

# 5. Test work mode
..\scripts\bitbot.ps1 work
```

**Tests**:
- ✅ Alpine auto-install prompt
- ✅ Dependency detection
- ✅ DevContainer build
- ✅ Terminal launch

---

### Workflow 2: Docker Auto-Start Test

Test Docker auto-start feature:

```powershell
# 1. Stop Docker only (keep Alpine)
.\clean-slate.ps1 -StopDockerOnly

# 2. Verify Docker is stopped
docker ps
# Should show: error during connect

# 3. Test auto-start
..\scripts\bitbot.ps1 work

# Should see:
# - "Starting Docker..."
# - Progress dots
# - "✓ Docker is ready"
# - Container builds successfully
```

**Tests**:
- ✅ Docker stopped detection
- ✅ Auto-start mechanism
- ✅ Timeout/retry logic
- ✅ Build after auto-start

---

### Workflow 3: CLI Installation Test

Test DevContainer CLI installation:

```powershell
# 1. Clean but keep Alpine (removes CLI)
.\clean-slate.ps1 -KeepAlpine

# 2. Test work mode (should prompt to install CLI)
..\scripts\bitbot.ps1 work

# Should prompt:
# "DevContainer CLI not found.
#  Options:
#    1. Install VS Code with Dev Containers extension
#    2. Install standalone: npm install -g @devcontainers/cli"
```

**Tests**:
- ✅ CLI detection
- ✅ Installation prompt
- ✅ Standalone installation
- ✅ Build after installation

---

### Workflow 4: VS Code Mode Test

Test VS Code integration:

```powershell
# 1. Clean environment
.\clean-slate.ps1 -KeepAlpine

# 2. Test VS Code launch
..\scripts\bitbot.ps1 vscode

# Should:
# - Check VS Code installation
# - Generate hex-encoded URI
# - Launch VS Code
# - Open directly in devcontainer (no popup)
```

**Tests**:
- ✅ VS Code detection
- ✅ Direct DevContainer Opening direct opening
- ✅ Path hex encoding
- ✅ No "Reopen in Container" popup

---

## Output Examples

### Successful Clean (Interactive)

```
=== BitBot Clean Slate Script ===

[1/5] Stopping Docker Desktop...
  Stopping Docker Desktop process...
  ✓ Docker Desktop stopped

[2/5] Removing DevContainers...
  Removing BitBot containers...
  Removing test containers...
  ✓ Containers removed

[3/5] Uninstalling DevContainer CLI...
  Uninstalling @devcontainers/cli...
  ✓ DevContainer CLI uninstalled

[4/5] Cleaning BitBot cache...
  Removing C:\Users\...\AppData\Local\BitBot...
  ✓ BitBot cache removed

[5/5] BitBot-Alpine WSL...
  BitBot-Alpine WSL distribution found.
  Remove BitBot-Alpine? (y/N): n
  ✓ BitBot-Alpine kept

=== Clean Slate Complete ===

Environment reset:
  ✓ Docker stopped
  ✓ DevContainers removed
  ✓ DevContainer CLI uninstalled
  ✓ BitBot cache cleaned
  ⚠ BitBot-Alpine kept

Ready for fresh testing!

Next steps:
  1. Start Docker Desktop manually (if testing auto-start)
  2. Run: ..\scripts\bitbot.ps1 version
  3. Install BitBot-Alpine when prompted
  4. Run: ..\scripts\bitbot.ps1 work
```

---

### Full Clean (No Prompts)

```powershell
.\clean-slate.ps1 -Full
```

Same output but removes Alpine automatically without prompting.

---

### Stop Docker Only

```powershell
.\clean-slate.ps1 -StopDockerOnly
```

```
=== BitBot Clean Slate Script ===

[1/5] Stopping Docker Desktop...
  Stopping Docker Desktop process...
  ✓ Docker Desktop stopped

✓ Docker stopped. Use -Full to clean everything.
```

---

## Troubleshooting

### Docker Won't Stop

**Symptom**: Docker Desktop process still running after clean-slate

**Solution**:
```powershell
# Manually stop Docker Desktop
Stop-Process -Name "Docker Desktop" -Force

# Or use Task Manager
```

---

### Alpine Won't Unregister

**Symptom**: `wsl --unregister BitBot-Alpine` fails

**Causes**:
1. Alpine is currently running
2. Another WSL process is using it

**Solution**:
```powershell
# Terminate Alpine
wsl --terminate BitBot-Alpine

# Try unregister again
wsl --unregister BitBot-Alpine

# Verify
wsl --list --verbose
```

---

### CLI Still Installed

**Symptom**: `devcontainer.cmd` still accessible after uninstall

**Causes**:
1. VS Code builtin CLI (not affected by npm uninstall)
2. Multiple npm global directories

**Solution**:
- VS Code builtin: This is expected and desired
- Multiple npm dirs: Check `npm bin -g` and manually remove

---

### Containers Still Running

**Symptom**: Containers not removed

**Causes**:
1. Docker was already stopped
2. Permission issues

**Solution**:
```powershell
# Start Docker first
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to start
Start-Sleep -Seconds 10

# Then run clean-slate again
.\clean-slate.ps1
```

---

## Safety Notes

### What's NOT Cleaned

- ✅ VS Code installation
- ✅ VS Code Dev Containers extension
- ✅ Docker Desktop installation
- ✅ Docker images (only containers removed)
- ✅ npm installation
- ✅ Node.js installation
- ✅ Other WSL distributions

### Data Loss Warning

⚠️ **Containers**: Any data inside removed containers will be lost (workspace data is safe)

⚠️ **Alpine**: If you remove BitBot-Alpine, any data stored IN the Alpine filesystem will be lost (workspace data is safe)

✅ **Workspace**: Your actual workspace files are NEVER touched (they're on the host filesystem)

---

## See Also

- **tests/README.md** - Complete testing documentation
- **scripts/TEST_RESULTS.md** - Automated test results
- **scripts/VERIFICATION.md** - Feature verification
- **scripts/DOCKER-AUTO-START.md** - Docker auto-start details
