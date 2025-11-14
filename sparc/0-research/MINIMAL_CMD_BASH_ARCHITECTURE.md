# Minimal CMD + Bash Architecture

**Date:** 2025-11-14
**Purpose:** Eliminate PowerShell dependency, move all logic to bash scripts

---

## Architecture Overview

### Complete Flow

```
User runs: bitbot.exe work

┌─────────────────────────────────────────────────────────────────┐
│ Windows Layer (Minimal)                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  bitbot.exe (C launcher)                                       │
│    ↓                                                           │
│    Calls: cmd.exe /c bitbot.cmd work                          │
│                                                                 │
│  bitbot.cmd (27 lines - minimal logic)                        │
│    ↓                                                           │
│    1. Check WSL installed: wsl --status                       │
│    2. Check Alpine exists: wsl -d BitBot-Alpine --exec true  │
│       (NO UTF-16 parsing!)                                    │
│    3. If not exists → call install-bitbot.cmd                │
│    4. Launch WSL: wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ First-Run Bootstrap (Only if Alpine doesn't exist)             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  install-bitbot.cmd (80 lines - bootstrap only)               │
│    ↓                                                           │
│    1. Download: curl alpine-rootfs.tar.gz                     │
│    2. Import: wsl --import BitBot-Alpine                      │
│    3. Copy scripts: setup-bitbot.sh, enable-docker-*.sh       │
│    4. Run setup: wsl -d BitBot-Alpine /opt/bitbot/setup-*.sh │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ WSL Layer (All Logic in Bash)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  setup-bitbot.sh (runs once after import)                     │
│    ↓                                                           │
│    1. Install packages: apk add bash git docker-cli nodejs... │
│    2. Install devcontainers CLI: npm install -g @devcontainers│
│    3. Create directories: /opt/bitbot/{bin,lib}               │
│    4. Configure bash as default shell                         │
│    5. Enable Docker integration (call enable-docker-*.sh)     │
│                                                                 │
│  enable-docker-integration.sh                                 │
│    ↓                                                           │
│    1. Find Docker settings.json (/mnt/c/Users/.../Docker/)   │
│    2. Modify with jq: enableIntegrationWithDistro[Alpine]=true│
│    3. Backup original settings                                │
│                                                                 │
│  /opt/bitbot/bin/bitbot (existing bash script)                │
│    ↓                                                           │
│    All BitBot runtime logic (work, init, config, etc.)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Changes

### New Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `container/bitbot/setup-bitbot.sh` | ~100 | Alpine first-run setup (replaces PS1) |
| `container/bitbot/lib/enable-docker-integration.sh` | ~80 | Docker config (replaces PS1) |
| `core/bitbot-new.cmd` | 27 | Minimal launcher (simplified) |
| `core/install-bitbot.cmd` | 80 | Bootstrap installer (replaces PS1) |

### Files to Replace

| Old File | Lines | New File | Lines | Savings |
|----------|-------|----------|-------|---------|
| `core/bitbot.cmd` | 67 | `core/bitbot-new.cmd` | 27 | -40 lines |
| `sparc/.../install-bitbot-wsl.ps1` | 120+ | `core/install-bitbot.cmd` | 80 | -40 lines |
| `sparc/.../enable-docker-*.ps1` | 30+ | `container/bitbot/lib/enable-docker-*.sh` | 80 | +50 (but bash!) |

### Files to Delete

- ❌ `sparc/4-refinement/archive/manual-building/install-bitbot-wsl.ps1`
- ❌ `sparc/4-refinement/archive/manual-building/enable-docker-wsl-integration-simple.ps1`
- ❌ `dev/tests/helpers/enable-docker-wsl-integration-simple.ps1`

**Result:** Zero PowerShell scripts in production!

---

## Key Improvements

### 1. No PowerShell Dependency

**Before:**
```cmd
REM bitbot.cmd line 21:
powershell -NoProfile -Command "$list = wsl --list --quiet | ForEach-Object { $_.Trim() -replace '\x00', '' }; if ($list -contains '%DISTRO_NAME%') { exit 0 } else { exit 1 }" >nul 2>&1

REM bitbot.cmd line 44:
powershell -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%"
```

**After:**
```cmd
REM bitbot-new.cmd line 11:
wsl -d BitBot-Alpine --exec true >nul 2>&1

