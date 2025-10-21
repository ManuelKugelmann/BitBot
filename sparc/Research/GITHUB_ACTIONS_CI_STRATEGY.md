# GitHub Actions CI/CD Strategy for BitBot

**Purpose:** Integrate tests into GitHub Actions CI/CD pipeline
**Challenge:** WSL compatibility, Docker requirements, cross-platform testing
**Date:** 2025-10-21

---

## TL;DR Recommendations

**✓ Primary:** Ubuntu runners (full test suite)
**⚠ Secondary:** Windows runners (basic script tests only)
**✗ Skip:** WSL-specific tests in CI (too complex, test manually)

---

## What Can Be Tested Where

### Ubuntu Runners (ubuntu-latest) ⭐ RECOMMENDED

**What works:**
- ✓ Docker (pre-installed)
- ✓ DevContainer CLI (easy to install)
- ✓ Bash scripts
- ✓ Git operations
- ✓ Container builds and tests
- ✓ Prerequisites checks
- ✓ Workspace initialization
- ✓ Full test suite

**What doesn't work:**
- ✗ WSL-specific features
- ✗ Windows-specific paths (C:\, backslashes)
- ✗ PowerShell/CMD testing

**Speed:** Fast (2-4 minutes typical)
**Cost:** Included in free tier
**Reliability:** Very high

---

### Windows Runners (windows-latest)

**What works:**
- ✓ PowerShell scripts
- ✓ CMD/Batch scripts
- ✓ Windows paths
- ✓ Basic script logic tests
- ⚠ WSL (with setup-wsl action, but slow)

**What doesn't work easily:**
- ✗ Docker (licensing issues, complex setup)
- ✗ WSL2 (requires nested virtualization setup)
- ✗ DevContainer testing

**Speed:** Slow (8-15 minutes with WSL setup)
**Cost:** 2x Linux minutes consumed
**Reliability:** Medium (WSL setup can be flaky)

**Note:** WSL2 technically works since Jan 2024 (nested virtualization enabled on Dadsv5 runners), but requires:
- setup-wsl action installation
- Linux distribution installation
- Package updates
- Adds 3-5 minutes to workflow time

---

### macOS Runners (macos-latest)

**What works:**
- ✓ Bash scripts
- ✓ Docker (via Docker Desktop)
- ✓ DevContainer CLI

