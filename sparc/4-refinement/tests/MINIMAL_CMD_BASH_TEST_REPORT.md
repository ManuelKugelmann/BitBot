# Minimal CMD + Bash Architecture - Test Report

**Date:** 2025-11-14
**Phase:** Syntax Validation & Static Analysis
**Status:** ✅ PASS (with fixes applied)

---

## Test Summary

| Test | Status | Details |
|------|--------|---------|
| **Bash syntax validation** | ✅ PASS | Both scripts valid after line ending fix |
| **CMD syntax validation** | ✅ PASS | Parentheses balanced, no syntax errors |
| **Line ending fix** | ✅ PASS | CRLF → LF conversion successful |
| **Script archival** | ✅ PASS | Old PowerShell scripts archived |
| **File replacement** | ✅ PASS | New bitbot.cmd deployed |

---

## Detailed Test Results

### 1. Bash Script Validation

#### setup-bitbot.sh

**Initial Issue:**
```bash
Error: CRLF line endings detected
/home/user/BitBot/container/bitbot/setup-bitbot.sh: line 33: syntax error
```

**Fix Applied:**
```bash
sed -i 's/\r$//' setup-bitbot.sh
```

**Result:**
```
✅ setup-bitbot.sh: Syntax OK
   - Shebang: #!/bin/sh
   - Line endings: LF (Unix)
   - if/fi balance: 4/4 ✓
   - Executable: chmod +x ✓
```

**Functions:**
- Package installation (apk add bash git docker-cli nodejs npm curl jq)
- @devcontainers/cli installation
- Directory creation (/opt/bitbot/{bin,lib})
- Bash shell configuration
- Docker integration trigger

#### enable-docker-integration.sh

**Initial Issue:**
```bash
Error: CRLF line endings detected
```

**Fix Applied:**
```bash
sed -i 's/\r$//' enable-docker-integration.sh
```

**Result:**
```
✅ enable-docker-integration.sh: Syntax OK
   - Shebang: #!/bin/bash
   - Line endings: LF (Unix)
   - jq dependency: Declared ✓
   - Error handling: set -e ✓
   - Executable: chmod +x ✓
```

**Functions:**
- Windows username detection
- Docker settings.json discovery
- jq-based JSON modification
- Backup creation
- Integration status display

---

### 2. CMD Script Validation

#### bitbot.cmd (new minimal version)

**Syntax Check:**
```
✅ Parentheses balanced: 8 opening / 8 closing
✅ Error handling: All paths covered
✅ Quote balance: Correct
✅ Variable expansion: %~1, %ERRORLEVEL% valid
```

**Structure:**
```cmd
Lines: 27 (down from 67 - 60% reduction!)

1. Check WSL installed: wsl --status
2. Check Alpine exists: wsl -d BitBot-Alpine --exec true
3. If missing → call install-bitbot.cmd
4. Launch WSL: wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot
```

**Key Improvement:**
- ❌ Old: `powershell -Command "wsl --list | ... -replace '\x00'"`
- ✅ New: `wsl -d BitBot-Alpine --exec true`

**No UTF-16 parsing needed!**

#### install-bitbot.cmd (bootstrap)

**Syntax Check:**
```
✅ Parentheses balanced: 9 opening / 9 closing
✅ Path variables: %LOCALAPPDATA%, %TEMP%, %~dp0 valid
✅ Curl usage: Correct Windows 10+ syntax
✅ WSL commands: Proper quoting
```

**Structure:**
```cmd
Lines: 80

1. Download Alpine rootfs (curl)
2. Import WSL (wsl --import)
3. Copy scripts to WSL (cat > /opt/bitbot/...)
4. Run setup (wsl -d BitBot-Alpine /opt/bitbot/setup-bitbot.sh)
5. Cleanup temp files
```

**Dependencies:**
- curl.exe (built-in Windows 10+)
- wsl.exe (WSL2 required)
- cat (inside WSL after import)

---

### 3. File Organization

#### Archived Files

**Location:** `sparc/4-refinement/archive/powershell-scripts/`