REM bitbot-new.cmd line 14:
call install-bitbot.cmd
```

**Benefits:**
- ✅ No ExecutionPolicy issues
- ✅ No UTF-16 parsing complexity
- ✅ Simpler, more reliable

### 2. No UTF-16 Parsing

**Before:** Had to parse `wsl --list --quiet` output (UTF-16LE with null bytes)

**After:** Just check if distro is accessible
```cmd
wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% neq 0 (
    REM Distro doesn't exist
)
```

### 3. Readable Source Code

**Before:** PowerShell binary modules, ExecutionPolicy restrictions

**After:** Users can read/modify bash scripts:
```bash
wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh
wsl -d BitBot-Alpine nano /opt/bitbot/lib/enable-docker-integration.sh
```

### 4. Better Tools Available

**In Alpine WSL:**
- ✅ `jq` - JSON manipulation (better than PowerShell parsing)
- ✅ `curl` - Downloads (simpler than Invoke-WebRequest)
- ✅ `apk` - Package manager (native Alpine)
- ✅ `git` - Version control
- ✅ Standard bash utilities

### 5. Cross-Platform Ready

Bash scripts can run on:
- ✅ Windows (via WSL)
- ✅ Linux (native)
- ✅ macOS (future support)

---

## Comparison Table

| Feature | Old (CMD + PowerShell) | New (CMD + Bash) |
|---------|------------------------|------------------|
| **Windows layer** | bitbot.cmd (67 lines) | bitbot.cmd (27 lines) |
| **Installer** | PowerShell (120 lines) | CMD bootstrap (80 lines) + bash setup (100 lines) |
| **UTF-16 handling** | PowerShell parsing | Not needed (direct check) |
| **Docker config** | PowerShell (30 lines) | Bash (80 lines) |
| **ExecutionPolicy** | Required bypass | Not applicable |
| **User editable** | No (PowerShell modules) | Yes (plain bash scripts) |
| **Total PowerShell** | 150+ lines | 0 lines |

---

## Implementation Status

### ✅ Completed (Phase 1)

- [x] `setup-bitbot.sh` - Alpine first-run setup
- [x] `enable-docker-integration.sh` - Docker config
- [x] `bitbot-new.cmd` - Minimal CMD launcher
- [x] `install-bitbot.cmd` - Bootstrap installer
- [x] Scripts marked executable

### 🔄 Testing (Phase 2)

**Test Plan:**

1. **Fresh Install Test**
   ```cmd
   REM Uninstall existing BitBot-Alpine
   wsl --unregister BitBot-Alpine

   REM Test fresh install
   bitbot.exe work
   REM Should: download, import, setup, launch
   ```

2. **Existing Install Test**
   ```cmd
   REM With BitBot-Alpine already installed
   bitbot.exe work
   REM Should: skip install, launch directly
   ```

3. **Docker Integration Test**
   ```bash
   wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh
   # Should: modify settings.json, show current integrations
   ```

4. **Script Accessibility Test**
   ```bash
   wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh
   # Should: display readable source
   ```

### 📋 Pending (Phase 3)

- [ ] Replace `core/bitbot.cmd` with `bitbot-new.cmd`
- [ ] Delete old PowerShell scripts
- [ ] Update documentation
- [ ] Update `.gitattributes` (remove .ps1 rules if unused)
- [ ] Update SPARC docs (remove PowerShell references)

---

## Migration Guide

### For Developers

**Before updating:**
```bash
# Backup existing Alpine (if you have custom config)
wsl -d BitBot-Alpine --export bitbot-alpine-backup.tar
```

**After updating:**
```bash
# Uninstall old Alpine
wsl --unregister BitBot-Alpine

# Run BitBot (will auto-install new Alpine)
bitbot work
```

### For Users (Fresh Install)

No changes needed! Just run:
```cmd
bitbot work
```

The new minimal architecture handles everything automatically.

---

## Security Improvements

### 1. No Execution Policy Bypass

**Old:**
```cmd
powershell -ExecutionPolicy Bypass -File install.ps1
```

**Risk:** Could accidentally run untrusted PowerShell scripts

**New:**
```cmd
call install-bitbot.cmd
wsl -d BitBot-Alpine /opt/bitbot/setup-bitbot.sh
```

**Safer:** CMD and bash scripts always executable (no policy bypass needed)

### 2. Transparent Source Code

Users can inspect all scripts:
```bash
# See exactly what setup does
wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh

# See Docker integration changes
wsl -d BitBot-Alpine cat /opt/bitbot/lib/enable-docker-integration.sh
```

### 3. Isolated Environment

All package installation happens inside Alpine WSL:
```bash
apk add --no-cache bash git docker-cli nodejs npm
```

No Windows system modifications (except Docker settings.json with user consent).

---

## Next Steps

1. **Test Phase** - Verify all scripts work correctly
2. **Replace Files** - Swap old bitbot.cmd with new version
3. **Cleanup** - Delete PowerShell scripts
4. **Documentation** - Update SPARC docs
5. **Release** - Announce PowerShell elimination in release notes

---

## References

- Claude CodePro Analysis: `/sparc/0-research/CLAUDE_CODEPRO_ANALYSIS.md` (Docker security)
- Meridian Analysis: `/sparc/0-research/MERIDIAN_ANALYSIS.md` (Task management)
- Current bitbot.cmd: `/core/bitbot.cmd` (to be replaced)
- PowerShell installer: `/sparc/4-refinement/archive/manual-building/install-bitbot-wsl.ps1` (to be deleted)

---

**Version:** 1.0
**Author:** Claude (BitBot Development)
**Status:** Phase 1 Complete (scripts created, testing pending)
