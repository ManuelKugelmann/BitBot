# BitBot Test Suite Analysis

## CI Tests (GitHub Actions)

### Tests Run in CI Pipeline

**Shellcheck Job:**
- `test-shellcheck.sh` - Shell script linting

**Test-Ubuntu Job:**
- `test-helpers.sh` - Helper function tests
- `test-bitbot-commands.sh` - BitBot command tests
- `test-platform-detection.sh` - Platform detection tests
- `test-prerequisites.sh` - Prerequisite checks (allowed to fail)
- `test-workspace-init.sh` - Workspace initialization tests
- `test-container-bitbot.sh` - Container BitBot tests
- `test-bitbot-integration.sh` - BitBot integration tests
- `run-tests.sh --quick` - Quick test suite

**Security-Check Job:**
- `test-helpers.sh` - Security injection tests

**Test-Containers Job (PR only):**
- Container build and start tests (inline, not in test file)
- Tests bitbot-work and bitbot-config templates

**Test-Windows Job (PR only):**
- Basic Windows launcher tests (inline)
- PowerShell syntax checks (inline)

### Tests NOT Run in CI

- `test-bitbot-init-interactive.sh` - Interactive tmux tests (requires tmux)
- `test-codespaces.sh` - Codespaces-specific tests
- `test-container-bitbot-start.sh` - Container start tests
- `test-devcontainer-filesystem-performance.sh` - Performance benchmarks
- `test-devcontainer-locations.sh` - WSL-specific location tests
- `test-filesystem-performance.sh` - Filesystem benchmarks
- `test-infrastructure-sync.sh` - Infrastructure sync tests
- `test-integration.sh` - Full integration tests (skipped in --quick mode)
- `test-merge-devcontainer.sh` - DevContainer merge tests
- `test-pipe-session-communication.sh` - IPC tests
- `test-pipe-session-ipc.sh` - IPC tests
- `test-session-hook-no-wrapper.sh` - Session hook tests
- `test-session-hook-with-wrapper.sh` - Session hook tests
- `test-session-management.sh` - Session management tests
- `test-wrapper-layer1.sh` - Wrapper layer tests
- `test-wrapper.sh` - Wrapper tests

## Duplicate Tests & Reuse Opportunities

### 1. **Duplicate Test Infrastructure** (HIGH PRIORITY)

**Problem:** Every test file duplicates test framework code

**Duplicated Code:**
```bash
# Color definitions (in ~20 test files)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking variables (in ~20 test files)
total_tests=0
passed_tests=0
failed_tests=0

# Test functions with slight variations
test_passed() / test_pass()
test_failed() / test_fail()

# Summary reporting (duplicated in ~20 files)
echo "Test Suite Summary"
echo "Total: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
```

**Solution:** Create `dev/tests/helpers/test-framework.sh`
- Standardize test function names
- Provide setup/teardown hooks
- Centralize summary reporting

### 2. **Duplicate Workspace Setup** (HIGH PRIORITY)

**Problem:** Many tests create temporary workspaces with same pattern

**Files with duplicate workspace setup:**
- `test-bitbot-integration.sh`
- `test-bitbot-init-interactive.sh`
- `test-workspace-init.sh`
- `test-integration.sh`
- Others...

**Common Pattern:**
```bash
TEST_WORKSPACE="/tmp/bitbot-test-$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"
git init -q
export BITBOT_HOME="$BITBOT_ROOT"
# ... run tests ...
cd /tmp
rm -rf "$TEST_WORKSPACE"
```

**Solution:** Create `dev/tests/helpers/workspace-helper.sh`
```bash
# Usage:
create_test_workspace "test-name"  # Returns workspace path
cleanup_test_workspace "$workspace_path"
```

### 3. **Potential Test Duplicates**

**IPC/Pipe Tests:**
- `test-pipe-session-communication.sh`
- `test-pipe-session-ipc.sh`

**Action:** Review if these can be merged or if one is obsolete

**Session Hook Tests:**
- `test-session-hook-no-wrapper.sh`
- `test-session-hook-with-wrapper.sh`

**Action:** Good separation (non-interactive vs interactive), keep both but share setup code

**Integration Tests:**
- `test-bitbot-integration.sh` - CI focused
- `test-integration.sh` - Full integration (skipped in quick mode)

**Action:** Keep both but clarify scope in file headers

**Container Tests:**
- `test-container-bitbot.sh` - Static analysis
- `test-container-bitbot-start.sh` - Runtime tests

