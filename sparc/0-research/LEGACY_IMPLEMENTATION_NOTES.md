# Legacy Implementation Notes

**Source**: Extracted from `sparc/archive/` before removal
**Date**: 2025-10-22
**Status**: Historical reference only

## Purpose

This document preserves useful technical details and patterns from the legacy BitBot implementation that may be valuable for future reference, without keeping the entire obsolete codebase.

---

## Key Technical Patterns Discovered

### 1. Workspace Mounting Pattern

**What Worked**:
- Using `WORKSPACE_FOLDER` environment variable (matches VS Code convention)
- Mounting as `/workspace` in container (devcontainer standard)
- Setting `working_dir: /workspace` in docker-compose
- Starting all tmux sessions with `-c /workspace`

**Implementation**:
```bash
# Set environment variable
export WORKSPACE_FOLDER="$CURRENT_DIR"

# docker-compose.yml
volumes:
  - type: bind
    source: "${WORKSPACE_FOLDER:-.}"
    target: /workspace
working_dir: /workspace

# tmux sessions
tmux new-session -d -s "$session_name" -c /workspace
```

**Why It Worked**: Perfect consistency with VS Code devcontainer behavior.

---

### 2. Template Variable System

**Legacy Approach**:
- Used template `devcontainer.json` with variables like `${WORKSPACE_HASH}`
- Generated unique workspace identifiers
- Processed templates to create per-workspace configs

**Example**:
```json
{
  "dockerComposeFile": "./docker-compose.yml",
  "containerEnv": {
    "WORKSPACE_HASH": "${WORKSPACE_HASH}"
  }
}
```

**Current Implementation**: Simplified to direct template copy without variable replacement.

**Lesson**: Variable replacement adds complexity; only use if truly needed.

---

### 3. Workspace Tracking (`.bitbot/` folder)

**Legacy Approach**:
- Created `.bitbot/` folder in workspace root
- Stored workspace metadata:
  - `workspace-hash` - Unique identifier
  - `created` - Creation timestamp
  - `launch-mode` - User preference (VS Code vs Direct)

**Current Implementation**: No tracking folder (not needed for MVP).

**Lesson**: Metadata tracking useful for advanced features, but not essential for core functionality.

---

### 4. MCP Services Integration

**Legacy Approach**:
- Global MCP services via `global/mcp/docker-compose.yml`
- Workspace-local MCP services via `bitbot/mcp/docker-compose.yml`
- Service registry for managing multiple MCP servers
- Post-create commands to start MCP services

**Current Implementation**: MCP not included in MVP.

**Lesson**: MCP integration adds significant complexity. Defer to post-MVP if needed.

---

## Architecture Insights

### Dual Launch Mode System

**What Was Learned**:
- Two modes needed: VS Code (GUI) and Direct Docker (CLI)
- Mode detection via folder presence (`.devcontainer/` indicates VS Code mode)
- First-run prompt for user preference
- Persistent preference storage

**Applied to Current**: Two-mode system retained, but simplified (work/config instead of VS Code/Direct).

---

### DevContainer Template System

**What Was Learned**:
- Centralized template provides consistency
- Template can be customized per workspace
- Relative paths need careful handling
- Template variables add flexibility but also complexity

**Applied to Current**: Simple template copy without variables.

---

## What Was Abandoned and Why

| Feature | Reason Abandoned |
|---------|-----------------|
| **MCP Services** | Too complex for MVP; can add later |
| **`.bitbot/` tracking** | Not needed for core functionality |
| **Template variables** | Adds complexity without clear benefit |
| **Workspace hash system** | Container names sufficient for identification |
| **Service registry** | Premature optimization |
| **Multi-service compose** | Simplified to single container |

---

## Valuable Code Patterns

### Environment Variable Consistency

```bash
# Always use same variable names as VS Code
WORKSPACE_FOLDER="$CURRENT_DIR"  # Not WORKSPACE_PATH or PROJECT_DIR

# Pass to docker-compose
export WORKSPACE_FOLDER
docker-compose up
```

