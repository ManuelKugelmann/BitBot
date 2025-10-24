# BitBot Global Claude Configuration Specification

## Overview

BitBot provides a **global shared configuration** for Claude Code that enables:
- **Single sign-on** - Credentials shared across all workspaces
- **Personal preferences** - Global CLAUDE.md and settings shared across workspaces
- **Standard project config** - Project-level `.claude/` works normally
- **Session isolation** - History and todos isolated per workspace

---

## Structure

### Two-Location System

**1. Project-Level Config (Standard Claude Code)**
- Location: `/workspace/.claude/`
- Standard Claude Code project configuration
- Team-shared, versioned in git
- Works exactly like normal Claude Code projects
- **No special handling by BitBot**

**2. User-Level Config (`~/.claude/`)**
- Composed from TWO sources:
  - Global config files from `[BITBOT_PATH]/global/.claude/` (CLAUDE.md, settings.json, .credentials.json)
  - Session data from `[WORKSPACE_PATH]/.bitbot/internal/global/.claude/` (history, todos, etc.)
- Mounted together to form complete `~/.claude/` directory

**Key Points:**
- `/workspace/.claude/` is standard project config (no BitBot involvement)
- `~/.claude/` combines global config + workspace-local session data
- Session data stored per-workspace in `.bitbot/internal/global/.claude/`

---

## Directory Structure

### BitBot Repository

```
BitBot/
  global/
    .claude/
      CLAUDE.md          # Global user instructions (shared across all workspaces)
      settings.json      # Global user settings (shared across all workspaces)
      .credentials.json  # Auth tokens (gitignored)

  templates/
    workspace/
      .devcontainer/
        devcontainer.json  # Mounts: /workspace and BITBOT_PATH/global/.claude
      .bitbot/             # BitBot internal (gitignored)
        internal/
          global/
            .claude/       # User-level session data
              .gitkeep
```

### User Workspace

```
my-project/
  .claude/               # Project-level config (VERSIONED - standard Claude Code)
    settings.json        # Project settings
    tools/               # Project tools
    CLAUDE.md            # Project instructions

  .bitbot/               # BitBot internal (GITIGNORED)
    internal/
      global/
        .claude/         # User-level session data (workspace-local)
          history.jsonl  # Command history
          projects/      # Project metadata
          todos/         # Session todos
          # Other session files...
```

### Inside DevContainer

```
Container filesystem:
  /workspace/
    .claude/             # Project config (standard Claude Code, no special handling)
      settings.json
      CLAUDE.md
    .bitbot/
      internal/
        global/
          .claude/       # Session data directory

  /home/bitbot/.claude/  # User config (composed from two sources)
    CLAUDE.md            → mounted from [BITBOT_PATH]/global/.claude/CLAUDE.md (RW)
    settings.json        → mounted from [BITBOT_PATH]/global/.claude/settings.json (RO)
    .credentials.json    → mounted from [BITBOT_PATH]/global/.claude/.credentials.json (RW)
    history.jsonl        → in /workspace/.bitbot/internal/global/.claude/ (RW)
    todos/               → in /workspace/.bitbot/internal/global/.claude/ (RW)
    # Other session files from .bitbot/internal/global/.claude/
```

---

## Mount Configuration

### Permission Model

**All Containers (Work + BitBot Dev):**
- ✅ Read-write: `/workspace` (includes `/workspace/.claude/` project config)
- ✅ Read-write: `/workspace/.bitbot/` (session data, gitignored)
- ✅ Read-write: `~/.claude/CLAUDE.md` (allows Claude to update global memory)
- ✅ Read-write: `~/.claude/.credentials.json` (allows login flow)
- 🔒 Read-only: `~/.claude/settings.json` (prevents accidental corruption)

**To Edit settings.json:**
- Edit `/workspace/global/settings.json` directly (from BitBot dev container)
- The readonly mount at `~/.claude/settings.json` is for Claude Code to read
- Changes take effect on next container restart

### DevContainer Mounts (Work Container)

