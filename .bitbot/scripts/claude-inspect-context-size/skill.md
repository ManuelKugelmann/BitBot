# claude-inspect-context-size

**Type**: BitBot-dependent skill (requires BitBot wrapper infrastructure)

**Purpose**: Help Claude monitor and manage context usage

## Description

Display current context percentage with color-coded status and provide actionable recommendations for context management.

## When Claude Should Use This

Use this skill when:
- User asks about context usage or remaining context
- Checking if compaction is needed before starting a large task
- Determining whether to continue current work or compact first
- Investigating context-related issues

## What It Does

1. **Reads Session Data**: Sources `.bitbot/session-env/<session-id>.env`
2. **Analyzes Context**: Evaluates current context percentage
3. **Provides Status**: Color-coded warning levels (Good/Moderate/High/Critical)
4. **Recommends Actions**: Specific guidance based on context level
5. **Shows Options**: Lists available context management commands

## Context Levels

| Level | Range | Status | Recommendation |
|-------|-------|--------|----------------|
| 🟢 Good | 0-49% | Healthy | Continue normally |
| 🟡 Moderate | 50-69% | Watch | Consider compacting after current task |
| 🟠 High | 70-84% | Warning | Plan to compact soon |
| 🔴 Critical | 85-100% | Danger | Compact now to avoid exhaustion |

## Dependencies

- **BitBot Infrastructure**: Requires `.bitbot/` workspace structure
- **Session Environment**: Populated by `statusline-wrapper`
- **SessionStart Hook**: Sets `CLAUDE_SESSION_ID` environment variable

## Usage

```bash
# From Claude Code (as a skill)
/claude-inspect-context-size

# Or directly
.bitbot/scripts/claude-inspect-context-size/claude-inspect-context-size.sh
```

## Output Example

```
╔═══════════════════════════════════════════════════════════════╗
║              Context Usage Report                             ║
╚═══════════════════════════════════════════════════════════════╝

Status:      🟠 HIGH
Context:     76.3%
Session:     abc123-def456-...

═══════════════════════════════════════════════════════════════
Recommendation:

Context usage is high. Plan to compact soon to avoid context exhaustion.

═══════════════════════════════════════════════════════════════
Context Management Options:

1. Compact now (recommended if at critical level):
   Use: /claude-restart-compact skill

2. Finish current task then compact:
   Complete your work, then use /claude-restart-compact

3. Manual compaction:
   Type: /compact

═══════════════════════════════════════════════════════════════
Available Wrapper Commands:

  - compact: Compact context and resume
  - restart: Restart without compaction
  - clear:   Fresh start (loses history)

Skills can send commands via: echo 'command $CLAUDE_SESSION_ID' > $WRAPPER_PIPE
```

## Integration with Context Self-Management

This skill is part of BitBot's context self-management system:

- **Monitoring**: `statusline-wrapper` tracks context % → writes to session env
- **Inspection**: This skill reads session env → displays status
- **Action**: Claude/skills can trigger compaction via wrapper pipe

## Location

`.bitbot/scripts/claude-inspect-context-size/` (BitBot-dependent scripts)

**Why here?**
- Depends on BitBot infrastructure (`.bitbot/session-env/`, wrapper system)
- Not a pure Claude Code extension
- Part of BitBot's context management features

## See Also

- `sparc/3-architecture/02-wrapper-system.md` - Wrapper system architecture
- `.claude/skills/claude-restart/` - Restart/compact skills
- `container/bitbot/wrapper/statusline-wrapper/` - Status line wrapper
