# BitBot Global User Instructions

This file contains your personal Claude Code preferences shared across all BitBot workspaces.

## Personal Preferences

- Never abort research or work on an approach without explicit instruction
- Test run all code and scripts before committing
- Only commit when all tests are done and pass
- Do not git reset without user confirmation

## About This File

This is your **global** CLAUDE.md file stored in BitBot's installation directory.

**Location:** `$BITBOT_HOME/container/home/.claude/CLAUDE.md`

**Mounted to containers:** `/root/.claude/CLAUDE.md` (read-write)

**Purpose:**
- Personal coding preferences that apply to all your BitBot workspaces
- Common patterns and shortcuts you use frequently
- Your personal development standards

**Note:** Project-specific instructions should go in `/workspace/.claude/CLAUDE.md` (standard Claude Code project config).

## How to Edit

From BitBot development container or directly edit this file:
```bash
nano $BITBOT_HOME/container/home/.claude/CLAUDE.md
```

Changes take effect immediately in all running containers (file is mounted, not copied).
