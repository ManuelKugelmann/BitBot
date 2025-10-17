# Terminal Session Management and Persistence Patterns

## Executive Summary

This report provides a comprehensive analysis of terminal multiplexer options (tmux, GNU screen, zellij), session persistence strategies, automation patterns, container integration best practices, and history management for implementing resumable terminal sessions in containerized environments like BitBot.

---

## 1. Terminal Multiplexer Comparison

### 1.1 Overview

| Feature | tmux | GNU screen | zellij |
|---------|------|------------|--------|
| **Language** | C | C | Rust |
| **First Release** | 2007 | 1987 | 2020 |
| **Binary Size** | ~900 KiB | Small | ~38 MiB |
| **Learning Curve** | Steep | Steep | Gentle |
| **Ecosystem** | Extensive | Mature | Growing |
| **Plugin System** | TPM (robust) | Limited | WASM-based |
| **Default UX** | Power user focused | Power user focused | Beginner friendly |
| **Configuration** | Complex but flexible | Complex | YAML-based, simpler |
| **Memory Efficiency** | Good | Good | Excellent |

### 1.2 tmux

**Strengths:**
- Battle-tested workhorse with 18+ years of development
- Extensive ecosystem with hundreds of plugins
- Deep integration with tools (fzf, vim, etc.)
- Universal compatibility across Unix systems
- Available in all major package repositories
- Comprehensive scripting capabilities
- Rich automation tools (tmuxinator, tmuxp, smug)
- Excellent documentation and community support

**Weaknesses:**
- Steep learning curve requiring memorization of keybindings
- Poor discoverability - no built-in help
- Requires significant configuration for optimal UX
- Complex config syntax

**Best For:**
- Production environments requiring stability
- Complex automation workflows
- Integration with existing tooling
- Users who value ecosystem depth over immediate productivity

### 1.3 GNU screen

**Strengths:**
- Oldest and most universally available (since 1987)
- Extremely stable and well-tested
- Minimal dependencies
- Simple and predictable behavior
- Works on ancient systems

**Weaknesses:**
- Limited features compared to modern alternatives
- No plugin system
- Dated architecture
- Less active development
- Fewer layout options

**Best For:**
- Legacy systems
- Minimal environments
- Simple use cases
- Users who need absolute stability

### 1.4 zellij

**Strengths:**
- Modern user experience with intuitive defaults
- Built-in keybinding hints and contextual help
- Productive within minutes - no configuration required
- Pre-defined layouts for quick setup
- YAML-based layout configuration
- Efficient memory management
- WebAssembly plugin system (innovative)
- Built-in session navigation UI
- Native session resurrection

