# Future: tmux-based Interactive CLI Tool

**Reference:** [GitHub Issue #2929, Comment #3149504677](https://github.com/anthropics/claude-code/issues/2929#issuecomment-3149504677)

## Concept

Create tmux-based tool for interactive CLI use with Claude Code, potentially enabling programmatic instance control.

## Key Insight

**Testing approach:** "Try a command that expects input"

If a command requires user input (interactive prompt), we can detect whether Claude Code actually processed the command by observing:
- Whether it's waiting for input
- Whether a prompt appears
- Whether the state changes from "ready" to "waiting for input"

## Potential Implementation

```bash
tell_claude() {
    local pane="$1"
    local message="$2"

    # Send message via tmux
    tmux send-keys -t "$pane" "$message" Enter

    # Wait for "esc to interrupt" indicator (Claude is processing)
    while ! tmux capture-pane -t "$pane" -p | grep -q "esc to interrupt"; do
        sleep 0.1
    done

    # Wait for indicator to disappear (processing complete)
    while tmux capture-pane -t "$pane" -p | grep -q "esc to interrupt"; do
        sleep 0.1
    done

    # Capture output
    tmux capture-pane -t "$pane" -p
}
```

## Testing Strategy

**Commands to test:**
1. **Interactive commands** that expect input:
   - `read -p "Enter something: " var` (bash)
   - Python script with `input()` call
   - Any command that blocks waiting for stdin

2. **Observation:**
   - If Claude processes command → will see prompt/waiting state
   - If Claude doesn't process → no state change, command appears as text

## Use Cases

If this approach works:

### Multi-Instance Orchestration
- One Claude instance coordinates multiple worker instances
- Send tasks to workers via tmux send-keys
- Poll for completion via capture-pane
- Collect results

### Specialist Agent Networks
- Generalist Claude dispatches to specialist Claudes
- Each specialist runs in separate tmux pane
- Natural language task routing between instances

### Remote Control
- Script-driven Claude Code automation
- Batch processing of multiple tasks
- Parallel execution across instances

## Current Status

**TESTED (October 2025)** - Results:
- ✅ **Regular messages work reliably** - Can send messages to Claude instances via tmux
- ❌ **Slash commands unreliable** - Work occasionally but timing/state-dependent
- ✅ **Cross-instance communication viable** - One Claude can coordinate others using regular messages
- ❌ **Slash command automation not viable** - Too unreliable for production use

## Key Findings

**Regular messages vs Slash commands:**
- **Regular messages**: Reliably entered and processed ✅
- **Slash commands**: Unreliable execution (timing/state-dependent) ❌
- **Interactive commands**: Not separately tested, but regular message approach works
- **State changes**: Can be detected via tmux capture-pane polling

## Future Work

1. Test with commands that expect input
2. Observe whether Claude Code state changes
3. If it works, develop `tell_claude()` wrapper function
4. Build multi-instance orchestration tools
5. Consider integration with BitBot's git worktree workflow

## Implementation Considerations

**If this works:**
- Create `.claude/tools/tell-claude` for sending messages to other instances
- Document the polling pattern for detecting completion
- Integrate with git worktree-based multi-agent workflows

**If this doesn't work:**
- Confirms that NO programmatic execution is possible
- DONOTSTOP hook remains the only automation approach
- Multi-instance orchestration would require manual coordination

## References

- [Issue #2929](https://github.com/anthropics/claude-code/issues/2929) - Programmatic instance control
- [Comment #3149504677](https://github.com/anthropics/claude-code/issues/2929#issuecomment-3149504677) - Interactive command testing approach
- [Issue #4963](https://github.com/anthropics/claude-code/issues/4963) - Parallel task management
- [CLAUDE_CODE_COMMAND_EXECUTION_LIMITATION.md](./CLAUDE_CODE_COMMAND_EXECUTION_LIMITATION.md) - Current findings