```json
{
  "name": "BitBot Workspace",
  "mounts": [
    // Workspace (includes .claude/ project config)
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",

    // User config directory - session data from workspace
    "source=${localWorkspaceFolder}/.bitbot/internal/global/.claude,target=/home/bitbot/.claude,type=bind,consistency=cached",

    // BitBot global - Individual files override specific files in ~/.claude/
    "source=/path/to/BitBot/global/.claude/CLAUDE.md,target=/home/bitbot/.claude/CLAUDE.md,type=bind,consistency=cached",
    "source=/path/to/BitBot/global/.claude/settings.json,target=/home/bitbot/.claude/settings.json,type=bind,readonly",
    "source=/path/to/BitBot/global/.claude/.credentials.json,target=/home/bitbot/.claude/.credentials.json,type=bind,consistency=cached"
  ],

  "postCreateCommand": "/workspace/.devcontainer/scripts/setup-claude-config.sh"
}
```

**Notes:**
- `~/.claude/` is mounted to `/workspace/.bitbot/internal/global/.claude/` (session data)
- **CLAUDE.md**: File mount from BitBot global - read-write (global memory)
- **settings.json**: File mount from BitBot global - read-only (protected)
- **.credentials.json**: File mount from BitBot global - read-write (login)
- Session files (history.jsonl, todos/, etc.) live in `.bitbot/internal/global/.claude/`
- `/workspace/.claude/` is standard project config (no special handling)

### DevContainer Mounts (BitBot Dev Container)

```json
{
  "name": "BitBot Development",
  "mounts": [
    // BitBot source
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",

    // User config directory - BitBot's own session data
    "source=${localWorkspaceFolder}/.bitbot/internal/global/.claude,target=/home/bitbot/.claude,type=bind,consistency=cached",

    // BitBot global - Same as work containers (settings.json is readonly)
    "source=${localWorkspaceFolder}/global/.claude/CLAUDE.md,target=/home/bitbot/.claude/CLAUDE.md,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/global/.claude/settings.json,target=/home/bitbot/.claude/settings.json,type=bind,readonly",
    "source=${localWorkspaceFolder}/global/.claude/.credentials.json,target=/home/bitbot/.claude/.credentials.json,type=bind,consistency=cached"
  ]
}
```

**Notes:**
- Same mount structure as work containers
- **settings.json is readonly** - edit directly at `/workspace/global/.claude/settings.json`
- Can edit global files through `/workspace/global/.claude/` (BitBot source is mounted read-write)
- The `~/.claude/` mounts are for Claude Code to consume the config

---

## Configuration Merging Strategy

### Setup Script (postCreateCommand)

```bash
#!/bin/bash
# setup-claude-config.sh - Container Setup

# Ensure session data directory exists (it's mounted as ~/.claude/)
mkdir -p /workspace/.bitbot/internal/global/.claude

# Verify global mounts are working
if [ -f /home/bitbot/.claude/CLAUDE.md ]; then
    echo "✓ BitBot global CLAUDE.md mounted"
else
    echo "⚠ Warning: BitBot global CLAUDE.md not found"
fi

if [ -f /home/bitbot/.claude/settings.json ]; then
    echo "✓ BitBot global settings.json mounted"
else
    echo "⚠ Warning: BitBot global settings.json not found"
fi

echo "✓ Claude config setup complete"
echo "  - ~/.claude/ → /workspace/.bitbot/internal/global/.claude/"
echo "  - CLAUDE.md, settings.json, .credentials.json mounted from BitBot/global/"
echo "  - /workspace/.claude/ is standard project config"
```

**Result:**
- `~/.claude/` = `/workspace/.bitbot/internal/global/.claude/` (base directory mount)
- `~/.claude/CLAUDE.md` = `BitBot/global/.claude/CLAUDE.md` (**read-write** file mount override)
- `~/.claude/settings.json` = `BitBot/global/.claude/settings.json` (**readonly** file mount override)
- `~/.claude/.credentials.json` = `BitBot/global/.claude/.credentials.json` (**read-write** file mount override)
- `~/.claude/history.jsonl` lives in `/workspace/.bitbot/internal/global/.claude/history.jsonl`
- `~/.claude/todos/` lives in `/workspace/.bitbot/internal/global/.claude/todos/`
- `/workspace/.claude/` is standard Claude Code project config (no special handling)

---

## File Classification

