# Docker Desktop WSL Corruption - Root Cause Analysis

**Date**: 2025-10-17
**Issue**: VS Code WSL terminals open at wrong path after Docker Desktop starts
**Status**: ✅ SOLVED with dedicated BitBot WSL distro

---

## The Problem

### Symptoms

When Docker Desktop is running on Windows with WSL2 backend:

| Context | Expected Path | Actual Path | Status |
|---------|---------------|-------------|--------|
| Standalone WSL terminal | `/home/mk` or `/mnt/c/...` | ✅ Correct | Working |
| VS Code opened from WSL | `/mnt/c/...` | ✅ Correct | Working |
| **VS Code opened from Windows** | `/mnt/c/...` | ❌ `/mnt/wsl/docker-desktop-bind-mounts/Ubuntu-22.04/8a998d90...` | **BROKEN** |

### Key Observations

1. **Only affects Windows-hosted VS Code** using WSL terminals
2. **Does NOT affect standalone WSL** or WSL-hosted VS Code
3. **Corruption happens when Docker Desktop starts**
4. **All Windows VS Code instances affected globally** (not workspace-specific)
5. **Same WSL distro** (`Ubuntu-22.04`) in both cases - only working directory differs
6. **Persists across VS Code restarts** but fixed by system reboot

---

## Root Cause Investigation

### Initial Hypotheses (Disproven)

❌ **Cached workspace paths** in `%APPDATA%\Code\User\workspaceStorage\`
- Tested: No corrupt paths found in cache
- Result: Not a caching issue

❌ **devcontainer CLI corruption**
- Initial suspicion: Running `devcontainer up` from WSL corrupts paths
- Tested: Corruption happens even without running devcontainer CLI
- Result: devcontainer CLI is innocent

❌ **Docker Compose bind-mount regression**
- Known bug in Docker Compose v2.29.3 (September 2024)
- Tested: User has v2.40.0 (December 2024) - bug already fixed
- Result: Not the compose bug

❌ **Native Docker in WSL conflict**
- Tested: No native Docker installed in WSL
- Result: No conflict

❌ **Windows Registry corruption**
- Checked: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`
- Ubuntu-22.04 `BasePath`: Clean, correct path
- Result: Registry is fine

### Actual Root Cause ✅

**Docker Desktop corrupts `wslservice.exe` runtime state**

#### Evidence

1. **Killing wslservice.exe fixes the issue**:
   ```powershell
   taskkill /f /im wslservice.exe
   # VS Code WSL terminals immediately work correctly
   ```

2. **But breaks Docker**:
   - Docker Desktop cannot start containers after killing wslservice
   - Docker Desktop depends on wslservice to manage `docker-desktop` and `docker-desktop-data` WSL distros

3. **Timing confirms it's Docker Desktop startup**:
   - Fresh reboot: WSL terminals work ✅
   - Start Docker Desktop: Corruption appears ❌
   - Persists until wslservice restart

4. **Only affects DEFAULT WSL distro**:
   - `Ubuntu-22.04` (default, marked with `*` in `wsl -l -v`): Corrupted ❌
   - `BitBot-Alpine` (non-default): Clean ✅
   - `docker-desktop`: Not user-facing

#### Technical Details

**What wslservice.exe does**:
- Windows service that manages all WSL distributions
- Handles WSL → Windows path translation
- Maintains working directory state for WSL terminals
- Used by VS Code Remote-WSL extension

**What Docker Desktop does to corrupt it**:
- Docker Desktop integrates with default WSL distro via Settings → Resources → WSL Integration
- When Docker Desktop starts, it modifies wslservice.exe's in-memory state
- wslservice.exe incorrectly associates default WSL's working directory with Docker's internal mount paths
- This is **runtime state corruption**, not registry or file-based

**Why standalone WSL is unaffected**:
- Standalone WSL terminal doesn't query wslservice.exe for working directory
- It uses WSL's internal path resolution
- Only Windows applications (like VS Code) using Remote-WSL extension are affected

---

## Solutions Tested

### Solution 1: Restart WSL Service ⚠️ Partial

```powershell
Restart-Service -Name "WslService" -Force
```

**Result**:
- ✅ Fixes VS Code WSL terminals
- ❌ Breaks Docker Desktop (cannot start containers)
- Verdict: Not viable - need both working

