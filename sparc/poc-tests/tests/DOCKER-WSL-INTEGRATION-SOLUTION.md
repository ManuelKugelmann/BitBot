# Docker WSL Integration - Correct Solution

## Summary

**Problem**: BitBot-Alpine couldn't access Docker  
**Root Cause**: Docker Desktop WSL integration not enabled for BitBot-Alpine  
**Solution**: Add BitBot-Alpine to `IntegratedWslDistros` array in settings

---

## Correct Settings Format

### File Location

```
%APPDATA%\Docker\settings-store.json
```

(Older Docker Desktop versions use `settings.json`)

### Correct Field: `IntegratedWslDistros` (Array)

```json
{
  "AutoStart": false,
  "DisplayedOnboarding": true,
  "EnableDockerAI": true,
  "IntegratedWslDistros": [
    "BitBot-Alpine",
    "Ubuntu-22.04"
  ],
  "LicenseTermsVersion": 2,
  "SettingsVersion": 43,
  "UseContainerdSnapshotter": true,
  "wslEngineEnabled": true,
  "enableIntegrationWithAdditionalDistros": {}
}
```

**Key Points**:
- ✓ `IntegratedWslDistros` is an **array of strings**
- ✓ `enableIntegrationWithAdditionalDistros` stays empty (`{}`)
- ✓ `wslEngineEnabled` must be `true`

---

## Automated Setup Script

### Usage

```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
.\enable-docker-wsl-integration-simple.ps1
```

### What It Does

1. Checks Docker Desktop and BitBot-Alpine exist
2. Backs up current settings
3. Stops Docker Desktop (required before modifying settings!)
4. Adds BitBot-Alpine to `IntegratedWslDistros` array
5. Saves settings as ASCII (no BOM - important!)
6. Restarts Docker Desktop
7. Verifies integration works

### Important Implementation Details

**Encoding**: Must use ASCII or UTF8 without BOM
```powershell
# ✓ Correct
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding ASCII

# ✗ Wrong - adds BOM, breaks Docker Desktop!
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding UTF8
```

**Timing**: Must stop Docker Desktop BEFORE modifying settings
```powershell
# 1. Stop Docker Desktop
Start-Process -FilePath $dockerDesktop -ArgumentList "--quit" -Wait

# 2. Modify settings
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath

# 3. Start Docker Desktop
Start-Process -FilePath $dockerDesktop
```

If you modify settings while Docker is running, it will overwrite them on restart!

---

## Manual Setup (GUI Method)

1. **Open Docker Desktop**
2. Click **⚙️ Settings** (top-right)
3. Navigate to **Resources** → **WSL Integration**
4. Check **☑ BitBot-Alpine**
5. Click **Apply & Restart**

---

## Verification

### Test from PowerShell

```powershell
# Should show container list, not error
wsl -d BitBot-Alpine docker ps
```

**Expected**:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Wrong (before enabling)**:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

### Test BitBot

```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
..\scripts\bitbot.ps1 work
```

**Expected**:
```
Building devcontainer...
✓ DevContainer built successfully
```

---

## Troubleshooting

### Integration Not Working After Script

**Try**:
1. Terminate WSL to force fresh connection:
   ```powershell
   wsl --terminate BitBot-Alpine
   wsl -d BitBot-Alpine docker ps
   ```

2. Wait longer (Docker Desktop takes 30-60s to fully initialize WSL integration)

3. Restart Docker Desktop completely:
   ```powershell
   # Via GUI: Right-click Docker icon → Quit Docker Desktop
   # Then: Start Docker Desktop from Start menu
   ```

### Settings Get Overwritten

**Problem**: Settings file changes, but integration doesn't work

**Cause**: Modified settings while Docker Desktop was running

**Fix**: Run the script again (it stops Docker Desktop first)

---

## Technical Notes

### Why Two Fields?

- **`IntegratedWslDistros`**: The actual setting Docker Desktop uses (array)
- **`enableIntegrationWithAdditionalDistros`**: Legacy/deprecated field (object, stays empty)

Both must exist in the file, but only `IntegratedWslDistros` matters.

### Docker Desktop Settings Behavior

- Settings are loaded when Docker Desktop starts
- Settings are saved when Docker Desktop stops (overwrites manual changes!)
- Must stop Docker Desktop before manual edits
- BOM in UTF-8 files causes Docker Desktop to fail parsing

---

## Related Documentation

- [Docker Desktop WSL 2 Backend](https://docs.docker.com/desktop/wsl/)
- [WSL Integration Settings](https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)

---

**Status**: ✅ Tested and working  
**Date**: 2025-10-20  
**Docker Desktop Version**: 4.35+ (uses `settings-store.json`)
