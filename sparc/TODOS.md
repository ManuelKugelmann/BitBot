# BitBot TODO Tracker

**Status**: Pre-Alpha → Alpha (v0.1.0)

**Last Updated**: 2025-11-12 (Test Fixes & Gitignore Updates)

---

## Alpha Release - Remaining Tasks

### 1. Manual Testing (P0 - Critical)

- [ ] Fresh install test on Windows (WSL2 + Docker Desktop)
- [ ] Fresh install test on macOS
- [ ] Fresh install test on Linux
- [ ] VS Code integration verification (all platforms)
- [ ] Terminal mode verification (all launchers)
- [x] Create tmux-wrapper-based user flow integration tests ✅ DONE
  - `dev/tests/test-user-flow-init.sh` tests global init flow (27/27 passing)
  - `dev/tests/test-user-flow-moved.sh` tests moved installation (7/7 passing)
  - `dev/tests/test-user-flows.sh` master test runner
  - Supports test mode (isolated) and dev mode (clean git required)
  - **Git diff analysis** detects both modified and untracked files
  - Categorizes changes and recommends template sync actions
  - Documents host-side changes (~/.bashrc) as expected
  - Adaptive timing with retry loop (handles Windows env updates)
  - `--no-cleanup` flag for inspecting changes before cleanup
  - **Shell config handling:** Backup/restore ~/.bashrc and ~/.zshrc
  - **Duplicate prevention:** Test 10 verifies no stacking on repeated init
  - **Tmux output logging:** log_tmux_output() helper for debugging
  - **Bug fixes:** Fixed duplicate PATH entry bug, workspace detection in tests

### 2. Test Suite Issues & Expansion (P0 - CRITICAL) 🔥

**Test Execution Status** (run-tests.sh) - Last Run: 2025-11-12:
- ✅ 10 test suites integrated (core tests)
- ✅ 200+ test assertions across all suites
- ✅ 9/10 passing (90% success rate)
- ❌ 1 minor failure: Merge DevContainer test (template content drift - non-blocking)
- ✅ All critical tests passing

**Recent Fixes** (2025-11-12):
- [x] **P0**: Fix test-integration.sh --template flag ✅ FIXED
  - Removed invalid `--template bitbot-base` flag
  - Changed to `--no-config` (correct syntax)
- [x] **P0**: Verify test-container-bitbot-start.sh ✅ PASSING
  - All 26/26 tests passing
  - Working directory issue was resolved
- [x] **P0**: Add gitignore for .bitbot/ internals ✅ DONE
  - Gitignore tmp/ and internal/global/
  - Keep internal/container/ for Codespaces

**Completed**:
- [x] **P0**: Fix DevContainer location test failure (WSL home) ✅ FIXED
- [x] **P0**: Expand run-tests.sh - Added all 32 test suites ✅ DONE
- [x] Add user flow tests (test-user-flow-*.sh) ✅ DONE (7 suites)
- [x] Add init tests (interactive/non-interactive) ✅ DONE
- [x] Add session tests (test-session-*.sh) ✅ DONE (5 suites)
- [x] Add infrastructure tests (sync, merge, helpers) ✅ DONE (3 suites)
- [x] Add wrapper tests (layer1, full) ✅ DONE (2 suites)
- [x] Add pipe/IPC tests ✅ DONE (2 suites)
- [x] **Verification**: No tests hiding output in logs ✅ VERIFIED

**Remaining**:
- [x] **P0**: Migrate test-integration.sh to framework ✅ DONE (Phase 5, 2025-11-14)
  - Migrated to use test-framework.sh and workspace-helper.sh
  - Reduced from 748 to 668 lines (80 lines saved)
  - Added BITBOT_CHOICE_GIT_NO_REMOTE=1 for non-interactive git prompts
  - 23 tests total (17 passing without container build, 73% success rate)
  - 80-char wide test title boxes
- [ ] **P1**: Fix Merge DevContainer test (template content drift - minor)
- [ ] **P1**: Add integration test to run-tests.sh (bitbot-integration)

**Test Framework Migration** (35/35 migrated, 100%):
- [x] Phase 1-3 complete ✅
- [x] Phase 4 complete ✅ (all CI tests migrated)
- [x] Phase 5 complete ✅ (all non-CI tests migrated)
- [x] **MIGRATION 100% COMPLETE** ✅✅✅ (All 35 active tests use test-framework.sh)

