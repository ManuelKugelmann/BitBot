# BitBot Manual Testing Guide

**Status**: Environment reset complete
**Date**: 2025-10-20

---

## Current Environment Status

✅ **Clean slate completed**:
- Docker stopped
- All containers removed
- DevContainer CLI uninstalled
- BitBot cache cleaned
- BitBot-Alpine removed (or not present)

---

## Prerequisites

### ⚠️ CRITICAL: Docker WSL Integration

**Before running ANY tests**, you MUST enable BitBot-Alpine in Docker Desktop WSL integration:

**Option 1: Automatic (Recommended)**:
```powershell
# Run this script to automatically enable integration
.\enable-docker-wsl-integration.ps1
```

**Option 2: Manual**:
1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable "BitBot-Alpine"
4. Click "Apply & Restart"

**Verify it worked**:
```powershell
wsl -d BitBot-Alpine docker ps
# Should show container list, NOT "Cannot connect to Docker daemon"
```

**Without this**: BitBot will timeout waiting for Docker (even though Docker is running!)

See: `DOCKER-WSL-INTEGRATION.md` for detailed explanation.

---

## Manual Test Suite

### Test 1: Fresh Alpine Installation ⭐

**Purpose**: Verify BitBot-Alpine auto-install prompt and installation

**Steps**:
```powershell
# From Windows PowerShell
cd C:\Projects\BitBot\test-windows-launch\tests

# Run version command
..\scripts\bitbot.ps1 version
```

**Expected Behavior**:
```
Entry Point: Windows PowerShell
BitBot-Alpine WSL distribution not found.

BitBot requires a dedicated WSL distribution for isolation.

Install BitBot-Alpine now? (Y/n):
```

**Actions**:
1. Enter `Y` to install (or press Enter for default)
2. Wait for installation to complete

**Verify**:
```powershell
# Should now show Alpine info
..\scripts\bitbot.ps1 version

# Expected:
# Entry Point: Windows PowerShell
# Using WSL:     BitBot-Alpine
# BitBot version 0.1.0-test
# ...
```

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 2: Docker Auto-Start ⭐⭐⭐

**Purpose**: Verify Docker Desktop auto-starts when not running

**Prerequisites**: Docker must be fully stopped

**Steps**:

1. **Stop Docker Desktop** (important!):
   ```powershell
   # Stop Docker Desktop process
   Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue

   # Wait for full shutdown (very important!)
   Start-Sleep -Seconds 10

   # Verify it's stopped
   docker ps
   # Should show: error during connect
   ```

2. **Run BitBot work mode**:
   ```powershell
   ..\scripts\bitbot.ps1 work
   ```

**Expected Behavior**:
```
BitBot Work Mode
================

Building devcontainer...
  Workspace: C:\Projects\BitBot\test-windows-launch
  Platform:  wsl
  CLI:       standalone (devcontainer.cmd)

Starting Docker...
  Waiting for Docker to start...
..........
  ✓ Docker is ready

[Building devcontainer continues...]
```

**Verify**:
- ✅ "Starting Docker..." message appears
- ✅ Progress dots show (each dot = 2 seconds)
- ✅ "✓ Docker is ready" appears
- ✅ Container build continues successfully

**Note**: Docker Desktop might auto-restart on its own very quickly. If so:
- Try disabling Docker auto-start in Docker Desktop settings
- Or accept that this feature works but is hard to test automatically

**Result**: ✅ Pass / ❌ Fail / ⚠️ Docker auto-restarted too fast
**Notes**: _______________________________________

---

### Test 3: Terminal Mode (Complete Workflow) ⭐⭐

**Purpose**: Verify complete terminal workflow from scratch

**Steps**:
```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
..\scripts\bitbot.ps1 work
```

**Expected Behavior**:

1. **Build Phase**:
   ```
   BitBot Work Mode
   ================

   Building devcontainer...
     Workspace: C:\Projects\BitBot\test-windows-launch
     Platform:  wsl
     CLI:       standalone (devcontainer.cmd)

   [DevContainer build logs...]
   ✓ DevContainer built successfully
   ```

2. **Launch Phase**:
   ```
   Launching terminal...
     Container: [random-name]

   Entering devcontainer terminal...
   ```

3. **Inside Container**:
   ```bash
   root@[container-id]:/workspace#
   ```

**Actions Inside Container**:
```bash
# Verify location
pwd
# Should show: /workspace

# List files
ls
# Should show: scripts/, tests/, .devcontainer/, etc.

# Check Claude Code
which claude
# Should show: /usr/local/bin/claude

# Check git
git --version
# Should show: git version 2.34.1 (or similar)

# Exit
exit
```

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 4: VS Code Mode (Direct DevContainer Opening Direct Opening) ⭐⭐⭐

