# Archived PowerShell Scripts

**Date Archived:** 2025-11-14
**Reason:** Replaced with minimal CMD + bash architecture

---

## What Was Replaced

### 1. bitbot-old.cmd (67 lines)
**Replaced by:** `core/bitbot.cmd` (27 lines)

**Old approach:**
- Complex UTF-16 parsing with PowerShell
- Called PowerShell for WSL distro checking
- 67 lines of CMD + PowerShell hybrid

**New approach:**
- Direct WSL distro check: `wsl -d BitBot-Alpine --exec true`
- No UTF-16 parsing needed
- 27 lines of pure CMD

### 2. install-bitbot-wsl.ps1 (120+ lines)
**Replaced by:** `core/install-bitbot.cmd` (80 lines) + `container/bitbot/setup-bitbot.sh` (100 lines)

**Old approach:**
- PowerShell script for everything
- ExecutionPolicy bypass required
- Complex UTF-16 handling
- Binary PowerShell modules

**New approach:**
- Minimal CMD bootstrap (download + import)
- All logic in bash (package install, configuration)
- No ExecutionPolicy issues
- User-readable source code

### 3. enable-docker-wsl-integration-simple.ps1 (30 lines)
**Replaced by:** `container/bitbot/lib/enable-docker-integration.sh` (80 lines bash)

**Old approach:**
- PowerShell JSON manipulation
- Windows-side execution

**New approach:**
- Bash with `jq` for JSON manipulation
- Runs inside WSL (access to /mnt/c)
- Better error handling
- Creates backups

---

## Why the Change?

### Problems with PowerShell
1. **ExecutionPolicy issues** - Users often blocked
2. **UTF-16 complexity** - `wsl --list` output parsing fragile
3. **Not readable** - Binary modules, hard to inspect
4. **Windows-only** - Can't reuse on Linux
5. **Heavyweight** - PowerShell startup overhead

### Benefits of CMD + Bash
1. ✅ **No ExecutionPolicy** - CMD always executable
2. ✅ **No UTF-16 parsing** - Direct distro check
3. ✅ **Readable source** - Users can inspect bash scripts
4. ✅ **Cross-platform** - Bash scripts work on Linux
5. ✅ **Better tools** - jq, curl, apk available
6. ✅ **Simpler** - 27-line CMD vs 67-line hybrid

---

## New Architecture

```
bitbot.exe (C launcher)
  ↓
bitbot.cmd (minimal - 27 lines)
  ├─ Check WSL exists
  ├─ Check Alpine exists (wsl -d BitBot-Alpine --exec true)
  ├─ If missing → install-bitbot.cmd
  └─ Launch → wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot
      ↓
      BASH (all logic in Alpine WSL)
```

---

## Migration

**For existing users:**
```cmd
REM Backup existing Alpine (if customized)
wsl -d BitBot-Alpine --export bitbot-backup.tar

REM Uninstall old
wsl --unregister BitBot-Alpine

REM Run BitBot (auto-installs with new method)
bitbot work
```

**For new users:**
No changes needed - just run `bitbot work`

---

## Related Documentation

- Architecture: `/sparc/0-research/MINIMAL_CMD_BASH_ARCHITECTURE.md`
- Claude CodePro: `/sparc/0-research/CLAUDE_CODEPRO_ANALYSIS.md`
- Meridian: `/sparc/0-research/MERIDIAN_ANALYSIS.md`

---

**These scripts are kept for reference only and should not be used in production.**
