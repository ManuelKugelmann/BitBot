# BitBot Global First-Run Flow

**Scenario**: User has just installed BitBot and runs it for the first time from the install folder.

**Purpose**: Set up global BitBot environment, add to PATH, create ~/.bitbot/

---

## Prerequisites

- User has downloaded/extracted BitBot to a folder (e.g., `/opt/bitbot/` or `C:\bitbot\`)
- Docker Desktop is installed
- Running on Linux, macOS, or WSL2

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ User installs BitBot (extract .zip or git clone)               │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ User opens terminal and navigates to BitBot install folder     │
│ $ cd /opt/bitbot                                                │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ User runs: ./scripts/bitbot                                     │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
        ┌───────┴───────┐
        │ First run?    │
        │ (no ~/.bitbot/│
        │  first-run)   │
        └───────┬───────┘
                │ YES
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ GLOBAL INIT FLOW STARTS                                         │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Welcome Banner                                          │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Check Prerequisites                                     │
│ - Docker installed & running?                                   │
│ - Docker Compose v2?                                            │
│ - DevContainer CLI available?                                   │
│ - VS Code (optional)?                                           │
└───────────────┬─────────────────────────────────────────────────┘
                │
        ┌───────┴───────┐
        │ Docker        │
        │ running?      │
        └───┬───────┬───┘
            │ NO    │ YES
            ▼       │
    ┌───────────┐  │
    │Auto-start?│  │
    │(Y/n)      │  │
    └───┬───┬───┘  │
        │Y  │N     │
        ▼   ▼      │
    ┌────┐┌────┐   │
    │Start││Exit│   │
    │wait ││    │   │
    └──┬─┘└────┘   │
       │           │
       └─────┬─────┘
             │
             ▼
    ┌─────────────────┐
    │ DevContainer    │
    │ CLI available?  │
    └────┬──────┬─────┘
         │ NO   │ YES
         ▼      │
    ┌─────────┐ │
    │Install? │ │
    │(y/N)    │ │
    └──┬──┬───┘ │
       │Y │N    │
       ▼  ▼     │
    ┌────┐┌───┐ │
    │npm ││Skip││
    │inst││   ││
    └──┬─┘└───┘│
       │       │
       └───┬───┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Create ~/.bitbot/ Structure                             │
│ - ~/.bitbot/config-devcontainer/                                │
│ - ~/.bitbot/config.json                                         │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Add to PATH                                             │
│ Platform-specific shell config update                           │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Mark First-Run Complete                                 │
│ Create ~/.bitbot/first-run marker                               │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Show Next Steps                                         │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ DONE - User can now run 'bitbot' from any directory            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Screen Flow

### Step 1: User runs BitBot for first time

**Terminal:**
```bash
user@laptop:/opt/bitbot$ ./scripts/bitbot
```

**Output:**
```
==============================================
  Welcome to BitBot!
==============================================

BitBot is a secure development environment
manager for AI-assisted coding.

This is your first run. Let's set up BitBot...

==============================================
```

---

### Step 2: Prerequisites Check

**Output:**
```
[1/4] Checking prerequisites...

Checking Docker...
  ✓ Docker installed (Docker version 24.0.7, build afdd53b)
  ✓ Docker is running

Checking Docker Compose...
  ✓ Docker Compose v2 (Docker Compose version v2.23.0)

Checking DevContainer CLI...
  ✓ DevContainer CLI (VS Code builtin)

Checking VS Code...
  ✓ VS Code installed
  ✓ Dev Containers extension installed

Checking Git...
  ✓ Git installed (git version 2.42.0)

[+] All prerequisites OK
```

**Alternative: Docker not running**
```
Checking Docker...
  ✓ Docker installed (Docker version 24.0.7, build afdd53b)
  ✗ Docker is not running

Start Docker now? (Y/n): █
```

**User input:** `Y` (or just Enter)

```
[>] Starting Docker...
  Waiting for Docker to start...
  .......... 10s... 20s
  ✓ Docker ready (took 24s)
```

**Alternative: DevContainer CLI missing**
```
Checking DevContainer CLI...
  ✗ DevContainer CLI not found

Install options:

Option 1: VS Code + Dev Containers extension (recommended)
  https://code.visualstudio.com/
  Extension: ms-vscode-remote.remote-containers

Option 2: Standalone CLI (requires Node.js)
  npm install -g @devcontainers/cli

Install standalone CLI now? (y/N): █
```

**User input:** `y`

```
[>] Installing @devcontainers/cli...

added 142 packages in 8s
  ✓ @devcontainers/cli installed
```

---

### Step 3: Global BitBot Setup

**Output:**
```
[2/4] Setting up BitBot...

Creating BitBot directory structure...
  ✓ Created ~/.bitbot/
  ✓ Created ~/.bitbot/config-devcontainer/
  ✓ Created ~/.bitbot/templates/
  ✓ Created ~/.bitbot/cache/

Creating default configuration...
  ✓ Created ~/.bitbot/config.json

Setting up config devcontainer template...
  ✓ Created ~/.bitbot/config-devcontainer/devcontainer.json
  ✓ Created ~/.bitbot/config-devcontainer/Dockerfile

[+] Global setup complete
```

---

### Step 4: Add to PATH

**Output (Linux/macOS):**
```
[3/4] Adding BitBot to PATH...

Detected shell: bash

Add BitBot to your PATH? (Y/n): █
```

**User input:** `Y` (or just Enter)

```
  ✓ Added to ~/.bashrc

  ┌─────────────────────────────────────────────────┐
  │ IMPORTANT: Reload your shell to use 'bitbot'   │
  │                                                 │
  │ Run: source ~/.bashrc                           │
  │ Or: Close and reopen your terminal              │
  └─────────────────────────────────────────────────┘
```

**Output (WSL):**
```
[3/4] Adding BitBot to PATH...

Detected environment: WSL (BitBot-Alpine)

Add BitBot to your PATH? (Y/n): Y

  ✓ Added to ~/.bashrc
  ✓ Set BITBOT_HOME=/mnt/c/bitbot

  ┌─────────────────────────────────────────────────┐
  │ IMPORTANT: Reload your shell to use 'bitbot'   │
  │                                                 │
  │ Run: source ~/.bashrc                           │
  │ Or: Close and reopen your WSL terminal          │
  └─────────────────────────────────────────────────┘
```

---

### Step 5: Mark Complete

**Output:**
```
[4/4] Finalizing setup...

  ✓ First-run complete
```

---

### Step 6: Next Steps

**Output:**
```
==============================================
  BitBot Setup Complete!
==============================================

Your BitBot environment is ready.

Next steps:

1. Reload your shell:
   $ source ~/.bashrc

2. Navigate to a project folder:
   $ cd ~/my-project

3. Initialize a BitBot workspace:
   $ bitbot init

4. Launch work mode:
   $ bitbot work

==============================================

For more information, visit:
https://docs.bitbot.dev/

```

---

## Alternative Flows

### User Cancels Docker Auto-Start

```
Start Docker now? (Y/n): n

Setup cancelled.

Please start Docker Desktop manually and run:
  ./scripts/bitbot

```

### User Cancels PATH Addition

```
Add BitBot to your PATH? (Y/n): n

Skipped PATH addition.

To use BitBot, run from the install directory:
  /opt/bitbot/scripts/bitbot

Or add to PATH manually:
  export PATH="$PATH:/opt/bitbot/scripts"

[+] Setup complete
```

---

## After First Run

**Next time user runs from install folder:**

```bash
user@laptop:~$ cd /opt/bitbot
user@laptop:/opt/bitbot$ bitbot
```

**Output:**
```
BitBot global context

Run from a project folder to use workspace commands, or:
  bitbot config    # Configure global settings
  bitbot serve     # Launch global services (future)

For workspace commands, navigate to a project:
  $ cd ~/my-project
  $ bitbot work
```

---

## Files Created

After global init, the following files exist:

```
~/.bitbot/
├── config-devcontainer/
│   ├── devcontainer.json     # Global config mode devcontainer
│   └── Dockerfile            # Config mode container image
├── config.json               # Global settings
├── templates/                # Built-in templates (future)
├── cache/                    # Cache directory
└── first-run                 # Marker file (timestamp)

~/.bashrc (or ~/.zshrc)
# Added lines:
export PATH="$PATH:/opt/bitbot/scripts"
export BITBOT_HOME="/opt/bitbot"
```

---

## User Experience Notes

### Timing
- Prerequisites check: **5-10 seconds**
- Docker auto-start: **20-60 seconds** (if needed)
- Global setup: **2-3 seconds**
- PATH addition: **< 1 second**
- **Total**: 30-75 seconds (depending on Docker)

### User Interactions
- **Minimal**: Only 2 confirmations (Docker start, PATH addition)
- **Defaults**: Sensible defaults (Y for both)
- **Cancellable**: User can cancel at any time
- **Resumable**: Can re-run if cancelled

### Error Handling
- **Docker not installed**: Clear error with install link
- **npm not found**: Prompt to install Node.js first
- **Permission errors**: Suggest using sudo or checking permissions
- **Network errors**: Retry or skip with manual instructions

---

## Platform-Specific Variations

### Linux
- Uses `~/.bashrc` or `~/.zshrc`
- May need `sudo` for Docker commands
- Systemd for Docker auto-start

### macOS
- Uses `~/.zshrc` (default shell is zsh)
- `open -a Docker` for Docker Desktop
- May need admin password

### WSL2 (Windows)
- Uses `~/.bashrc` in WSL
- Windows paths (e.g., `/mnt/c/bitbot`)
- May prompt for WSL Docker integration setup
- PowerShell commands for Docker Desktop (Windows side)

---

## Success State

**User knows setup succeeded when:**
1. See "✓ Setup complete" message
2. See next steps with clear instructions
3. Can reload shell and run `bitbot --version` from any directory

**What user can do next:**
1. Reload shell (`source ~/.bashrc`)
2. Navigate to project folder
3. Run `bitbot init` to initialize workspace
4. Run `bitbot work` to start development

---

## Common Issues

### Issue: "Docker not running" keeps appearing
**Cause**: Docker Desktop not starting or WSL integration disabled
**Solution**:
1. Check Docker Desktop is running
2. On WSL, enable BitBot-Alpine in Docker settings
3. Wait 30-60 seconds for Docker to initialize

### Issue: "command not found: bitbot" after setup
**Cause**: Shell not reloaded
**Solution**: Run `source ~/.bashrc` or close/reopen terminal

### Issue: npm install fails
**Cause**: Node.js not installed or network issue
**Solution**:
1. Install Node.js from https://nodejs.org/
2. Or skip CLI install and use VS Code extension instead

---

## Summary

**Global first-run initializes:**
- ✅ ~/.bitbot/ directory structure
- ✅ Global config devcontainer template
- ✅ PATH environment variable
- ✅ BITBOT_HOME environment variable
- ✅ First-run marker

**User is ready to:**
- ✅ Run `bitbot` from any directory
- ✅ Initialize workspaces with `bitbot init`
- ✅ Launch work/config modes
- ✅ Use VS Code integration

**Next step:** See `FLOW_WORKSPACE_INIT.md` for workspace initialization flow.
