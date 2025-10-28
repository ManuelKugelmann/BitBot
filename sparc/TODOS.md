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

- [ ] tmux integration & session management
- [ ] Multi-session support
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
- [ ] where do global files live for codespaces ?
- [ ] mermaid in readme
- [ ] update folder structure in readme
- [ ] less duplicate info in readme
- [ ] update todos in readme

## Recent Additions

### Infrastructure (2025-10-28)

- [x] Migrate hooks to .bitbot/ infrastructure ✅
- [x] Migrate wrapper to .bitbot/ infrastructure ✅
- [x] Update project detection to use .bitbot/ marker ✅
- [ ] Add relevant session info to statusline (session ID, PID, wrapper status)