**Test Categories in run-tests.sh**:
1. Core Unit Tests (4 suites): Prerequisites, Platform, Helpers, Commands
2. Workspace Tests (2 suites): Init, Non-Interactive Init
3. Container Tests (2 suites): BitBot, Start/Resume
4. Infrastructure Tests (2 suites): Sync, Merge DevContainer
5. Session/Wrapper Tests (5 suites): Layer1, Full, Management, Hooks
6. Pipe/IPC Tests (2 suites): Communication, IPC
7. User Flow Tests (7 suites): Init, Workspace, Context Switch, etc
8. Interactive Tests (1 suite): Interactive Init
9. Performance Tests (2 suites): Filesystem, DevContainer
10. DevContainer Tests (1 suite): Locations
11. Integration Tests (2 suites): BitBot, Full
12. Quality Tests (1 suite): Shellcheck
13. Cloud Tests (1 suite): Codespaces

**See**: `dev/tests/MIGRATION-PLAN.md`, Commit: f959854

### 3. Config Agent Preparation (P1 - Important)

- [ ] Configure agent to reference TEMPLATES.md for template customization help
- [ ] Agent should understand template merge process (shared scripts)

### 4. Untested Code Paths (P1 - Important) ⚠️

**Commands** (3/6 tested in run-tests.sh):
- [x] `bitbot help` / `--help` / `-h` ✅
- [x] `bitbot version` / `--version` / `-v` ✅
- [ ] `bitbot init` (interactive with prompts)
- [ ] `bitbot init --config` flag
- [ ] `bitbot init --no-config` flag
- [ ] `bitbot work` (container operations)
- [ ] `bitbot work vscode` (VS Code integration)
- [ ] `bitbot config` (config mode)
- [ ] `bitbot config vscode`
- [ ] `bitbot vscode` (shorthand for work vscode)

**Code Branches Not Tested**:
- [ ] Uninitialized workspace: init prompt (yes/no responses)
- [ ] Uninitialized workspace: command rejection
- [ ] Global context: config migration from old location
- [ ] Global context: validation after init
- [ ] Container reuse across work/config modes
- [ ] Mode switching (work ↔ config)
- [ ] Error paths: invalid commands
- [ ] Error paths: missing prerequisites
- [ ] Error paths: failed container builds
- [ ] Git safety: uncommitted changes warnings

**Recommendation**: Create test-bitbot-work.sh, test-bitbot-config.sh, test-init-flags.sh

### 5. Bug Fixes (P0 - Critical)

- [ ] **FIX**: DevContainer location test failing on WSL home
- [ ] Document all known issues in GitHub
- [ ] Fix critical bugs (blocking issues)
- [ ] Triage non-critical bugs (defer to post-alpha)

---

## Post-Alpha (v0.2.0+)

### Security Enhancements (P1)

- [ ] Add comprehensive config mode warning
- [ ] Implement secret scanning in git hooks
- [ ] Interactive secret review before commits

### Platform Support (P1)

- [ ] macOS native testing & packaging
- [ ] Linux (Debian/Ubuntu) testing & packaging
- [ ] Linux (Fedora/RHEL) testing & packaging

### Templates & Customization (P2)

- [ ] Additional templates (Docker-in-Docker, VM-based, language-specific)
- [ ] Template selection during init
- [ ] Custom template validation

### Advanced Features (P2)

- [x] tmux integration & session management ✅ DONE
- [x] Multi-session support ✅ DONE
- [x] Claude context self-management system ✅ DONE
  - Wrapper infrastructure with pipes
  - Statusline wrapper for context tracking
  - Restart/compact/clear skills
  - Do-not-stop automation hook
- [ ] Container resource limits & monitoring

### Integration (P2)

- [ ] MCP Service Architecture
- [ ] Multi-container orchestration
- [ ] Cloud integration (AWS, Azure, GCP)

---

## Specification Gaps (Post-v1.0)

- [ ] Template contribution & sharing system
- [ ] Backup & restore flows
- [ ] Multi-user workspace collaboration
- [ ] Resource limits & quotas

---

## Known Issues

- [ ] Document all known issues
- [ ] Categorize by severity
- [ ] Create GitHub issues
- [ ] Prioritize fixes

---

## Technical Debt

- [x] Line ending handling ✅ SOLVED (via .gitattributes)
- [x] Test coverage ✅ DONE (34 automated test suites)
- [x] Test framework consolidation ✅ IN PROGRESS (13/26 tests migrated, 50%)
- [ ] Windows launcher optimization (38KB → smaller)
- [ ] Error handling improvements (comprehensive error messages + recovery)

---

## Success Criteria

