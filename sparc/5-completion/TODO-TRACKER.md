# BitBot TODO Tracker

Comprehensive tracking of all remaining tasks to reach production readiness.

**Status**: Pre-Alpha → Alpha (v0.1.0)
**Last Updated**: 2025-10-24
**Purpose**: Track implementation tasks, testing, and release management
**Last Consistency Review**: 2025-10-22 (see CONSISTENCY_REVIEW.md)
**Recent Progress**: Core implementation complete, 7 automated tests passing, project structure reorganized

---

## P0 - Critical Fixes from Consistency Review

**Source**: CONSISTENCY_REVIEW.md (2025-10-22)
**Status**: ✅ **COMPLETE** (Fixed: 2025-10-22, Commit: ab5003b)

### 1. Security Feature Missing ✅ FIXED
- [x] **Add read-only `.devcontainer` mount to work mode template**
  - **File**: `templates/workspace/devcontainer.json`
  - **Issue**: Core security feature not implemented - AI can modify infrastructure files
  - **Action**: Add `"source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"` as first mount
  - **Impact**: HIGH - Without this, work mode doesn't protect infrastructure as advertised
  - **Priority**: P0 (Blocking)
  - **Status**: ✅ Fixed - Read-only mount added to template and fallback minimal template

### 2. Template Path Fix ✅ FIXED
- [x] **Fix template path reference in bitbot-init.sh**
  - **File**: `core/workspace/bitbot-init.sh` line 178
  - **Issue**: References non-existent `devcontainer-template/`, falls back to inline minimal template
  - **Action**: Change to `templates/workspace/`
  - **Impact**: MEDIUM - Currently works via fallback but not using actual template
  - **Priority**: P0 (Blocking)
  - **Status**: ✅ Fixed - Now uses templates/workspace/, template properly copied on init

### 3. Documentation Updates
- [x] **Reorganized template structure** ✅ DONE (2025-10-24)
  - Moved templates into `templates/bitbot/` (base, config, dev, workspace)
  - Created `templates/custom/` for future user templates
  - Updated all documentation references
  - Added SPARC process section to CLAUDE.md
  - Moved `/src` and `/tests` to `sparc/5-completion/`
  - Renamed `/lib` to `/core` throughout documentation

- [x] **Update SPEC-02 terminology and paths** (P1) ✅ COMPLETE (2025-10-24)
  - Applied all "setup mode" → "config mode" terminology updates
  - Applied all path updates: `~/.bitbot/setup-devcontainer/` → `templates/bitbot/config/`
  - Applied all path updates: `.bitbot/setup/` → `.bitbot/internal/`
  - Updated in 20-line chunks to avoid tool limitations
  - Reference guides created (can be removed): `02_SECURITY_MODE_SYSTEM_TERMINOLOGY.md`, `02_SECURITY_MODE_SYSTEM_PATHS.md`

- [x] **Update MVP_SCOPE.md paths** (P1) ✅ DONE (2025-10-24)
  - Updated architecture diagram with correct template paths
  - Changed `config-devcontainer/` → `templates/bitbot/config/`
  - Changed `devcontainer-template/` → `templates/bitbot/workspace/`
  - Changed `lib/` → `core/` throughout

- [x] **Update pseudocode paths** (P1) ✅ DONE (2025-10-24)
  - `core/workspace/init.md` line 121: Updated template path to `templates/bitbot/workspace`
  - Updated config template path to `templates/bitbot/config/devcontainer.json`
  - Updated all `lib/` → `core/` references

---

## Recent Accomplishments (2025-10-24)

### Template Organization & Dogfooding
- [x] **Created bitbot-dev template** - BitBot can now develop itself using its own workspace system
  - Combines workspace features (Claude Code, shared configs) with MinGW cross-compiler
  - Root `.devcontainer/` is exact copy of `templates/bitbot/dev/`
  - Persistent AI config folders: `.devcontainer/home/.claude`, `.claude-flow`, `.opencode`
  - Feature-based installs (Node.js, Claude Code) instead of manual npm

- [x] **Reorganized template structure** - Clear separation of internal vs custom templates
  ```
  templates/
  ├── bitbot/          # BitBot internal templates
  │   ├── base/        # Shared foundation
  │   ├── config/      # Config mode
  │   ├── dev/         # BitBot development (dogfooding)
  │   └── workspace/   # Work mode (AI tools)
  ├── custom/          # Future user templates
  └── shared/          # Shared scripts
  ```

