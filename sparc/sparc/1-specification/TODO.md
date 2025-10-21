# BitBot Specification TODO List

**Last Updated**: 2025-10-20

This document tracks specification items that need clarification, enhancement, or implementation. Items are categorized by status and priority.

---

## ✅ Completed Items

### 1. Git Protection Strategy ✅
**Status**: **FULLY ADDRESSED** in SPEC-02A (Git Safety Integration)

**Originally Requested**:
- Document how `bitbot` initializes Git repositories in workspaces
- Define mechanism for preventing destructive Git operations
- Clarify interaction with security modes

**Resolution**:
- Comprehensive Git safety system documented in SPEC-02A
- Three-layer protection: Startup warnings, MCP tools, pre-destructive checks
- Git state requirements prevent unsafe operations
- No custom permission systems needed - uses Git's native safety

**Reference**: `Specification/02A_GIT_SAFETY_INTEGRATION.md`

---

### 2. User ID (UID/GID) Synchronization Strategy ✅
**Status**: **FULLY ADDRESSED** in SPEC-02 Section 1.3
**Completed**: 2025-10-20

**Decision**: Synced UID/GID (host UID = container UID)

**Rationale**:
- Seamless file permissions between host and container
- No ownership mismatches on workspace files
- Standard devcontainer practice (VS Code compatible)
- Security via mount restrictions (not UID separation)

**Trade-offs**:
- All modes run as same UID (no UID-based isolation)
- Rejected static UIDs: File ownership complexity outweighs security benefit
- Security achieved through mount flags and git protection instead

**Reference**: `Specification/02_SECURITY_MODE_SYSTEM.md` Section 1.3

---

### 3. CLI Workspace Detection Logic ✅
**Status**: **SIMPLIFIED FOR MVP** in SPEC-09 Part B
**Completed**: 2025-10-20
**Updated**: 2025-10-21 (MVP simplification)

**MVP Decision**: CWD only (no parent directory search)

**Workspace Discovery Algorithm** (MVP):
```bash
# When `bitbot` command is run:

1. Check current directory (CWD) for `.bitbot/`
   ↓ Found → Use this workspace
   ↓ Not found → Continue

2. No workspace found in CWD
   → Prompt to initialize workspace
   → Yes: Run `bitbot init`
   → No: Exit with code 4
```

**MVP Simplifications**:
- ✅ CWD-only detection (no parent directory walk-up)
- ✅ No `--workspace <path>` flag
- ✅ Prompt for init if not found

**Future Features** (Post-MVP):
- Parent directory search with confirmation prompt
- `--workspace <path>` flag to override detection
- Multiple .bitbot/ resolution in hierarchy
- Non-interactive mode with required flags

**Edge Cases Handled** (MVP):
- ✅ Symlinks in path (follow to canonical path)
- ✅ Workspace in `/tmp` (allow with warning)
- ✅ Different filesystem/mount (allow)

**Reference**: `Specification/09_CLI_UX_AND_ONBOARDING.md` Part B (Workspace Discovery)

---

## 🔴 High Priority TODO Items

---

## 🟡 Medium Priority TODO Items

### 4. Template Contribution & Sharing Guidelines 🟡
**Status**: **MENTIONED** but not detailed
**Priority**: P2 (Medium - Community feature)

**Current State**:
SPEC-08 mentions custom templates in `~/.bitbot/templates/` but doesn't explain:
- How users share templates (GitHub repos? Registry?)
- Template discovery/installation (`bitbot template add <url>`)
- Template validation and security
- Community template repository

**Recommendation**:
Create subsection in SPEC-08 "A6. Template Sharing & Community Registry"

---

### 5. Backup & Restore Strategy 🟡
**Status**: **MENTIONED** but not detailed
**Priority**: P2 (Medium - Data safety)

**Current State**:
- SPEC-08 mentions `backups/` directory
- SPEC-09 mentions `bitbot backup` command
- No detailed backup/restore flow documented

**Required Documentation**:
- What gets backed up? (`.bitbot/`, container volumes, both?)
- Backup formats (tar.gz? Docker volumes?)
- Incremental vs full backups
- Restore process
- Automatic backup triggers (before updates, before setup mode, etc.)

**Recommendation**:
Expand SPEC-08 Part B with "B8. Backup & Restore"

---

### 6. Multi-User Workspace Collaboration 🟡
**Status**: **NOT ADDRESSED**
**Priority**: P2 (Medium - Team feature)

**Question**:
Can multiple users work in the same workspace simultaneously?

**Scenarios**:
- Same workspace directory, different containers?
- Shared `.bitbot/` directory on network filesystem?
- Concurrent session handling
- Session locks and conflicts

**Current Assumption**:
BitBot is single-user per workspace. Multiple users = multiple workspace clones.