**Weaknesses:**
- Younger project with smaller ecosystem
- Large binary size (38 MiB vs tmux's 900 KiB)
- Less mature tooling
- Fewer third-party integrations
- Plugin system currently limited to Rust

**Best For:**
- Modern development environments
- Users prioritizing UX over ecosystem
- Rapid onboarding scenarios
- Projects where binary size is not a concern

### 1.5 Recommendation for BitBot

**Primary Choice: tmux**

For BitBot's containerized environment, tmux is recommended because:

1. **Ecosystem Maturity**: Extensive plugin ecosystem and automation tools
2. **Container Integration**: Well-documented patterns for Docker/container use
3. **Persistence Solutions**: Mature plugins (tmux-resurrect, tmux-continuum)
4. **Scripting**: Robust automation via tmuxinator, tmuxp, or bash scripts
5. **Community Support**: Large knowledge base for troubleshooting
6. **Small Footprint**: Important for container image sizes
7. **Universal Availability**: Users likely already familiar with tmux

**Alternative: zellij** (if UX is prioritized over ecosystem)

Consider zellij if:
- User onboarding speed is critical
- Binary size is not a concern
- Built-in session resurrection is preferred
- Modern UX is valued over plugin ecosystem

---

## 2. Session Persistence and Resumability

### 2.1 tmux Session Persistence

#### Problem Statement

tmux sessions are stored in operating system memory and are lost when:
- System reboots
- Container restarts
- tmux server crashes
- System crashes

#### Solution: tmux-resurrect

**What it saves:**
- All sessions, windows, and panes with their order
- Current working directory for each pane
- Precise pane layouts within windows (including zoom state)
- Active and alternative sessions
- Active and alternative windows for each session
- Window focus state
- Active panes within each window
- Programs running within panes (configurable list)

**What it does NOT save:**
- Actual terminal content (scrollback buffer)
- Program state/memory
- Network connections
- File descriptors

**Default Restored Programs:**
```
vi vim nvim emacs man less more tail top htop irssi weechat mutt
```

**Installation via TPM:**
```bash
# In ~/.tmux.conf
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Restore vim sessions (optional)
set -g @resurrect-strategy-vim 'session'
# Restore neovim sessions (optional)
set -g @resurrect-strategy-nvim 'session'
# Restore pane contents (experimental)
set -g @resurrect-capture-pane-contents 'on'
```

**Usage:**
- **Save**: `prefix + Ctrl-s`
- **Restore**: `prefix + Ctrl-r`

**Data Storage:**
```
~/.tmux/resurrect/
├── last -> tmux_resurrect_20231015T120000.txt
├── tmux_resurrect_20231015T120000.txt
├── tmux_resurrect_20231015T130000.txt
└── ...
```

#### Solution: tmux-continuum

**Automated persistence layer built on tmux-resurrect.**

**Features:**
- Continuous automatic saving (every 15 minutes by default)
- Automatic restoration on tmux start
- Background operation with zero user intervention
- Configurable save interval

**Installation via TPM:**
```bash
# In ~/.tmux.conf
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Enable automatic restore
set -g @continuum-restore 'on'

# Change save interval (default: 15 minutes)
set -g @continuum-save-interval '10'

# Enable boot start (systemd)
set -g @continuum-boot 'on'
```

**Boot Integration:**
```bash
# systemd service example
# ~/.config/systemd/user/tmux.service
[Unit]
Description=tmux default session (detached)
Documentation=man:tmux(1)

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d -s default
ExecStop=/usr/bin/tmux kill-session -t default
Restart=on-failure

[Install]
WantedBy=default.target
```

### 2.2 zellij Session Persistence

**Built-in Session Resurrection** (native feature as of v0.39.0)

**Configuration:**
```kdl
// In ~/.config/zellij/config.kdl

// Enable session serialization (default: true)
session_serialization true

// Serialize pane viewport (visible content)
pane_viewport_serialization true

// How many scrollback lines to serialize (0 = all)
scrollback_lines_to_serialize 10000
```

**What Gets Serialized:**
- Session layout (panes and tabs)
- Commands running in each pane
- Pane viewport (when enabled)
- Scrollback history (configurable)
- Working directories

**Behavior:**
- Automatic serialization every 1 second
- Saved to system cache folder
- Resumption via `zellij attach <session-name>`
- Safety feature: Commands show "Press ENTER to run..." banner
- Override with `--force-run-commands` flag

**Data Storage:**
```
# Linux
~/.cache/zellij/

# macOS
~/Library/Caches/zellij/
```

**Usage:**
```bash
# Create or attach to session
zellij attach my-session

# Resurrect with forced command execution
zellij attach my-session --force-run-commands

# List sessions (including exited/resurrectable)
zellij list-sessions
```

### 2.3 GNU screen Session Persistence

**Native Detach/Reattach:**

screen has built-in session persistence through detach/reattach mechanism:

```bash
# Detach from session
Ctrl-a d

# List sessions
screen -ls

# Reattach to session
screen -r [session-name]

# Force detach and reattach (if attached elsewhere)
screen -d -r [session-name]

# More aggressive reattach
screen -D -RR  # Detach and logout remote, then attach
```

**Auto-detach:**
- Screen automatically detaches on hangup (configurable)
- Sessions persist until explicitly killed or system reboot

**Limitations:**
- No built-in state serialization to disk
- Sessions lost on system reboot
- No built-in plugin for disk-based persistence
- Manual scripting required for full restoration

### 2.4 Persistence Patterns for Containers

#### Challenge

Containers are ephemeral by design. When a container stops:
- All in-memory data is lost
- Terminal multiplexer sessions disappear
- Running processes are terminated

#### Solution Pattern 1: Volume-Mounted Session Data

**For tmux:**
```dockerfile
# Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y tmux git

# Install TPM and plugins
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Copy tmux configuration
COPY tmux.conf /root/.tmux.conf

# Install plugins automatically
RUN ~/.tmux/plugins/tpm/bin/install_plugins

# Volume for persistent session data
VOLUME ["/root/.tmux/resurrect"]

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

**entrypoint.sh:**
```bash
#!/bin/bash

# Start tmux server in background if not running
if ! tmux has-session 2>/dev/null; then
    # Attempt to restore previous session
    tmux new-session -d -s default
    tmux send-keys -t default "echo 'Session restored. Press prefix + Ctrl-r to restore layout.'" C-m
fi

# Keep container alive
exec "$@"
```

**docker-compose.yml:**
```yaml
services:
  bitbot:
    build: .
    volumes:
      - tmux-sessions:/root/.tmux/resurrect
    command: tail -f /dev/null  # Keep alive
    stdin_open: true
    tty: true

volumes:
  tmux-sessions:
```

**Usage:**
```bash
# Attach to container and tmux session
docker exec -it bitbot tmux attach -t default

# Or use new-session with -A flag (attach if exists)
docker exec -it bitbot tmux new-session -A -s default
```

#### Solution Pattern 2: Automatic Session Recreation

**entrypoint.sh with auto-restore:**
```bash
#!/bin/bash

# Function to setup tmux session
setup_tmux_session() {
    local session_name="${1:-default}"

    # Check if session data exists
    if [ -f ~/.tmux/resurrect/last ]; then
        echo "Restoring previous session..."
        tmux new-session -d -s "$session_name"
        # Give tmux time to start
        sleep 1
        # Trigger restore
        tmux send-keys -t "$session_name" "" C-m
        # Wait for potential restore
        sleep 2
    else
        echo "Creating new session..."
        tmux new-session -d -s "$session_name"
    fi
}

# Ensure tmux server is running
if ! tmux has-session 2>/dev/null; then
    setup_tmux_session "workspace"
fi

# Execute main container command
exec "$@"
```

#### Solution Pattern 3: Workspace-Specific Sessions

```bash
#!/bin/bash
# workspace-session.sh

WORKSPACE_NAME="${WORKSPACE_NAME:-default}"
SESSION_NAME="ws-${WORKSPACE_NAME}"

# Attach to existing session or create new one
tmux new-session -A -s "$SESSION_NAME" -c "/workspace/${WORKSPACE_NAME}"
```

**docker-compose.yml:**
```yaml
services:
  bitbot:
    build: .
    environment:
      - WORKSPACE_NAME=${USER}-dev
    volumes:
      - ./workspace:/workspace
      - tmux-data:/root/.tmux/resurrect
    command: /workspace-session.sh
```

---

## 3. Multi-Session Orchestration

### 3.1 Session Management Patterns

#### Creating Named Sessions

**tmux:**
```bash
# Create new named session
tmux new-session -s my-project

# Create detached session
tmux new-session -d -s background-job

# Attach to existing or create new (idiomatic)
tmux new-session -A -s my-project

# Force detach others and attach
tmux new-session -AD -s my-project
```

**zellij:**
```bash
# Create new named session
zellij -s my-project

# Create detached session
zellij --session my-project

# Attach to existing or create
zellij attach my-project

# Attach with options
zellij attach my-project --force-run-commands
```

**screen:**
```bash
# Create new named session
screen -S my-project

# Create detached session
screen -dmS my-project

# Reattach or create (idiom)
screen -D -RR -S my-project
```

#### Listing Sessions

**tmux:**
```bash
# List all sessions
tmux list-sessions
tmux ls

# Formatted output
tmux list-sessions -F "#{session_name}: #{session_windows} windows (created #{session_created_string})"

# From within tmux
prefix + s  # Interactive session list
```

**zellij:**
```bash
# List sessions
zellij list-sessions
zellij ls

# Shows running AND exited sessions
```

**screen:**
```bash
# List sessions
screen -ls
screen -list

# Shows attached and detached sessions
```

#### Killing Sessions

**tmux:**
```bash
# Kill specific session
tmux kill-session -t my-project

# Kill all except current
tmux kill-session -a

# Kill all except specific
tmux kill-session -a -t my-project

# Kill server (all sessions)
tmux kill-server
```

### 3.2 Session Selection UIs

#### Using fzf with tmux

**Basic Session Switcher:**
```bash
# Add to ~/.tmux.conf
bind-key C-j display-popup -E "\
    tmux list-sessions -F '#{?session_attached,,#{session_name}}' |\
    sed '/^$/d' |\
    fzf --reverse --header jump-to-session --preview 'tmux capture-pane -pt {}' |\
    xargs tmux switch-client -t"
```

**Advanced Switcher with Preview:**
```bash
# Session switcher with detailed preview
bind-key C-s split-window -v "\
    tmux list-sessions -F '#S: #{session_windows} windows #{?session_attached,(attached),}' |\
    fzf --reverse \
        --header 'Select session' \
        --preview 'tmux list-windows -t {1} -F \"#{window_index}: #{window_name} (#{window_panes} panes)\"' \
        --preview-window=right:60% |\
    cut -d: -f1 |\
    xargs tmux switch-client -t"
```

**Popup-Based Switcher (tmux 3.2+):**
```bash
# Modern popup interface
bind-key C-j display-popup -E -w 80% -h 60% "\
    tmux list-sessions -F '#{session_name}' |\
    fzf --reverse \
        --header 'Switch Session' \
        --preview 'tmux capture-pane -ep -t {}' \
        --preview-window=down:70% |\
    xargs tmux switch-client -t"
```

**Script-Based Solution:**
```bash
#!/bin/bash
# ~/.local/bin/tmux-session-picker

sessions=$(tmux list-sessions -F "#{session_name}")
current=$(tmux display-message -p "#{session_name}")

# Filter out current session
sessions=$(echo "$sessions" | grep -v "^${current}$")

if [ -z "$sessions" ]; then
    echo "No other sessions to switch to"
    exit 0
fi

selected=$(echo "$sessions" | fzf \
    --reverse \
    --header="Current: $current" \
    --preview="tmux list-windows -t {} -F '#{window_index}: #{window_name} - #{pane_current_command}'" \
    --preview-window=right:50%)

if [ -n "$selected" ]; then
    tmux switch-client -t "$selected"
fi
```

**Bind in tmux.conf:**
```bash
bind-key C-j run-shell "tmux display-popup -E ~/.local/bin/tmux-session-picker"
```

#### Using tmux-fzf Plugin

```bash
# In ~/.tmux.conf
set -g @plugin 'sainnhe/tmux-fzf'

# Bind to prefix + F
set -g @tmux-fzf-launch-key 'F'

# Features:
# - Fuzzy search sessions
# - Preview windows and panes
# - Multiple selection support
# - Session/window/pane management
```

#### Native tmux Menu (No Dependencies)

```bash
# Session menu
bind-key S display-menu -T "Sessions" \
    "New Session" n "command-prompt -p 'New session name:' 'new-session -s \"%%\"'" \
    "Kill Session" k "confirm-before -p 'Kill session #S? (y/n)' kill-session" \
    "" \
    "Session 1" 1 "switch-client -t session1" \
    "Session 2" 2 "switch-client -t session2"
```

#### zellij Built-in Session UI

```bash
# Within zellij, press Ctrl+o then 'w' for session manager
# Features:
# - Visual session list
# - Arrow key navigation
# - Enter to switch
# - Create new sessions
# - No external dependencies
```

### 3.3 Session Naming Conventions

**Recommended Patterns:**

```bash
# Project-based
project-api
project-frontend
project-database

# User-workspace based
user-john-dev
user-john-debug

# Task-based
feature-auth-implementation
bugfix-payment-gateway
review-pr-1234

# Environment-based
dev-local
staging-test
prod-monitor

# Combined approach
myproject-dev-api
myproject-staging-frontend
```

---

## 4. Automation and Scripting

### 4.1 Shell Script Automation

#### Basic Session Creation Script

```bash
#!/bin/bash
# create-dev-session.sh

SESSION_NAME="dev"

# Check if session exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
    # Create session
    tmux new-session -d -s "$SESSION_NAME" -n "editor"

    # First window: editor
    tmux send-keys -t "$SESSION_NAME:editor" "cd ~/project && nvim" C-m

    # Second window: server
    tmux new-window -t "$SESSION_NAME" -n "server"
    tmux send-keys -t "$SESSION_NAME:server" "cd ~/project && npm run dev" C-m

    # Third window: shell
    tmux new-window -t "$SESSION_NAME" -n "shell"
    tmux send-keys -t "$SESSION_NAME:shell" "cd ~/project" C-m

    # Split shell window
    tmux split-window -h -t "$SESSION_NAME:shell"
    tmux send-keys -t "$SESSION_NAME:shell.1" "cd ~/project && git status" C-m

    # Select first window
    tmux select-window -t "$SESSION_NAME:editor"
fi

# Attach to session
tmux attach-session -t "$SESSION_NAME"
```

#### Advanced Multi-Pane Layout

```bash
#!/bin/bash
# complex-layout.sh

SESSION_NAME="workspace"

# Create session with first window
tmux new-session -d -s "$SESSION_NAME" -n "main" -x "$(tput cols)" -y "$(tput lines)"

# Window 1: Main development (3 panes)
tmux send-keys -t "$SESSION_NAME:main" "cd ~/project" C-m

# Split horizontally (top/bottom)
tmux split-window -v -t "$SESSION_NAME:main" -p 30
tmux send-keys -t "$SESSION_NAME:main.1" "cd ~/project && git status" C-m

# Split bottom pane vertically (left/right)
tmux split-window -h -t "$SESSION_NAME:main.1"
tmux send-keys -t "$SESSION_NAME:main.2" "cd ~/project && npm run test -- --watch" C-m

# Select top pane
tmux select-pane -t "$SESSION_NAME:main.0"

# Window 2: Server
tmux new-window -t "$SESSION_NAME" -n "server"
tmux send-keys -t "$SESSION_NAME:server" "cd ~/project && npm run dev" C-m

# Window 3: Database
tmux new-window -t "$SESSION_NAME" -n "database"
tmux send-keys -t "$SESSION_NAME:database" "docker compose up database" C-m

# Window 4: Logs (split view)
tmux new-window -t "$SESSION_NAME" -n "logs"
tmux send-keys -t "$SESSION_NAME:logs" "tail -f /var/log/app.log" C-m
tmux split-window -v -t "$SESSION_NAME:logs"
tmux send-keys -t "$SESSION_NAME:logs.1" "docker compose logs -f" C-m

# Return to main window
tmux select-window -t "$SESSION_NAME:main"

# Attach
tmux attach-session -t "$SESSION_NAME"
```

#### Idempotent Session Script

```bash
#!/bin/bash
# idempotent-session.sh

SESSION_NAME="${1:-default}"

# Attach if exists, create if doesn't
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Creating new session: $SESSION_NAME"

    # Create session
    tmux new-session -d -s "$SESSION_NAME"

    # Setup windows
    tmux rename-window -t "$SESSION_NAME:0" "shell"
    tmux new-window -t "$SESSION_NAME" -n "editor"
    tmux new-window -t "$SESSION_NAME" -n "server"

    # Select first window
    tmux select-window -t "$SESSION_NAME:0"
fi

# Attach (detach others if needed)
tmux attach-session -t "$SESSION_NAME"
```

### 4.2 Tmuxinator

**YAML-Based Session Management**

**Installation:**
```bash
# Using gem
gem install tmuxinator

# Or with package manager
# Ubuntu/Debian
sudo apt install tmuxinator

# macOS
brew install tmuxinator
```

**Configuration:**
```bash
# Create new project config
tmuxinator new myproject

# Edit existing project
tmuxinator edit myproject

# Config location
~/.config/tmuxinator/myproject.yml
```

**Example Configuration:**
```yaml
# ~/.config/tmuxinator/myproject.yml

name: myproject
root: ~/projects/myproject

# Pre-commands (before windows created)
pre_window: export RAILS_ENV=development

# Windows configuration
windows:
  - editor:
      layout: main-vertical
      panes:
        - nvim
        - guard

  - server:
      panes:
        - npm run dev

  - database:
      panes:
        - docker compose up database

  - shell:
      layout: even-horizontal
      panes:
        - # Empty pane
        - git status
        - npm run test -- --watch

  - logs:
      layout: tiled
      panes:
        - tail -f log/development.log
        - tail -f log/test.log
```

**Advanced Features:**
```yaml
# ~/.config/tmuxinator/advanced.yml

name: advanced
root: ~/project

# Pre-start commands (before tmux)
pre:
  - docker compose up -d database
  - sleep 3

# Post-start commands (after everything)
post:
  - tmux send-keys -t advanced:server "npm run dev" C-m

startup_window: editor
startup_pane: 0

windows:
  - editor:
      layout: main-horizontal
      panes:
        - nvim
        - # Bottom pane stays empty

  - server:
      # Manual layout using dimensions
      layout: |
        ae14,211x50,0,0{105x50,0,0,3,105x50,106,0,4}
      panes:
        - # Server will start via post command
        - tail -f logs/server.log

  - monitoring:
      layout: tiled
      panes:
        - htop
        - docker stats
        - watch -n 1 df -h
        - nethogs
```

**Usage:**
```bash
# Start project
tmuxinator start myproject
tmuxinator s myproject

# Start with override root
tmuxinator start myproject root=/different/path

# List projects
tmuxinator list
tmuxinator l

# Delete project
tmuxinator delete myproject

# Stop project (kill session)
tmuxinator stop myproject

# Debug configuration
tmuxinator debug myproject
```

### 4.3 tmuxp

**Python-Based Alternative to Tmuxinator**

**Installation:**
```bash
pip install --user tmuxp
```

**Configuration Formats (YAML or JSON):**

```yaml
# ~/.config/tmuxp/myproject.yaml

session_name: myproject
start_directory: ~/projects/myproject

windows:
  - window_name: editor
    layout: main-vertical
    panes:
      - shell_command:
          - cd ~/projects/myproject
          - nvim
      - shell_command:
          - cd ~/projects/myproject
          - npm run watch

  - window_name: server
    panes:
      - shell_command:
          - cd ~/projects/myproject
          - npm run dev

  - window_name: shell
    layout: even-horizontal
    panes:
      - cd ~/projects/myproject
      - cd ~/projects/myproject && git status
```

**JSON Configuration:**
```json
{
  "session_name": "myproject",
  "start_directory": "~/projects/myproject",
  "windows": [
    {
      "window_name": "editor",
      "panes": [
        {
          "shell_command": ["nvim"]
        }
      ]
    },
    {
      "window_name": "shell",
      "panes": [
        {
          "shell_command": [""]
        }
      ]
    }
  ]
}
```

**Usage:**
```bash
# Load configuration
tmuxp load myproject.yaml

# Load and attach
tmuxp load -d myproject.yaml

# Convert from tmuxinator
tmuxp convert /path/to/tmuxinator.yml

# Freeze current session to YAML
tmuxp freeze session-name
```

**Advantages over Tmuxinator:**
- No Ruby dependency (uses Python)
- Can import Tmuxinator configs
- Can export/freeze current sessions
- JSON support
- Programmatic API via libtmux library

### 4.4 smug

**Go-Based Session Manager (No Dependencies)**

**Installation:**
```bash
# Go install
go install github.com/ivaaaan/smug@latest

# Manual install
wget https://github.com/ivaaaan/smug/releases/latest/download/smug_Linux_x86_64.tar.gz
tar xzf smug_Linux_x86_64.tar.gz
sudo mv smug /usr/local/bin/
```

**Configuration:**
```yaml
# ~/.config/smug/myproject.yml

session: myproject
root: ~/projects/myproject

# Auto-start when loading
start_on_load: true

windows:
  - name: editor
    root: ~/projects/myproject
    layout: main-vertical
    panes:
      - commands:
          - nvim
      - commands:
          - npm run watch

  - name: server
    commands:
      - npm run dev

  - name: shell
    layout: even-horizontal
    panes:
      - type: horizontal
      - commands:
          - git status
```

**Usage:**
```bash
# Start session
smug start myproject

# Stop session
smug stop myproject

# List configs
smug list

# Print config
smug print myproject
```

**Benefits:**
- Single binary, no dependencies
- Fast startup
- Simple YAML config
- Familiar tmuxinator-like syntax

### 4.5 Scripting Comparison

| Tool | Language | Config Format | Dependencies | Best For |
|------|----------|---------------|--------------|----------|
| **Bash Scripts** | Shell | Bash | None | Simple, custom logic |
| **Tmuxinator** | Ruby | YAML | Ruby, tmux | Mature, feature-rich |
| **tmuxp** | Python | YAML/JSON | Python, tmux | Python envs, API access |
| **smug** | Go | YAML | None (binary) | Zero dependencies |

---

## 5. Container Integration Best Practices

### 5.1 Architecture Patterns

#### Pattern 1: tmux Server in Container

```dockerfile
# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install essentials
RUN apt-get update && apt-get install -y \
    tmux \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install TPM
RUN git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm

# Copy tmux configuration
COPY tmux.conf /root/.tmux.conf

# Install plugins
RUN /root/.tmux/plugins/tpm/bin/install_plugins

# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Persist session data
VOLUME ["/root/.tmux/resurrect"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sleep", "infinity"]
```

**entrypoint.sh:**
```bash
#!/bin/bash
set -e

# Function to ensure tmux server is running
ensure_tmux_server() {
    if ! tmux has-session 2>/dev/null; then
        echo "Starting tmux server..."
        tmux start-server

        # Create default session if resurrect data exists
        if [ -f /root/.tmux/resurrect/last ]; then
            echo "Restoring previous session..."
            tmux new-session -d -s default
            sleep 1
            # Manual restore trigger (if using resurrect)
            # Or rely on continuum for auto-restore
        else
            echo "Creating new default session..."
            tmux new-session -d -s default
        fi
    fi
}

# Start tmux server
ensure_tmux_server

# Execute main command
exec "$@"
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  workspace:
    build: .
    container_name: bitbot-workspace
    stdin_open: true
    tty: true
    volumes:
      - ./project:/workspace
      - tmux-sessions:/root/.tmux/resurrect
      - tmux-plugins:/root/.tmux/plugins
    working_dir: /workspace
    environment:
      - WORKSPACE_NAME=default
    networks:
      - bitbot

volumes:
  tmux-sessions:
  tmux-plugins:

networks:
  bitbot:
```

**Usage:**
```bash
# Start container
docker compose up -d workspace

# Attach to tmux session
docker exec -it bitbot-workspace tmux attach -t default

# Or use new-session -A idiom
docker exec -it bitbot-workspace tmux new -As default

# Detach: Ctrl-b d (or Ctrl-a d if configured)

# Container persists, tmux server keeps running
```

#### Pattern 2: Per-User Workspace Sessions

```bash
#!/bin/bash
# workspace-session.sh

USER_ID="${USER_ID:-1000}"
USER_NAME="${USER_NAME:-developer}"
WORKSPACE_NAME="${WORKSPACE_NAME:-default}"
SESSION_NAME="ws-${WORKSPACE_NAME}"

# Create user if doesn't exist
if ! id "$USER_NAME" &>/dev/null; then
    useradd -u "$USER_ID" -m -s /bin/bash "$USER_NAME"
fi

# Switch to user and start/attach tmux
exec su - "$USER_NAME" -c "tmux new-session -A -s $SESSION_NAME -c /workspace"
```

**docker-compose.yml:**
```yaml
services:
  workspace:
    build: .
    environment:
      - USER_NAME=${USER}
      - USER_ID=${UID}
      - WORKSPACE_NAME=myproject-dev
    volumes:
      - ./workspace:/workspace
      - tmux-data-${USER}:/home/${USER}/.tmux
```

#### Pattern 3: Socket Mounting (Advanced)

**When to Use:**
- Sharing tmux sessions between containers
- Accessing host tmux from container
- Container orchestration scenarios

**Important Security Note:**
⚠️ **Mounting tmux sockets has security implications** - sockets grant full control over sessions.

**Host-to-Container Socket Sharing:**
```yaml
services:
  workspace:
    build: .
    volumes:
      # Mount tmux socket (read-only for safety)
      - /tmp/tmux-${UID}:/tmp/tmux-${UID}:ro
    environment:
      - TMUX_TMPDIR=/tmp/tmux-${UID}
```

**Limitations:**
- File descriptor passing doesn't work across namespaces
- Socket sharing between different hosts/VMs fails
- Better to use SSH for remote access

**Recommended Alternative:**
```bash
# Instead of socket sharing, use SSH
ssh -t user@container-host "tmux attach -t session-name"
```

### 5.2 Handling Container Lifecycle

#### Graceful Shutdown

```bash
#!/bin/bash
# entrypoint.sh with signal handling

trap 'cleanup' SIGTERM SIGINT

cleanup() {
    echo "Shutting down gracefully..."

    # Save tmux sessions
    if tmux has-session 2>/dev/null; then
        # Trigger manual save (if using resurrect without continuum)
        tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh

        # Wait for save to complete
        sleep 2
    fi

    exit 0
}

# Your initialization code
ensure_tmux_server

# Keep running
exec "$@" &
MAIN_PID=$!

wait $MAIN_PID
```

#### Startup Checks

```bash
#!/bin/bash
# healthcheck.sh

# Check if tmux server is responsive
if ! tmux list-sessions &>/dev/null; then
    exit 1
fi

# Check if default session exists
if ! tmux has-session -t default 2>/dev/null; then
    exit 1
fi

exit 0
```

**Dockerfile:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /healthcheck.sh
```

### 5.3 Multi-Container Coordination

**Example: Separate Service Containers with Shared Network**

```yaml
version: '3.8'

services:
  # Main workspace
  workspace:
    build: ./workspace
    container_name: bitbot-main
    stdin_open: true
    tty: true
    volumes:
      - ./project:/workspace
      - tmux-main:/root/.tmux
    networks:
      - bitbot
    depends_on:
      - database
      - redis

  # Database
  database:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - bitbot

  # Redis
  redis:
    image: redis:7
    networks:
      - bitbot

volumes:
  tmux-main:
  db-data:

networks:
  bitbot:
```

**Session Script for Multi-Service Monitoring:**
```bash
#!/bin/bash
# multi-service-session.sh

SESSION_NAME="bitbot"

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Create session
    tmux new-session -d -s "$SESSION_NAME" -n "main"

    # Window 1: Main shell
    tmux send-keys -t "$SESSION_NAME:main" "cd /workspace" C-m

    # Window 2: Database logs
    tmux new-window -t "$SESSION_NAME" -n "database"
    tmux send-keys -t "$SESSION_NAME:database" \
        "docker compose logs -f database" C-m

    # Window 3: Redis logs
    tmux new-window -t "$SESSION_NAME" -n "redis"
    tmux send-keys -t "$SESSION_NAME:redis" \
        "docker compose logs -f redis" C-m

    # Window 4: Application server
    tmux new-window -t "$SESSION_NAME" -n "server"
    tmux send-keys -t "$SESSION_NAME:server" \
        "cd /workspace && npm run dev" C-m

    # Window 5: Tests
    tmux new-window -t "$SESSION_NAME" -n "tests"
    tmux send-keys -t "$SESSION_NAME:tests" \
        "cd /workspace" C-m

    # Return to main
    tmux select-window -t "$SESSION_NAME:main"
fi

tmux attach-session -t "$SESSION_NAME"
```

### 5.4 Performance Considerations

#### Minimize Image Size

```dockerfile
# Multi-stage build
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/tmux-plugins/tpm /tmp/tpm

FROM ubuntu:22.04

# Install only tmux (smaller layer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Copy TPM from builder
COPY --from=builder /tmp/tpm /root/.tmux/plugins/tpm

COPY tmux.conf /root/.tmux.conf

# Pre-install plugins during build
RUN /root/.tmux/plugins/tpm/bin/install_plugins
```

#### Resource Limits

```yaml
services:
  workspace:
    build: .
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

#### Disk I/O Optimization

```yaml
services:
  workspace:
    build: .
    volumes:
      # Use delegated/cached for macOS performance
      - ./project:/workspace:cached
      # Keep session data in named volume (faster)
      - tmux-sessions:/root/.tmux/resurrect
```

---

## 6. History Management Strategies

### 6.1 Understanding Shell History in tmux

**Key Concepts:**

1. **Shell history ≠ tmux history**
   - Shell history: Commands typed in bash/zsh
   - tmux history: Terminal scrollback buffer

2. **History persistence**
   - Bash: Writes to `~/.bash_history` on session exit
   - Zsh: Can use immediate/shared history
   - tmux: Can save command-line history to `~/.tmux_history`

### 6.2 Global Shared History (Zsh)

**Configuration:**
```bash
# ~/.zshrc

# History file
HISTFILE=~/.zsh_history

# History size
HISTSIZE=50000
SAVEHIST=50000

# Shared history across all sessions
setopt SHARE_HISTORY

# Append to history file
setopt APPEND_HISTORY

# Add timestamps
setopt EXTENDED_HISTORY

# Ignore duplicates
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS

# Ignore commands starting with space
setopt HIST_IGNORE_SPACE

# Remove superfluous blanks
setopt HIST_REDUCE_BLANKS
```

**Behavior:**
- All zsh instances share history immediately
- Commands available across all tmux panes/windows
- History updated after each command

### 6.3 Isolated Per-Pane History

#### Zsh Per-Pane History

```bash
# ~/.zshrc

# Disable shared history
setopt NO_SHARE_HISTORY
setopt NO_INC_APPEND_HISTORY

# Use tmux pane ID for separate history files
if [ -n "$TMUX_PANE" ]; then
    HISTFILE=~/.zsh_history_${TMUX_PANE:1}
else
    HISTFILE=~/.zsh_history
fi

HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
```

**Result:**
- Each tmux pane gets its own history file
- Format: `~/.zsh_history_0`, `~/.zsh_history_1`, etc.
- History isolated per pane

#### Bash Per-Pane History

```bash
# ~/.bashrc

# Use tmux pane ID for history file
if [ -n "$TMUX_PANE" ]; then
    HISTFILE=~/.bash_history_${TMUX_PANE:1}
else
    HISTFILE=~/.bash_history
fi

# History size
HISTSIZE=10000
HISTFILESIZE=20000

# Append to history
shopt -s histappend

# Save after each command
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
```

### 6.4 Per-Directory History

**oh-my-zsh Plugin:**
```bash
# ~/.zshrc
plugins=(per-directory-history)

# Toggle between directory and global history
# Alt+/ or Alt-Up/Down
```

**Manual Implementation:**
```bash
# ~/.zshrc

# Function to set history per directory
function precmd() {
    local dir=$(pwd)
    local hash=$(echo -n "$dir" | md5sum | cut -d' ' -f1)
    HISTFILE=~/.zsh_history_dir_${hash}
}

# Call on prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd precmd
```

### 6.5 Per-Workspace History (BitBot Use Case)

**Concept:** Isolate history per workspace/project.

```bash
# ~/.zshrc or ~/.bashrc

# Workspace-based history
if [ -n "$WORKSPACE_NAME" ]; then
    HISTFILE=~/.history_workspace_${WORKSPACE_NAME}
elif [ -n "$TMUX_PANE" ]; then
    # Fallback to pane-based
    HISTFILE=~/.history_tmux_${TMUX_PANE:1}
else
    HISTFILE=~/.history_default
fi

HISTSIZE=50000
SAVEHIST=50000
```

**Docker Integration:**
```yaml
services:
  workspace:
    build: .
    environment:
      - WORKSPACE_NAME=myproject
    volumes:
      - ./project:/workspace
      # Persist workspace-specific history
      - workspace-history:/root/.history_workspace_myproject
```

### 6.6 History Syncing Strategies

#### Strategy 1: Immediate Sync (Zsh)

```bash
# ~/.zshrc

setopt SHARE_HISTORY        # Share history between sessions
setopt INC_APPEND_HISTORY   # Write immediately
```

**Pros:**
- Commands instantly available everywhere
- Never lose history

**Cons:**
- Can be confusing (unrelated commands in history)
- Slightly slower performance

#### Strategy 2: Append on Exit (Bash Default)

```bash
# ~/.bashrc

shopt -s histappend
```

**Pros:**
- Simple and predictable
- No performance impact

**Cons:**
- History only saved on clean exit
- History not shared until session ends

#### Strategy 3: Append After Each Command (Bash)

```bash
# ~/.bashrc

shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
```

**Explanation:**
- `history -a`: Append new history to file
- `history -c`: Clear current history
- `history -r`: Read history file

**Pros:**
- Immediate save
- Can share between sessions

**Cons:**
- Performance overhead
- Can be confusing

#### Strategy 4: Hybrid (Save Immediately, Don't Share)

```bash
# ~/.zshrc
setopt INC_APPEND_HISTORY   # Save immediately
setopt NO_SHARE_HISTORY     # Don't import from others
```

**Pros:**
- Safe (never lose history)
- Isolated (predictable)

**Cons:**
- History not shared between sessions

### 6.7 History with tmux-resurrect

**Problem:** When restoring tmux panes, shell history can be mismatched.

**Solution for Zsh:**
```bash
# ~/.zshrc

# After tmux restores, reload history
if [ -n "$TMUX_PANE" ]; then
    # Reload history when pane is restored
    fc -R
fi
```

**Solution for Bash:**
```bash
# ~/.bashrc

if [ -n "$TMUX_PANE" ]; then
    # Reload history
    history -r
fi
```

### 6.8 History Best Practices for Containers

#### Persistent History Volume

```yaml
services:
  workspace:
    build: .
    volumes:
      - ./project:/workspace
      # Persist shell history
      - shell-history:/root/.history
    environment:
      - HISTFILE=/root/.history/.zsh_history
```

#### Workspace-Specific History

```dockerfile
# Dockerfile

# Set default history location
ENV HISTFILE=/workspace/.history/.shell_history

# Create history directory
RUN mkdir -p /workspace/.history
```

**Benefits:**
- History tied to workspace
- Persists across container recreations
- Can be version-controlled (.gitignore it!)

### 6.9 Recommended Configuration for BitBot

```bash
# ~/.zshrc or ~/.bashrc in container

# Determine history file based on context
if [ -n "$WORKSPACE_NAME" ]; then
    # Workspace-based history
    HISTFILE="/workspace/.history/${WORKSPACE_NAME}.history"
    mkdir -p "$(dirname "$HISTFILE")"
elif [ -n "$TMUX_PANE" ]; then
    # Fallback: per-pane history
    HISTFILE="$HOME/.history/pane_${TMUX_PANE:1}.history"
    mkdir -p "$(dirname "$HISTFILE")"
else
    # Default
    HISTFILE="$HOME/.history/default.history"
fi

# Zsh configuration
if [ -n "$ZSH_VERSION" ]; then
    HISTSIZE=50000
    SAVEHIST=50000

    # Save immediately but don't share
    setopt INC_APPEND_HISTORY
    setopt NO_SHARE_HISTORY

    # Quality of life
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_REDUCE_BLANKS
    setopt EXTENDED_HISTORY
fi

# Bash configuration
if [ -n "$BASH_VERSION" ]; then
    HISTSIZE=50000
    HISTFILESIZE=100000

    shopt -s histappend

    # Save after each command
    PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
fi
```

---

## 7. Complete BitBot Implementation Example

### 7.1 Directory Structure

```
bitbot/
├── docker/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── tmux.conf
├── scripts/
│   ├── session-manager.sh
│   ├── workspace-session.sh
│   └── healthcheck.sh
├── config/
│   ├── tmuxp/
│   │   └── workspace.yaml
│   └── tmuxinator/
│       └── workspace.yml
├── docker-compose.yml
└── README.md
```

### 7.2 Dockerfile

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install core tools
RUN apt-get update && apt-get install -y \
    tmux \
    git \
    curl \
    wget \
    vim \
    neovim \
    zsh \
    fzf \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Install TPM
RUN git clone --depth=1 https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Copy configurations
COPY docker/tmux.conf /root/.tmux.conf
COPY docker/zshrc /root/.zshrc

# Pre-install tmux plugins
RUN /root/.tmux/plugins/tpm/bin/install_plugins

# Copy scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Setup workspace directory
RUN mkdir -p /workspace

# Volumes for persistence
VOLUME ["/workspace", "/root/.tmux/resurrect", "/root/.history"]

WORKDIR /workspace

# Entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sleep", "infinity"]
```

### 7.3 tmux.conf

```bash
# ~/.tmux.conf

# === Basic Settings ===

# Change prefix to Ctrl-a (like screen)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Increase history limit
set -g history-limit 50000

# Enable 256 colors
set -g default-terminal "screen-256color"

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows on close
set -g renumber-windows on

# Don't rename windows automatically
set -g allow-rename off

# Reduce escape time
set -sg escape-time 0

# === Key Bindings ===

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Switch windows using Shift-arrow without prefix
bind -n S-Left previous-window
bind -n S-Right next-window

# Session picker with fzf (Ctrl-a Ctrl-j)
bind C-j display-popup -E -w 80% -h 60% "\
    tmux list-sessions -F '#{session_name}' |\
    fzf --reverse \
        --header 'Switch Session' \
        --preview 'tmux list-windows -t {} -F \"#{window_index}: #{window_name}\"' |\
    xargs tmux switch-client -t"

# === Plugins ===

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'sainnhe/tmux-fzf'

# === Plugin Settings ===

# tmux-resurrect
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-dir '/root/.tmux/resurrect'

# tmux-continuum
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# tmux-fzf
set -g @tmux-fzf-launch-key 'F'

# === Status Bar ===

set -g status-position bottom
set -g status-style 'bg=colour234 fg=colour137 dim'
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-style 'fg=colour1 bg=colour19 bold'
setw -g window-status-current-format ' #I#[fg=colour249]:#[fg=colour255]#W#[fg=colour249]#F '

setw -g window-status-style 'fg=colour9 bg=colour18'
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# === Initialize TPM ===
run '/root/.tmux/plugins/tpm/tpm'
```

### 7.4 zshrc

```bash
# ~/.zshrc

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker docker-compose)
source $ZSH/oh-my-zsh.sh

# === History Configuration ===

# Determine history file based on workspace
if [ -n "$WORKSPACE_NAME" ]; then
    HISTFILE="/workspace/.history/${WORKSPACE_NAME}.zsh_history"
    mkdir -p "$(dirname "$HISTFILE")"
elif [ -n "$TMUX_PANE" ]; then
    HISTFILE="$HOME/.history/pane_${TMUX_PANE:1}.zsh_history"
    mkdir -p "$HOME/.history"
else
    HISTFILE="$HOME/.zsh_history"
fi

HISTSIZE=50000
SAVEHIST=50000

# Save immediately but don't share
setopt INC_APPEND_HISTORY
setopt NO_SHARE_HISTORY

# Quality of life
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# === Aliases ===

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# tmux aliases
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'

# === Functions ===

# Smart tmux attach
tm() {
    local session=${1:-default}
    tmux new-session -A -s "$session"
}

# Quick session picker
tms() {
    local session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --reverse --header="Select Session")
    if [ -n "$session" ]; then
        tmux switch-client -t "$session" 2>/dev/null || tmux attach -t "$session"
    fi
}

# === Environment ===

export EDITOR=nvim
export VISUAL=nvim

# Welcome message
if [ -n "$TMUX" ]; then
    echo "BitBot Workspace: ${WORKSPACE_NAME:-default}"
    echo "tmux session: $(tmux display-message -p '#{session_name}')"
fi
```

### 7.5 entrypoint.sh

```bash
#!/bin/bash
set -e

# Function to ensure tmux server is running
ensure_tmux_server() {
    local session_name="${WORKSPACE_SESSION:-default}"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Creating tmux session: $session_name"

        # Check if resurrect data exists
        if [ -f /root/.tmux/resurrect/last ]; then
            echo "Restoring previous session..."
            tmux new-session -d -s "$session_name"
            sleep 2
            # Continuum will auto-restore
        else
            echo "Creating new session..."
            # Create initial layout
            tmux new-session -d -s "$session_name" -n "shell"
            tmux send-keys -t "$session_name:shell" "cd /workspace" C-m

            # Create additional windows
            tmux new-window -t "$session_name" -n "editor"
            tmux send-keys -t "$session_name:editor" "cd /workspace" C-m

            tmux new-window -t "$session_name" -n "server"
            tmux send-keys -t "$session_name:server" "cd /workspace" C-m

            # Select first window
            tmux select-window -t "$session_name:0"
        fi

        echo "Session $session_name ready"
    else
        echo "Session $session_name already exists"
    fi
}

# Signal handling for graceful shutdown
trap 'handle_shutdown' SIGTERM SIGINT

handle_shutdown() {
    echo "Shutting down gracefully..."

    # Trigger save if tmux is running
    if tmux has-session 2>/dev/null; then
        echo "Saving tmux sessions..."
        tmux run-shell /root/.tmux/plugins/tmux-resurrect/scripts/save.sh 2>/dev/null || true
        sleep 2
    fi

    exit 0
}

# Main initialization
echo "BitBot Container Starting..."
echo "Workspace: ${WORKSPACE_NAME:-default}"

# Ensure required directories exist
mkdir -p /root/.tmux/resurrect
mkdir -p /root/.history
mkdir -p /workspace/.history

# Start tmux server
ensure_tmux_server

# Execute main command
exec "$@"
```

### 7.6 session-manager.sh

```bash
#!/bin/bash
# /usr/local/bin/session-manager.sh

SESSION_NAME="${1:-default}"
LAYOUT="${2:-standard}"

create_standard_layout() {
    local session="$1"

    # Window 1: Shell
    tmux new-window -t "$session" -n "shell"
    tmux send-keys -t "$session:shell" "cd /workspace" C-m

    # Window 2: Editor
    tmux new-window -t "$session" -n "editor"
    tmux send-keys -t "$session:editor" "cd /workspace && nvim" C-m

    # Window 3: Server (split)
    tmux new-window -t "$session" -n "server"
    tmux send-keys -t "$session:server.0" "cd /workspace" C-m
    tmux split-window -h -t "$session:server"
    tmux send-keys -t "$session:server.1" "cd /workspace" C-m

    # Window 4: Logs
    tmux new-window -t "$session" -n "logs"
    tmux send-keys -t "$session:logs" "cd /workspace" C-m

    # Select first window
    tmux select-window -t "$session:0"
}

create_dev_layout() {
    local session="$1"

    # Main development window with 3 panes
    tmux new-window -t "$session" -n "dev"
    tmux send-keys -t "$session:dev.0" "cd /workspace && nvim" C-m

    # Bottom pane (30% height)
    tmux split-window -v -p 30 -t "$session:dev"
    tmux send-keys -t "$session:dev.1" "cd /workspace" C-m

    # Split bottom into two panes
    tmux split-window -h -t "$session:dev.1"
    tmux send-keys -t "$session:dev.2" "cd /workspace && npm run test -- --watch" C-m

    # Server window
    tmux new-window -t "$session" -n "server"
    tmux send-keys -t "$session:server" "cd /workspace && npm run dev" C-m
}

# Main logic
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session $SESSION_NAME already exists"
    tmux attach -t "$SESSION_NAME"
else
    echo "Creating session $SESSION_NAME with layout: $LAYOUT"

    # Create base session
    tmux new-session -d -s "$SESSION_NAME" -n "main"
    tmux send-keys -t "$SESSION_NAME:main" "cd /workspace" C-m

    # Apply layout
    case "$LAYOUT" in
        "dev")
            create_dev_layout "$SESSION_NAME"
            ;;
        "standard"|*)
            create_standard_layout "$SESSION_NAME"
            ;;
    esac

    # Attach to session
    tmux attach -t "$SESSION_NAME"
fi
```

### 7.7 docker-compose.yml

```yaml
version: '3.8'

services:
  workspace:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: bitbot-workspace
    hostname: bitbot
    stdin_open: true
    tty: true

    environment:
      - WORKSPACE_NAME=${WORKSPACE_NAME:-default}
      - WORKSPACE_SESSION=${WORKSPACE_SESSION:-workspace}
      - TZ=UTC

    volumes:
      # Project files
      - ./workspace:/workspace

      # Persistent data
      - tmux-resurrect:/root/.tmux/resurrect
      - shell-history:/root/.history
      - workspace-history:/workspace/.history

      # Optional: mount local config for development
      # - ./docker/tmux.conf:/root/.tmux.conf:ro
      # - ./docker/zshrc:/root/.zshrc:ro

    networks:
      - bitbot

    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 30s
      timeout: 3s
      start_period: 5s
      retries: 3

volumes:
  tmux-resurrect:
  shell-history:
  workspace-history:

networks:
  bitbot:
    driver: bridge
```

### 7.8 Usage

```bash
# Start container
docker compose up -d

# Attach to default session
docker exec -it bitbot-workspace tmux attach -t workspace

# Or use session manager
docker exec -it bitbot-workspace session-manager.sh my-project dev

# Create new session with custom layout
docker exec -it bitbot-workspace session-manager.sh api-dev standard

# List sessions
docker exec -it bitbot-workspace tmux ls

# Detach from session: Ctrl-a d

# Stop container (sessions persist in volumes)
docker compose down

# Restart container (sessions restore automatically)
docker compose up -d

# Clean everything
docker compose down -v  # Warning: deletes volumes
```

---

## 8. Troubleshooting and Tips

### 8.1 Common Issues

#### Issue: Lost sessions after container restart

**Causes:**
- tmux-resurrect not configured
- Volume not mounted
- Continuum not enabled

**Solutions:**
```bash
# Check if resurrect is working
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh

# Check save location
ls -la ~/.tmux/resurrect/

# Verify volume mount
docker inspect bitbot-workspace | grep -A 10 Mounts
```

#### Issue: History not persisting

**Causes:**
- HISTFILE not set correctly
- Volume not mounted
- Shell not writing history

**Solutions:**
```bash
# Check history file location
echo $HISTFILE

# Check if writable
touch $HISTFILE

# Force write (zsh)
fc -W

# Force write (bash)
history -a
```

#### Issue: tmux server won't start in container

**Causes:**
- TERM environment variable issues
- Insufficient permissions
- Missing dependencies

**Solutions:**
```bash
# Check TERM
echo $TERM

# Set explicitly
export TERM=screen-256color

# Check tmux version
tmux -V

# Start server manually
tmux start-server
tmux info
```

### 8.2 Performance Tips

1. **Limit history size in long-running sessions**
   ```bash
   set -g history-limit 10000  # Instead of 50000
   ```

2. **Disable unused features**
   ```bash
   set -g visual-activity off
   set -g visual-bell off
   set -g visual-silence off
   setw -g monitor-activity off
   ```

3. **Use efficient status bar**
   ```bash
   set -g status-interval 5  # Update every 5 seconds instead of 1
   ```

4. **Clean old sessions**
   ```bash
   # Kill inactive sessions older than 7 days
   tmux list-sessions -F '#{session_created} #{session_name}' | \
   awk -v cutoff=$(($(date +%s) - 604800)) '$1 < cutoff {print $2}' | \
   xargs -I {} tmux kill-session -t {}
   ```

### 8.3 Security Considerations

1. **Don't share socket files carelessly**
2. **Use read-only mounts where appropriate**
3. **Limit container capabilities**
4. **Don't commit sensitive history to version control**
5. **Use .gitignore for history directories**

```gitignore
# .gitignore
.history/
*.history
.zsh_history*
.bash_history*
```

---

## 9. Additional Resources

### Documentation

- **tmux**: https://github.com/tmux/tmux/wiki
- **zellij**: https://zellij.dev/documentation/
- **GNU screen**: https://www.gnu.org/software/screen/manual/
- **tmux-resurrect**: https://github.com/tmux-plugins/tmux-resurrect
- **Tmuxinator**: https://github.com/tmuxinator/tmuxinator

### Tutorials

- tmux crash course: https://thoughtbot.com/blog/a-tmux-crash-course
- zellij getting started: https://zellij.dev/tutorials/
- fzf integration: https://github.com/junegunn/fzf

### Community

- r/tmux: https://www.reddit.com/r/tmux/
- tmux discussions: https://github.com/tmux/tmux/discussions
- zellij discord: https://discord.gg/CrUAFH3

---

## 10. Conclusion

For BitBot's resumable terminal sessions inside containers, **tmux with tmux-resurrect/continuum** provides the most robust and battle-tested solution. The combination offers:

- **Session Persistence**: Automatic saving and restoration across container restarts
- **Multi-Session Support**: Easy management of multiple concurrent workspaces
- **Rich Ecosystem**: Extensive plugins and tooling
- **Automation**: Multiple options for scripted session creation
- **History Management**: Flexible per-workspace/per-pane history isolation
- **Container Integration**: Well-documented patterns and best practices

**Alternative:** Consider **zellij** if you prioritize modern UX and built-in features over ecosystem maturity.

**Recommended Stack for BitBot:**
- **Multiplexer**: tmux 3.3+
- **Session Persistence**: tmux-resurrect + tmux-continuum
- **Automation**: Bash scripts or tmuxp
- **Session Selection**: fzf integration
- **Shell**: zsh with custom history configuration
- **Container**: Docker with volume-mounted session data

This provides a production-ready, maintainable solution for resumable development environments.
