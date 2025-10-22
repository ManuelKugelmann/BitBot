# tmux Configuration for BitBot

BitBot containers include tmux configured with mouse mode and frameless display for a clean, interactive terminal experience.

## Configuration

All BitBot containers (work and config modes) come with tmux pre-configured:

**Location**: `/etc/tmux.conf` (global, applies to all users)

**Settings**:
```bash
set -g mouse on                         # Enable mouse scrolling
set -g history-limit 10000              # Increase history buffer
set -g status off                       # Hide status bar
set -g default-terminal "screen-256color"
```

## Features

### ✅ Mouse Mode Scrolling
- **Scroll with mouse wheel** - Works directly in tmux, no setup needed
- Scroll history preserved (10,000 lines)
- Click to position cursor
- Drag to select text for copying

### ✅ Frameless Display
- No status bar at bottom
- Clean, minimal appearance
- Maximum screen space for output
- Terminal looks like a standard shell

### ✅ Copy Mode (Alternative)
For keyboard-only scrolling:
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
# Example: Show status bar for this user
cat > ~/.tmux.conf << EOF
set -g status on
EOF

# Reload
tmux source-file ~/.tmux.conf
```

## Why These Settings?

**Mouse on**: Enables intuitive scroll wheel scrolling directly in tmux without relying on terminal emulator behavior

**Status bar off**: Claude Code and other AI assistants provide their own UI; tmux status adds visual clutter and takes up screen space

**Large history**: AI coding sessions generate lots of output; 10K lines ensures context isn't lost

## Technical Details

**Template files**:
- `templates/base/Dockerfile` - Work mode template
- `templates/config/Dockerfile` - Config mode template

Both install tmux and configure `/etc/tmux.conf` during image build.

**tmux version**: Uses Ubuntu 22.04's default tmux (3.2a+)

**Compatibility**: Works with all standard terminal emulators (Windows Terminal, iTerm2, GNOME Terminal, etc.)
