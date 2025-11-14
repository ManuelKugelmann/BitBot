# Phase 2 Runtime Testing Plan - Minimal CMD + Bash Architecture

**Date:** 2025-11-14
**Phase:** Runtime Testing & Validation
**Prerequisites:** Phase 1 (Syntax Validation) Complete ✅

---

## Test Objectives

1. Validate fresh BitBot-Alpine installation
2. Verify existing installation detection
3. Test WSL2 auto-install flow
4. Validate Docker Desktop integration
5. Test script accessibility and user editability
6. Verify error handling and fallback paths

---

## Test Environment Requirements

### Windows Requirements
- Windows 10 (Build 19041+) or Windows 11
- Administrator privileges (for WSL install)
- Internet connection (for downloads)

### Software Requirements
- WSL2 (or ability to install it)
- Docker Desktop (optional - for integration tests)
- curl.exe (built-in Windows 10+)

### BitBot Requirements
- BitBot repository cloned
- `bitbot.exe` + `bitbot.cmd` in PATH or local directory
- `install-bitbot.cmd` available
- Bash scripts in `container/bitbot/`

---

## Test Scenarios

### Scenario 1: Fresh Install (No WSL2)

**Prerequisites:**
- WSL2 not installed on system
- No existing BitBot-Alpine distro

**Test Steps:**
1. Run: `bitbot work`
2. Expect prompt: "Install WSL2 now?"
3. User answers: Y
4. System runs: `wsl --install`
5. System prompts: "Please REBOOT Windows"

**Expected Results:**
- ✅ WSL2 installation initiated
- ✅ Reboot prompt displayed
- ✅ Clean exit (no errors)

**Validation:**
```cmd
REM After reboot, WSL should be available
wsl --status
REM Exit code 0
```

---

### Scenario 2: Fresh Install (WSL2 Exists, No Alpine)

**Prerequisites:**
- WSL2 installed and working
- No BitBot-Alpine distro

**Test Steps:**
1. Run: `bitbot work`
2. System detects missing BitBot-Alpine
3. Calls: `install-bitbot.cmd`
4. Downloads Alpine rootfs (~3MB)
5. Imports WSL distro
6. Copies setup scripts
7. Runs: `setup-bitbot.sh`
8. Installs packages (bash, git, docker-cli, nodejs, npm, jq)
9. Installs @devcontainers/cli
10. Enables Docker integration
11. Launches: `wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot work`

**Expected Results:**
- ✅ Alpine rootfs downloaded successfully
- ✅ BitBot-Alpine distro created
- ✅ Packages installed (no errors)
- ✅ @devcontainers/cli installed
- ✅ BitBot bash script launched

**Validation:**
```cmd
REM Check distro exists
wsl -d BitBot-Alpine --exec true
REM Exit code 0

REM Check packages installed
wsl -d BitBot-Alpine which bash git docker node npm jq
REM All found

REM Check devcontainer CLI
wsl -d BitBot-Alpine devcontainer --version
REM Shows version number

REM Check directories
wsl -d BitBot-Alpine ls -la /opt/bitbot/bin /opt/bitbot/lib
REM Directories exist

REM Check scripts
wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh
REM Shows readable source
```

---

### Scenario 3: Existing Install

**Prerequisites:**
- WSL2 installed
- BitBot-Alpine exists and configured

**Test Steps:**
1. Run: `bitbot work`
2. System detects BitBot-Alpine exists
3. Skips installation
4. Launches directly: `wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot work`

**Expected Results:**
- ✅ No download/install triggered
- ✅ Direct launch to WSL
- ✅ Fast startup (<1 second)

**Validation:**
```cmd
REM Check no installation messages shown
bitbot work 2>&1 | findstr "Downloading Installing"
REM No output (already installed)

REM Check launch time
REM Should be <1 second
```

---

### Scenario 4: Docker Integration

**Prerequisites:**
- BitBot-Alpine installed
- Docker Desktop installed (optional)

**Test Steps:**
1. Run: `wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh`
2. Script detects Windows username
3. Finds Docker settings.json
4. Creates backup
5. Modifies JSON with jq
6. Sets: `enableIntegrationWithDistro["BitBot-Alpine"] = true`
7. Shows current integrations

**Expected Results:**
- ✅ Settings.json found
- ✅ Backup created in /tmp
- ✅ JSON modified correctly
- ✅ Integration enabled
- ✅ Current status displayed

**Validation:**
```bash
# Inside WSL
cat /mnt/c/Users/$USER/AppData/Roaming/Docker/settings.json | jq '.enableIntegrationWithDistro["BitBot-Alpine"]'
# true

# Check backup exists
ls /tmp/docker-settings-backup-*.json
# File exists
```

---

### Scenario 5: Script Accessibility

**Prerequisites:**
- BitBot-Alpine installed

**Test Steps:**
1. View setup script: `wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh`
2. View Docker script: `wsl -d BitBot-Alpine cat /opt/bitbot/lib/enable-docker-integration.sh`
3. Edit script: `wsl -d BitBot-Alpine nano /opt/bitbot/setup-bitbot.sh`

