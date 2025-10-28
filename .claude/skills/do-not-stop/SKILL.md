---
name: do-not-stop
description: Enable Stop hook automation for continuous multi-phase workflows. Use this skill when working until finished, implementing multiple tasks sequentially, running test-fix-commit loops, or any workflow requiring automatic continuation without user prompting. The user can also invoke this with /do-not-stop [reason].
---

# Enable DONOTSTOP Automation

Enables the Stop hook that blocks completion and continues work automatically.

## When to Use

**Model-Invoked (Automatic):**
- When starting multi-phase implementation tasks
- Before entering test-fix-commit loops
- When implementing features from TODO-TRACKER.md
- At the start of automated documentation generation
- When user expresses desire to "work until finished"

**User-Invoked (Manual):**
- User types `/do-not-stop` to enable automation
- User types `/do-not-stop "Custom reason"` with specific instructions

## Usage

```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh [reason]
```

## How It Works

1. Creates/updates `.bitbot/DO-NOT-STOP.txt` with continuation reason
2. Stop hook reads this file when Claude finishes responding
3. Hook blocks completion and continues with the specified reason
4. Claude automatically continues working without user prompting

## Default Reason

If no reason is provided:
> "Continue working. Check TODO list and implement the next pending task."

## Instructions

**To enable automation:**

Call the tool without arguments for default behavior:
```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh
```

Or with custom reason:
```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh "Implement all features from specification"
```

**Tool output:**
- Displays confirmation message with active reason
- Shows file location (`.bitbot/DO-NOT-STOP.txt`)
- Provides instructions for disabling

## Use Cases

1. **Multi-phase implementation**: Implement complex features in sequential steps
2. **Test-fix-commit loops**: Run tests → fix failures → commit → repeat
3. **Documentation generation**: Create docs for all modules systematically
4. **Feature backlog processing**: Work through TODO-TRACKER.md automatically
5. **Refactoring tasks**: Apply changes across multiple files consistently

## Important Notes

- **Enabled by default** in BitBot
- Tool is auto-approved and doesn't require user confirmation
- Creates file in `/workspace/.bitbot/` (containers) or project root
- User can disable anytime with `/allow-stop` skill
- To change reason while active: run tool again with new reason
- See `.claude/hooks/do-not-stop.sh` for hook implementation
