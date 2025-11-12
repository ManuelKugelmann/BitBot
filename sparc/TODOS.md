# BitBot TODO Tracker

**Status**: Pre-Alpha → Alpha (v0.1.0)

**Last Updated**: 2025-11-12

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

**Test Execution Status** (run-tests.sh):
- ✅ 5/6 core tests passing (83.3%)
- ❌ 1 test failing: DevContainer Locations (WSL home)
- ❌ 1 test error: Integration Test (not migrated)

**Critical Issues**:
- [ ] **P0**: Fix DevContainer location test failure (WSL home)
- [ ] **P0**: Migrate test-integration.sh to framework
- [ ] **P0**: Expand run-tests.sh - only 8/33 tests run (24% coverage!)

**Missing from run-tests.sh** (25+ working tests not executed):
- [ ] Add user flow tests (test-user-flow-*.sh) - 34+ tests passing
- [ ] Add init tests (interactive/non-interactive)
- [ ] Add session tests (test-session-*.sh) - 23+ tests passing
- [ ] Add infrastructure tests (sync, merge, helpers) - 63+ tests passing
- [ ] Add integration test (bitbot-integration) - 19 tests passing

**Test Framework Migration** (13/26 migrated, 50%):
- [x] Phase 1-3 complete ✅
- [ ] Phase 4: Complex CI tests (wrapper-layer1, etc.)
- [ ] Phase 5: Non-CI tests

**See**: `dev/tests/MIGRATION-PLAN.md`, `/tmp/test-gaps-analysis.md`

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

**Last Major Update**: 2025-10-24
**Test Analysis**: 2025-11-12 (run-tests.sh: 5/6 passing, 25+ tests not included)

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