- [x] **Standardized AI config paths** - Researched and aligned with industry standards
  - Claude Code: `~/.claude/` (verified)
  - Claude Flow: `~/.claude-flow/` (documented)
  - Open Code: `~/.opencode/` (documented)
  - Updated mount paths to match standards

### Documentation & Organization
- [x] **Added SPARC process to CLAUDE.md** - AI assistants now understand development methodology
  - Clear guidelines for where to put research, specs, tests, code
  - Explicit folder mapping for each SPARC phase

- [x] **Cleaned up project structure** - More logical organization
  - Moved `/lib` → `/core` (updated all docs)
  - Moved `/src` → `sparc/5-completion/src/` (launcher source)
  - Moved `/tests` → `sparc/5-completion/tests/` (test suites)
  - Supporting materials now clearly separated from core implementation

### AI Agent Configuration
- [x] **Researched AI agent configuration standards** (see `sparc/0-research/AI_AGENT_CONFIGURATION_STANDARDS.md`)
  - Global config locations for Claude Code, Claude Flow, Open Code
  - AGENTS.md universal standard (emerging 2025)
  - Configuration hierarchy and best practices

---

## Critical Path to Alpha (v0.1.0)

### 1. Testing & Validation
**Priority**: P0 (Blocking)

- [x] **Core Implementation** ✅ COMPLETE
  - [x] Global init flow (`bitbot` first run) - Implemented in `core/global/bitbot-init.sh`
  - [x] Workspace init flow (`bitbot init`) - Implemented in `core/workspace/bitbot-init.sh`
  - [x] Work mode launch - Implemented in `core/workspace/bitbot-work.sh`
  - [x] Config mode launch - Implemented in `core/workspace/bitbot-config.sh`
  - [x] Git safety warnings - Implemented in `core/util/git.sh`
  - [x] Prerequisites validation - Implemented in `core/util/prerequisites.sh`
  - [x] Version command - Implemented in `core/bitbot-version.sh`
  - [x] Help command - Implemented in `core/workspace/bitbot-help.sh`
  - [x] Platform detection - Implemented in `core/util/detect.sh`

- [x] **Launchers** ✅ COMPLETE
  - [x] Bash launcher (`bitbot`) - Main entry point
  - [x] Windows executable (`bitbot.exe`) - Compiled C launcher in `dev/src/launcher_windows/`
  - [x] CMD wrapper (`bitbot.cmd`) - Windows CMD launcher
  - [x] PowerShell wrapper - Test launcher in refinement

- [x] **Automated Tests** ✅ COMPLETE (7 test suites)
  - [x] Prerequisites check - `dev/tests/test-prerequisites.sh`
  - [x] Workspace initialization - `dev/tests/test-workspace-init.sh`
  - [x] BitBot commands - `dev/tests/test-bitbot-commands.sh`
  - [x] Platform detection - `dev/tests/test-platform-detection.sh`
  - [x] Filesystem performance - `dev/tests/test-filesystem-performance.sh`
  - [x] DevContainer functionality - `dev/tests/test-devcontainer-locations.sh`
  - [x] Container BitBot - `dev/tests/test-container-bitbot.sh`
  - [x] Test runner - `dev/tests/run-tests.sh` (orchestrates all tests)

- [ ] **Manual End-to-End Testing** (REMAINING)
  - [ ] Windows testing (WSL2 + Docker Desktop) - Fresh install test needed
  - [ ] macOS testing (native) - Requires macOS environment
  - [ ] Linux testing (native) - Requires Linux environment
  - [ ] VS Code integration (all platforms) - Fresh workspace test
  - [ ] Terminal mode (all platforms) - Verify all launchers work