### Location 1: BitBot Global (BitBot/global/.claude/)

**Purpose:** User-level config shared across ALL BitBot workspaces

| File               | Purpose                  | Mounted To        | Permissions | Versioned? |
|--------------------|--------------------------|-------------------|-------------|------------|
| `CLAUDE.md`        | Global user instructions | `~/.claude/CLAUDE.md` | Read-Write | ✅ Yes  |
| `settings.json`    | Global user settings     | `~/.claude/settings.json` | Read-Only | ✅ Yes |
| `.credentials.json`| Auth tokens              | `~/.claude/.credentials.json` | Read-Write | ❌ No |

### Location 2: Project Config (/workspace/.claude/)

**Purpose:** Standard Claude Code project-level config (team-shared, versioned)

| File/Directory  | Purpose                  | Access       | Versioned? |
|-----------------|--------------------------|--------------|------------|
| `settings.json` | Project settings         | ✅ Read-Write | ✅ Yes     |
| `CLAUDE.md`     | Project instructions     | ✅ Read-Write | ✅ Yes     |
| `tools/`        | Project tools            | ✅ Read-Write | ✅ Yes     |

**Note:** Standard Claude Code project config, no special handling by BitBot.

### Location 3: Session Data (/workspace/.bitbot/internal/global/.claude/)

**Purpose:** User-level session data (gitignored, workspace-local)

| File/Directory     | Purpose              | Part of ~/ | Versioned? |
|--------------------|----------------------|------------|------------|
| `history.jsonl`    | Command history      | `~/.claude/` | ❌ No    |
| `projects/`        | Project metadata     | `~/.claude/` | ❌ No    |
| `session-env/`     | Session environments | `~/.claude/` | ❌ No    |
| `todos/`           | Session todos        | `~/.claude/` | ❌ No    |
| `shell-snapshots/` | Shell state          | `~/.claude/` | ❌ No    |
| `file-history/`    | Edit history         | `~/.claude/` | ❌ No    |
| `debug/`           | Debug logs           | `~/.claude/` | ❌ No    |

**Note:** `~/.claude/` base directory = `/workspace/.bitbot/internal/global/.claude/`

---

## CLAUDE.md Hierarchy

Claude Code loads multiple CLAUDE.md files in this order (later overrides earlier):

1. **Enterprise** (if configured) - Organization-wide policies
2. **Project** (`/workspace/.claude/CLAUDE.md`) - Project-specific instructions
3. **User** (`~/.claude/CLAUDE.md` → `BitBot/global/CLAUDE.md`) - User's global instructions

**Key Points:**
- Project CLAUDE.md is standard Claude Code project config (versioned, team-shared)
- User CLAUDE.md is in BitBot/global/ (shared across all your BitBot workspaces)
- User CLAUDE.md can contain your personal preferences, shortcuts, common patterns
- Project CLAUDE.md should contain project-specific instructions

**Example BitBot Global CLAUDE.md:**

```markdown
# My Global BitBot Instructions

## Personal Preferences
- I prefer concise explanations with code examples
- Always use TypeScript when available
- Prefer functional programming style

## Common Patterns I Use
- API calls: Use axios with async/await
- Error handling: Always log errors with context
- Testing: Jest for unit tests, Playwright for E2E
```

**Example Project CLAUDE.md:**

```markdown
# MyProject Instructions

React TypeScript project using Vite and Tailwind.

## Project Structure
- /src/components - React components
- /src/api - API client
- /src/hooks - Custom hooks

## Build Commands
- Dev: npm run dev
- Build: npm run build
- Test: npm test
```

---

## .gitignore Configuration

### BitBot Repository

```gitignore
# BitBot global credentials (sensitive)
global/.claude/.credentials.json
```

### User Workspace

```gitignore
# BitBot internal (session data)
.bitbot/
```

**What gets versioned:**
- ✅ `/workspace/.claude/` - Standard project config (team-shared)
- ✅ `BitBot/global/.claude/CLAUDE.md` - Your global instructions
- ✅ `BitBot/global/.claude/settings.json` - Your global settings
- ❌ `BitBot/global/.claude/.credentials.json` - Credentials (gitignored)
- ❌ `.bitbot/` - Session data (gitignored)

