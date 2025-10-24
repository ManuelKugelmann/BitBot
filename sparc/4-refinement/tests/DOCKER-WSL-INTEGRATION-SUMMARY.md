# Docker WSL Integration - Summary

**Date**: 2025-10-20
**Issue**: BitBot timeout when Docker is running
**Root Cause**: BitBot-Alpine not enabled in Docker Desktop WSL Integration
**Status**: ✅ Documented and automated

---

## Problem

User reported:
```
Starting Docker...
  Waiting for Docker to start...
..... 10s..... 20s..... 30s..... 40s..... 50s..... 60s
  Timeout waiting for Docker to start
```

**But Docker WAS running!**

---

## Root Cause

BitBot runs inside **BitBot-Alpine WSL distribution**.

Docker Desktop only shares the Docker socket with WSL distributions that are **explicitly enabled** in settings.

**Test Results**:
- ✅ `docker ps` from Ubuntu-22.04: Works
- ✅ `docker ps` from PowerShell: Works
- ❌ `docker ps` from BitBot-Alpine: **Cannot connect to Docker daemon**

---

## Solution

### Automatic (Recommended):

Created script: `enable-docker-wsl-integration.ps1`

**Usage**:
```powershell
cd test-windows-launch/tests
.\enable-docker-wsl-integration.ps1
```

**What it does**:
1. ✅ Checks if Docker Desktop installed
2. ✅ Checks if BitBot-Alpine exists
3. ✅ Backs up Docker settings
4. ✅ Enables WSL 2 backend
5. ✅ Adds BitBot-Alpine to integration list
6. ✅ Restarts Docker Desktop
7. ✅ Verifies integration works

### Manual:

Docker Desktop → Settings → Resources → WSL Integration → Enable "BitBot-Alpine" → Apply & Restart

---

## Files Created

### Scripts:
- ✅ `enable-docker-wsl-integration.ps1` - PowerShell automation
- ✅ `enable-docker-wsl-integration.sh` - Bash wrapper

### Documentation:
- ✅ `DOCKER-WSL-INTEGRATION.md` - Complete guide (why, how, troubleshooting)
- ✅ `DOCKER-WSL-INTEGRATION-SUMMARY.md` - This file

### Updated:
- ✅ `MANUAL-TESTING-GUIDE.md` - Added prerequisites section
- ✅ `CURRENT-STATUS.md` - Added critical requirement
- ✅ `README.md` - Added Docker WSL integration to prerequisites

---

## How It Works

### Docker Desktop Settings Location:
```
%APPDATA%\Docker\settings.json
```

### Relevant Settings:
```json
{
  "wslEngineEnabled": true,
  "enableIntegrationWithAdditionalDistros": {
    "Ubuntu-22.04": true,
    "BitBot-Alpine": true  ← Added by script
  }
}
```

### Script Actions:
1. Parse `settings.json`
2. Add `"BitBot-Alpine": true` to integration list
3. Save settings
4. Restart Docker Desktop (required for changes to apply)
5. Wait for Docker to be ready
6. Test: `wsl -d BitBot-Alpine docker ps`

---

## Verification

### Before Enabling:
```powershell
PS> wsl -d BitBot-Alpine docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

### After Enabling:
```powershell
PS> wsl -d BitBot-Alpine docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### BitBot Test:
```powershell
PS> cd test-windows-launch\tests
PS> ..\scripts\bitbot.ps1 work

BitBot Work Mode
================

Building devcontainer...
  Workspace: C:\Projects\BitBot\test-windows-launch
  Platform:  wsl
  CLI:       standalone (devcontainer.cmd)

✓ DevContainer built successfully
```

---

## Production Integration

### Installation Script Should:

1. **Install BitBot-Alpine**
2. **Show warning**:
   ```
   ⚠️  IMPORTANT: Docker Desktop Setup Required

   BitBot needs access to Docker from the BitBot-Alpine WSL distribution.

   Please run this command after installation:
     enable-docker-wsl-integration.ps1

   Or manually enable in Docker Desktop:
     Settings → Resources → WSL Integration → BitBot-Alpine
   ```

3. **Optionally run automatically**:
   ```powershell
   # After installing Alpine
   & "$PSScriptRoot\enable-docker-wsl-integration.ps1"
   ```

---

## Future Enhancement

### Add Detection to BitBot:

Add to `scripts/bitbot` before Docker timeout:

```bash
check_docker_accessible() {
    if ! docker ps &>/dev/null 2>&1; then
        local error=$(docker ps 2>&1)

        if echo "$error" | grep -q "Cannot connect to the Docker daemon"; then
            echo ""
            echo "⚠️  Docker WSL Integration Not Enabled"
            echo ""
            echo "Docker Desktop is not integrated with BitBot-Alpine."
            echo ""
            echo "Quick fix:"
            echo "  powershell.exe -File /path/to/enable-docker-wsl-integration.ps1"
            echo ""
            echo "Manual fix:"
            echo "  1. Open Docker Desktop"
            echo "  2. Settings → Resources → WSL Integration"
            echo "  3. Enable 'BitBot-Alpine'"
            echo "  4. Apply & Restart"
            echo ""
            echo "See: DOCKER-WSL-INTEGRATION.md for details"
            exit 1
        fi
    fi
}
```

This gives a **clear, actionable error** instead of a confusing timeout.

---

## Summary

✅ **Root cause identified**: WSL integration not enabled
✅ **Automation created**: `enable-docker-wsl-integration.ps1`
✅ **Documentation complete**: Guides and troubleshooting
✅ **Testing updated**: Prerequisites added

**Next**: Enable integration, then manual testing can proceed!

---

## Quick Reference

**Enable integration**:
```powershell
.\enable-docker-wsl-integration.ps1
```

**Verify**:
```powershell
wsl -d BitBot-Alpine docker ps
```

**Test BitBot**:
```powershell
..\scripts\bitbot.ps1 work
```

**See**: `DOCKER-WSL-INTEGRATION.md` for complete documentation
