---
name: claude-restart-compact
description: Compact context to free up tokens and continue working. Use when context is getting full during a long task or multi-phase implementation. Summarizes conversation and resumes work.
---

Compacting context and resuming work...

This will:
- Summarize recent conversation to free tokens
- Preserve task context and state
- Resume with compact history
- Continue working on current task

Use this when:
- Context is getting full (high token usage)
- Working on multi-phase implementations
- Need to free up space while keeping task continuity

```bash
.claude/skills/claude-restart-resume/scripts/claude-restart.sh compact
```
