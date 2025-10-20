# BitBot Pseudocode Implementation

**Status**: Phase 2 (Pseudocode) - Complete
**Created**: 2025-10-20
**SPARC Phase**: 2 of 5

---

## Overview

This directory contains comprehensive pseudocode for BitBot's core components. These files define the algorithmic flows, decision trees, and error handling logic that will guide the actual implementation.

**Purpose**: Bridge specification and implementation with clear, language-agnostic algorithms

---

## Core Components

### 01. CLI Entry Point
**File**: `01_cli-entry.md`
**Implements**: SPEC-05, SPEC-09
**Description**: Main `bitbot` command entry point, context detection, and command routing

**Key Functions**:
- `main()` - Entry point with argument parsing
- `detect_context()` - Determine if running on host or in container
- `handle_host_commands()` - Route container management commands
- `handle_container_commands()` - Route AI agent commands
- `smart_launch()` - Intelligent session resumption

**Dependencies**: None (entry point)

---

### 02. Workspace Detection
**File**: `02_workspace-detect.md`
**Implements**: SPEC-09 Part B, TODO Item 3
**Description**: Discover or initialize BitBot workspaces

**Key Functions**:
- `detect_workspace()` - CWD → parent → initialize logic
- `prompt_use_parent_workspace()` - User confirmation for parent workspace
- `initialize_workspace_in()` - Create `.bitbot/` structure
- `validate_workspace()` - Check workspace integrity

**Decision**: CWD first, then parent with prompt, else initialize

**Dependencies**: None

---

### 03. Container Launch
**File**: `03_container-launch.md`
**Implements**: SPEC-01, SPEC-02
**Description**: Launch and manage work/setup containers

**Key Functions**:
- `launch_work_mode()` - Start or attach to work container
- `launch_setup_mode()` - Start setup container with approval
- `launch_via_devcontainer_cli()` - Use @devcontainers/cli
- `launch_via_docker()` - Fallback direct Docker launch
- `build_mount_config()` - Configure security mounts

**Security**: Work mode (ro .devcontainer), Setup mode (rw + docker socket with approval)

**Dependencies**:
- 02_workspace-detect.md (workspace path)
- 07_uid-sync.md (UID/GID)

---

### 04. Mode System
**File**: `04_mode-system.md`
**Implements**: SPEC-02, SPEC-02A
**Description**: Security mode management and git safety

**Key Functions**:
- `enter_work_mode()` - Work mode entry with warnings
- `enter_setup_mode()` - Setup mode with strict checks
- `check_git_safety_strict()` - Blocking git checks
- `log_setup_approval()` - Audit trail logging
- `done_workflow()` - Review → commit → push → exit

**Security**: Setup requires `--allow-socket` + `--reason`, git checks prevent data loss

**Dependencies**:
- 02_workspace-detect.md (workspace path)
- 03_container-launch.md (container launch)

---

### 05. Session Management
**File**: `05_session-management.md`
**Implements**: SPEC-04, D-06
**Description**: tmux session management for resumability

**Key Functions**:
- `enter_session()` - Session entry point (resume or create)
- `list_tmux_sessions()` - Get sessions from container
- `create_new_session()` - Auto-timestamped session creation
- `prompt_session_selection()` - Multi-session choice UI
- `save_session_metadata()` - Context preservation

**Decision**: Auto-timestamped sessions, optional user names, metadata tracking

**Dependencies**:
- 03_container-launch.md (container name)

---

### 06. First-Run Experience
**File**: `06_first-run.md`
**Implements**: SPEC-09 Part A, SPEC-08
**Description**: Onboarding wizard for new users

**Key Functions**:
- `first_run_wizard()` - Main wizard flow
- `check_prerequisites()` - Docker, Git, VS Code, WSL2
- `setup_global_bitbot()` - Create `~/.bitbot/` structure
- `setup_windows_wsl()` - Install BitBot-Alpine (Windows)
- `workspace_initialization_wizard()` - Template selection

**Flow**: Prerequisites → Global setup → Platform setup → Workspace init

**Dependencies**:
- 02_workspace-detect.md (workspace init)

---

### 07. UID/GID Synchronization
**File**: `07_uid-sync.md`
**Implements**: SPEC-02 Section 1.3
**Description**: Sync container user UID/GID with host

**Key Functions**:
- `get_uid_gid()` - Detect host UID/GID
- `configure_container_user()` - Pass to container config
- `container_entrypoint_uid_sync()` - Runtime fixup in container
- `validate_workspace_permissions()` - Check file accessibility

**Decision**: Synced UID/GID for seamless file permissions

**Dependencies**: None (used by 03_container-launch.md)

---

## Component Dependency Graph

```
01_cli-entry.md
    ↓
    ├─→ 02_workspace-detect.md
    │       ↓
    │       └─→ 06_first-run.md (optional)
    │
    └─→ 03_container-launch.md
            ↓
            ├─→ 07_uid-sync.md
            ├─→ 04_mode-system.md
            └─→ 05_session-management.md
```

---

## Implementation Order

