# Phase 2 Runtime Testing - Quick Start Guide

**Test Suite for:** Minimal CMD + Bash Architecture
**Purpose:** Validate BitBot installation and runtime behavior
**Prerequisites:** Phase 1 (Syntax Validation) Complete ✅

---

## Quick Start

### Option 1: Full Test Suite (Recommended)

Run all tests in order:

```cmd
cd sparc\4-refinement\tests\phase2

REM 1. Fresh install test (WARNING: Destroys existing Alpine!)
test-fresh-install.cmd

REM 2. Existing install test
test-existing-install.cmd

REM 3. Validation
validate-installation.cmd

REM 4. Docker integration (if Docker Desktop installed)
wsl -d BitBot-Alpine bash test-docker-integration.sh

REM 5. Script accessibility
wsl -d BitBot-Alpine bash test-script-access.sh
```

### Option 2: Validation Only

Just check if BitBot is installed correctly:

```cmd
cd sparc\4-refinement\tests\phase2
validate-installation.cmd
```

### Option 3: Fresh Install Only

Reinstall BitBot-Alpine from scratch:

```cmd
cd sparc\4-refinement\tests\phase2
test-fresh-install.cmd
```

---

## Test Files

| File | Type | Purpose | Run From |
|------|------|---------|----------|
| `test-plan.md` | Doc | Complete test plan | (Read only) |
| `test-fresh-install.cmd` | CMD | Fresh install test | Windows CMD |
| `test-existing-install.cmd` | CMD | Existing install test | Windows CMD |
| `validate-installation.cmd` | CMD | Component validation | Windows CMD |
| `test-docker-integration.sh` | Bash | Docker config test | WSL (BitBot-Alpine) |
| `test-script-access.sh` | Bash | Script accessibility test | WSL (BitBot-Alpine) |
| `README.md` | Doc | This file | (Read only) |

---

## Test Descriptions

### 1. Fresh Install Test

**File:** `test-fresh-install.cmd`

**What it does:**
1. Creates backup of existing BitBot-Alpine (if exists)
2. Unregisters BitBot-Alpine
3. Runs `bitbot work` (triggers fresh install)
4. Validates all packages installed correctly

**Duration:** 5-10 minutes (depends on network speed)

**WARNING:** Destroys existing BitBot-Alpine!

**When to run:**
- Testing fresh installation flow
- After code changes to installation logic
- Troubleshooting installation issues

**Expected output:**
```
==========================================
 Test Result: PASS
==========================================

Fresh installation completed successfully!
```

---

### 2. Existing Install Test

**File:** `test-existing-install.cmd`

**What it does:**
1. Checks BitBot-Alpine exists
2. Runs `bitbot work` (should skip install)
3. Validates no reinstallation triggered

**Duration:** <10 seconds

**Prerequisites:** BitBot-Alpine already installed

**When to run:**
- After fresh install test
- Testing detection logic
- Validating performance

**Expected output:**
```
==========================================
 Test Result: PASS
==========================================

Existing installation detected and reused correctly!
```

---

### 3. Validation Script

**File:** `validate-installation.cmd`

**What it does:**
1. Checks WSL2 installed
2. Checks BitBot files exist (exe, cmd)
3. Checks BitBot-Alpine distro exists
4. Validates all packages installed
5. Checks directories created
6. Validates scripts exist and executable

**Duration:** <5 seconds

**When to run:**
- After any installation
- Before reporting bugs
- Regular health checks

**Expected output:**
```
==========================================
 Validation Summary
==========================================

  Tests Passed:  19
  Tests Failed:  0
  Warnings:      0

  Overall: PASS

  All components installed correctly!
```

---

### 4. Docker Integration Test

**File:** `test-docker-integration.sh`

**What it does:**
1. Finds Docker Desktop settings.json
2. Creates backup
3. Runs enable-docker-integration.sh
4. Validates BitBot-Alpine added to WSL integrations

**Duration:** <5 seconds

**Prerequisites:**
- Docker Desktop installed
- BitBot-Alpine installed

**When to run:**
- Testing Docker integration feature
- After Docker Desktop install/update
- Troubleshooting Docker connectivity

**Run from WSL:**
```bash
wsl -d BitBot-Alpine bash /path/to/test-docker-integration.sh
```

**Expected output:**
```
==========================================
 Test Result: PASS
==========================================

Docker Desktop integration configured successfully!

IMPORTANT: Restart Docker Desktop for changes to take effect
```

