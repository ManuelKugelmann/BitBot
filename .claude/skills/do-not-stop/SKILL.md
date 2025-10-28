---
name: do-not-stop
description: Enable Stop hook automation for continuous multi-phase workflows. Use when working until finished, implementing multiple tasks sequentially, running test-fix-commit loops, or workflows requiring automatic continuation. User can invoke with /do-not-stop [reason].
---

# Enable Stop Hook Automation

**Enabled by default in BitBot.**

```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh [reason]
```

Or user invokes: `/do-not-stop [reason]`

Default reason: "Continue working. Check TODO list and implement the next pending task."
