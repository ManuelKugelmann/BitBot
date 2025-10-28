---
name: claude-do-not-stop
description: Enable Stop hook automation for continuous multi-phase workflows. Use when working until finished, implementing multiple tasks sequentially, running test-fix-commit loops, or workflows requiring automatic continuation. User can invoke with /claude-do-not-stop [reason].
---

# Enable Stop Hook Automation

**Enabled by default in BitBot.**

```bash
.claude/skills/claude-do-not-stop/scripts/do-not-stop.sh [reason]
```

Or user invokes: `/claude-do-not-stop [reason]`

Default: "Resume work!"