- [x] **WSL Mode VSCode Testing** ✅ **RESOLVED** (2025-10-24)
  - **Finding**: VS Code handles path formats correctly in both WSL and Windows modes
  - **Test completed**: VS Code launched from WSL with `code` command
  - **Result**: Uses Windows UNC paths (`\\wsl.localhost\Ubuntu\...`) - correct format!

  **Test Results** (Scenario 1 completed):
  - [x] **Scenario 1: VS Code started from WSL native terminal**
    - Launch: `code .` from WSL bash
    - Result: ✅ Opens VS Code in WSL mode (bottom-left shows `WSL: Ubuntu`)
    - Container labels: `\\wsl.localhost\Ubuntu\tmp\vscode-wsl-test`
    - Path format: **Windows UNC** (not `/mnt/c/...`, not corrupted)
    - Conclusion: VS Code uses correct path format automatically

  **Key Discovery**:
  VS Code is smart about path formats:
  - From WSL: Uses `\\wsl.localhost\<distro>\<path>` (UNC format)
  - From Windows: Uses `C:\...` or `\\wsl$\...` (Windows format)
  - Both work correctly - no path corruption
  - No need for `windows` modifier or `code.exe` forcing

  **Removed**:
  - `windows` modifier implementation (unnecessary)
  - `BITBOT_WINDOWS_MODE` environment variable (unnecessary)
  - Explicit `code.exe` vs `code` selection logic (VS Code handles it)

  **Documentation**:
  - Full test results: `sparc/4-refinement/poc-tests/archive/research/VSCODE-WSL-MODE-TEST-RESULTS.md`

  **Conclusion**: BitBot can simply use `code` command - VS Code handles path formats correctly

### 2. Config Agent Preparation
**Priority**: P1 (Important)

- [ ] **Prepare template documentation for config agent**
  - [ ] Reference TEMPLATES.md - explains base template structure
  - [ ] Reference TEMPLATES.md - documents shared scripts/configs
  - [ ] Reference TEMPLATES.md - explains container-side BitBot runtime
  - [ ] Reference TEMPLATES.md - BitBot development template
  - [ ] Agent should use these docs to help users customize templates
  - [ ] Agent should understand template merge process (shared scripts)

### 3. Bug Fixes
**Priority**: P0 (Blocking)

- [ ] **Known Issues**
  - [ ] Document all known issues
  - [ ] Fix critical bugs (blocking issues)
  - [ ] Triage non-critical bugs (defer to post-alpha)

---

## Post-Alpha Features (v0.2.0+)

### Security Enhancements
**Priority**: P1 (High)

- [ ] **Config Mode Warning** (Post-Alpha)
  - [ ] Add comprehensive warning on config mode entry
  - [ ] Explain that config mode defines AI workspace
  - [ ] List critical files AI can modify:
    - `.devcontainer` configuration
    - `.github` workflows
    - `.gitignore` patterns
    - Docker configs
    - Secrets and environment files
  - [ ] Recommend reviewing README "The Problem" section
  - [ ] Show examples of what AI can modify
  - [ ] **Locations to update**:
    - [ ] Specification: `sparc/1-specification/02_SECURITY_MODE_SYSTEM.md` (Section 3.2)
    - [ ] Pseudocode: `sparc/2-pseudocode/core/workspace/config.md` (Main function)
    - [ ] Flow: `sparc/2-pseudocode/FLOW_WORKSPACE_INIT.md` (Config launch section)
    - [ ] Implementation: `core/workspace/bitbot-config.sh`

- [ ] **Git Safety Enhancements**
  - [x] Prompts to review commits before pushing (README updated)
  - [x] Reminds to check for secrets in staged files (README updated)
  - [ ] Implement secret scanning in git hooks
  - [ ] Add git pre-commit hook for secret detection
  - [ ] Interactive secret review before commits

### Platform Support
**Priority**: P1 (High)

- [ ] **macOS**
  - [ ] Native testing
  - [ ] Installation packaging
  - [ ] Homebrew formula (optional)
  - [ ] Documentation updates

- [ ] **Linux**
  - [ ] Debian/Ubuntu testing
  - [ ] Fedora/RHEL testing
  - [ ] Installation packaging
  - [ ] Package manager integration (optional)

### Templates & Customization
**Priority**: P2 (Medium)

- [ ] **Additional Templates**
  - [ ] Rootless Docker template (Docker-in-Docker workflows)
  - [ ] VM-based template (maximum isolation)
  - [ ] Agent steering templates (code, docs, testing)
  - [ ] Language-specific templates (Python, Go, Rust, Java)