### tmux Session Management

```bash
# Create session in specific directory
tmux new-session -d -s "$session_name" -n "terminal" -c /workspace

# Attach to existing or create new
tmux attach -t "$session_name" || tmux new-session -s "$session_name"
```

### Docker Compose Volume Mounting

```yaml
volumes:
  # Use environment variable with fallback
  - type: bind
    source: "${WORKSPACE_FOLDER:-.}"
    target: /workspace

  # Explicit ro/rw permissions
  - type: bind
    source: "${WORKSPACE_FOLDER}/.devcontainer"
    target: /workspace/.devcontainer
    read_only: true  # Prevent AI modification
```

---

## Evolution Timeline

```
Legacy Implementation (Pre-SPARC)
  ↓
  - Complex, ad-hoc development
  - MCP services, tracking folders, template variables
  - No formal specifications
  ↓
Course Correction: Adopt SPARC
  ↓
  - Phase 0: Research (25+ documents)
  - Phase 1: Specifications (12 formal specs)
  - Phase 2: Pseudocode
  ↓
Current Implementation (SPARC-driven)
  ↓
  - Clean, spec-driven
  - Simplified features
  - Core functionality only
  - ~2,759 lines bash
```

---

## Key Lessons Applied

### ✓ What We Kept
- Two-mode system concept (work/config)
- DevContainer integration approach
- Cross-platform support strategy
- tmux session management
- Workspace mounting pattern

### ✗ What We Simplified
- Removed MCP services (defer to post-MVP)
- Removed tracking folders (not essential)
- Removed template variables (too complex)
- Removed service registry (not needed)
- Single container instead of compose stack

### 📝 What We Learned
- **Specifications are essential** - Prevented similar rework
- **Start simple** - Add complexity only when proven necessary
- **SPARC methodology works** - Systematic approach prevents problems
- **Multiple AI inputs valuable** - Different perspectives improve design
- **Test early** - Catch issues before they compound

---

## Specific Environment Variables Used

```bash
# Standard VS Code variables
WORKSPACE_FOLDER="/path/to/workspace"   # Workspace root
WORKSPACE_MOUNT="/workspace"            # Container mount point

# BitBot-specific (legacy)
WORKSPACE_HASH="abc12345"               # Unique workspace ID (not used in current)
BITBOT_HOME="/path/to/bitbot"          # BitBot installation path (retained)
LAUNCH_MODE="vscode"                    # User preference (concept retained)

# Container environment
TZ="America/Los_Angeles"               # Timezone sync
```

---

## Technical Debt Avoided

By learning from legacy implementation:

1. **Over-engineering** - Started with MVP features only
2. **Configuration complexity** - Simple template copy vs. variable system
3. **Service management** - Single container vs. multi-service orchestration
4. **State tracking** - Container names vs. tracking files
5. **Path handling** - Consistent use of standard variables

---

## References

- **Original archive**: Was located in `sparc/archive/` (removed 2025-10-22)
- **Archive README**: Contained full lesson learned summary
- **Legacy docs**: DEVCONTAINER-TEMPLATE-SYSTEM.md, WORKSPACE-MOUNTING.md, etc.
- **Current specs**: `../1-specification/` (authoritative)
- **Research**: `../0-research/` (comprehensive technical exploration)
- **Decisions**: `../1-specification/00_DECISIONS.md` (why current approach chosen)

---

## For Future Developers

**If considering re-adding features from legacy**:

1. ✅ DO review this document for patterns that worked
2. ✅ DO check current specifications first
3. ✅ DO start with simplest possible implementation
4. ✅ DO add tests for new complexity

5. ❌ DON'T assume legacy code was correct
6. ❌ DON'T copy complex patterns without understanding
7. ❌ DON'T add features without specifications
8. ❌ DON'T skip SPARC methodology

**The archive was removed because**:
- All valuable insights extracted to this document
- Obsolete code can confuse developers
- Current implementation is authoritative
- SPARC methodology prevents need for historical reference code

---

*End of Legacy Implementation Notes*
