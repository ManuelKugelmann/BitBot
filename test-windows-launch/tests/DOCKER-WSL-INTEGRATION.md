# Docker Desktop WSL Integration Requirement

**Issue**: BitBot-Alpine cannot access Docker
**Status**: ⚠️ Required Configuration
**Priority**: 🔴 Critical - BitBot won't work without this

---

## Problem

### Symptom:
When running `bitbot work`, you see:
```
Starting Docker...
  Waiting for Docker to start...
..... 10s..... 20s..... 30s..... 40s..... 50s..... 60s

  Timeout waiting for Docker to start (waited 60s)
  Docker Desktop may need more time to initialize WSL integration
  Check Docker Desktop status and try again
```

**But Docker IS running!**

You can verify from PowerShell or your default WSL:
```bash
docker ps  # Works fine!
```

### Root Cause:

**BitBot runs inside BitBot-Alpine WSL distribution**, which is NOT enabled in Docker Desktop's WSL integration by default.

Docker Desktop only shares the Docker socket (`/var/run/docker.sock`) with WSL distributions that are explicitly enabled.

---

## Solution

### Enable BitBot-Alpine in Docker Desktop

**Step 1: Open Docker Desktop**
- Click the Docker icon in system tray
- Or start "Docker Desktop" from Start menu

**Step 2: Open Settings**
- Click the ⚙️ gear icon (top-right)

**Step 3: Navigate to WSL Integration**
- Click **"Resources"** in left sidebar
- Click **"WSL Integration"**

**Step 4: Enable BitBot-Alpine**
```
WSL Integration
───────────────────────────────────────────

Enable integration with my default WSL distro
☑ Ubuntu-22.04

Enable integration with additional distros:
☑ Ubuntu-22.04
☐ BitBot-Alpine          ← TURN THIS ON!
☐ docker-desktop
☐ docker-desktop-data
```

**Step 5: Apply Changes**
- Click **"Apply & Restart"** button
- Wait for Docker Desktop to restart (~10-30 seconds)

---

## Verification

### Test from BitBot-Alpine:

**From PowerShell**:
```powershell
wsl -d BitBot-Alpine docker ps
```

**Expected Output** (after enabling):
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Wrong Output** (before enabling):
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

---

### Test BitBot:

```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
..\scripts\bitbot.ps1 work
```

**Expected Output** (after enabling):
```
BitBot Work Mode
================

Building devcontainer...
  Workspace: C:\Projects\BitBot\test-windows-launch
  Platform:  wsl
  CLI:       standalone (devcontainer.cmd)

[Building continues...]
✓ DevContainer built successfully
```

**Wrong Output** (before enabling):
```
Starting Docker...
  Waiting for Docker to start...
..... 10s..... 20s..... (timeout after 60s)
```

---

## Why This Happens

### Docker Desktop Architecture on WSL:

1. **Docker Desktop** (Windows app)
   - Runs Docker Engine in a VM/WSL2 backend
   - Controls which WSL distros can access Docker

2. **Docker Socket** (`/var/run/docker.sock`)
   - Unix socket for Docker API
   - Only mounted in enabled WSL distributions

3. **WSL Integration**
   - Mounts Docker socket into enabled distros
   - Sets up `docker` CLI in PATH
   - Configures Docker context

**Without integration**: WSL distro cannot talk to Docker at all!

---

## Common Issues

### Issue 1: Can't Find BitBot-Alpine in List

**Symptom**: BitBot-Alpine doesn't appear in the WSL Integration list

**Causes**:
1. BitBot-Alpine not installed yet
2. Docker Desktop hasn't detected it yet

**Solutions**:
```powershell
# Verify Alpine exists
wsl --list --verbose

# If exists but not in Docker Desktop list:
# 1. Restart Docker Desktop
# 2. Wait 30 seconds
# 3. Check WSL Integration settings again
```

---

### Issue 2: Already Enabled But Still Times Out

**Symptom**: Toggle is ON but BitBot still can't access Docker

**Solutions**:

1. **Click "Apply & Restart"** (even if already enabled)
   - Settings don't always apply immediately

2. **Restart BitBot-Alpine**:
   ```powershell
   wsl --terminate BitBot-Alpine
   wsl -d BitBot-Alpine docker ps
   ```

3. **Restart Docker Desktop completely**:
   - Right-click Docker icon → Quit Docker Desktop
   - Wait 10 seconds
   - Start Docker Desktop
   - Re-enable BitBot-Alpine integration

4. **Check Docker Desktop is using WSL 2 backend**:
   - Settings → General
   - ☑ "Use the WSL 2 based engine" should be checked

---

### Issue 3: Other WSL Distros Work But Not Alpine

**Symptom**: Your default WSL (Ubuntu) can access Docker, but Alpine can't

**This is normal!** Each WSL distro must be individually enabled.

**Verify**:
```powershell
# Works (default distro or enabled distro)
wsl -d Ubuntu-22.04 docker ps
✓ Success

# Doesn't work (Alpine not enabled)
wsl -d BitBot-Alpine docker ps
✗ Cannot connect to Docker daemon
```

**Fix**: Enable Alpine in WSL Integration settings

---

## Automatic Detection (Future Enhancement)

### Proposed Helper Check:

Add to `bitbot` script before building containers:

```bash
# Check if Docker is accessible from this WSL distro
check_docker_wsl_integration() {
    if ! docker ps &>/dev/null 2>&1; then
        local error=$(docker ps 2>&1)

        if echo "$error" | grep -q "Cannot connect to the Docker daemon"; then
            echo ""
            echo "⚠️  Docker WSL Integration Issue Detected"
            echo ""
            echo "Docker Desktop is not integrated with this WSL distribution."
            echo ""
            echo "Fix:"
            echo "  1. Open Docker Desktop"
            echo "  2. Settings → Resources → WSL Integration"
            echo "  3. Enable 'BitBot-Alpine'"
            echo "  4. Click 'Apply & Restart'"
            echo ""
            echo "Then try again: bitbot work"
            exit 1
        fi
    fi
}
```

This would give a **clear error message** instead of a confusing timeout.

---

## Production Installation

### When Installing BitBot-Alpine:

The installation script should:

1. **Detect if Docker Desktop is installed**
2. **Warn user about WSL integration requirement**:
   ```
   ⚠️  IMPORTANT: Docker Desktop WSL Integration

   After installation, you must enable BitBot-Alpine in Docker Desktop:

   1. Open Docker Desktop
   2. Settings → Resources → WSL Integration
   3. Enable "BitBot-Alpine"
   4. Apply & Restart

   Press any key to continue...
   ```

3. **Provide post-install verification**:
   ```powershell
   # Test Docker access
   wsl -d BitBot-Alpine docker ps

   # If fails, show integration instructions
   ```

---

## Documentation Updates Needed

### Files to Update:

1. **README.md**:
   - Add WSL Integration requirement to prerequisites
   - Add setup step

2. **MANUAL-TESTING-GUIDE.md**:
   - Add Docker WSL integration as step 0 (before all tests)

3. **Installation Scripts**:
   - `install-bitbot-wsl.ps1`: Add warning about integration
   - Add verification step

4. **Troubleshooting**:
   - Add this as common issue #1

---

## Quick Reference

### Enable Integration (TL;DR):

```
Docker Desktop → Settings → Resources → WSL Integration
→ Enable "BitBot-Alpine" → Apply & Restart
```

### Verify:

```powershell
wsl -d BitBot-Alpine docker ps
# Should show container list, not error
```

### Test BitBot:

```powershell
cd test-windows-launch\tests
..\scripts\bitbot.ps1 work
# Should build container, not timeout
```

---

## Related Documentation

- **Official Docker Docs**: [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/wsl/)
- **WSL Integration**: [Configure WSL integration](https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)

---

**Status**: ⚠️ This is a **required setup step** for BitBot on Windows

**Impact**: Without this, BitBot cannot function at all

**Next**: Add detection and helpful error message to BitBot script