---

## Implementation Plan

### Phase 1: Setup BitBot Global

1. Create `BitBot/global/.claude/` directory
2. Add `CLAUDE.md` (user instructions, versioned)
3. Add `settings.json` (user settings, versioned)
4. Add `.credentials.json` (gitignored)

### Phase 2: Update Templates

1. Update `templates/workspace/devcontainer.json`:
   - Mount `/workspace` (unchanged)
   - Mount `.bitbot/internal/global/.claude` → `~/.claude` (base directory)
   - Mount 3 individual files from `BitBot/global/.claude/` to `~/.claude/`
   - Set `postCreateCommand` to setup script

2. Create setup script `.devcontainer/scripts/setup-claude-config.sh`:
   - Create `/workspace/.bitbot/internal/global/.claude/`
   - Verify global file mounts

3. Create `.bitbot/internal/global/.claude/` template structure

4. Update `.gitignore` template to ignore `.bitbot/`

### Phase 3: Migration Script

Create `core/util/migrate-to-global-config.sh` to:
1. Detect existing workspace configs (`.devcontainer/home/.claude/`)
2. Extract credentials → move to `BitBot/global/.claude/.credentials.json`
3. Extract user-level CLAUDE.md/settings → move to `BitBot/global/.claude/`
4. Extract session data → move to `.bitbot/internal/global/.claude/`
5. Leave project-level config in `/workspace/.claude/` (if exists)
6. Update `devcontainer.json` with new mounts
7. Remove old `.devcontainer/home/` directory

### Phase 4: Documentation

1. Update README with new structure
2. Document BitBot global vs project config
3. Explain CLAUDE.md hierarchy
4. Create migration guide

---

## Benefits

✅ **Single Sign-On** - Credentials shared across all BitBot workspaces
✅ **Standard Project Config** - `/workspace/.claude/` works exactly like normal Claude Code
✅ **Personal Preferences** - Global CLAUDE.md and settings shared across your workspaces
✅ **Session Isolation** - History and todos per workspace (in `.bitbot/`)
✅ **Simple Setup** - Only 2 mounts: workspace + BitBot global
✅ **Clean Separation** - Global user config vs project config vs session data
✅ **Better Security** - Credentials in one location, mounted read-only

---

## Design Rationale

### Why This Structure?

**BitBot Global (CLAUDE.md, settings.json, .credentials.json)**
- **Single Sign-On:** Login once, use across all workspaces
- **Personal Preferences:** Your coding style, common patterns, shortcuts
- **Shared Settings:** Status line, tool auto-approvals, etc.
- **Security:** Mounted read-only prevents accidental modification

**Project Config (/workspace/.claude/)**
- **Standard Claude Code:** Works exactly like normal projects
- **Team Collaboration:** Versioned, shared with team
- **Project-Specific:** Build commands, project structure, conventions

**Session Data (.bitbot/internal/.claude/)**
- **Per-Workspace:** History and todos isolated per workspace
- **Not Shared:** Gitignored, personal to you
- **Temporary:** Can delete without losing configuration

### Why Individual File Mounts?

Instead of mounting `BitBot/global/` as `~/.claude/`, we mount individual files because:
- Session data (history, todos) should be workspace-local in `.bitbot/`
- Only 3 files (CLAUDE.md, settings.json, .credentials.json) are global
- Individual file mounts override specific files in the `~/.claude/` directory mount

### Why Different Permissions?

**CLAUDE.md (Read-Write):**
- Allows Claude to update global memory/learnings
- Changes apply across all your BitBot workspaces
- Example: Claude learns your coding preferences and updates global CLAUDE.md

**settings.json (Read-Only):**
- Prevents accidental corruption of global settings
- Tool auto-approvals, status line config stay consistent
- Must edit from BitBot dev container to change

**.credentials.json (Read-Write):**
- Allows login flow to write credentials
- When you run `claude login`, credentials written here
- Shared across all workspaces (single sign-on)

### Editing Workflow

**To Update Global Config:**
```bash
# Edit from BitBot dev container
cd /path/to/BitBot
nano global/.claude/CLAUDE.md
nano global/.claude/settings.json
git commit -m "Update global Claude config"

# Changes apply to all workspaces immediately (files are mounted)
```