### Phase 1: Foundation (Week 1)
1. **07_uid-sync.md** - No dependencies, needed by others
2. **02_workspace-detect.md** - Core workspace logic
3. **01_cli-entry.md** - Entry point and routing

### Phase 2: Container Management (Week 2)
4. **03_container-launch.md** - Docker/devcontainer launch
5. **04_mode-system.md** - Security modes

### Phase 3: User Experience (Week 3)
6. **05_session-management.md** - tmux integration
7. **06_first-run.md** - Onboarding wizard

---

## Pseudocode Conventions

### Control Flow
- `IF ... THEN ... ELSE ... END IF`
- `FOR EACH ... IN ... END FOR`
- `WHILE ... END WHILE`
- `SWITCH ... CASE ... DEFAULT ... END SWITCH`

### Functions
- `FUNCTION name(params) → return_type:`
- `CALL function(args) → result`
- `RETURN value`

### Operations
- `SET variable = value`
- `APPEND item to list`
- `EXECUTE command → output`
- `PRINT message`
- `ERROR message` / `WARN message`

### Comments
- `# Single-line comment`

---

## Specifications Implemented

| Pseudocode File          | Primary Spec           | Secondary Specs             |
|--------------------------|------------------------|------------------------------|
| 01_cli-entry.md          | SPEC-05, SPEC-09       | SPEC-00 (D-03)              |
| 02_workspace-detect.md   | SPEC-09 Part B         | SPEC-08                     |
| 03_container-launch.md   | SPEC-01, SPEC-02       | SPEC-05                     |
| 04_mode-system.md        | SPEC-02, SPEC-02A      | SPEC-04                     |
| 05_session-management.md | SPEC-04                | SPEC-00 (D-06)              |
| 06_first-run.md          | SPEC-09 Part A         | SPEC-08, SPEC-10            |
| 07_uid-sync.md           | SPEC-02 Section 1.3    | SPEC-01                     |

---

## Key Decisions Implemented

| Decision | File              | Description                                |
|----------|-------------------|--------------------------------------------|
| D-02     | 04_mode-system.md | Two modes (work/setup) via separate containers |
| D-03     | 01_cli-entry.md   | Context-aware CLI (host vs container)      |
| D-06     | 05_session-management.md | tmux with auto-timestamped sessions |
| D-08     | 06_first-run.md   | 3-question setup + workspace wizard        |
| UID Sync | 07_uid-sync.md    | Synced UID/GID (not static)                |
| Workspace| 02_workspace-detect.md | CWD → parent → initialize              |

---

## Testing Strategy

Each pseudocode file should have corresponding tests:

### Unit Tests
- Individual function logic
- Edge case handling
- Error conditions

### Integration Tests
- Component interactions
- Data flow between functions
- State management

### End-to-End Tests
- Complete user workflows
- First-run experience
- Mode switching
- Session management

---

## Next Steps (SPARC Phase 3: Architecture)

1. **Define Module Boundaries**
   - Bash script organization
   - Function library structure
   - Shared utilities

2. **Data Architecture**
   - File formats (JSON, YAML)
   - State persistence
   - Configuration management

3. **Error Handling Strategy**
   - Exit codes (from 01_cli-entry.md)
   - Logging levels
   - Recovery procedures

4. **Platform Abstraction**
   - Linux/macOS/WSL2 differences
   - Command availability checks
   - Path handling

---

## Usage

**For Implementation**:
1. Read pseudocode file
2. Translate to bash/shell script
3. Add error handling and logging
4. Write tests
5. Integrate with other components

**For Review**:
1. Check logic correctness
2. Verify error handling
3. Validate security considerations
4. Ensure spec compliance

---

## File Statistics

| File                      | Lines | Functions | Complexity |
|---------------------------|-------|-----------|------------|
| 01_cli-entry.md           | ~300  | 12        | High       |
| 02_workspace-detect.md    | ~280  | 10        | Medium     |
| 03_container-launch.md    | ~350  | 15        | High       |
| 04_mode-system.md         | ~270  | 11        | High       |
| 05_session-management.md  | ~300  | 13        | Medium     |
| 06_first-run.md           | ~290  | 12        | Medium     |
| 07_uid-sync.md            | ~260  | 10        | Low        |
| **Total**                 | ~2050 | 83        | -          |

---

## Contributing

When adding new pseudocode:

1. **Follow conventions** (see above)
2. **Reference specs** (SPEC-XX)
3. **Document functions** (purpose, params, returns)
4. **Handle errors** (validate inputs, clear messages)
5. **Update this README** (add to component list)

---

## Validation Checklist

Before moving to implementation:

- [ ] All SPEC-00 decisions implemented
- [ ] High-priority TODO items addressed
- [ ] Error handling comprehensive
- [ ] Security considerations documented
- [ ] Platform compatibility noted
- [ ] Dependencies identified
- [ ] Test cases outlined

---

**Status**: ✅ Phase 2 Complete - Ready for Phase 3 (Architecture)
**Next Phase**: Detailed bash script architecture and module design
**Created**: 2025-10-20
**Last Updated**: 2025-10-20
