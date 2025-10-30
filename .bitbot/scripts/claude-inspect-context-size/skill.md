# claude-inspect-context-size

**Type**: BitBot-dependent skill (requires BitBot wrapper infrastructure)

**Purpose**: Intelligent context management advisor for work continuation optimization

## Description

Provides strategic guidance for context management based on work state and natural break points, not just arbitrary thresholds. Helps Claude make intelligent decisions about when and how to compact for optimal work continuation.

## Philosophy

**Context management is about work continuation, not hitting thresholds.**

Compact at natural break points (even at 40% context) with clear continuation instructions, rather than waiting for arbitrary percentage limits.

## When Claude Should Use This

**Proactively use this skill:**
- Before starting large or complex tasks
- After completing major milestones
- When context feels full but unsure if should compact
- To get break point recommendations and compaction guidance

**Reactive use:**
- User asks about context usage
- Need to check if at good compaction point
- Investigating context-related issues

## What It Does

1. **Reads Session Data**: Sources `.bitbot/session-env/<session-id>.env`
2. **Analyzes Context**: Evaluates current context percentage
3. **Identifies Break Points**: Recommends good vs bad compaction points
4. **Provides Strategies**: Work-state-aware guidance for continuation
5. **Shows Examples**: Real compaction prompts with continuation context
6. **Lists Tools**: Available compaction commands and wrapper integration

## Context Levels & Strategic Guidance

| Level | Range | Status | Strategy |
|-------|-------|--------|----------|
| 🟢 Healthy | 0-49% | Good | Continue normally. Compact at natural breaks (tests pass, feature done, docs updated) |
| 🟡 Moderate | 50-69% | Watch | Plan for compaction at next logical break point. Lists good vs bad break points |
| 🟠 High | 70-84% | Priority | Prioritize finding break point. Complete current task, commit, prepare continuation |
| 🔴 Critical | 85-100% | Urgent | Immediate break point or compact NOW. Save state, commit WIP, preserve debug context |

**Key Insight**: Level is less important than work state. A natural break at 40% is better than forced compaction at 85%.

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

## Output Example (High Context)

```
╔═══════════════════════════════════════════════════════════════╗
║              Context Usage Report                             ║
╚═══════════════════════════════════════════════════════════════╝

Status:      🟠 HIGH
Context:     76.3%
Session:     abc123-def456-...

═══════════════════════════════════════════════════════════════
Recommendation:

Context usage is high. Prioritize finding a break point soon.

Strategy:
1. Complete current atomic task (fix, feature, test)
2. Commit working code
3. Prepare continuation instructions
4. Compact with detailed resumption prompt

If context approaching 90%:
- Stop current work at safe point
- Commit what's working
- Compact NOW with clear next steps

═══════════════════════════════════════════════════════════════
Compaction Strategy:

Effective compaction requires work continuation instructions.
Instead of just running /compact, provide context about:

  • What was just completed
  • What remains to be done
  • Critical decisions or findings
  • Next specific steps

Example compaction prompts:

  /compact Completed user auth feature (tests passing, committed).
           Next: Implement password reset flow. Start with email
           template design, then backend endpoint.

  /compact Fixed bug in data parser (root cause: null handling).
           Next: Add comprehensive null safety tests across parser
           module. Check edge cases in spec doc.

═══════════════════════════════════════════════════════════════
Compaction Tools:

1. With continuation prompt (RECOMMENDED):
   /compact <brief summary of state + next steps>

2. Via skill (for programmatic compaction):
   /claude-restart-compact

3. Pipe command (from scripts):
   echo 'compact $CLAUDE_SESSION_ID <prompt>' > $WRAPPER_PIPE
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
