# Test Suite Migration Plan

## Overview

Migration of BitBot test suite to use shared helpers (`test-framework.sh` and `workspace-helper.sh`) to eliminate ~500 lines of duplicate code and standardize test infrastructure.

**Status**: 14 of 26 tests migrated (54%) - **Phase 3 Complete** ✅

## Migration Status

### ✓ Completed (14 tests)

| Test | Lines | Status | Notes |
|------|-------|--------|-------|
| `test-prerequisites.sh` | 215 | ✅ | Detection function testing |
| `test-bitbot-init-non-interactive.sh` | 279 | ✅ | Full workspace-helper usage |
| `test-bitbot-commands.sh` | 167 | ✅ Phase 1 | Command handling tests |
| `test-platform-detection.sh` | 109 | ✅ Phase 1 | Platform detection logic |
| `test-shellcheck.sh` | 186 | ✅ Phase 1 | ShellCheck static analysis |
| `test-workspace-init.sh` | 142 | ✅ Phase 2 | Workspace initialization + helper |
| `test-helpers.sh` | 252 | ✅ Phase 3 | Helper function tests (17 tests) |
| `test-merge-devcontainer.sh` | 273 | ✅ Phase 3 | DevContainer JSON merging (22/23 tests) |
| `test-bitbot-integration.sh` | 245 | ✅ Phase 3 | Integration test (19 tests, 100%) |
| `test-infrastructure-sync.sh` | 273 | ✅ Phase 3 | Infrastructure sync (24 tests) |
| `test-session-management.sh` | 231 | ✅ Phase 3 | Session management (23 tests, 100%) |
| `test-container-bitbot.sh` | 237 | ✅ Phase 3 | Container scripts (31 tests, 100%) |
| `test-integration.sh` | 668 | ✅ Phase 5 | Full integration test (23 tests, 73% without container build) |
| `test-bitbot-commands-migrated.sh` | 166 | ✅ (POC) | Can be removed after Phase 1 |

### High Priority - Simple CI Tests (5 tests)

These are in CI, relatively simple, and good candidates for quick wins:

| Priority | Test | Lines | In CI | Complexity | Migration Effort |
|----------|------|-------|-------|------------|------------------|
| **1** | `test-bitbot-commands.sh` | 195 | ✓ | Low | Easy - Similar to POC |
| **2** | `test-platform-detection.sh` | 138 | ✓ | Low | Easy - Detection tests |
| **3** | `test-workspace-init.sh` | 203 | ✓ | Medium | Medium - Needs workspace-helper |
| **4** | `test-shellcheck.sh` | 228 | ✓ | Low | Easy - Validation only |
| **5** | `test-bitbot-init-interactive.sh` | 199 | ✓ | Medium | Medium - Git prompt fix needed |

**Estimated Impact**: ~963 lines, 5 CI tests standardized

### Medium Priority - Complex CI Tests (7 tests)

In CI but more complex, require careful migration:

| Priority | Test | Lines | In CI | Complexity | Notes |
|----------|------|-------|-------|------------|-------|
| **6** | `test-helpers.sh` | 281 | ✓ | Medium | Tests helper functions themselves |
| **7** | `test-bitbot-integration.sh` | 304 | ✓ | High | Integration test |
| **8** | `test-merge-devcontainer.sh` | 310 | ✓ | Medium | JSON merging logic |
| **9** | `test-infrastructure-sync.sh` | 312 | ✓ | Medium | File sync validation |
| **10** | `test-container-bitbot.sh` | 331 | ✓ | High | Container testing |
| **11** | `test-session-management.sh` | 335 | ✓ | High | Session handling |
| **12** | `test-wrapper-layer1.sh` | 374 | ✓ | High | Wrapper infrastructure |

**Estimated Impact**: ~2,247 lines, 7 CI tests standardized

### Lower Priority - Non-CI Tests (11 tests)

Not currently in CI, can be migrated after CI tests are done:

**Simple Session Tests** (4 tests, ~289 lines):
- `test-session-hook-no-wrapper.sh` (59 lines)
- `test-pipe-session-communication.sh` (69 lines)
- `test-pipe-session-ipc.sh` (78 lines)
- `test-session-hook-with-wrapper.sh` (83 lines)

**Performance Tests** (3 tests, ~925 lines):
- `test-codespaces.sh` (263 lines)
- `test-filesystem-performance.sh` (271 lines)
- `test-devcontainer-filesystem-performance.sh` (327 lines)

**Complex Infrastructure Tests** (3 tests, ~918 lines):
- `test-container-bitbot-start.sh` (287 lines)
- `test-devcontainer-locations.sh` (306 lines)
- `test-wrapper.sh` (325 lines)

**Large Integration Test** (1 test):
- ~~`test-integration.sh` (748 lines)~~ - ✅ **MIGRATED** (Phase 5, now 668 lines)

## Migration Benefits

### Code Reduction

- **Current**: ~500+ lines of duplicate test infrastructure code
- **After High Priority**: ~963 lines of tests standardized
- **After Medium Priority**: ~2,247 additional lines standardized
- **Total Impact**: ~3,210 lines using shared helpers (instead of duplicates)

### Consistency

All tests will use:
- Standardized `test_pass()`, `test_fail()`, `test_skip()` functions
- Consistent output formatting (✓/✗ symbols, colors)
- Unified test result reporting
- Automatic test counting and summaries

### Maintainability

- Single source of truth for test infrastructure
- Bug fixes in helpers benefit all tests
- Easier to add new test features
- Clearer test structure

## Migration Pattern

### Standard Migration Steps

1. **Add helper imports** at top:
```bash
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/workspace-helper.sh"  # If workspace needed
```

2. **Replace test suite structure**:
```bash
# Old:
echo "=== Test Suite: Foo ==="
passed=0
failed=0

# New:
test_suite_begin "Foo Tests"
```

3. **Replace test sections**:
```bash
# Old:
echo "Test 1: Something"

# New:
test_section "Test 1: Something"
```

4. **Replace pass/fail logic**:
```bash
# Old:
if [[ condition ]]; then
    echo "✓ Test passed"
    passed=$((passed + 1))
else
    echo "✗ Test failed"
    failed=$((failed + 1))
fi

# New:
if [[ condition ]]; then
    test_pass "Test description"
else
    test_fail "Test description" "Optional reason"
fi
```

5. **Replace workspace setup** (if applicable):
```bash
# Old:
test_workspace="/tmp/bitbot-test-$$"
mkdir -p "$test_workspace"
cd "$test_workspace"
git init
# ... cleanup logic at end ...

# New:
workspace=$(create_test_workspace "test-name")
cd "$workspace"
git init -q
# ... test logic ...
cleanup_test_workspace "$workspace"
```

6. **Replace final summary**:
```bash
# Old:
echo "Tests: $passed passed, $failed failed"
exit $failed

# New:
test_suite_end  # Automatic summary and exit
```

## Special Considerations

### Tests Needing Workspace Helper

These tests create temporary workspaces and should use `workspace-helper.sh`:

- ✓ `test-bitbot-init-non-interactive.sh` (already migrated)
- `test-bitbot-init-interactive.sh`
- `test-workspace-init.sh`
- `test-infrastructure-sync.sh`
- `test-merge-devcontainer.sh`
- `test-bitbot-integration.sh`
- `test-container-bitbot.sh`
- `test-container-bitbot-start.sh`
- `test-integration.sh`

### Tests With Git Operations

These tests initialize git repos and should use `setup_pre_init_workspace()`:

- ✓ `test-bitbot-init-non-interactive.sh` (already uses it)
- `test-bitbot-init-interactive.sh`
- `test-workspace-init.sh`
- `test-infrastructure-sync.sh`

### Tests With Container Builds

These tests build/start containers and may benefit from pre-built containers:

- `test-wrapper-layer1.sh` (already uses pre-built container)
- `test-session-management.sh`
- `test-container-bitbot.sh`
- `test-container-bitbot-start.sh`
- `test-devcontainer-locations.sh`

### Tests Needing Fixes

**Interactive Test Git Prompts** (`test-bitbot-init-interactive.sh`):
- Currently expects "Launch config mode?" prompt immediately
- New behavior shows git remote setup prompts first
- Need to update tmux automation to handle git prompts
- Currently non-blocking in CI

## Recommended Migration Order

### Phase 1: Quick Wins (5 tests, ~1-2 hours)

Migrate high-priority simple tests to demonstrate pattern:

1. `test-bitbot-commands.sh` - Easiest, similar to POC
2. `test-platform-detection.sh` - Simple detection tests
3. `test-shellcheck.sh` - Simple validation

**Deliverable**: 3 more tests migrated, pattern established

### Phase 2: Workspace Tests (2 tests, ~1 hour)

Add workspace-helper usage to workspace-focused tests:

4. `test-workspace-init.sh` - Workspace initialization
5. `test-bitbot-init-interactive.sh` - Interactive init (includes git prompt fix)

**Deliverable**: 5 high-priority tests complete

### Phase 3: Medium Complexity (4 tests, ~2-3 hours)

Migrate medium-complexity CI tests:

6. `test-helpers.sh` - Helper function testing
7. `test-merge-devcontainer.sh` - JSON merging
8. `test-infrastructure-sync.sh` - File sync
9. `test-bitbot-integration.sh` - Integration test

**Deliverable**: 9 more CI tests migrated

### Phase 4: Complex CI Tests (3 tests, ~2-3 hours)

Tackle complex container/session tests:

10. `test-container-bitbot.sh` - Container testing
11. `test-session-management.sh` - Session handling
12. `test-wrapper-layer1.sh` - Wrapper infrastructure

**Deliverable**: All 12 CI tests migrated

### Phase 5: Non-CI Tests (11 tests, ~3-4 hours)

Complete remaining tests:

13-16. Simple session tests (4 tests)
17-19. Performance tests (3 tests)
20-22. Complex infrastructure tests (3 tests)
23. Large integration test

**Deliverable**: Full test suite migrated

## Success Metrics

- [x] 3/26 tests migrated (11.5%) - Initial helpers created
- [x] 6/26 tests migrated (23.1%) - **Phase 1 Complete** ✅
- [x] 7/26 tests migrated (26.9%) - **Phase 2 Partial** (workspace-init done)
- [x] 8/26 tests migrated (30.8%) - **Phase 3 Started** (test-helpers done)
- [x] 9/26 tests migrated (34.6%) - **Phase 3 Continuing** (merge-devcontainer done)
- [x] 10/26 tests migrated (38.5%) - **Phase 3 Continuing** (bitbot-integration done)
- [x] 13/26 tests migrated (50%) - **Phase 3 Complete** ✅ (infrastructure-sync, session-management, container-bitbot done)
- [x] 14/26 tests migrated (54%) - **Phase 5 Partial** ✅ (test-integration done - large integration test)
- [ ] 15/26 tests migrated (57.7%) - After Phase 4
- [ ] 26/26 tests migrated (100%) - Complete

## Next Steps

1. **Start Phase 4** - Complex CI tests (wrapper-layer1, session-management variant tests)
2. **Test in CI** - Ensure migrated tests pass
3. **Complete Phase 4** - Finish complex CI tests
4. **Phase 5** - Non-CI tests (performance, codespaces, etc.)
5. **Final cleanup** - Remove POC test, update CI configuration

## Notes

- Can remove `test-bitbot-commands-migrated.sh` after `test-bitbot-commands.sh` is migrated (POC no longer needed)
- Consider organizing into subdirectories after migration (unit/, integration/, e2e/)
- Update `run-tests.sh` if directory structure changes