**What doesn't work:**
- ✗ WSL (macOS doesn't have WSL)
- ✗ Windows-specific features

**Speed:** Medium (4-6 minutes)
**Cost:** 10x Linux minutes consumed
**Reliability:** High
**Verdict:** Not worth the cost for our use case

---

## Recommended CI/CD Strategy

### Tier 1: Ubuntu (Primary Test Suite)

Run full test suite on every push/PR:

```yaml
- Prerequisites tests (Docker, DevContainer CLI, Git)
- Workspace initialization tests
- Container build tests
- Integration tests
```

**Frequency:** Every push to trunk, every PR
**Time:** ~3-5 minutes
**Coverage:** ~80% of functionality

---

### Tier 2: Windows (Basic Tests)

Run basic script tests without Docker/WSL:

```yaml
- Script syntax validation
- PowerShell/CMD wrapper tests
- Path handling tests
- Basic CLI tests (help, version)
```

**Frequency:** Every PR, weekly scheduled
**Time:** ~2-3 minutes
**Coverage:** ~20% of functionality (Windows-specific)

---

### Tier 3: Manual (WSL Integration)

Test WSL integration manually on local dev machines:

```yaml
- WSL path conversion
- Docker Desktop WSL integration
- Windows + WSL workflows
```

**Frequency:** Before releases, major changes
**Location:** Local Windows 10/11 + WSL2 machines
**Coverage:** WSL-specific edge cases

---

## Test Matrix Strategy

### Option A: Simple (Recommended for MVP)

```yaml
name: Tests

on:
  push:
    branches: [trunk]
  pull_request:

jobs:
  test-ubuntu:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: ./tests/run-tests.sh
```

**Pros:**
- Simple and fast
- Covers 80% of use cases
- Free tier friendly

**Cons:**
- No Windows/WSL testing
- Misses Windows-specific bugs

---

### Option B: Multi-Platform (Future)

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    include:
      - os: ubuntu-latest
        test-suite: full
      - os: windows-latest
        test-suite: basic
```

**Pros:**
- Cross-platform coverage
- Catches Windows bugs

**Cons:**
- More complex
- Costs 2x minutes for Windows
- Longer CI times

---

## Example GitHub Actions Workflows

### Workflow 1: Ubuntu Full Tests (Recommended)

```yaml
name: Tests

on:
  push:
    branches: [trunk]
  pull_request:
    branches: [trunk]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install DevContainer CLI
        run: npm install -g @devcontainers/cli

      - name: Run prerequisite tests
        run: ./tests/test-prerequisites.sh

      - name: Run workspace init tests
        run: ./tests/test-workspace-init.sh

      - name: Run all tests
        run: ./tests/run-tests.sh

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: tests/*.log
```

---

### Workflow 2: DevContainer Testing (Advanced)

```yaml
name: DevContainer Tests

on:
  push:
    branches: [trunk]
  pull_request:

jobs:
  test-devcontainer:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Test basic template devcontainer
        uses: devcontainers/ci@v0.3
        with:
          imageName: bitbot/test-basic
          runCmd: |
            echo "Testing inside devcontainer..."
            node --version
            claude --version
```

**Uses:** Official devcontainers/ci action
**Benefit:** Tests actual container builds
**Time:** +2-3 minutes for container build

---

### Workflow 3: Windows Basic Tests (Optional)

```yaml
name: Windows Tests

on:
  pull_request:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  test-windows:
    runs-on: windows-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Test PowerShell scripts
        shell: pwsh
        run: |
          # Test script syntax
          $scripts = Get-ChildItem -Path . -Filter *.ps1 -Recurse
          foreach ($script in $scripts) {
            $null = [System.Management.Automation.PSParser]::Tokenize(
              (Get-Content $script.FullName -Raw), [ref]$null
            )
          }

      - name: Test bitbot.cmd wrapper
        shell: cmd
        run: |
          bitbot.cmd --help
          if %ERRORLEVEL% NEQ 0 exit /b 1

      - name: Test basic CLI
        shell: pwsh
        run: |
          # Basic CLI tests without Docker
          Write-Host "Testing CLI help..."
          # Add basic tests here
```

---

### Workflow 4: WSL Tests (NOT RECOMMENDED for CI)

```yaml
# ⚠️ NOT RECOMMENDED - For reference only
name: WSL Tests (Slow)

on:
  workflow_dispatch:  # Manual trigger only

jobs:
  test-wsl:
    runs-on: windows-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup WSL
        uses: Vampire/setup-wsl@v2
        with:
          distribution: Ubuntu-22.04

      - name: Test in WSL
        shell: wsl-bash {0}
        run: |
          # This will be slow (3-5 min setup time)
          ./tests/run-tests.sh
```

**Warning:**
- Adds 3-5 minutes for WSL setup
- Flaky on runners
- Better to test manually

---

## Recommended Implementation Plan

### Phase 1: MVP (Now)

1. **Create `.github/workflows/tests.yml`**
   - Ubuntu runner only
   - Run existing test suite
   - Fast feedback on PRs

2. **Update existing tests**
   - Ensure they work without user interaction
   - Add exit codes
   - Generate test reports

3. **Add test status badge to README**
   ```markdown
   ![Tests](https://github.com/user/BitBot/actions/workflows/tests.yml/badge.svg)
   ```

---

### Phase 2: Enhancement (Later)

1. **Add DevContainer testing**
   - Use devcontainers/ci action
   - Test template builds
   - Verify containers work

2. **Add Windows basic tests**
   - Script validation
   - CLI tests
   - Weekly schedule

3. **Matrix testing**
   - Test against multiple Ubuntu versions
   - Test different Docker versions

---

### Phase 3: Advanced (Future)

1. **Integration tests**
   - Full workspace workflows
   - Multi-container scenarios
   - VS Code integration tests

2. **Performance benchmarks**
   - Container build times
   - Startup performance
   - Track over time

---

## Test Coverage Strategy

### What to Test in CI

**High Priority (Ubuntu):**
- ✓ Prerequisites validation
- ✓ Workspace initialization
- ✓ Template copying
- ✓ Git operations
- ✓ Container builds (basic)
- ✓ Script execution
- ✓ Exit codes

**Medium Priority (Windows Basic):**
- ⚠ Script syntax
- ⚠ CLI help/version
- ⚠ Path handling
- ⚠ Basic wrappers

**Low Priority (Manual):**
- ⚠ WSL integration
- ⚠ Docker Desktop integration
- ⚠ VS Code extension
- ⚠ Full end-to-end workflows

---

## Limitations and Workarounds

### Limitation 1: No WSL in CI

**Problem:** WSL-specific features can't be easily tested in CI
**Workaround:**
- Test WSL manually before releases
- Document WSL requirements clearly
- Provide troubleshooting guide
- Community testing

---

### Limitation 2: Docker Desktop Licensing

**Problem:** Docker Desktop has licensing restrictions for CI
**Workaround:**
- Use Docker Engine on Linux (open source)
- Don't test Docker Desktop-specific features in CI
- Test Docker Desktop manually

---

### Limitation 3: Windows CI Cost

**Problem:** Windows runners cost 2x Linux minutes
**Workaround:**
- Run Windows tests less frequently (weekly)
- Use `workflow_dispatch` for manual triggering
- Focus on critical Windows tests only

---

### Limitation 4: Long CI Times

**Problem:** Full test suite + container builds = slow CI
**Workaround:**
- Run full tests on trunk pushes only
- Run quick tests on PR commits
- Cache container layers
- Parallelize tests

---

## CI/CD Best Practices for BitBot

### 1. Fast Feedback

```yaml
# Quick tests on every commit
on:
  pull_request:
    paths:
      - 'lib/**'
      - 'tests/**'
      - '.github/workflows/**'
```

Only run tests when relevant files change.

---

### 2. Fail Fast

```yaml
jobs:
  test:
    steps:
      - name: Quick syntax check
        run: bash -n lib/**/*.sh

      - name: Run full tests
        if: steps.syntax-check.outcome == 'success'
        run: ./tests/run-tests.sh
```

Check syntax before running full suite.

---

### 3. Cache Dependencies

```yaml
- name: Cache npm packages
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

Speed up DevContainer CLI installation.

---

### 4. Test Reports

```yaml
- name: Generate test report
  if: always()
  run: |
    ./tests/generate-report.sh > test-report.md

- name: Upload report
  uses: actions/upload-artifact@v4
  with:
    name: test-report
    path: test-report.md
```

Always upload results, even on failure.

---

## Example: Complete Test Workflow

```yaml
name: Tests

on:
  push:
    branches: [trunk]
  pull_request:
    branches: [trunk]

jobs:
  # Fast syntax check
  syntax:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check bash syntax
        run: |
          find lib -name "*.sh" -exec bash -n {} \;
          find scripts -name "*.sh" -exec bash -n {} \;

  # Main test suite
  test:
    needs: syntax
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install DevContainer CLI
        run: npm install -g @devcontainers/cli

      - name: Run tests
        run: ./tests/run-tests.sh

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: tests/*.log

  # DevContainer build test
  devcontainer:
    needs: syntax
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test basic template
        uses: devcontainers/ci@v0.3
        with:
          imageName: bitbot/test-basic
          cwd: templates/basic
          runCmd: echo "Container works!"
```

---

## Summary

**Recommended Approach:**

1. **Primary:** Ubuntu runners with full test suite
   - Fast, free, reliable
   - Covers 80% of functionality
   - Tests Docker + DevContainer features

2. **Secondary:** Windows basic tests (optional)
   - Script validation only
   - No Docker/WSL testing
   - Weekly or manual trigger

3. **Manual:** WSL integration testing
   - Test on local Windows + WSL2
   - Before releases
   - Community feedback

**Skip:** WSL tests in GitHub Actions CI
- Too slow (3-5 min setup)
- Too complex
- Too unreliable
- Better tested manually

**Start Simple:** MVP with Ubuntu-only tests, expand later as needed.

---

## Next Steps

1. Create `.github/workflows/tests.yml` with Ubuntu runner
2. Ensure existing tests work in CI environment
3. Add test status badge to README
4. Monitor CI times and adjust as needed
5. Expand to Windows basic tests if needed
