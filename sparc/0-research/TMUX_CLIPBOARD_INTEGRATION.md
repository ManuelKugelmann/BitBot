# tmux Clipboard Integration

## Overview

By default, tmux mouse selections (drag, double-click word, triple-click line) only copy to tmux's internal buffer, not the system clipboard. This research documents how to integrate tmux with the system clipboard using `copy-pipe-and-cancel`.

## Problem

When using mouse to select text in tmux:
- **Drag selection**: Copies to tmux buffer only
- **Double-click**: Word selection → tmux buffer only
- **Triple-click**: Line selection → tmux buffer only
- **Right-click paste**: Requires `C-]` binding or terminal passthrough

Users expect selections to automatically copy to system clipboard for use outside tmux.

## Solution: copy-pipe-and-cancel

tmux provides `copy-pipe-and-cancel` to pipe selected text to external commands:

```bash
send-keys -X copy-pipe-and-cancel "command"
```

**Behavior:**
- Copies selection to tmux buffer
- Pipes text to external command
- Exits copy mode automatically

## Cross-Platform Clipboard Tools

Different platforms use different clipboard commands:

| Platform      | Command                                | Package        |
| ------------- | -------------------------------------- | -------------- |
| Windows/WSL   | `clip.exe`                             | Built-in       |
| Linux (X11)   | `xclip -i -selection clipboard`        | `xclip`        |
| macOS         | `pbcopy`                               | Built-in       |
| Wayland       | `wl-copy`                              | `wl-clipboard` |

## Implementation

### Platform Detection Chain

```bash
if command -v clip.exe >/dev/null 2>&1; then
    clip.exe
elif command -v xclip >/dev/null 2>&1; then
    xclip -i -selection clipboard
elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy
elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
else
    cat  # Fallback: no-op
fi
```

### Mouse Selection Bindings

**Drag selection:**
```bash
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "..."
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "..."
```

**Double-click (word selection):**
```bash
bind-key -T copy-mode DoubleClick1Pane select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "..."
bind-key -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "..."
```

**Triple-click (line selection):**
```bash
bind-key -T copy-mode TripleClick1Pane select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "..."
bind-key -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "..."
```

**Note:** `run-shell -d 0.3` adds 300ms delay for word/line selection visibility before copy mode exits.

## Trade-offs

### Pros
- **Seamless workflow**: Select → auto-copy to system clipboard
- **Cross-platform**: Works on Windows/WSL, Linux, macOS
- **Consistent UX**: Matches native terminal behavior

### Cons
- **Dependencies**: Requires clipboard tools installed (`xclip`, `wl-clipboard`)
- **Security**: Clipboard accessible to any application
- **Complexity**: Longer configuration, platform-specific logic
- **Privacy**: Selections auto-copied even if unintended

### Performance
- Minimal overhead: clipboard tools execute quickly (<10ms)
- Potential issue: Large selections may block briefly

## Alternatives

### 1. Manual Copy (Default)
**Approach:** Use tmux buffer, paste with `C-]` or `prefix + ]`

**Pros:**
- No dependencies
- Explicit control over clipboard
- Works everywhere

**Cons:**
- Extra steps required
- tmux-only (can't paste outside tmux)

### 2. Terminal OSC 52 (Clipboard Escape Sequences)
**Approach:** Terminal emulator handles clipboard via OSC 52 escape codes

**Pros:**
- Works remotely over SSH
- No external tools needed
- Integrated into terminal

**Cons:**
- Requires terminal support (Windows Terminal, iTerm2, Alacritty)
- Not universally supported
- Configuration varies by terminal

**Example:**
```bash
set -g set-clipboard on  # Let terminal handle clipboard via OSC 52
```

### 3. Right-Click Paste Passthrough
**Approach:** Unbind right-click in tmux, let terminal handle paste

**Pros:**
- Native terminal paste behavior
- No configuration needed
- Simple

**Cons:**
- Only for paste, not copy
- Selection still requires external binding

**Example:**
```bash
unbind-key -n MouseDown3Pane  # Allow terminal right-click menu
```

## Recommendation for BitBot

**Current approach:** Right-click passthrough only

```bash
set -g mouse on
unbind-key -n MouseDown3Pane  # Terminal handles right-click paste
```

**Rationale:**
- **Simplicity**: No dependencies, works everywhere
- **Native behavior**: Terminal emulators provide native copy/paste
- **Flexibility**: Users can customize per-workspace if needed
- **Privacy**: Explicit control, no auto-copying

**For users wanting auto-copy:** Document clipboard integration in research, let users add to workspace-specific `~/.tmux.conf` overrides if desired.

## Future Consideration

If auto-clipboard becomes common user request:
1. Add as optional feature with documentation
2. Detect clipboard tools during container build
3. Provide workspace-specific override template
4. Document trade-offs clearly

## References

- tmux manual: `man tmux` (search for `copy-pipe`)
- OSC 52: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
- xclip: https://github.com/astrand/xclip
- wl-clipboard: https://github.com/bugaevc/wl-clipboard
