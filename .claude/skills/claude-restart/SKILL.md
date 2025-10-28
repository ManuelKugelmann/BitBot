---
name: claude-restart
description: Restart Claude Code session to reload new skills, manage context, or start fresh. Use this skill when skills have been added/modified, when needing to compact/clear context, or to reload configuration changes.
---

# Restart Claude Code Session

Restart Claude with options for session management.

**Modes:**

```bash
.claude/skills/claude-restart/scripts/claude-restart.sh [resume|compact|clear]
```

- **resume** (default) - Reload skills, keep conversation
- **compact** - Context management mode
- **clear** - Fresh start, no history
