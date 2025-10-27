# Claude Code Stop Hook Automation Research

**Date**: 2025-10-27
**Status**: Experimental
**Related**: Claude Code Hooks, Automated Workflows, Session Management

---

## Executive Summary

Claude Code's Stop hook can enable automated workflows by blocking completion and injecting new prompts, creating continuous work loops. Combined with session resumption, this enables fully automated multi-phase implementations without manual intervention.

**Key Finding**: Stop hooks receive `stop_hook_active` flag to prevent infinite loops and can use `"decision": "block"` to continue work with new prompts.

---

## Stop Hook Mechanics

### What Is the Stop Hook?

The Stop hook executes "when the main Claude Code agent has finished responding." It can:

1. **Allow completion** (default behavior)
2. **Block completion** and inject new prompt/context to continue work

### Input Structure

```json
{
  "stop_hook_active": boolean,
  "hook_event_name": "Stop"
}
```

**Fields:**
- `stop_hook_active`: `true` when Claude is already continuing from a stop hook (prevents loops)
- `hook_event_name`: Always `"Stop"` for this hook

### Output Control

**Allow Completion:**
```json
{}
```
or exit code 0 without JSON output

**Block Completion (Continue Work):**
```json
{
  "decision": "block",
  "reason": "More tasks pending. Continue with next item from TODO list."
}
```

The `reason` is injected into Claude's context as additional instruction.

---

## Automated Workflow Pattern

### Basic Loop Pattern

```bash
#!/bin/bash
# .claude/hooks/stop-loop.sh

# Read JSON input from stdin
INPUT=$(cat)

# Parse stop_hook_active flag
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loops
if [ "$STOP_ACTIVE" = "true" ]; then
    exit 0
fi

# Check if more work is needed
if [ -f .claude/todo-remaining.txt ]; then
    NEXT_TASK=$(head -n1 .claude/todo-remaining.txt)

    # Block completion and inject next prompt
    cat <<EOF
{
  "decision": "block",
  "reason": "Continue with next task: $NEXT_TASK"
}
EOF

    # Remove completed task
    tail -n +2 .claude/todo-remaining.txt > .claude/todo-remaining.tmp
    mv .claude/todo-remaining.tmp .claude/todo-remaining.txt
else
    # All tasks complete, allow stop
    exit 0
fi
```

### Configuration

`.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [{
      "type": "command",
      "command": ".claude/hooks/stop-loop.sh",
      "timeout": 5000
    }]
  }
}
```

---

## Environment Variables

### Documented Variables

From official Claude Code documentation:

| Variable | Availability | Description |
|----------|-------------|-------------|
| `CLAUDE_PROJECT_DIR` | All hooks | Absolute path to project root |
| `CLAUDE_CODE_REMOTE` | All hooks | `true` if web/remote, `false` if CLI |
| `CLAUDE_ENV_FILE` | SessionStart only | Path to persist env vars for bash commands |

### Undocumented Variables (User Example)

The user's example references `CLAUDE_SESSION_ID`:
```bash
SESSION_ID="$CLAUDE_SESSION_ID"
echo "$REPEATING_PROMPT" | claude -p --resume "$SESSION_ID"
```

**Status**: Not mentioned in official documentation. May be:
- Deprecated feature
- Undocumented internal variable
- Third-party extension
- User's custom implementation

**Alternative**: Use `--resume` without session ID (resumes last session).

---

## Session Resumption with Hooks

### Pattern 1: Block and Continue (Recommended)

```bash
#!/bin/bash
# Stop hook that blocks and continues in same session

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

if [ "$STOP_ACTIVE" = "true" ]; then
    exit 0
fi

# Check for more work
if has_more_work; then
    cat <<EOF
{
  "decision": "block",
  "reason": "$(get_next_instruction)"
}
EOF
else
    exit 0
fi
```

**Advantages:**
- No session restart needed
- Context preserved automatically
- Simpler implementation
- Official documented approach

### Pattern 2: Resume with Text Mode (Experimental)