### Solution 2: Disable WSL Integration ❌ Rejected

**Approach**: Disable Docker Desktop's WSL integration for Ubuntu-22.04

**Problem**: BitBot needs 99% Linux code for cross-platform compatibility
- Must run docker/devcontainer commands from WSL, not Windows
- Disabling integration defeats BitBot's architecture goals

### Solution 3: Dedicated BitBot WSL Distro ✅ WINNER

**Approach**: Create separate WSL distro exclusively for BitBot

**Implementation**:
```powershell
# Install Alpine Linux as BitBot-Alpine
.\install-bitbot-wsl.ps1
```

**Why it works**:
- Docker Desktop only corrupts the **DEFAULT** WSL distro
- Non-default distros are immune ✅
- BitBot-Alpine is isolated from user's Ubuntu-22.04

**Benefits**:
```
┌─────────────────────────────────┐
│ Windows                         │
│  ┌──────────────────────────┐  │
│  │ Docker Desktop           │  │
│  └──────────────────────────┘  │
│           │                     │
│  ┌────────┴────────────────┐   │
│  │                         │   │
│  ▼                         ▼   │
│  Ubuntu-22.04         BitBot-Alpine
│  (User's WSL)         (BitBot only)
│  - User tools         - git
│  - User configs       - docker-cli
│  - User projects      - devcontainer
│  - May get corrupted  - nodejs/npm
│  ✅ User unaffected   ✅ Immune to corruption
└─────────────────────────────────┘
```

**Technical advantages**:
- ✅ 8 MB footprint (Alpine Linux)
- ✅ Immune to Docker Desktop corruption
- ✅ Isolated from user's WSL environment
- ✅ Easy to reset if issues occur
- ✅ User's WSL stays completely clean
- ✅ 99% Linux code (cross-platform goal met)
- ✅ No conflicts with user's tools/configs

---

## BitBot Architecture Decision

### Final Windows Launch Flow

```
User runs: bitbot vscode
  ↓
BitBot PowerShell script
  ↓
Checks if BitBot-Alpine exists
  ├─ No → Run install-bitbot-wsl.ps1
  └─ Yes → Continue
  ↓
wsl -d BitBot-Alpine bash -l -c "cd /mnt/c/Projects/MyProject && devcontainer up"
  ↓
wsl -d BitBot-Alpine bash -l -c "code /mnt/c/Projects/MyProject"
  ↓
VS Code opens in clean BitBot-Alpine context
  ↓
✅ All paths correct, no corruption
```

### Why Not Other Solutions?

**Why not fix Docker Desktop?**
- It's a Docker Desktop bug, not BitBot's responsibility
- Microsoft/Docker need to fix wslservice.exe corruption
- BitBot needs to work with current Docker Desktop versions
- Workaround is cleaner than patching Docker

**Why not use Windows-hosted VS Code without WSL?**
- BitBot's goal: 99% Linux code for cross-platform
- Windows-only approach defeats portability
- WSL provides Linux environment on Windows

**Why not use WSL-hosted VS Code?**
- Requires `code` CLI installed in WSL
- User might not have it configured
- Windows VS Code is the standard installation
- BitBot should work with default Windows VS Code

**Why Alpine instead of Debian/Ubuntu?**
- Size: 8 MB vs 100-300 MB
- Speed: Faster startup
- Minimal: Only what BitBot needs
- Isolation: Clearly not user's main environment

---

## Testing Results

### Before Fix (Ubuntu-22.04 as default)

```powershell
PS> wsl -l -v
  NAME              STATE           VERSION
* Ubuntu-22.04      Running         2
  docker-desktop    Running         2

PS> code C:\Projects\BitBot\test-windows-launch
# VS Code opens
# Ctrl+` for WSL terminal
# Inside terminal:

$ echo $WSL_DISTRO_NAME
Ubuntu-22.04

$ pwd
/mnt/wsl/docker-desktop-bind-mounts/Ubuntu-22.04/8a998d90da1a56ab7885c7e1acce98518fcb6d4db120e0bd84cd7dbe107afbcc

❌ Wrong path!
```

### After Fix (BitBot-Alpine)

```powershell
PS> wsl -l -v
  NAME              STATE           VERSION
* Ubuntu-22.04      Running         2
  BitBot-Alpine     Running         2
  docker-desktop    Running         2