**Decision Needed**:
Document this assumption explicitly in SPEC-04 (Session Management) or add multi-user support plan.

---

### 7. Container Resource Limits & Quotas 🟡
**Status**: **PARTIALLY ADDRESSED**
**Priority**: P2 (Medium - Resource management)

**Current State**:
- SPEC-01 mentions resource quotas
- SPEC-09 shows `--memory` flag in `bitbot config`
- No comprehensive resource limit documentation

**Gaps**:
- Default resource limits (CPU, memory, disk I/O)
- Per-mode limits (sketch vs work vs setup)
- User-configurable limits
- Resource monitoring and alerts

**Recommendation**:
Add section to SPEC-01 "1.5 Resource Limits & Quotas"

---

## 🟢 Low Priority TODO Items

### 8. Windows Native Implementation (Non-WSL) 🟢
**Status**: **OUT OF SCOPE** for v1.0
**Priority**: P3 (Low - Future enhancement)

**Current Approach**:
Windows support via WSL2 (SPEC-05, SPEC-10)

**Future Consideration**:
Pure Windows implementation using:
- Windows containers (Docker for Windows)
- PowerShell-only implementation
- No WSL dependency

**Decision**: Defer to v2.0+

---

### 9. BitBot Plugin System 🟢
**Status**: **NOT PLANNED** for v1.0
**Priority**: P3 (Low - Extensibility)

**Concept**:
Allow third-party plugins to extend BitBot functionality:
- Custom security mode plugins
- Custom MCP service plugins
- Custom CLI commands
- Custom AI agent integrations

**Decision**: Evaluate after v1.0 based on user feedback

---

### 10. BitBot Cloud / Remote Workspaces 🟢
**Status**: **OUT OF SCOPE**
**Priority**: P3 (Low - Future product)

**Concept**:
Remote development environments (like GitHub Codespaces):
- BitBot workspaces in cloud
- SSH access
- Web-based VS Code

**Decision**: Separate product consideration

---

## 📋 Documentation Cleanup Tasks

### Spec Consolidation Status ✅
All specifications consolidated from Claude/Copilot/Gemini sources:
- ✅ SPEC-00: Decisions
- ✅ SPEC-01: Container Orchestration
- ✅ SPEC-02: Security Mode System
- ✅ SPEC-02A: Git Safety Integration
- ✅ SPEC-03: MCP Service Architecture
- ✅ SPEC-04: Session Management
- ✅ SPEC-05: Cross-Platform CLI
- ✅ SPEC-06: VS Code DevContainer Integration
- ✅ SPEC-07: AI Agent Integration
- ✅ SPEC-08: Workspace Management
- ✅ SPEC-09: CLI UX & Onboarding
- ✅ SPEC-10: Installation & Distribution

### Remaining Documentation Tasks
- [ ] Delete old specification directories (Claude_Specification, Copilot_Specification, Gemini_Specification) after review
- [ ] Update `README.md` in root to point to consolidated specs
- [ ] Generate API documentation (if applicable)
- [ ] Create quick-start guide from SPEC-09
- [ ] Create developer contribution guide

---

## 🔄 Implementation Tracking

**Phase 1 (MVP)**: Core functionality
- Container orchestration (SPEC-01)
- Security modes (SPEC-02)
- Basic MCP services (SPEC-03)
- CLI implementation (SPEC-05)

**Phase 2**: Developer Experience
- VS Code integration (SPEC-06)
- AI agent integration (SPEC-07)
- Workspace templates (SPEC-08)
- First-run experience (SPEC-09)

**Phase 3**: Distribution
- Installation methods (SPEC-10)
- Package managers
- Auto-updates

**Phase 4**: Polish
- Documentation
- Testing
- Performance optimization
- Security audit

---

## ✏️ How to Use This TODO

**Adding Items**:
1. Add new section with clear title
2. Mark status (NOT ADDRESSED, PARTIALLY DOCUMENTED, etc.)
3. Assign priority (P0-P3 or 🔴🟡🟢)
4. Describe the issue/gap
5. Provide recommendation or next steps
6. Reference relevant spec files

**Updating Items**:
- Move completed items to "✅ Completed Items" section
- Update status as documentation progresses
- Add "Decision Needed" tag for items requiring stakeholder input

**Priority Guide**:
- 🔴 P0/P1: Must address before v1.0 (blocking or critical)
- 🟡 P2: Should address for v1.0 (important but not blocking)
- 🟢 P3: Nice to have / future versions

---

**Status**: Living document (updated as specs evolve)
**Last Review**: 2025-10-20
**Next Review**: After implementation Phase 1 completion

**Consolidated From**:
- Claude_Specification/TODO.md (Git protection, UID sync, workspace detection)
- Additional items discovered during spec consolidation (2025-10-20)