```bash
#!/bin/bash
# Stop hook that resumes session with new prompt

# Note: Session ID mechanism not documented
# This example assumes external session tracking

REPEATING_PROMPT="Continue with next phase"

# Resume last session with new prompt
echo "$REPEATING_PROMPT" | claude -p --resume
```

**Challenges:**
- Session ID mechanism unclear
- Context management manual
- More complex error handling
- Potential for session conflicts

---

## Use Cases for BitBot

### 1. Multi-Phase Implementation Loop

**Scenario**: Implement multiple features sequentially without manual prompting

```bash
#!/bin/bash
# .claude/hooks/implementation-loop.sh

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

[ "$STOP_ACTIVE" = "true" ] && exit 0

# Check TODO-TRACKER.md for pending tasks
PENDING=$(grep -c "^- \[ \]" sparc/5-completion/TODO-TRACKER.md)

if [ "$PENDING" -gt 0 ]; then
    NEXT=$(grep "^- \[ \]" sparc/5-completion/TODO-TRACKER.md | head -n1)

    cat <<EOF
{
  "decision": "block",
  "reason": "Implementation phase complete. Continue with next task: $NEXT. Read TODO-TRACKER.md and implement the next uncompleted item."
}
EOF
else
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "message": "All implementation tasks complete! 🎉"
  }
}
EOF
fi
```

### 2. Test-Fix-Commit Loop

**Scenario**: Automatically run tests after each change and fix failures

```bash
#!/bin/bash
# .claude/hooks/test-loop.sh

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

[ "$STOP_ACTIVE" = "true" ] && exit 0

# Run tests
cd dev/tests
TEST_OUTPUT=$(./run-tests.sh 2>&1)
TEST_RESULT=$?

if [ $TEST_RESULT -ne 0 ]; then
    # Tests failed, continue to fix
    FAILURES=$(echo "$TEST_OUTPUT" | grep "✗" | head -n3)

    cat <<EOF
{
  "decision": "block",
  "reason": "Tests failed. Fix these failures:\n$FAILURES"
}
EOF
else
    # Tests passed, allow completion
    echo '{"hookSpecificOutput": {"message": "All tests passing ✓"}}'
    exit 0
fi
```

### 3. Documentation Generation Loop

**Scenario**: Generate docs for each module automatically

```bash
#!/bin/bash
# .claude/hooks/doc-loop.sh

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

[ "$STOP_ACTIVE" = "true" ] && exit 0

# Find undocumented modules
UNDOCUMENTED=$(find core container/bitbot -name "*.sh" -type f | while read f; do
    README_DIR=$(dirname "$f")
    [ ! -f "$README_DIR/README.md" ] && echo "$f"
done | head -n1)

if [ -n "$UNDOCUMENTED" ]; then
    cat <<EOF
{
  "decision": "block",
  "reason": "Generate documentation for: $UNDOCUMENTED. Create a README.md in the same directory explaining the script's purpose, usage, and examples."
}
EOF
else
    exit 0
fi
```

---

## Safety Considerations

### Infinite Loop Prevention

**Always check `stop_hook_active`:**
```bash
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && exit 0
```

Without this check, the hook creates infinite loops.

### Timeout Configuration

Set appropriate timeouts for hooks:
```json
{
  "hooks": {
    "Stop": [{
      "command": ".claude/hooks/stop-loop.sh",
      "timeout": 5000
    }]
  }
}
```

Default is 60 seconds, but loop logic should be fast (<5s).

### Exit Conditions

Always have clear exit conditions:
- Task queue empty
- Maximum iterations reached
- Error threshold exceeded
- User intervention required

### User Control

Provide escape hatches:
```bash
# Check for emergency stop file
[ -f .claude/STOP_AUTOMATION ] && exit 0
```

User can create `.claude/STOP_AUTOMATION` to halt automated loops.

---

## Comparison: Stop Hook vs Manual Prompting