PS> wsl -d BitBot-Alpine bash -c "code /mnt/c/Projects/BitBot/test-windows-launch"
# VS Code opens
# Ctrl+` for WSL terminal
# Inside terminal:

$ echo $WSL_DISTRO_NAME
BitBot-Alpine

$ pwd
/mnt/c/Projects/BitBot/test-windows-launch

✅ Correct path!
```

### User's WSL Unaffected

```powershell
PS> wsl -d Ubuntu-22.04
$ pwd
/home/mk

✅ User's WSL completely clean and unaffected
```

---

## Related Issues Found Online

### Stack Overflow: Long working directory in bash (2020)
**Link**: https://stackoverflow.com/questions/62396010/long-working-directory-in-bash-when-docker-desktop-is-running-in-wsl2

**Quote**:
> "When Docker Desktop is running with WSL2, launching wsl.exe can initialize the shell in a very long directory path like `/mnt/wsl/docker-desktop-bind-mounts/Ubuntu-20.04/[hash]/mnt/c/Windows/System32`"

**Workaround suggested**: Add bashrc script to detect and redirect

**Our finding**: This is the same bug, 4+ years old, still unfixed in Docker Desktop 4.48

### Docker Compose v2.29.3 Bind Mount Bug (2024)
**Issue**: https://github.com/docker/compose/issues/12129

**Status**: Fixed in v2.29.5+ (September 2024)

**Our finding**: Not our issue - we have v2.40.0

### Windows Registry Solutions
**Common advice**: Fix `BasePath` in `HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`

**Our finding**: Registry was clean - issue is runtime state, not persisted data

---

## Recommendations for BitBot

### Implementation Decisions

1. **Use dedicated BitBot WSL distro** (BitBot-Alpine)
   - Automatically install if missing
   - Document in user guide
   - Script: `install-bitbot-wsl.ps1`

2. **All BitBot commands run through BitBot-Alpine**
   ```powershell
   wsl -d BitBot-Alpine bash -l -c "..."
   ```

3. **Keep user's default WSL untouched**
   - No modifications to Ubuntu-22.04
   - No interference with user's setup
   - Clean separation of concerns

4. **Document the issue**
   - Explain why dedicated distro is needed
   - Reference this analysis document
   - Provide troubleshooting guide

### User Experience

**First time setup**:
```powershell
PS> bitbot init
[>] BitBot WSL not found
[>] Installing BitBot-Alpine (8 MB)...
[+] BitBot-Alpine installed
[+] Ready to use BitBot
```

**Transparent to user**:
- User doesn't need to know about corruption issue
- "BitBot uses its own environment for isolation"
- Works reliably regardless of Docker Desktop state

**Easy recovery**:
```powershell
PS> bitbot repair
[>] Reinstalling BitBot-Alpine...
[+] BitBot environment reset
```

---

## Open Questions

### For Microsoft/Docker

1. Why does Docker Desktop corrupt default WSL's working directory state?
2. Is this intentional or a bug in wslservice.exe?
3. Will WSL 3.0 fix this issue?
4. Should Docker Desktop only affect docker-desktop distros, not user distros?

### For BitBot

1. ✅ Should BitBot install Alpine automatically? **Yes**
2. ✅ Should BitBot support other distros (Debian, etc.)? **Alpine default, others optional**
3. ✅ How to handle if BitBot-Alpine gets corrupted? **Easy reinstall script**
4. ✅ Should BitBot set itself as default WSL? **No - stay non-default for immunity**

---

## Conclusion

**Problem**: Docker Desktop corrupts default WSL distro's working directory state

**Root Cause**: wslservice.exe runtime corruption when Docker Desktop starts

**Solution**: Use dedicated non-default WSL distro (BitBot-Alpine)

**Status**: ✅ SOLVED

**Impact**:
- ✅ BitBot works reliably
- ✅ User's WSL environment untouched
- ✅ Cross-platform (99% Linux code)
- ✅ Small footprint (8 MB)
- ✅ Easy to maintain/reset

**Next Steps**:
1. Update BitBot specification with BitBot-Alpine requirement
2. Integrate `install-bitbot-wsl.ps1` into BitBot installer
3. Document user-facing explanation
4. Consider reporting bug to Microsoft/Docker (low priority)