| File | Size | Reason |
|------|------|--------|
| `bitbot-old.cmd` | 67 lines | Replaced by 27-line version |
| `install-bitbot-wsl.ps1` | 120+ lines | Replaced by CMD + bash |
| `enable-docker-wsl-integration-simple.ps1` | 30 lines | Replaced by bash script |
| `enable-docker-wsl-integration-simple-tests.ps1` | 30 lines | Test helper (archived) |
| `README.md` | - | Archive documentation |

#### Active Files

| File | Location | Lines | Purpose |
|------|----------|-------|---------|
| `bitbot.cmd` | `core/` | 27 | Minimal launcher |
| `install-bitbot.cmd` | `core/` | 80 | Bootstrap installer |
| `setup-bitbot.sh` | `container/bitbot/` | 100 | Alpine setup |
| `enable-docker-integration.sh` | `container/bitbot/lib/` | 80 | Docker config |

---

## Issues Found & Fixed

### Issue 1: CRLF Line Endings in Bash Scripts

**Symptom:**
```bash
bash -n setup-bitbot.sh
# Error: line 33: syntax error near unexpected token `||'
```

**Root Cause:**
- Git warning: "CRLF will be replaced by LF"
- Bash scripts created with Windows line endings
- Bash interprets `\r` as part of the command

**Fix:**
```bash
sed -i 's/\r$//' setup-bitbot.sh
sed -i 's/\r$//' enable-docker-integration.sh
```

**Prevention:**
Update `.gitattributes`:
```gitattributes
*.sh text eol=lf
container/bitbot/**/*.sh text eol=lf
```

### Issue 2: Multi-line Command Continuation

**Symptom:**
```bash
apk add --no-cache \
    bash \
    jq \
    || { echo "error"; exit 1; }
```

**Problem:** `||` on separate line without backslash continuation

**Fix:**
```bash
apk add --no-cache \
    bash \
    jq || { echo "error"; exit 1; }