| Aspect | Stop Hook Automation | Manual Prompting |
|--------|---------------------|------------------|
| **Speed** | Immediate continuation | Requires user input |
| **Consistency** | Deterministic workflow | Variable based on user |
| **Supervision** | Minimal (review after) | Continuous oversight |
| **Error Recovery** | Programmatic logic | User judgment |
| **Learning Curve** | Requires hook setup | Immediate use |
| **Best For** | Repetitive multi-phase tasks | Exploratory development |

---

## Implementation Recommendations for BitBot

### 1. Provide Sample Stop Hooks

Include example hooks in BitBot workspace template:

**Location**: `container/templates/bitbot/workspace/home/.claude/hooks/`

**Samples:**
- `implementation-loop.sh` - Multi-phase implementation
- `test-fix-loop.sh` - Test-driven development
- `doc-generation-loop.sh` - Automated documentation

### 2. Hook Management Tools

Create tools for hook management:

```bash
# .claude/tools/enable-automation [hook-name]
# Activates a specific automation hook

# .claude/tools/disable-automation
# Deactivates all automation hooks

# .claude/tools/automation-status
# Shows active hooks and loop state
```

### 3. Documentation

**Add to DEVELOPMENT.md:**
```markdown
## Automated Workflows with Stop Hooks

BitBot includes sample Stop hooks for automated workflows:

- **Implementation Loop**: Automatically implements tasks from TODO-TRACKER.md
- **Test-Fix Loop**: Runs tests after changes and auto-fixes failures
- **Doc Generation**: Creates documentation for undocumented modules

Enable automation: `.claude/tools/enable-automation [hook-name]`
Disable automation: `.claude/tools/disable-automation`

⚠️  Warning: Automated workflows require supervision for complex tasks.
```

### 4. Emergency Stop Mechanism

**Create `.claude/STOP_AUTOMATION.md`:**
```markdown
# Emergency Stop for Automated Workflows

If automation is running and needs to be stopped:

1. Create this file: `touch .claude/STOP_AUTOMATION`
2. All automation hooks will immediately exit
3. Remove file to re-enable: `rm .claude/STOP_AUTOMATION`

This provides user control over automated loops.
```

---

## Technical Considerations

### Hook Execution Timing

Hooks execute "when the main Claude Code agent has finished responding":
- After all tool calls complete
- Before waiting for user input
- Before context compaction (if any)

### Context Preservation

When blocking with `"decision": "block"`:
- Full conversation context preserved
- File context maintained
- TODO state persists
- Token usage continues accumulating

**Important**: Monitor token usage; use `/compact` between phases if needed.

### Hook Reliability

Hooks are loaded at session startup:
- Changes require session restart
- Hook failures don't crash Claude
- Timeouts (60s default) prevent hangs
- Parallel execution for multiple hooks

---

## Open Questions

### Session ID Access

User example shows `CLAUDE_SESSION_ID` environment variable, but this is not documented. Questions:

1. Is `CLAUDE_SESSION_ID` available in hooks?
2. Is it reliable for session resumption?
3. Are there alternatives for session tracking?

**Recommendation**: Use documented `"decision": "block"` pattern instead of resume-based loops until session ID mechanism is clarified.

### Resume Behavior

Documentation mentions SessionStart receives `"source": "resume"` but doesn't detail:
- How to get current session ID
- Whether `--resume` without ID works reliably
- Context preservation across resumes

**Action**: Test resume behavior in BitBot environment.

---

## References

- [Claude Code Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide.md)
- [Claude Code Hooks Reference](https://docs.claude.com/en/docs/claude-code/hooks)
- User example: Stop hook with session resumption
- [BitBot TODO-TRACKER.md](../../sparc/5-completion/TODO-TRACKER.md)

---

## Conclusion

Stop hook automation enables powerful automated workflows for repetitive multi-phase tasks. The documented `"decision": "block"` pattern is recommended over undocumented session resumption approaches.

**For BitBot:**
1. Provide sample hooks for common workflows
2. Include emergency stop mechanism
3. Document automation capabilities
4. Test with TODO-TRACKER integration

**Status**: ✅ Research complete. Ready for implementation planning.