**Action:** Good separation, keep both

### 4. **DevContainer Location Tests**

**Files:**
- `test-devcontainer-locations.sh` - WSL-specific
- `test-devcontainer-filesystem-performance.sh` - Performance benchmarks
- `test-filesystem-performance.sh` - Filesystem benchmarks

**Action:** These test different aspects, keep separate but share setup code

## Shared Code Extraction Opportunities

### Priority 1: Test Framework Helper

**Create:** `dev/tests/helpers/test-framework.sh`

**Contents:**
```bash
#!/usr/bin/env bash
# Test Framework Helper
# Provides standardized test infrastructure

# Colors (exported)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Test counters
test_total=0
test_passed=0
test_failed=0
test_skipped=0

# Test functions
test_pass() { ... }
test_fail() { ... }
test_skip() { ... }

# Test suite functions
test_suite_begin() { ... }
test_suite_end() { ... }
test_group_begin() { ... }
```

**Benefits:**
- Standardize test output format
- Reduce 500+ lines of duplicate code
- Easier to add new test features (e.g., TAP output, JUnit XML)

### Priority 2: Workspace Setup Helper

**Create:** `dev/tests/helpers/workspace-helper.sh`

**Contents:**
```bash
#!/usr/bin/env bash
# Workspace Helper
# Provides test workspace creation/cleanup

create_test_workspace() {
    local test_name="${1:-test}"
    local workspace="/tmp/bitbot-${test_name}-$$"
    mkdir -p "$workspace"
    cd "$workspace"
    git init -q
    echo "$workspace"
}

cleanup_test_workspace() {
    local workspace="$1"
    if [[ -d "$workspace" ]]; then
        cd /tmp
        rm -rf "$workspace"
    fi
}

# Pre-init workspace (git initialized but no .devcontainer)
setup_pre_init_workspace() { ... }

# Post-init workspace (with .devcontainer)
setup_post_init_workspace() { ... }
```

**Benefits:**
- Consistent workspace setup
- Automatic cleanup on error (trap)
- Reusable pre/post-init states

### Priority 3: Container Test Helper

**Create:** `dev/tests/helpers/container-helper.sh`

**Contents:**
```bash
#!/usr/bin/env bash
# Container Test Helper

# Check if devcontainer CLI is available
check_devcontainer_cli() { ... }

# Build test container
build_test_container() { ... }

# Start test container
start_test_container() { ... }

# Execute command in container
container_exec() { ... }

# Cleanup test container
cleanup_test_container() { ... }
```

**Benefits:**
- Reusable container test infrastructure
- Consistent error handling
- Easier to add new container tests

### Priority 4: Existing Helper Enhancement

**Enhance:** `dev/tests/helpers/tmux-test-helper.sh`

**Currently has:** Good tmux testing infrastructure

**Add:**
- Integration with test framework helper
- Better error messages
- Timeout handling improvements

## Missing Tests

### Critical Missing Tests

1. **`test-bitbot-init-non-interactive.sh`**
   - Test: `bitbot init --config` (enable config mode via flag)
   - Test: `bitbot init --no-config` (disable config mode via flag)
   - Test: `CI=true bitbot init` (non-interactive mode)
   - Status: MISSING - should be in CI

2. **`test-infrastructure-sync.sh` (not in CI)**
   - Test: Infrastructure sync from container/ to .bitbot/
   - Importance: Critical for Codespaces
   - Status: EXISTS but not run in CI

3. **`test-merge-devcontainer.sh` (not in CI)**
   - Test: Template merging (base + details)
   - Importance: Critical for template system
   - Status: EXISTS but not run in CI

4. **`test-wrapper.sh` / `test-wrapper-layer1.sh` (not in CI)**
   - Test: Wrapper infrastructure
   - Importance: Core functionality
   - Status: EXISTS but not run in CI

5. **`test-session-management.sh` (not in CI)**
   - Test: Session start/resume/default commands
   - Importance: Core functionality
   - Status: EXISTS but not run in CI

### Important Missing Tests

6. **Container BitBot Command Tests**
   - Test: Container-side bitbot commands (start, resume, default)
   - Scope: Command routing, mode detection, session management
   - Status: Partially covered by test-container-bitbot-start.sh

7. **Template Validation Tests**
   - Test: All templates (base, config, dev, work) build successfully
   - Test: Template-specific features work
   - Status: Partially covered in test-containers job (only work/config)

