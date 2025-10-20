# Troubleshooting: WSL Terminal Going to Wrong Path

## Problem

VS Code WSL terminals open at:
```
/mnt/wsl/docker-desktop-bind-mounts/Ubuntu-22.04/...
```

Instead of normal paths like `/mnt/c/Projects/...`

## Symptoms

| Context | Expected Path | Actual Path | Status |
|---------|---------------|-------------|--------|
| Standalone WSL | `/mnt/c/...` | `/mnt/c/...` | ✅ OK |
| VS Code PowerShell | `C:\...` | `C:\...` | ✅ OK |
| VS Code cmd | `C:\...` | `C:\...` | ✅ OK |
| VS Code WSL | `/mnt/c/...` | `/mnt/wsl/docker-desktop-bind-mounts/...` | ❌ WRONG |

## Likely Causes

1. **VS Code Remote-WSL extension confused by Docker Desktop**
   - Docker Desktop creates WSL mounts that VS Code might be picking up

2. **VS Code workspace associated with Docker path**
   - VS Code might have cached the Docker mount as the workspace root

3. **DevContainer configuration affecting WSL**
   - `.devcontainer/devcontainer.json` might be interfering

## Fixes to Try (After Reboot)

### Fix 1: Clear VS Code Workspace State

```powershell
# Close ALL VS Code windows first

# Clear workspace storage (Windows)
Remove-Item -Recurse -Force "$env:APPDATA\Code\User\workspaceStorage\*"

# Or manually delete:
# %APPDATA%\Code\User\workspaceStorage\
```

Then reopen VS Code fresh.

### Fix 2: Reset VS Code Remote-WSL Extension

In VS Code:
1. `Ctrl+Shift+P`
2. "Remote-WSL: Uninstall VS Code Server from WSL"
3. Close VS Code
4. Reopen and try again

### Fix 3: Check Docker Desktop WSL Integration

In Docker Desktop:
1. Settings → Resources → WSL Integration
2. Verify only necessary distros are enabled
3. Try disabling/re-enabling Ubuntu integration

### Fix 4: Clear DevContainer Cache

```powershell
# Stop all containers
docker stop $(docker ps -q)

# Remove devcontainer volumes
docker volume ls | findstr vscode
docker volume rm <volume-name>
```

### Fix 5: Temporarily Disable DevContainer Extension

1. VS Code Extensions panel
2. Find "Dev Containers" extension
3. Click "Disable"
4. Open WSL terminal to test
5. If fixed, re-enable and see if problem returns

## Diagnostic Commands

### Inside VS Code WSL Terminal

```bash
# Where are we?
pwd

# What's our hostname?
hostname

# Are we in Docker?
echo $DEVCONTAINER

# Can we navigate to Docker mounts?
ls /mnt/wsl/docker-desktop-bind-mounts/

# What's our working directory supposed to be?
echo $PWD
```

### Check VS Code Settings

```powershell
# Check for terminal.integrated.cwd settings
code "$env:APPDATA\Code\User\settings.json"
```

Look for:
- `terminal.integrated.cwd`
- `remote.WSL.*`
- `dev.containers.*`

## Expected Behavior After Fix

Open VS Code to Windows folder:
```powershell
code C:\Projects\BitBot\test-windows-launch
```

Open WSL terminal (`Ctrl+` ` then select WSL):
- Path should be: `/mnt/c/Projects/BitBot/test-windows-launch`
- NOT: `/mnt/wsl/docker-desktop-bind-mounts/...`

## Reference Tests

After fix, run these to verify:

```powershell
# Test 1: Regular Windows terminal in VS Code
.\test-vscode-regular.ps1
# New terminal should be PowerShell at C:\...

# Test 2: WSL terminal in VS Code
.\test-vscode-wsl.ps1
# New terminal should be bash at /mnt/c/...

# Test 3: DevContainer terminal in VS Code
.\test-vscode-clean-rebuild.ps1
# New terminal should be bash at /workspace
```

## Nuclear Option

If nothing works:

```powershell
# 1. Close all VS Code windows
# 2. Uninstall extensions
code --uninstall-extension ms-vscode-remote.remote-wsl
code --uninstall-extension ms-vscode-remote.remote-containers

# 3. Clear all VS Code data
Remove-Item -Recurse -Force "$env:APPDATA\Code"

# 4. Reinstall VS Code (or just reopen to recreate config)
# 5. Reinstall extensions when prompted
```

---

## Status Tracking

Fill in after testing:

- [ ] Reboot completed
- [ ] Standalone WSL terminal: _______________
- [ ] VS Code PowerShell terminal: _______________
- [ ] VS Code WSL terminal: _______________
- [ ] Fix attempted: _______________
- [ ] Result: _______________
