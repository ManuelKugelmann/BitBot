---
name: allow-stop
description: Disable Stop hook automation to allow normal completion. Use this skill when asking questions, discussing approaches, working interactively with the user, brainstorming solutions, or any workflow requiring back-and-forth conversation. The user can also invoke this with /allow-stop.
---

# Disable DONOTSTOP Automation

Disables the Stop hook automation, allowing Claude to complete normally and wait for user input.

## When to Use

**Model-Invoked (Automatic):**
- When user asks questions or requests clarification
- Before brainstorming or discussing multiple approaches
- When entering interactive problem-solving mode
- When user wants to review progress before continuing
- When switching from automated to manual workflow
- After completing a major implementation milestone

**User-Invoked (Manual):**
- User types `/allow-stop` to stop automation

## Usage

```bash
.claude/skills/allow-stop/scripts/allow-stop.sh
```

## How It Works

1. Removes `.bitbot/DO-NOT-STOP.txt` file
2. Stop hook detects file is missing
3. Claude completes normally (stops responding)
4. User must manually send next prompt

## Instructions

Call the tool with no arguments:
```bash
.claude/skills/allow-stop/scripts/allow-stop.sh
```

**Tool output:**
- Displays confirmation that automation is disabled
- Shows Claude will stop after finishing responses
- Provides instructions for re-enabling

## Use Cases

1. **Interactive discussion**: User wants to discuss approach before proceeding
2. **Question & Answer**: User has questions about implementation
3. **Progress review**: Review current state before continuing
4. **Manual checkpoint**: User wants control over next steps
5. **Debugging session**: Interactive investigation of issues
6. **End of work session**: Stop automation before closing for the day
7. **Context management**: Stop to run `/compact` or `/clear` manually

## Re-enabling Automation

To re-enable after disabling:
```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh
```

Or with custom reason:
```bash
.claude/skills/do-not-stop/scripts/do-not-stop.sh "Continue with next phase"
```

## Important Notes

- Tool is auto-approved and doesn't require user confirmation
- Takes effect immediately (next completion will stop normally)
- Can be re-enabled anytime with `/do-not-stop` skill
- Removes file from `/workspace/.bitbot/` (containers) or project root
- See `.claude/hooks/do-not-stop.sh` for hook implementation

## Workflow Pattern

**Typical interactive session:**
1. Start with automation disabled (or disable with `/allow-stop`)
2. Discuss approach, ask questions, plan implementation
3. Once plan is clear, enable automation with `/do-not-stop`
4. Claude works automatically until tasks complete
5. Disable again with `/allow-stop` for review/discussion