- [ ] **Template System**
  - [ ] Template selection during init
  - [ ] Custom template support
  - [ ] Template validation
  - [ ] Template documentation

### Advanced Features
**Priority**: P2 (Medium)

- [ ] **Session Management**
  - [ ] tmux integration
  - [ ] Session persistence
  - [ ] Session naming
  - [ ] Multi-session support

- [ ] **Container Management**
  - [ ] `bitbot stop` command
  - [ ] `bitbot restart` command
  - [ ] `bitbot status` command
  - [ ] Container cleanup utilities

- [ ] **Self-Improvement**
  - [ ] BitBot self-configuration capabilities
  - [ ] Agent-driven self-improvement mechanisms
  - [ ] AI agents can help optimize their own environment

### Integration & Ecosystem
**Priority**: P3 (Low)

- [ ] **MCP Service Architecture**
  - [ ] MCP server integration
  - [ ] Service discovery
  - [ ] Service management

- [ ] **Multi-Container Orchestration**
  - [ ] Docker Compose support
  - [ ] Multi-service projects
  - [ ] Inter-container communication

- [ ] **Cloud Integration**
  - [ ] GitHub Codespaces support
  - [ ] Cloud workspace sharing
  - [ ] Remote development

---

## Release Checklist

### Pre-Release Validation

- [ ] **Testing**
  - [ ] All tests passing (unit, integration, platform)
  - [ ] Cross-platform validation (Windows/macOS/Linux)
  - [ ] VS Code integration tested
  - [ ] Terminal mode tested
  - [ ] Git safety features tested


- [ ] **Security**
  - [ ] Security review completed
  - [ ] No secrets in repository
  - [ ] Permissions properly set
  - [ ] Container isolation validated

- [ ] **Quality**
  - [ ] Performance benchmarks met
  - [ ] User acceptance testing completed
  - [ ] Known issues documented
  - [ ] Rollback plan documented

**Note**: Release process details in `RELEASE.md`

---

## Known Issues & Technical Debt

### Current Known Issues

- [ ] Document all known issues
- [ ] Categorize by severity
- [ ] Create GitHub issues
- [ ] Prioritize fixes

### Technical Debt

- [ ] Line ending handling (CRLF/LF conversions)
  - Current: Git handles conversion
  - Future: Consistent tooling
- [ ] Windows launcher optimization
  - Current: 38KB C executable
  - Future: Consider smaller alternatives
- [ ] Test coverage
  - Current: Manual testing only
  - Future: Automated test suite
- [ ] Error handling
  - Current: Basic error messages
  - Future: Comprehensive error handling with recovery

---

## Success Metrics

### Alpha Success Criteria

- [ ] Successfully tested on all three platforms
- [ ] Installation works without manual intervention
- [ ] Core workflows (init, work, config) functional
- [ ] At least 5 external users can install and use

### Beta Success Criteria

- [ ] No critical bugs in issue tracker
- [ ] At least 20 external users
- [ ] Positive user feedback
- [ ] Community contributions

### v1.0 Success Criteria

- [ ] Production readiness checklist satisfied
- [ ] Full test coverage (>80%)
- [ ] Active community
- [ ] Sustainable maintenance plan

---

## Progress Tracking

### Phase Completion

| Phase              | Status      | Progress | Notes |
|--------------------|-------------|----------|-------|
| 0. Research        | ✓ Complete  | 100%     | All research complete + AI config standards |
| 1. Specification   | ⚠ Review    | 95%      | Need terminology/path updates (P1) |
| 2. Pseudocode      | ⚠ Review    | 95%      | Need path updates (P1) |
| 3. Architecture    | ✓ Complete  | 100%     | Diagrams accurate to intent |
| 4. Refinement      | ✓ Complete  | 100%     | Implementation solid |
| 5. Completion      | In Progress | 85%      | Template reorg done, dogfooding ready, P0 fixes complete |

### Consistency Review Status

**Overall Score**: 85/100 (🟡 Good with critical security gap)

| Category | Score | Status |
|----------|-------|--------|
| **Naming** | 70/100 | ⚠️  Multiple terms for same concepts |
| **Paths** | 60/100 | ⚠️  Significant mismatches between docs and implementation |
| **Features** | 90/100 | ✅ Most features implemented correctly |
| **Security** | 70/100 | ✅ Git safety implemented, ❌ RO mount missing |
| **Documentation** | 85/100 | ⚠️  Generally accurate but some outdated paths |
| **Code Quality** | 95/100 | ✅ Clean, well-structured, tested |

