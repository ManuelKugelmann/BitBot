# Claude Code Command Execution Limitation

**Research Date:** 2025-10-27
**Context:** Investigating programmatic execution of Claude Code slash commands (`/compact`, `/clear`, `/exit`)

## Summary

**Finding:** Claude Code's TUI **cannot** execute slash commands programmatically via tmux or any other terminal automation method.

**Reason:** Claude Code uses raw keyboard input mode and distinguishes between:
- **Physical keyboard Return key** → Execute command
- **Any escape sequence** (`\n`, `\r`, `\r\n`, `C-m`, etc.) → New line (Shift+Enter behavior)

## Background

Built-in slash commands (`/compact`, `/clear`, `/exit`, etc.) cannot be executed via the SlashCommand tool - they are reserved for user interaction only. We investigated alternative approaches using tmux automation.

## Investigation Process

### Terminal Input Handling

Claude Code's input handling:
- **Enter** → Submit/execute command
- **Shift+Enter / Alt+Enter** → Insert newline (multiline input)
- **`\ + Enter`** → Quick escape for newline when keybindings not configured

**Escape Sequences:**
- Newline: `\u001B\u000A` (Escape + Linefeed)
- Standard: `\n`, `\r`, `\r\n`, `C-m` all interpreted as newline

### tmux Automation Attempts

All attempts to execute commands via tmux failed:

| Method | Command | Result |
|--------|---------|--------|
| `send-keys` with `Enter` | `tmux send-keys "/cost" Enter` | Typed literal "Enter" text |
| `send-keys` with `C-m` | `tmux send-keys "/cost" C-m` | Inserted newline, no execution |
| `send-keys` literal + `C-m` | `tmux send-keys -l "/cost"` + `C-m` | Inserted newline, no execution |
| `paste-buffer` with `\n` | Load `/cost\n`, paste | Inserted newline, no execution |
| `paste-buffer` with `\r` | Load `/cost\r`, paste | Inserted newline, no execution |
| `paste-buffer` with `-p` | Disable bracketed paste | Inserted newline, no execution |
| Separate sends with delays | Send `/`, `cost`, `C-m` separately | Inserted newline, no execution |

**Successful text injection:**
- `tmux send-keys -l "/cost"` → Text appears in input buffer ✓
- User manually presses Return → Command executes ✓

### Key Findings

1. **Bracketed Paste Mode:** tmux uses bracketed paste by default, wrapping pasted content in escape sequences. Even with `-p` flag to disable, execution still fails.

2. **Raw Keyboard Input:** Claude Code's TUI uses raw keyboard input mode, receiving actual key events rather than processed escape sequences.

3. **Newline vs Execute Distinction:** Any escape sequence (`\n`, `\r`, etc.) is interpreted as "insert newline" (Shift+Enter), not "execute command" (Return).

4. **Physical Key Requirement:** Only a physical Return key press triggers command execution.

## Technical Details

### Bracketed Paste Mode

When bracketed paste is enabled, terminals wrap pasted content in special sequences:
- Start: `\e[200~`
- Content: `<pasted text>`
- End: `\e[201~`

This allows applications to distinguish typed vs pasted content. Claude Code treats pasted newlines as literal newlines (Shift+Enter behavior).

### Terminal Input Layers

Two layers process terminal input:
1. **Shell** (bash, zsh, etc.) - processes commands when app not active
2. **Application** (Claude Code TUI) - intercepts input when active

Claude Code runs in application mode, intercepting all input before the shell sees it.

### Escape Sequence Handling

Standard terminal control sequences:
- `\n` (0x0A) - Line Feed (LF)
- `\r` (0x0D) - Carriage Return (CR)
- `\r\n` - CR+LF (Windows style)
- `C-m` - Control-M (same as CR)

All of these are **character data**, not keyboard events. Claude Code interprets them as Shift+Enter.

**Terminal Driver Translation (icrnl):**
On Unix systems, the terminal driver automatically translates incoming CR (0x0D) to LF (0x0A) via the `icrnl` flag. This means:
- Physical Return key: sends CR → terminal converts to LF → app receives LF
- Programmatic `\r`: sends CR → terminal converts to LF → app receives LF

Both produce identical character sequences at the application level, yet Claude Code still distinguishes between them. This suggests the distinction happens at a different layer (possibly application-level input state tracking).

## Workaround

**Text Injection Only:**
```bash
# Inject command text into input buffer
tmux send-keys -l "/compact"

# User must manually press Return to execute
```

This approach:
- ✓ Places command in input buffer
- ✓ Works reliably across platforms
- ✗ Requires manual Return key press
- ✗ Cannot fully automate execution

## Impact on BitBot

**Stop Hook Automation:** ✓ Works perfectly
- Uses `"decision": "block"` with reason
- No command execution required
- Fully automated workflow possible

**Context Management Tools:** ✗ Cannot work
- Cannot programmatically execute `/compact` or `/clear`
- Removed tools: `compact-context`, `clear-context`, `exit`
- Updated docs to recommend manual execution