**Purpose**: Verify VS Code opens directly in devcontainer without popup

**Prerequisites**:
- VS Code installed
- Dev Containers extension installed (or standalone CLI)

**Steps**:
```powershell
# Clean up any existing containers first
cd C:\Projects\BitBot\test-windows-launch\tests
.\clean-slate.ps1 -KeepAlpine

# Launch VS Code mode
..\scripts\bitbot.ps1 vscode
```

**Expected Behavior**:

1. **Console Output**:
   ```
   BitBot Work Mode
   ================

   Launching VS Code...
     Using: Direct DevContainer Opening

     Windows path: C:\Projects\BitBot\test-windows-launch
     Hex encoded:  433a5c50726f6a656374735c4269744...

   ✓ VS Code launched

   VS Code should open directly in the devcontainer.
   If prompted, click 'Install' to add required extensions.
   ```

2. **VS Code Window**:
   - Opens a new VS Code window
   - Shows "Opening Remote..." in status bar
   - Builds devcontainer (if not already built)
   - Opens directly in container

3. **Verify in VS Code**:
   - Bottom-left corner shows: "Dev Container: BitBot Test"
   - No "Reopen in Container" popup
   - Terminal opens at /workspace
   - File explorer shows workspace files

**Important Checks**:
- ✅ No "Reopen in Container" popup (this means Direct DevContainer Opening worked!)
- ✅ Opens directly in devcontainer
- ✅ Status bar shows "Dev Container"
- ✅ File paths are correct (/workspace)

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 5: Command Shortcuts ⭐

**Purpose**: Verify shortcut commands work

**Steps**:
```powershell
cd C:\Projects\BitBot\test-windows-launch\tests

# Test terminal shortcut
..\scripts\bitbot.ps1 terminal
# Should enter terminal mode

# Exit container
exit

# Test vscode shortcut
..\scripts\bitbot.ps1 vscode
# Should launch VS Code mode
```

**Expected Behavior**:
- `bitbot terminal` = `bitbot work terminal`
- `bitbot vscode` = `bitbot work vscode`
- Both work identically to explicit syntax

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 6: Batch Entry Point ⭐

**Purpose**: Verify cmd.exe entry point works

**Steps**:
```batch
REM From Windows cmd.exe
cd C:\Projects\BitBot\test-windows-launch\tests

REM Test version
..\scripts\bitbot.bat version

REM Test work mode
..\scripts\bitbot.bat work
```

**Expected Behavior**:
```
Entry Point: Windows cmd.exe
Using WSL:     BitBot-Alpine
BitBot version 0.1.0-test
...
```

- Same functionality as PowerShell
- Shows "Windows cmd.exe" as entry point

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 7: Direct Bash Execution ⭐

**Purpose**: Verify direct bash execution (no Windows wrapper)

**Steps**:
```bash
# From WSL or Linux terminal
cd /mnt/c/Projects/BitBot/test-windows-launch/tests

# Test version
../scripts/bitbot version

# Test work mode
../scripts/bitbot work
```

**Expected Behavior**:
- No "Entry Point" message (direct execution)
- No "Using WSL" message (native bash)
- Otherwise identical functionality

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

### Test 8: Error Handling - No VS Code ⭐

**Purpose**: Verify error message when VS Code not found

**Prerequisites**:
- Temporarily rename VS Code or test on system without it
- Or mock the test

**Steps**:
```powershell
..\scripts\bitbot.ps1 vscode
```

**Expected Behavior**:
```
Error: VS Code not found
Install from: https://code.visualstudio.com/
```

**Result**: ✅ Pass / ❌ Fail / ⚠️ Skipped (VS Code installed)
**Notes**: _______________________________________

---

### Test 9: DevContainer CLI Installation ⭐⭐

**Purpose**: Verify CLI installation prompt works

**Prerequisites**: DevContainer CLI not installed (clean-slate removes it)

**Steps**:
```powershell
# If VS Code with Dev Containers extension is installed,
# this test might not apply (builtin CLI used)

..\scripts\bitbot.ps1 work
```

**Expected Behavior** (if no CLI found):
```
DevContainer CLI not found.

Options:
  1. Install VS Code with Dev Containers extension (recommended)
     https://code.visualstudio.com/
     Extension: ms-vscode-remote.remote-containers

  2. Install standalone CLI:
     npm install -g @devcontainers/cli

Install standalone CLI now? (requires Node.js) [y/N]:
```

**If VS Code Builtin**:
- Should show: "CLI: builtin (devcontainer.cmd)"
- No installation prompt (expected)

**Result**: ✅ Pass / ❌ Fail / ⚠️ Builtin CLI used
**Notes**: _______________________________________