**To Update Project Config:**
```bash
# Edit from work container
nano .claude/settings.json
nano .claude/CLAUDE.md
git commit -m "Update project Claude config"
```

**Session Data:**
- Automatically stored in `.bitbot/internal/.claude/`
- No manual editing needed
- Gitignored

---

## Considerations

### Security

- **Credential Sharing**: Shared credentials across all workspaces
  - Risk: One workspace compromise exposes credentials for all workspaces
  - Mitigation: Mounted read-only, can't be modified from workspace
  - Benefit: Only need to rotate credentials in one place
  - Alternative: Per-workspace credentials (defeats single sign-on benefit)

### Workspace Portability

- **BitBot Dependency**: Workspaces require BitBot global mount
  - Impact: Team members need BitBot installed
  - Mitigation: Setup script shows clear error if mount missing
  - Benefit: Project config (` /workspace/.claude/`) still works normally
  - Fallback: Can manually provide credentials if global mount unavailable

### Session Data Location

- **Workspace-Local Sessions**: Session data in `.bitbot/` per workspace
  - Benefit: History and todos isolated per project
  - Consideration: History not shared across workspaces
  - Trade-off: More isolation vs less continuity

### Performance

- **Mount Overhead**: Minimal - only 2 mounts (workspace + global)
  - Impact: Negligible container startup time
  - Benefit: Simple setup, no complex multi-tier mounting

---

## Alternative Approaches

### Option A: Recommended (Described Above)
- **Global:** BitBot/global (CLAUDE.md, settings.json, .credentials.json)
- **Project:** /workspace/.claude/ (standard Claude Code project config)
- **Session:** .bitbot/internal/.claude/ (workspace-local session data)
- **Benefits:** Simple, standard project config, single sign-on

### Option B: Fully Global ~/.claude/
- Mount BitBot/global/ directly as ~/.claude/
- **Problem:** Session data (history, todos) shared across ALL workspaces
- **Problem:** Can't have workspace-specific session data

### Option C: Fully Workspace-Local
- Everything in .devcontainer/home/.claude/
- No BitBot/global at all
- **Problem:** Credentials duplicated per workspace
- **Problem:** Can't share personal preferences across workspaces

### Option D: Complex Three-Tier Mounts
- Separate mounts for credentials, workspace config, session data
- **Problem:** More complex than necessary
- **Problem:** Current approach is simpler and achieves same goals

---

## Open Questions

1. **Multi-User**: What if multiple users share BitBot installation?
   - A: Each user has their own `BitBot/` directory with separate `global/`
   - Alternative: Per-user subdirectories in `BitBot/global/<username>/`

2. **Credentials Rotation**: How to update credentials?
   - A: Edit `BitBot/global/.credentials.json` from BitBot dev container
   - All workspaces pick up changes on next container restart

3. **Concurrent Workspaces**: What if two workspaces run simultaneously?
   - A: No conflict - each has isolated session data in `.bitbot/`
   - Global mount is read-only (safe for concurrent access)

4. **Settings Conflicts**: What if global and project settings conflict?
   - A: Claude Code merges them (project settings override global)
   - Standard Claude Code behavior applies

5. **Symlink Behavior**: How does Claude Code handle symlinked files?
   - A: Claude Code follows symlinks transparently
   - Should work, but needs testing to confirm

---

## Success Metrics

- ✅ **Single Sign-On**: Credentials stored once in BitBot/global, accessible from all workspaces
- ✅ **Standard Project Config**: /workspace/.claude/ works like normal Claude Code projects
- ✅ **Global Preferences**: Personal CLAUDE.md and settings shared across workspaces
- ✅ **Session Isolation**: History/todos isolated per workspace in .bitbot/
- ✅ **Simple Setup**: Only 2 mounts (workspace + global), easy to understand
- ✅ **Clean Separation**: Clear distinction between global, project, and session config
- ✅ **Smooth Migration**: Migration script converts existing workspaces

---

## Next Steps

1. Review and refine specification
2. Prototype with single workspace
3. Test credential sharing
4. Validate mount performance
5. Implement migration script
6. Roll out to all templates