**Expected Results:**
- ✅ Scripts readable (plain text bash)
- ✅ Scripts editable (nano works)
- ✅ No binary/encoded content
- ✅ Comments and documentation present

**Validation:**
```bash
# Check script is readable
wsl -d BitBot-Alpine head -n 10 /opt/bitbot/setup-bitbot.sh
# Shows shebang, comments, code

# Check executable
wsl -d BitBot-Alpine ls -l /opt/bitbot/setup-bitbot.sh
# -rwxr-xr-x (executable bit set)
```

---

### Scenario 6: Error Handling - Download Failure

**Prerequisites:**
- No internet connection OR invalid Alpine URL

**Test Steps:**
1. Disconnect network (or modify URL in install-bitbot.cmd)
2. Run: `bitbot work`
3. System attempts download
4. curl fails

**Expected Results:**
- ✅ Clear error message: "Download failed"
- ✅ Exit code 1
- ✅ No partial installation
- ✅ Temp files cleaned up

**Validation:**
```cmd
REM Check exit code
echo %ERRORLEVEL%
REM 1 (error)

REM Check no partial distro
wsl --list | findstr "BitBot-Alpine"
REM Not found

REM Check temp files cleaned
dir %TEMP%\alpine-bitbot.tar.gz
REM File not found (or deleted)
```

---

### Scenario 7: Error Handling - WSL Import Failure

**Prerequisites:**
- Insufficient disk space OR invalid Alpine rootfs

**Test Steps:**
1. Fill disk to <500MB free (or use corrupted tar.gz)
2. Run: `bitbot work`
3. Download succeeds
4. WSL import fails

**Expected Results:**
- ✅ Error message: "Import failed"
- ✅ Exit code 1
- ✅ Temp file cleaned up
- ✅ No partial distro

**Validation:**
```cmd
REM Check no distro created
wsl --list | findstr "BitBot-Alpine"
REM Not found

REM Check temp cleaned
dir %TEMP%\alpine-bitbot.tar.gz
REM File not found
```

---

### Scenario 8: Error Handling - Package Install Failure

**Prerequisites:**
- Network issues OR APK repository unavailable

**Test Steps:**
1. Modify setup-bitbot.sh to use invalid package
2. Run fresh install
3. APK install fails

**Expected Results:**
- ✅ Error message: "Package installation failed"
- ✅ Exit code 1
- ✅ Distro created but not configured

**Validation:**
```bash
# Check distro exists but incomplete
wsl -d BitBot-Alpine which bash
# May not be found

# Can manually retry setup
wsl -d BitBot-Alpine /opt/bitbot/setup-bitbot.sh
```

---

### Scenario 9: WSL2 Auto-Install (User Decline)

**Prerequisites:**
- No WSL2 installed

**Test Steps:**
1. Run: `bitbot work`
2. Prompt: "Install WSL2 now?"
3. User answers: N
4. System shows manual install URL

**Expected Results:**
- ✅ No installation attempted
- ✅ Manual URL shown: https://aka.ms/wsl2
- ✅ Exit code 1
- ✅ Clean exit

---

### Scenario 10: Multiple Arguments

**Prerequisites:**
- BitBot-Alpine installed

**Test Steps:**
1. Run: `bitbot work --help`
2. Run: `bitbot init myproject`
3. Run: `bitbot config --list`

**Expected Results:**
- ✅ Arguments passed to WSL bash script
- ✅ Correct command executed in Alpine
- ✅ Output displayed to user

**Validation:**
```cmd
REM Check args passed through
bitbot work --help
REM Shows bitbot work help (from bash script)

REM Check multiple args
bitbot init test-project
REM Creates test-project (if init implemented)
```

---

## Test Matrix

| Scenario | WSL2 | BitBot-Alpine | Docker | Expected Result | Priority |
|----------|------|---------------|--------|-----------------|----------|
| 1. Fresh (No WSL) | ❌ | ❌ | N/A | Prompt WSL install | P0 |
| 2. Fresh Install | ✅ | ❌ | ❌ | Full install | P0 |
| 3. Existing Install | ✅ | ✅ | ❌ | Direct launch | P0 |
| 4. Docker Integration | ✅ | ✅ | ✅ | JSON modified | P1 |
| 5. Script Access | ✅ | ✅ | N/A | Readable source | P1 |
| 6. Download Fail | ✅ | ❌ | N/A | Error handling | P2 |
| 7. Import Fail | ✅ | ❌ | N/A | Error handling | P2 |
| 8. Package Fail | ✅ | Partial | N/A | Error handling | P2 |
| 9. WSL Decline | ❌ | ❌ | N/A | Manual URL shown | P2 |
| 10. Multi Args | ✅ | ✅ | N/A | Args passed | P1 |

---

## Automated Test Scripts

### Test 1: Fresh Install Simulation

**Location:** `sparc/4-refinement/tests/phase2/test-fresh-install.cmd`

**Purpose:** Simulate fresh install by unregistering existing Alpine

**Usage:**
```cmd
REM WARNING: Destroys existing BitBot-Alpine!
test-fresh-install.cmd
```

