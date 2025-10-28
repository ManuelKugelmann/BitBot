# BitBot Global Claude Configuration

This directory contains global Claude Code configuration shared across all BitBot workspaces.

## Files

| File | Purpose | Mounted As | Versioned |
|------|---------|------------|-----------|
| `CLAUDE.md` | Global user instructions | `/root/.claude/CLAUDE.md` (RW) | ✅ Yes |
| `settings.json` | Global Claude settings | `/root/.claude/settings.json` (RO) | ✅ Yes |
| `.credentials.json` | Auth tokens (SSO) | `/root/.claude/.credentials.json` (RW) | ❌ No (gitignored) |

## How It Works

### Global vs Project Config

**Global Config (this directory):**
- Shared across ALL your BitBot workspaces
- Personal preferences, coding style, common patterns
- Mounted from `$BITBOT_HOME/container/home/.claude/`
- Changes apply to all workspaces immediately

**Project Config (`/workspace/.claude/`):**
- Standard Claude Code project config
- Team-shared, versioned in git
- Project-specific instructions, build commands, etc.
- No special handling by BitBot

### Claude Code Loading Order

1. **Enterprise** (if configured) - Organization policies
2. **Project** (`/workspace/.claude/CLAUDE.md`) - Project instructions
3. **User** (`/root/.claude/CLAUDE.md` → this directory) - Your preferences

Later overrides earlier, so your global preferences take precedence.

## Session Data

Session data (history, todos, projects) is stored **per-workspace** in:
- `.devcontainer/home/.claude/` (workspace-specific, gitignored)

This directory only contains **non-ephemeral configuration**.

## Editing

### From BitBot Development Container

```bash
cd /workspace
nano container/home/.claude/CLAUDE.md
nano container/home/.claude/settings.json
git commit -m "Update global Claude config"
```

### From Host

```bash
cd $BITBOT_HOME
nano container/home/.claude/CLAUDE.md
nano container/home/.claude/settings.json
git commit -m "Update global Claude config"
```

Changes take effect immediately (files are mounted, not copied).

## Permissions

- **CLAUDE.md**: Read-write (allows Claude to update global memory)
- **settings.json**: Read-only (prevents accidental corruption)
- **.credentials.json**: Read-write (allows login flow)

### Why settings.json is Read-Only?

To prevent accidental corruption of global settings by Claude Code. To edit:
1. Edit this file directly from BitBot dev container or host
2. Changes apply on next container restart

## Security

**.credentials.json** contains authentication tokens and is:
- ✅ Shared across all workspaces (single sign-on)
- ✅ Mounted read-write (login flow can write)
- ✅ Gitignored (never committed)
- ⚠️ One workspace compromise exposes all workspaces

## See Also

- `/sparc/1-specification/GLOBAL_CLAUDE_CONFIG_SPEC.md` - Full specification
- `/sparc/1-specification/12_MOUNT_STRUCTURE.md` - Mount architecture
