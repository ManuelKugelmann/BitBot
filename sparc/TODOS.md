# BitBot TODO Tracker

**Status**: Pre-Alpha → Alpha (v0.1.0)

**Last Updated**: 2025-10-24

---

## Alpha Release - Remaining Tasks

### 1. Manual Testing (P0 - Critical)

- [ ] Fresh install test on Windows (WSL2 + Docker Desktop)
- [ ] Fresh install test on macOS
- [ ] Fresh install test on Linux
- [ ] VS Code integration verification (all platforms)
- [ ] Terminal mode verification (all launchers)
- [x] Create tmux-wrapper-based user flow integration tests ✅ DONE
  - `dev/tests/test-user-flow.sh` tests global init flow
  - Supports test mode (isolated) and dev mode (clean git required)
  - Git diff analysis for template sync detection
  - **22/22 tests passing (100%)** ✅
  - Adaptive timing with retry loop (handles Windows env updates)

### 2. Config Agent Preparation (P1 - Important)

- [ ] Configure agent to reference TEMPLATES.md for template customization help
- [ ] Agent should understand template merge process (shared scripts)

### 3. Bug Fixes (P0 - Critical)

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
- [x] Test coverage ✅ DONE (7 automated test suites)
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

**Last Updated**: 2025-10-24

Urgent:

- [ ] test dev container rebuild after config (terminal, vscode, new start / while in use)
- [x] where do global files live for codespaces ? ✅ SOLVED: `.bitbot/internal/` mount strategy
- [ ] mermaid in readme
- [ ] update folder structure in readme
- [ ] less duplicate info in readme
- [ ] update todos in readme

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
- [ ] Decide: Keep `.version` as-is, implement hash-based, or remove entirely
- [ ] Implement infrastructure verification if needed

**Session Data Organization:**
- [ ] Consider moving `.bitbot/session-env/` to `.bitbot/tmp/session-env/`
  - Both are ephemeral (cleaned by hooks)
  - Both are gitignored
  - Logical grouping under `tmp/`
  - Requires updating: wrapper, hooks, skills, docs

**Wrapper Infrastructure:**
- [x] Move ccstatusline-wrapper to /container/bitbot/wrapper/ ✅
- [x] Document wrapper mount point in containers ✅
- [x] Aggressive session cleanup strategy implemented ✅
- [x] Rename ccstatusline-wrapper to statusline-wrapper (tool-agnostic) ✅
- [x] Document distinction between claude-wrapper and statusline-wrapper ✅
- [x] Create wrapper system architecture doc (02-wrapper-system.md) ✅
- [x] Add wrapper overview to CLAUDE.md ✅
- [x] Create claude-inspect-context-size skill (.bitbot/scripts/) ✅
- [x] Enhance context management: work continuation over thresholds ✅
- [x] Add context color signals to statusline-wrapper ✅
- [x] Create comprehensive ccstatusline config with git branch ✅
- [x] Functional grouping: Model │ Git │ Context │ Session ✅
- [x] Dynamic context colors: 🟢🟡🟠🔴 aligned with break point strategy ✅

### Infrastructure (2025-10-28)

- [x] Migrate hooks to .bitbot/ infrastructure ✅
- [x] Migrate wrapper to .bitbot/ infrastructure ✅
- [x] Update project detection to use .bitbot/ marker ✅
- [x] Add watchdog prototype for stall detection ✅
- [x] Move host launchers to core/ directory ✅
- [x] Create core/shared/ for version tracking ✅
- [x] Fix dogfooding conflict (host vs container bitbot command) ✅
- [x] Design Codespaces infrastructure strategy ✅ (See: `sparc/1-specification/13_CODESPACES_INFRASTRUCTURE.md`)
- [ ] Implement `.bitbot/internal/` directory structure
  - [ ] Add `sync_infrastructure()` shared function
  - [ ] Update `bitbot init` to create `.bitbot/internal/container/` and call sync
  - [ ] Update `bitbot work` to call `sync_infrastructure()` before starting container
  - [ ] Update `bitbot config` to call `sync_infrastructure()` before starting container
- [ ] Update templates (simple readonly mounts)
  - [ ] Update base.devcontainer.json (add `.bitbot/internal/` readonly mount)
  - [ ] Update bitbot-config template (add Docker socket mount)
- [ ] Optional container-side detection
  - [ ] Add `check-infrastructure.sh` to detect uncommitted changes (work mode)
- [ ] Testing
  - [ ] Test local environment (host command sync workflow)
  - [ ] Test Codespaces (uses committed copies, no host commands)
  - [ ] Test switching modes (work ↔ config)
- [ ] Test watchdog in real-world stall scenarios
- [ ] Add relevant session info to statusline (session ID, PID, wrapper status)
- [ ] Integrate wrapper into BitBot container startup
- [ ] Replace tmux-based restart with pipe-based system

### Skills Testing (2025-10-29)

- [ ] Test claude-restart-resume skill (config reloads)
- [ ] Test claude-restart-compact skill (context compaction mid-task)
- [ ] Test claude-restart-clear skill (fresh start after task)
- [ ] Test claude-do-not-stop skill (automation hook)
- [ ] Test claude-allow-stop skill (disable automation)