### Alpha

- [ ] Successfully tested on all three platforms
- [ ] Installation works without manual intervention
- [ ] Core workflows (init, work, config) functional
- [ ] At least 5 external users can install and use

### Beta

- [ ] No critical bugs in issue tracker
- [ ] At least 20 external users
- [ ] Positive user feedback
- [ ] Community contributions

### v1.0

- [ ] Production readiness checklist satisfied
- [ ] Full test coverage (>80%)
- [ ] Active community
- [ ] Sustainable maintenance plan

---

## Release Process

**See**: `RELEASE.md` for complete release workflow

---

## Timeline

**This Week**:

1. Manual testing on Windows
2. Document known issues
3. Fix critical bugs

**Next 2 Weeks**:

1. macOS testing
2. Linux testing
3. Prepare alpha release

**Next Month**:

1. Create release (v0.1.0-alpha)
2. Gather user feedback
3. Iterate based on feedback
4. Plan beta release

---

**Last Major Update**: 2025-11-12 (Test Fixes & Gitignore Updates)
**Test Status**: 2025-11-12 (run-tests.sh: 10 core suites, 9/10 passing, 90% success rate)

Urgent:

- [ ] test dev container rebuild after config (terminal, vscode, new start / while in use)
- [x] where do global files live for codespaces ? ✅ SOLVED: `.bitbot/internal/` mount strategy
- [x] mermaid in readme ✅ DONE
- [ ] update folder structure in readme
- [ ] less duplicate info in readme
- [x] update todos tracking to use /sparc/TODOS.md ✅ DONE

## Recent Additions

### Infrastructure & Architecture (2025-10-30)

**Directory Structure & Documentation:**
- [x] Add Complete Path Reference to 01-directory-structure.md ✅
- [x] Document all `.bitbot/` paths and container mounts ✅
- [x] Add environment variable reference table ✅
- [x] Create directory structure reference in CLAUDE.md ✅
- [x] Add instruction to keep structure docs updated ✅

**Infrastructure Version Tracking:**
- [x] Research `.version` and `global/` directory purpose ✅
- [x] Create design document for hash-based tracking ✅
- [x] Decision: Defer implementation (not currently needed) ✅
- See: `sparc/5-completion/INFRASTRUCTURE-VERSION-TRACKING.md`

**Session Data Organization:**
- [ ] Consider moving `.bitbot/session-env/` to `.bitbot/tmp/session-env/`
  - Both are ephemeral (cleaned by hooks)
  - Both are gitignored
  - Logical grouping under `tmp/`
  - Requires updating: wrapper, hooks, skills, docs

**Wrapper Infrastructure:**
- [x] Complete wrapper infrastructure implementation ✅ DONE
  - Claude wrapper with pipe control (restart/compact/clear)
  - Statusline wrapper for context tracking
  - Watchdog for stall detection
  - Session management utilities
  - Context size inspection skill
  - Comprehensive documentation in CLAUDE.md
  - Architecture docs: `sparc/3-architecture/02-wrapper-system.md`

### Infrastructure (2025-10-28)

- [x] Migrate hooks to .bitbot/ infrastructure ✅
- [x] Migrate wrapper to .bitbot/ infrastructure ✅
- [x] Update project detection to use .bitbot/ marker ✅
- [x] Add watchdog prototype for stall detection ✅
- [x] Move host launchers to core/ directory ✅
- [x] Create core/shared/ for version tracking ✅
- [x] Fix dogfooding conflict (host vs container bitbot command) ✅
- [x] Design Codespaces infrastructure strategy ✅ (See: `sparc/1-specification/13_CODESPACES_INFRASTRUCTURE.md`)
- [x] Implement `.bitbot/internal/` directory structure ✅ DONE
  - `sync_infrastructure()` function implemented
  - `bitbot init` creates structure and syncs
  - Templates include container bitbot scripts
  - Readonly mounts configured
- [x] Integrate wrapper into BitBot container startup ✅ DONE
- [x] Add relevant session info to statusline ✅ DONE
- [ ] Test watchdog in real-world stall scenarios
- [ ] Optional: Replace tmux-based restart with pipe-based system (current works well)

### Skills Testing (2025-10-29)

- [ ] Test claude-restart-resume skill (config reloads)
- [ ] Test claude-restart-compact skill (context compaction mid-task)
- [ ] Test claude-restart-clear skill (fresh start after task)
- [ ] Test claude-do-not-stop skill (automation hook)
- [ ] Test claude-allow-stop skill (disable automation)