8. **MCP Integration Tests**
   - Test: MCP server installation
   - Test: MCP server configuration
   - Status: MISSING

9. **Hook System Tests**
   - Test: Session-start hook
   - Test: Other hooks (if any)
   - Status: Partially covered by test-session-hook-* files

10. **Cross-Platform Tests**
    - Test: WSL detection and integration
    - Test: Windows launcher (bitbot.cmd, bitbot.exe)
    - Status: Basic tests exist, needs expansion

### Nice-to-Have Missing Tests

11. **Performance Regression Tests**
    - Track: Container startup time
    - Track: Command execution time
    - Status: Basic filesystem performance tests exist

12. **Documentation Tests**
    - Test: All commands have help text
    - Test: README examples are valid
    - Status: MISSING

13. **End-to-End Workflow Tests**
    - Test: Complete workflow from init → work → commit → push
    - Status: MISSING

## Test Organization Recommendations

### Current Structure
```
dev/tests/
├── helpers/
│   ├── tmux-test-helper.sh         # ✓ Good
│   └── enable-docker-wsl-integration.sh
├── test-*.sh                        # 24 test files
├── run-tests.sh                     # Test runner
└── clean-slate.sh                   # Cleanup script
```

### Recommended Structure
```
dev/tests/
├── helpers/
│   ├── test-framework.sh            # NEW: Test infrastructure
│   ├── workspace-helper.sh          # NEW: Workspace setup/cleanup
│   ├── container-helper.sh          # NEW: Container test helpers
│   ├── tmux-test-helper.sh          # EXISTING: Enhanced
│   └── enable-docker-wsl-integration.sh
├── unit/                            # NEW: Fast unit tests
│   ├── test-helpers.sh              # Move here
│   ├── test-platform-detection.sh   # Move here
│   ├── test-prerequisites.sh        # Move here
│   └── test-shellcheck.sh           # Move here
├── integration/                     # NEW: Integration tests
│   ├── test-bitbot-commands.sh      # Move here
│   ├── test-workspace-init.sh       # Move here
│   ├── test-container-bitbot.sh     # Move here
│   └── test-bitbot-integration.sh   # Move here
├── interactive/                     # NEW: Interactive tests
│   ├── test-bitbot-init-interactive.sh  # Move here
│   └── test-session-*.sh            # Move here
├── performance/                     # NEW: Performance tests
│   ├── test-filesystem-performance.sh
│   └── test-devcontainer-filesystem-performance.sh
├── e2e/                            # NEW: End-to-end tests
│   ├── test-integration.sh          # Move here (full)
│   └── test-codespaces.sh           # Move here
├── run-tests.sh                     # UPDATED: New structure
└── clean-slate.sh
```

## Action Items

### Phase 1: Create Shared Helpers (HIGH PRIORITY)
- [ ] Create `helpers/test-framework.sh`
- [ ] Create `helpers/workspace-helper.sh`
- [ ] Enhance `helpers/tmux-test-helper.sh`
- [ ] Update 2-3 test files to use new helpers (proof of concept)

### Phase 2: Refactor Existing Tests
- [ ] Migrate all tests to use test-framework.sh
- [ ] Migrate all tests to use workspace-helper.sh
- [ ] Review and merge duplicate IPC tests
- [ ] Review and clarify integration test scope

### Phase 3: Add Missing Tests
- [ ] Add `test-bitbot-init-non-interactive.sh` to CI
- [ ] Add infrastructure-sync test to CI
- [ ] Add merge-devcontainer test to CI
- [ ] Add wrapper tests to CI
- [ ] Add session-management tests to CI

### Phase 4: Reorganize (OPTIONAL)
- [ ] Create unit/integration/interactive/performance/e2e directories
- [ ] Move tests to appropriate directories
- [ ] Update run-tests.sh for new structure
- [ ] Update CI workflows

## Summary

**Total Test Files:** 24
**Tests in CI:** ~8-10 (depending on job)
**Tests NOT in CI:** ~14-16
**Critical Missing:** Non-interactive init tests
**High Priority:** Extract shared test infrastructure
**Duplicate Code:** ~500+ lines across test framework

**Immediate Actions:**
1. Create test-framework.sh helper
2. Create workspace-helper.sh helper
3. Add non-interactive init tests to CI
4. Add infrastructure-sync/merge/wrapper tests to CI