**Recommended Approach:**
- Proactively **remind** users to run `/compact` or `/clear`
- Explain when to use each command
- Do NOT attempt programmatic execution

## Alternative Approaches Considered

### 1. Claude Code Wrapper with JSON Streams

**Concept:** Create wrapper around Claude Code that:
- Intercepts JSON input/output streams
- Injects commands programmatically
- Proxies between user and Claude Code

**Issues:**
- Hacky and fragile
- Breaks with Claude Code updates
- Requires reverse-engineering internal protocols
- Not officially supported

**Verdict:** ✗ Not recommended

### 2. Virtual Keyboard Input

**Concept:** Use platform-specific tools to simulate keyboard hardware events:
- Linux: `xdotool`, `ydotool`
- macOS: `cliclick`
- Windows: AutoHotKey, SendKeys

**Issues:**
- Platform-specific implementation
- Requires X11/Wayland access (may not work in headless)
- Window focus requirements
- Security implications
- Complex setup

**Verdict:** ✗ Too complex, not portable

### 3. Terminal Integration/Plugin

**Concept:** Request official API or plugin system from Anthropic

**Status:** Would require feature request to Claude Code team

**Verdict:** ⏳ Future possibility, not current solution

## Workaround for Regular Messages (Not Slash Commands)

**GitHub Issue #2929** documents a working approach for **inter-instance communication**:

```bash
# Send regular message to Claude Code instance
tmux send-keys -t <pane> "message text" Enter

# Poll for completion by checking "esc to interrupt" indicator
# Capture output with tmux capture-pane
```

**Key Finding After Extensive Testing:**
- ✅ **Regular messages CAN be entered reliably**: `tmux send-keys "message" Enter` - messages can be sent to Claude
- ❌ **Slash commands DON'T execute reliably**: `tmux send-keys "/compact" Enter` - unreliable, inconsistent behavior
- ✅ **Text injection works**: Messages/commands appear in input buffer
- ⚠️ **Slash command execution unreliable**: Works occasionally cross-session, but timing/state-dependent

**Root Cause:**
Claude Code's TUI distinguishes between:
- **Physical keyboard input** → Processes and executes
- **Programmatic injection via tmux** → Displays text only, no processing

This is likely intentional security/design - the TUI only responds to actual user interaction, not programmatic input injection.

**Cross-Session Testing Results:**
Tested sending commands from one tmux session to another Claude Code instance:
- **First attempt (session 5)**: `/cost` executed successfully ✅
- **Second attempt (session 5)**: `/cost` appeared as text only ❌
- **Active session (session 8)**: All attempts failed ❌
- **Self-send (session 7)**: Failed ❌

**Conclusion on Cross-Session Control:** Even cross-session command execution is **unreliable**:
- Timing-dependent behavior
- State-dependent (active vs inactive session)
- Inconsistent results (works once, fails next time)
- No guarantee of execution

**Note:** Issue #2929's "workaround" may work occasionally for cross-session control, but is not reliable enough for production automation. The inconsistent behavior makes it unsuitable for BitBot's automation needs.

## Conclusion

**Regular messages can be reliably sent via tmux**, enabling cross-instance communication (one Claude coordinating another). However, **slash commands cannot be reliably executed** - they work occasionally cross-session but with timing/state-dependent behavior unsuitable for automation.

For BitBot's automation needs (specifically `/compact` and `/clear` execution), tmux-based approaches are not viable.

**What Works:**
- ✅ **Stop hooks with block decision** - DONOTSTOP pattern for automated workflows
- ✅ **Text injection for convenience** - Places text in input buffer (user must press Enter)
- ✅ **Proactive reminders** - Claude reminds users to run `/compact` or `/clear` manually
- ✅ **Regular message injection** - Can reliably send messages to Claude instances via tmux
- ✅ **Cross-instance messaging** - One Claude can send tasks to another Claude (using regular messages, not slash commands)

**What Doesn't Work:**
- ❌ **Slash command automation** - Unreliable execution even cross-session
- ❌ **Slash command cross-session** - Works occasionally but timing/state-dependent, not suitable for automation
- ❌ **Self-execution** - Cannot send commands to own session programmatically

**Recommendation:** The DONOTSTOP Stop hook is the correct and only automation solution for BitBot. It works at the protocol level without requiring input simulation.

## References

- [Claude Code Terminal Config](https://docs.claude.com/en/docs/claude-code/terminal-config.md)
- [Shift+Enter Issue #2754](https://github.com/anthropics/claude-code/issues/2754)
- [Programmatic Control Issue #2929](https://github.com/anthropics/claude-code/issues/2929) - tmux workaround discussion
- [Parallel Task Management Issue #4963](https://github.com/anthropics/claude-code/issues/4963) - Multi-agent orchestration
- [tmux paste-buffer discussion #4098](https://github.com/orgs/tmux/discussions/4098)
- [BitBot DONOTSTOP Hook](/.claude/hooks/donotstop.sh)