---

### 5. Script Accessibility Test

**File:** `test-script-access.sh`

**What it does:**
1. Checks scripts exist
2. Validates scripts readable
3. Checks scripts executable
4. Validates bash syntax
5. Shows file permissions

**Duration:** <5 seconds

**Prerequisites:** BitBot-Alpine installed

**When to run:**
- Validating user can modify scripts
- After script updates
- Testing permissions

**Run from WSL:**
```bash
wsl -d BitBot-Alpine bash /path/to/test-script-access.sh
```

**Expected output:**
```
==========================================
 Test Result: PASS
==========================================

Scripts are accessible and user-editable!
```

---

## Common Issues

### Issue: "WSL not installed"

**Symptom:**
```
[X] FAIL: WSL not installed
```

**Solution:**
1. Run PowerShell as Administrator:
   ```powershell
   wsl --install
   ```
2. Reboot Windows
3. Run test again

---

### Issue: "BitBot-Alpine not found"

**Symptom:**
```
[X] FAIL: BitBot-Alpine not found
[i] Run test-fresh-install.cmd first
```

**Solution:**
```cmd
test-fresh-install.cmd
```

---

### Issue: "Download failed"

**Symptom:**
```
[X] Download failed
```

**Solution:**
1. Check internet connection
2. Retry test
3. Check firewall/proxy settings
4. Try manual download:
   ```cmd
   curl -L -o %TEMP%\alpine.tar.gz https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz
   ```

---

### Issue: "Package installation failed"

**Symptom:**
```
[X] Package installation failed
```

**Solution:**
1. Check Alpine mirrors:
   ```bash
   wsl -d BitBot-Alpine cat /etc/apk/repositories
   ```
2. Update package index:
   ```bash
   wsl -d BitBot-Alpine apk update
   ```
3. Retry package install:
   ```bash
   wsl -d BitBot-Alpine apk add bash git docker-cli nodejs npm curl jq
   ```

---

### Issue: "Docker Desktop not installed"

**Symptom:**
```
[!] WARN: Docker Desktop not installed
Test Result: SKIPPED (No Docker Desktop)
```

**Solution:**
This is expected if Docker Desktop is not installed. Docker integration test will skip automatically.

To install Docker Desktop:
https://www.docker.com/products/docker-desktop/

---

## Test Results

After running tests, document results:

### Template

```markdown
# Test Execution Report

**Date:** [YYYY-MM-DD]
**Tester:** [Name]
**Environment:**
- Windows: [Version]
- WSL: [Version]
- BitBot: [Branch/Commit]

## Test Results

| Test | Status | Notes |
|------|--------|-------|
| Fresh Install | ✅ PASS | Completed in 8 minutes |
| Existing Install | ✅ PASS | <1 second launch |
| Validation | ✅ PASS | All 19 checks passed |
| Docker Integration | ✅ PASS | Settings modified correctly |
| Script Access | ✅ PASS | Scripts readable/editable |

## Issues Found

(None / List issues)

## Conclusion

All tests passed successfully. Ready for production.
```

Save results in: `sparc/4-refinement/tests/phase2/results/test-results-YYYYMMDD.md`

---

## Next Steps

### After All Tests Pass ✅

1. **Update Documentation**
   - README.md (installation instructions)
   - SPARC completion docs

2. **Create Release**
   - Tag version
   - Write release notes
   - Announce PowerShell elimination

3. **Clean Up**
   - Archive old test artifacts
   - Update .gitignore

### If Tests Fail ❌

1. **Document Failures**
   - Create test results report
   - Screenshot error messages
   - Collect logs

2. **Create Issues**
   - GitHub issue per failure
   - Include reproduction steps
   - Tag with severity

3. **Fix Issues**
   - Prioritize by severity
   - Fix and commit
   - Re-run failed tests

4. **Verify Fixes**
   - Run full test suite again
   - Update test results

---

## Reference

- **Test Plan:** `test-plan.md` (comprehensive scenarios)
- **Phase 1 Results:** `../MINIMAL_CMD_BASH_TEST_REPORT.md`
- **Architecture:** `/sparc/0-research/MINIMAL_CMD_BASH_ARCHITECTURE.md`
- **Archived Scripts:** `/sparc/4-refinement/archive/powershell-scripts/`

---

**Test Suite Version:** 1.0
**Last Updated:** 2025-11-14
**Status:** Ready for Execution
