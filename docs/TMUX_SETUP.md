# tmux Configuration for BitBot

BitBot containers include a frameless tmux configuration for a clean, minimal terminal experience.

## Configuration

All BitBot containers (work and config modes) come with tmux pre-configured:

**Location**: `/etc/tmux.conf` (global, applies to all users)

**Settings**:
```bash
set -g status off                       # No status bar
set -g pane-border-status off           # No border status
set -g mouse off                        # Let terminal scrollbar work
set -g history-limit 10000              # Increase history buffer
set -g default-terminal "screen-256color"
```

## Features

### ✅ Frameless Display
- No status bar at bottom
- No visible pane borders
- Clean, minimal appearance
- Terminal looks like a standard shell

### ✅ Native Scrolling
- **Use your terminal's scrollbar** (mouse wheel, trackpad, scrollbar)
- tmux mouse mode is **disabled** to allow terminal's native scrolling
- Scroll history preserved (10,000 lines)

### ✅ tmux Scroll Mode (Alternative)
If your terminal scrollbar doesn't work:
1. `Ctrl+b` then `[` - Enter copy mode
2. Use arrow keys, `PgUp`/`PgDn` to navigate
3. `q` or `Esc` - Exit copy mode

## Usage

### Start tmux Session
```bash
# Simple session
tmux

# Named session
tmux new -s mysession

# Resume session
tmux attach -t mysession
```

### Temporary Status Bar (Optional)
```bash
# Show status bar temporarily
Ctrl+b :set status on

# Hide again
Ctrl+b :set status off
```

### User Override
Users can override global settings with `~/.tmux.conf`:

```bash
# Example: Enable mouse mode for this user
cat > ~/.tmux.conf << EOF
set -g mouse on
EOF

# Reload
tmux source-file ~/.tmux.conf
```

## Why These Settings?

**Status bar off**: Claude Code and other AI assistants provide their own UI; tmux status adds visual clutter

**Mouse off**: Allows terminal's native scrolling which is more familiar and works consistently across all terminals

**No borders**: Single-pane workflows don't need visible borders; multi-pane users can see boundaries from content

**Large history**: AI coding sessions generate lots of output; 10K lines ensures context isn't lost

## Technical Details

**Template files**:
- `templates/base/Dockerfile` - Work mode template
- `templates/config/Dockerfile` - Config mode template

Both install tmux and configure `/etc/tmux.conf` during image build.

**tmux version**: Uses Ubuntu 22.04's default tmux (3.2a+)

**Compatibility**: Works with all standard terminal emulators (Windows Terminal, iTerm2, GNOME Terminal, etc.)