**Key Findings**:
- ✅ **Strong**: Git safety, devcontainer launch, platform detection, error handling, test suite
- ⚠️  **Needs Improvement**: Naming consistency, path references, template usage
- ❌ **Missing**: Read-only .devcontainer mount (P0), Config mode warning (P1/post-alpha)

### Current Milestone: Alpha (v0.1.0)

**Target**: 2025-Q4
**Blocking Items**: Manual testing, installation guide, release creation

**Status**:
- Implementation: ✓ Complete (untested)
- Testing: ⚠ Not Started
- Documentation: ⚠ Partial
- Release: ⚠ Not Started

---

## Next Actions

### Immediate (This Week) - Ready for Alpha Testing

**P0 Fixes**: ✅ Complete (Commit: ab5003b)

1. [x] **Fix read-only .devcontainer mount** (P0 - Blocking) ✅ DONE
   - Edit `templates/workspace/devcontainer.json` ✅
   - Add readonly mount as first mount entry ✅
   - Test in new workspace initialization ✅
   - Verify AI cannot modify .devcontainer files ✅

2. [x] **Fix template path reference** (P0 - Blocking) ✅ DONE
   - Edit `core/workspace/bitbot-init.sh` line 178 ✅
   - Change `devcontainer-template` to `templates/workspace` ✅
   - Test workspace init uses actual template ✅
   - Verify no fallback to inline minimal template ✅

3. [ ] **Manual testing on Windows** (P0 - Next Step)
   - Test with P0 fixes applied
   - Document known issues found during testing
   - Fix critical bugs discovered

4. [ ] **Update documentation** (P1 - Not blocking alpha)
   - Update SPEC-02 terminology and paths
   - Update MVP_SCOPE.md paths
   - Update pseudocode paths

### Short-term (Next 2 Weeks)

1. [ ] macOS testing
2. [ ] Linux testing
3. [ ] Complete troubleshooting guide
4. [ ] Prepare alpha release

### Medium-term (Next Month)

1. [ ] Create release (v0.1.0-alpha)
2. [ ] Gather user feedback
3. [ ] Iterate based on feedback
4. [ ] Plan beta release

---

## Notes

**Development Approach**: SPARC methodology
- **S**pecification: What to build (complete)
- **P**seudocode: How to build (complete)
- **A**rchitecture: Structure & design (complete)
- **R**efinement: Optimize & improve (complete)
- **C**ompletion: Deliver & document (current phase)

**Version Strategy**: Semantic versioning (SemVer)
- Pre-Alpha: 0.0.x (development)
- Alpha: 0.1.x (internal testing)
- Beta: 0.9.x (public testing)
- Stable: 1.0.0 (production)

**Release Strategy**: Dual-branch
- `trunk`: Development branch (all files)
- `release`: Distribution branch (production files only)

---

**Last Updated**: 2025-10-22 by Claude Code
**Next Review**: After manual testing completion

---

## Specification Gaps (Future Enhancements)

### Medium Priority Gaps
**Priority**: P2 (Post-v1.0)

- [ ] **Template Contribution & Sharing** (SPEC-08)
  - Template discovery/installation (`bitbot template add <url>`)
  - Template validation and security
  - Community template repository

- [ ] **Backup & Restore** (SPEC-08)
  - Backup/restore flow for `.bitbot/` and containers
  - Backup formats and triggers
  - Incremental vs full backups

- [ ] **Multi-User Workspaces** (SPEC-04)
  - Document single-user assumption
  - Concurrent session handling
  - Multi-user collaboration scenarios

- [ ] **Resource Limits & Quotas** (SPEC-01)
  - Default CPU/memory/disk limits
  - Per-mode resource constraints
  - Resource monitoring and alerts

### Low Priority Gaps
**Priority**: P3 (v2.0+)

- [ ] **Windows Native** (non-WSL) - Pure Windows containers
- [ ] **Plugin System** - Extensibility framework
- [ ] **Network Isolation** - Container network policies
- [ ] **Audit Logging** - Comprehensive activity logs