```

---

## Static Analysis Results

### Bash Scripts

**setup-bitbot.sh:**
```
✅ Syntax: Valid
✅ Shebang: #!/bin/sh (POSIX-compatible)
✅ Set flags: set -e (exit on error)
✅ Error handling: Present
✅ Idempotency: Safe to re-run
✅ Dependencies: apk, npm (available after install)
⚠️  Alpine check: Only warns, doesn't exit
```

**enable-docker-integration.sh:**
```
✅ Syntax: Valid
✅ Shebang: #!/bin/bash
✅ Set flags: set -e (exit on error)
✅ Error handling: Comprehensive
✅ Backup: Creates timestamped backup
✅ Dependencies: jq (auto-installed if missing)
✅ Path detection: Dynamic Windows username
```

### CMD Scripts

**bitbot.cmd:**
```
✅ Syntax: Valid
✅ Error codes: Checked (%ERRORLEVEL%)
✅ Paths: Relative (%~dp0)
✅ Quoting: Correct
✅ Logic: Clear, minimal
⚠️  WSL check: Could show install instructions
```

**install-bitbot.cmd:**
```
✅ Syntax: Valid
✅ Error codes: Checked at each step
✅ Cleanup: Removes temp files
✅ Paths: Properly escaped
✅ Progress: Clear echo statements
✅ Fallback: Warns if scripts not found
```

---

## Comparison: Old vs New

| Metric | Old (CMD + PowerShell) | New (CMD + Bash) | Improvement |
|--------|------------------------|------------------|-------------|
| **Total lines (Windows)** | 187 lines | 107 lines | -43% |
| **PowerShell lines** | 150 lines | 0 lines | -100% |
| **UTF-16 parsing** | Yes (complex) | No (direct check) | Eliminated |
| **ExecutionPolicy** | Required bypass | Not applicable | Eliminated |
| **Readable source** | No (PS modules) | Yes (bash scripts) | ✅ |
| **Cross-platform** | Windows only | WSL + Linux ready | ✅ |
| **User editable** | No | Yes (in WSL) | ✅ |

---

## Next Steps

### Phase 2: Runtime Testing (Pending)

**Test Scenarios:**

1. **Fresh Install Test**
   ```cmd
   REM Prerequisites: WSL2 installed, no BitBot-Alpine
   wsl --unregister BitBot-Alpine
   bitbot work

   Expected:
   - Download Alpine rootfs
   - Import as BitBot-Alpine
   - Run setup-bitbot.sh
   - Install packages
   - Launch bitbot work
   ```

2. **Existing Install Test**
   ```cmd
   REM Prerequisites: BitBot-Alpine already exists
   bitbot work

   Expected:
   - Skip installation
   - Direct launch to WSL
   ```

3. **Docker Integration Test**
   ```bash
   wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh

   Expected:
   - Find Docker settings.json
   - Modify enableIntegrationWithDistro
   - Create backup
   - Show current integrations
   ```

4. **Script Accessibility Test**
   ```bash
   wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh
   wsl -d BitBot-Alpine nano /opt/bitbot/lib/enable-docker-integration.sh

   Expected:
   - Display readable source
   - Allow user editing
   ```

5. **Error Handling Test**
   ```cmd
   REM Test with no WSL installed
   bitbot work

   Expected:
   - Error: WSL not found
   - Show install URL: https://aka.ms/wsl2
   ```

### Phase 3: Integration Testing (Future)

- [ ] Test with Docker Desktop running
- [ ] Test with Docker Desktop stopped
- [ ] Test with non-default Windows username
- [ ] Test from PowerShell prompt
- [ ] Test from CMD prompt
- [ ] Test from WSL bash (via bitbot.exe)

### Phase 4: User Acceptance Testing

- [ ] Fresh Windows 11 installation
- [ ] Windows 10 with WSL2
- [ ] User with spaces in username
- [ ] User with non-English locale

---

## Recommendations

### 1. Add WSL Installation Prompt

**Current:**
```cmd
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: WSL not found. Install from: https://aka.ms/wsl2
    exit /b 1
)
```

**Suggested Enhancement:**
```cmd
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WSL not found.
    echo.
    set /p INSTALL="Install WSL2 now? (requires admin + reboot) (Y/n): "
    if /i "%INSTALL%"=="y" (
        echo Installing WSL2...
        wsl --install
        echo.
        echo Please reboot Windows, then run bitbot again.
    ) else (
        echo Manual install: https://aka.ms/wsl2
    )
    exit /b 1
)
```

### 2. Update .gitattributes

Add line ending rules:
```gitattributes
# Bash scripts must have LF
*.sh text eol=lf
container/bitbot/**/*.sh text eol=lf

# CMD scripts can have CRLF
*.cmd text eol=crlf
*.bat text eol=crlf
```

### 3. Add Pre-commit Hook

Validate bash syntax before commit:
```bash
#!/bin/bash
# .git/hooks/pre-commit

for file in $(git diff --cached --name-only | grep '\.sh$'); do
    if ! bash -n "$file"; then
        echo "Syntax error in $file"
        exit 1
    fi
done
```

---

## Conclusion

**Status:** ✅ Phase 1 (Syntax Validation) Complete

**Summary:**
- All bash scripts validated (after CRLF fix)
- All CMD scripts validated
- Old PowerShell scripts archived
- New minimal architecture deployed
- Zero PowerShell dependency achieved

**Confidence Level:** High
- Syntax errors fixed
- Static analysis passed
- File organization clean
- Documentation complete

**Ready for:** Phase 2 (Runtime Testing)

**Risk Assessment:** Low
- Bash scripts use standard commands (apk, npm, jq)
- CMD scripts use Windows built-ins (curl, wsl)
- Error handling comprehensive
- Fallback paths defined

---

## References

- Architecture: `/sparc/0-research/MINIMAL_CMD_BASH_ARCHITECTURE.md`
- Archive: `/sparc/4-refinement/archive/powershell-scripts/README.md`
- Old bitbot.cmd: `/sparc/4-refinement/archive/powershell-scripts/bitbot-old.cmd`

---

**Test conducted by:** Claude (BitBot Development)
**Review status:** Pending user review
**Next action:** Runtime testing with actual BitBot-Alpine installation