### Test 2: Existing Install Validation

**Location:** `sparc/4-refinement/tests/phase2/test-existing-install.cmd`

**Purpose:** Verify existing installation is detected and used

**Usage:**
```cmd
test-existing-install.cmd
```

### Test 3: Docker Integration Test

**Location:** `sparc/4-refinement/tests/phase2/test-docker-integration.sh`

**Purpose:** Test Docker Desktop settings modification

**Usage:**
```bash
wsl -d BitBot-Alpine /path/to/test-docker-integration.sh
```

### Test 4: Script Accessibility Test

**Location:** `sparc/4-refinement/tests/phase2/test-script-access.sh`

**Purpose:** Validate user can read/edit scripts

**Usage:**
```bash
wsl -d BitBot-Alpine /path/to/test-script-access.sh
```

### Test 5: Validation Script

**Location:** `sparc/4-refinement/tests/phase2/validate-installation.cmd`

**Purpose:** Check all components installed correctly

**Usage:**
```cmd
validate-installation.cmd
REM Reports: PASS/FAIL for each component
```

---

## Success Criteria

### Must Pass (P0)
- ✅ Fresh install completes without errors
- ✅ Existing install detected (no re-install)
- ✅ WSL2 auto-install prompts user
- ✅ All packages installed correctly
- ✅ BitBot commands execute in Alpine

### Should Pass (P1)
- ✅ Docker integration modifies settings.json
- ✅ Scripts readable and editable
- ✅ Arguments passed through correctly
- ✅ Error messages clear and actionable

### Nice to Have (P2)
- ✅ Download failure handled gracefully
- ✅ Import failure cleaned up properly
- ✅ Package install failures recoverable
- ✅ WSL decline shows manual instructions

---

## Test Execution Order

1. **Pre-Test:** Backup existing BitBot-Alpine (if exists)
   ```cmd
   wsl -d BitBot-Alpine --export bitbot-backup.tar
   ```

2. **Test Scenario 1:** WSL2 Auto-Install
   - Only if WSL2 not installed
   - Requires admin privileges
   - Requires reboot

3. **Test Scenario 2:** Fresh Install
   ```cmd
   wsl --unregister BitBot-Alpine
   bitbot work
   ```

4. **Test Scenario 3:** Existing Install
   ```cmd
   bitbot work
   REM Should skip install
   ```

5. **Test Scenario 4:** Docker Integration
   ```bash
   wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh
   ```

6. **Test Scenario 5:** Script Accessibility
   ```bash
   wsl -d BitBot-Alpine cat /opt/bitbot/setup-bitbot.sh
   ```

7. **Test Scenarios 6-9:** Error Handling
   - Run validation script
   - Simulate failures
   - Verify recovery

8. **Test Scenario 10:** Multiple Arguments
   ```cmd
   bitbot work --help
   bitbot init test
   ```

9. **Post-Test:** Restore backup (if needed)
   ```cmd
   wsl --import BitBot-Alpine %LOCALAPPDATA%\WSL\BitBot-Alpine bitbot-backup.tar
   ```

---

## Test Reporting

### Test Report Template

```markdown
# Phase 2 Test Results - [Scenario Name]

**Tester:** [Name]
**Date:** [Date]
**Environment:** Windows [Version], WSL [Version]

## Test Execution

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | ... | ... | ... | ✅/❌ |
| 2 | ... | ... | ... | ✅/❌ |

## Issues Found

1. **Issue:** [Description]
   - **Severity:** Critical/High/Medium/Low
   - **Reproduction:** [Steps]
   - **Expected:** [Behavior]
   - **Actual:** [Behavior]

## Screenshots

[Attach screenshots of key steps]

## Conclusion

**Overall Status:** PASS/FAIL
**Notes:** [Additional observations]
```

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Update documentation
2. Create release notes
3. Tag release version
4. Update SPARC completion docs

### If Tests Fail ❌
1. Document failures in test report
2. Create issues for each failure
3. Fix issues
4. Re-run failed tests
5. Update scripts/documentation

---

## Test Artifacts

All test artifacts stored in:
```
sparc/4-refinement/tests/phase2/
├── test-plan.md                      # This document
├── test-fresh-install.cmd            # Fresh install test
├── test-existing-install.cmd         # Existing install test
├── test-docker-integration.sh        # Docker integration test
├── test-script-access.sh             # Script accessibility test
├── validate-installation.cmd         # Validation script
├── test-error-handling.cmd           # Error scenario tests
└── results/
    ├── test-results-[date].md        # Test execution results
    ├── screenshots/                  # Test screenshots
    └── logs/                         # Test logs
```

---

## References

- Phase 1 Results: `/sparc/4-refinement/tests/MINIMAL_CMD_BASH_TEST_REPORT.md`
- Architecture: `/sparc/0-research/MINIMAL_CMD_BASH_ARCHITECTURE.md`
- Archived Scripts: `/sparc/4-refinement/archive/powershell-scripts/`

---

**Status:** Ready for Execution
**Estimated Time:** 2-4 hours (all scenarios)
**Risk Level:** Medium (destructive tests on BitBot-Alpine)
