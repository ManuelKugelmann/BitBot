---
name: restart
description: Restart Claude Code session to reload new skills, manage context, or start fresh. Use this skill when skills have been added/modified, when needing to compact/clear context, or to reload configuration changes.
---

# Restart Claude Code Session

Restart Claude with options for resuming, compacting context, or starting fresh.

## When to Use

Invoke automatically when:
- After creating or modifying skills (skills load at session start only)
- User requests "restart Claude" or "reload skills"
- User wants to compact or clear context
- After configuration changes requiring reload

## Restart Modes

### Resume (Default)
Quick restart preserving conversation history.

```bash
.claude/skills/restart/scripts/claude-restart.sh resume
```

Reloads newly added skills while keeping the conversation.

### Compact
Restart in print mode for context management.

```bash
.claude/skills/restart/scripts/claude-restart.sh compact
```

Use when context window is filling up. After restart, run `/compact` to compress context.

### Clear
Start completely fresh with no history.

```bash
.claude/skills/restart/scripts/claude-restart.sh clear
```

New session with clean slate.

## Troubleshooting

**Cannot find Claude process:** Restart aborted safely.

**Cannot detect session ID:** For resume/compact modes, script aborts. Use `clear` mode instead.

**Script fails:** Try manual restart: `claude --resume <session-id>`

See `TECH.md` for implementation details.
