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

## Conclusion

**Programmatic execution of Claude Code slash commands is not possible** with current architecture. The TUI's raw keyboard input mode is a deliberate design choice that prevents automation while enabling rich multiline input handling.

**Recommendation:** Focus on automation patterns that work within this constraint:
- ✓ Stop hooks with block decision
- ✓ Proactive reminders to users
- ✓ Text injection for convenience
- ✗ Full command execution automation

## References

- [Claude Code Terminal Config](https://docs.claude.com/en/docs/claude-code/terminal-config.md)
- [Shift+Enter Issue #2754](https://github.com/anthropics/claude-code/issues/2754)
- [tmux paste-buffer discussion #4098](https://github.com/orgs/tmux/discussions/4098)
- [BitBot DONOTSTOP Hook](.claude/hooks/donotstop.sh)