---

### Test 10: Container Re-use ⭐

**Purpose**: Verify BitBot reuses existing containers

**Steps**:
```powershell
# First run - builds container
..\scripts\bitbot.ps1 work
exit

# Second run - should reuse container
..\scripts\bitbot.ps1 work
```

**Expected Behavior**:

**First Run**:
- Builds devcontainer (takes time)
- Shows Docker build output

**Second Run**:
- Uses existing container (very fast)
- Shows: "Launching terminal..."
- No rebuild (unless devcontainer.json changed)

**Result**: ✅ Pass / ❌ Fail
**Notes**: _______________________________________

---

## Priority Test Order

### Critical Tests (Must Pass) 🔴
1. **Test 1**: Fresh Alpine Installation
2. **Test 3**: Terminal Mode (Complete Workflow)
3. **Test 4**: VS Code Mode (Direct DevContainer Opening Direct Opening)

### Important Tests (Should Pass) 🟡
4. **Test 2**: Docker Auto-Start
5. **Test 5**: Command Shortcuts
6. **Test 10**: Container Re-use

### Nice to Have (Can Skip) 🟢
7. **Test 6**: Batch Entry Point
8. **Test 7**: Direct Bash Execution
9. **Test 8**: Error Handling - No VS Code
10. **Test 9**: DevContainer CLI Installation

---

## Known Issues to Watch For

### Issue 1: Docker Auto-Restart
**Symptom**: Docker restarts immediately after stopping
**Cause**: Docker Desktop auto-start behavior
**Impact**: Can't test auto-start feature
**Workaround**: Disable auto-start in Docker Desktop settings

### Issue 2: Container Name Mismatch
**Symptom**: "Container not running" error
**Cause**: DevContainer CLI uses random names
**Status**: FIXED - now finds by label
**Expected**: Should work correctly

### Issue 3: VS Code Reopen Popup
**Symptom**: VS Code shows "Reopen in Container" popup
**Cause**: Direct DevContainer Opening not working correctly
**Status**: Should NOT happen (implementation verified)
**Expected**: Opens directly without popup

### Issue 4: Path Encoding Issues
**Symptom**: Hex encoding errors, path not found
**Cause**: Special characters in path
**Status**: Implementation uses wslpath + hex encoding
**Expected**: Should work with standard paths

---

## Test Results Template

Copy this template to record your results:

```markdown
# BitBot Manual Test Results

**Tester**: _______________________
**Date**: 2025-10-20
**Environment**: Windows 11 / WSL2

## Test Results

| Test | Status | Time | Notes |
|------|--------|------|-------|
| 1. Fresh Alpine Install | ☐ Pass / ☐ Fail | ___ | ________________ |
| 2. Docker Auto-Start | ☐ Pass / ☐ Fail / ☐ Skip | ___ | ________________ |
| 3. Terminal Mode | ☐ Pass / ☐ Fail | ___ | ________________ |
| 4. VS Code Mode | ☐ Pass / ☐ Fail | ___ | ________________ |
| 5. Command Shortcuts | ☐ Pass / ☐ Fail | ___ | ________________ |
| 6. Batch Entry Point | ☐ Pass / ☐ Fail | ___ | ________________ |
| 7. Direct Bash | ☐ Pass / ☐ Fail | ___ | ________________ |
| 8. Error - No VS Code | ☐ Pass / ☐ Fail / ☐ Skip | ___ | ________________ |
| 9. CLI Installation | ☐ Pass / ☐ Fail / ☐ Skip | ___ | ________________ |
| 10. Container Re-use | ☐ Pass / ☐ Fail | ___ | ________________ |

## Critical Issues Found

1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

## Overall Assessment

☐ Ready for production
☐ Needs minor fixes
☐ Needs major fixes

## Recommendations

_________________________________________________
_________________________________________________
_________________________________________________
```

---

## Quick Start - Most Important Tests

If you only have time for 3 tests, run these:

### 1️⃣ Test Alpine Install + Version
```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
..\scripts\bitbot.ps1 version
# Install Alpine when prompted
```

### 2️⃣ Test Terminal Mode
```powershell
..\scripts\bitbot.ps1 work
# Should build and enter container
# Type: pwd, ls, exit
```

### 3️⃣ Test VS Code Mode
```powershell
.\clean-slate.ps1 -KeepAlpine
..\scripts\bitbot.ps1 vscode
# Should open VS Code directly in container (no popup!)
```

**If these 3 pass**: ✅ Core functionality works!

---

## After Testing

Please report results with:
1. Which tests passed/failed
2. Any error messages
3. Screenshots (especially for VS Code Direct DevContainer Opening test)
4. System info (Windows version, WSL version)

---

**Good luck testing! 🚀**
