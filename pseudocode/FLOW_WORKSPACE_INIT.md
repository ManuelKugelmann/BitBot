# BitBot Workspace First-Time Initialization Flow

**Scenario**: User has completed global init and wants to set up BitBot in a project folder.

**Purpose**: Initialize BitBot workspace, create .bitbot/ structure, launch config mode to set up .devcontainer.

---

## Prerequisites

- Global BitBot initialization complete (see `FLOW_GLOBAL_INIT.md`)
- User has navigated to a project directory
- Docker is running

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ User navigates to project folder                                │
│ $ cd ~/my-awesome-project                                       │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ User runs: bitbot init                                          │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
        ┌───────┴───────┐
        │ .bitbot/      │
        │ exists?       │
        └───┬───────┬───┘
            │ YES   │ NO
            ▼       │
    ┌──────────┐    │
    │ ERROR:   │    │
    │ Already  │    │
    │ init'd   │    │
    └──────────┘    │
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Check Prerequisites                                     │
│ (Docker, DevContainer CLI)                                      │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Create .bitbot/ Structure                               │
│ - .bitbot/config.json                                           │
│ - .bitbot/state/                                                │
│ - .bitbot/internal/                                             │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Check for Existing .devcontainer/                       │
└───────────────┬─────────────────────────────────────────────────┘
                │
        ┌───────┴───────┐
        │.devcontainer/ │
        │ exists?       │
        └───┬───────┬───┘
            │ YES   │ NO
            ▼       ▼
    ┌──────────┐┌──────────┐
    │ Inform   ││ Create   │
    │ user it  ││ from     │
    │ will be  ││ template │
    │ used     ││ in config│
    └────┬─────┘└────┬─────┘
         │           │
         └─────┬─────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Launch Config Mode                                      │
│ Auto-launch config devcontainer to configure .devcontainer      │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Config mode launches (in devcontainer)                          │
│ User can now create/edit .devcontainer files                    │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ User exits config mode (exit or Ctrl+D)                         │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│ DONE - Workspace initialized                                    │
│ User can now run: bitbot work                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Screen Flow

### Step 1: User navigates to project

**Terminal:**
```bash
user@laptop:~$ cd ~/my-awesome-project
user@laptop:~/my-awesome-project$ ls
```

**Output:**
```
README.md  src/  package.json  .git/
```

**User runs init:**
```bash
user@laptop:~/my-awesome-project$ bitbot init
```

---

### Step 2: Prerequisites Check

**Output:**
```
[>] Initializing BitBot workspace: /home/user/my-awesome-project

Checking prerequisites...
  ✓ Docker is running
  ✓ DevContainer CLI available

```

**Alternative: Docker not running**
```
Checking prerequisites...
  ✗ Docker is not running

Start Docker now? (Y/n): █
```

**User input:** `Y`

```
[>] Starting Docker...
  Waiting for Docker to start...
  .......... 10s
  ✓ Docker ready (took 12s)

```

---

### Step 3: Create .bitbot/ Structure

**Output:**
```
Creating workspace structure...
  ✓ Created .bitbot/
  ✓ Created .bitbot/state/
  ✓ Created .bitbot/internal/
  ✓ Created .bitbot/config.json

Workspace configuration:
  Name: my-awesome-project
  Default mode: work

```

---

### Step 4: Check for Existing .devcontainer

**Scenario A: No existing .devcontainer**

**Output:**
```
Checking for .devcontainer...
  [i] No .devcontainer found

[+] Workspace initialized

Launching config mode to set up .devcontainer...

  You'll be dropped into a devcontainer where you can:
  - Create .devcontainer/devcontainer.json
  - Add a Dockerfile
  - Install development tools
  - Configure features

  When done, type 'exit' to return to your host

```

**Scenario B: Existing .devcontainer found**

**Output:**
```
Checking for .devcontainer...
  ✓ Found existing .devcontainer/

[+] Workspace initialized

Launching config mode to review/edit .devcontainer...

  Your existing .devcontainer will be used.
  Config mode allows you to safely edit it.

  When done, type 'exit' to return to your host

```

---

### Step 5: Config Mode Launch

**Output:**
```
[>] Launching config mode...

Building devcontainer...
[+] Building config devcontainer
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 450B
 => [internal] load .dockerignore
 => [1/4] FROM mcr.microsoft.com/devcontainers/base:ubuntu
 => [2/4] RUN apt-get update && apt-get install -y nodejs npm
 => [3/4] RUN npm install -g @devcontainers/cli
 => [4/4] COPY setup-devcontainer-docs.sh /usr/local/bin/
 => exporting to image
 => => exporting layers
 => => writing image sha256:abc123...
 => => naming to docker.io/library/bitbot-config-my-awesome-project

[+] Devcontainer built successfully

Starting devcontainer...
  ✓ Container started: bitbot-config-abc123

Entering devcontainer with tmux session 'config'...

```

**Screen transitions to inside the container:**

```
┌─────────────────────────────────────────────────────────────────┐
│ BitBot Config Mode                                              │
│ Container: bitbot-config-abc123                                 │
│ Workspace: /workspace                                           │
└─────────────────────────────────────────────────────────────────┘

vscode@bitbot-config:/workspace$ █
```

---

### Step 6: User Creates .devcontainer (No Existing Config)

**Inside config mode container:**

```bash
vscode@bitbot-config:/workspace$ ls
```

**Output:**
```
README.md  src/  package.json  .git/  .bitbot/
```

**User creates .devcontainer:**
```bash
vscode@bitbot-config:/workspace$ mkdir .devcontainer
vscode@bitbot-config:/workspace$ cd .devcontainer
```

**User can use helper script:**
```bash
vscode@bitbot-config:/workspace/.devcontainer$ devcontainer-init-helper

BitBot DevContainer Helper
===========================

This will create a basic devcontainer.json for you.

Select base image:
  1) Node.js 20
  2) Python 3.11
  3) Ubuntu (minimal)
  4) Custom

Choice (1-4): █
```

**User selects option 1:**
```
Choice (1-4): 1

Creating devcontainer.json for Node.js 20...
  ✓ Created devcontainer.json
  ✓ Added common-utils feature (UID/GID sync)
  ✓ Added RO mount for .devcontainer (work mode security)
  ✓ Added .bash_history persistence

Review the file:
  /workspace/.devcontainer/devcontainer.json

Edit as needed, then 'exit' to finish setup.
```

**User reviews the file:**
```bash
vscode@bitbot-config:/workspace/.devcontainer$ cat devcontainer.json
```

**Output:**
```json
{
  "name": "my-awesome-project",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:20",

  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true,
      "username": "vscode",
      "upgradePackages": true
    }
  },

  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint"
      ]
    }
  },

  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],

  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/state/.bash_history"
  },

  "postCreateCommand": "npm install",

  "remoteUser": "vscode",
  "updateRemoteUserUID": true
}
```

**User is satisfied and exits:**
```bash
vscode@bitbot-config:/workspace/.devcontainer$ exit
```

---

### Step 7: Exit Config Mode

**Output:**
```
[i] Exiting config mode...

Stopping devcontainer...
  ✓ Container stopped

==============================================
  Workspace Setup Complete!
==============================================

Your BitBot workspace is ready:
  /home/user/my-awesome-project

DevContainer configured:
  .devcontainer/devcontainer.json

Next steps:

1. Launch work mode:
   $ bitbot work

2. Or launch in VS Code:
   $ bitbot vscode

==============================================
```

**User is back on host:**
```bash
user@laptop:~/my-awesome-project$ █
```

---

### Step 8: User Launches Work Mode

**Terminal:**
```bash
user@laptop:~/my-awesome-project$ bitbot work
```

**Output:**
```
[>] Launching work mode...

Checking prerequisites...
  ✓ Docker is running
  ✓ DevContainer CLI available

Validating workspace...
  ✓ Workspace initialized
  ✓ .devcontainer found

Git status check...
  [i] No uncommitted changes

[>] Building and starting devcontainer...

Building devcontainer from .devcontainer/devcontainer.json...
[+] Building work devcontainer
 => [internal] load build definition
 => [1/3] FROM mcr.microsoft.com/devcontainers/javascript-node:20
 => [2/3] RUN apt-get update && apt-get install -y git
 => [3/3] USER vscode
 => exporting to image

[+] Devcontainer built successfully

Starting devcontainer...
  ✓ Container started: bitbot-work-abc123def
  ✓ UID/GID synchronized (1000:1000)

Entering devcontainer with tmux session 'work'...

```

**Screen transitions to work mode container:**

```
┌─────────────────────────────────────────────────────────────────┐
│ BitBot Work Mode                                                │
│ Container: bitbot-work-abc123def                                │
│ Workspace: /workspace                                           │
│ .devcontainer: Read-Only ✓                                      │
└─────────────────────────────────────────────────────────────────┘

vscode@bitbot-work:/workspace$ █
```

**User verifies .devcontainer is read-only:**
```bash
vscode@bitbot-work:/workspace$ touch .devcontainer/test
```

**Output:**
```
touch: cannot touch '.devcontainer/test': Read-only file system
```

**Success! User can now work safely:**
```bash
vscode@bitbot-work:/workspace$ npm run dev
```

---

## Alternative Flows

### Already Initialized

**User runs init in an already-initialized workspace:**

```bash
user@laptop:~/my-project$ bitbot init
```

**Output:**
```
[X] Error: Workspace already initialized

Found existing .bitbot/ directory in:
  /home/user/my-project

To reinitialize, first remove .bitbot/:
  $ rm -rf .bitbot/
  $ bitbot init

Or just launch work mode:
  $ bitbot work

```

---

### Git Uncommitted Changes (Warning Only)

**User has uncommitted changes when launching config mode:**

**Output:**
```
Validating workspace...
  ✓ Workspace initialized

Git status check...
  [!] Uncommitted changes detected
      Files modified: 3
      Recommendation: Commit before infrastructure changes

Continue anyway? (y/N): █
```

**User chooses to commit first:**
```
Continue anyway? (y/N): n

Setup cancelled.

Commit your changes first:
  $ git add .
  $ git commit -m "Work in progress"
  $ bitbot init

```

**Or user continues anyway:**
```
Continue anyway? (y/N): y

[>] Launching config mode...
```

---

### Existing .devcontainer with .gitignore

**User has .devcontainer/ already:**

```bash
user@laptop:~/existing-project$ ls -la .devcontainer/
```

**Output:**
```
total 12
drwxr-xr-x 2 user user 4096 Oct 21 10:30 .
drwxr-xr-x 8 user user 4096 Oct 21 10:30 ..
-rw-r--r-- 1 user user  850 Oct 21 10:30 devcontainer.json
```

**User runs init:**
```bash
user@laptop:~/existing-project$ bitbot init
```

**Output:**
```
[>] Initializing BitBot workspace: /home/user/existing-project

Creating workspace structure...
  ✓ Created .bitbot/
  ✓ Created .bitbot/state/
  ✓ Created .bitbot/config.json

Checking for .devcontainer...
  ✓ Found existing .devcontainer/

[+] Workspace initialized

IMPORTANT: Your existing .devcontainer will be used.

BitBot will add a read-only mount for work mode security.
Review/edit in config mode if needed.

Launching config mode...

[>] Building devcontainer...
```

**Inside config mode:**
```bash
vscode@bitbot-config:/workspace$ cat .devcontainer/devcontainer.json
```

**User sees existing config and can edit:**
```bash
vscode@bitbot-config:/workspace$ vi .devcontainer/devcontainer.json
```

**User adds BitBot-specific mounts:**
```json
{
  "name": "existing-project",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",

  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],

  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/state/.bash_history"
  },

  "remoteUser": "vscode",
  "updateRemoteUserUID": true
}
```

**User saves and exits:**
```bash
vscode@bitbot-config:/workspace$ exit
```

---

## Files Created

After workspace init, the following structure exists:

```
my-awesome-project/
├── .devcontainer/
│   └── devcontainer.json         # Work mode config (created or existing)
├── .bitbot/
│   ├── config.json               # Workspace config
│   ├── state/
│   │   └── .bash_history         # Persistent history mountpoint
│   └── internal/
│       └── devcontainer.json     # Per-workspace config mode config
├── .git/                         # Existing git repo
├── src/                          # Existing project files
└── README.md
```

**Contents of .bitbot/config.json:**
```json
{
  "workspace_name": "my-awesome-project",
  "default_mode": "work",
  "initialized": "2025-10-21T14:30:22Z"
}
```

---

## User Experience Notes

### Timing
- Prerequisites check: **2-3 seconds**
- Create .bitbot/: **< 1 second**
- Config mode launch: **10-30 seconds** (first time, cached after)
- User .devcontainer creation: **2-5 minutes** (manual)
- Exit config mode: **2-3 seconds**
- **Total**: 15 seconds to 6 minutes (depending on user edits)

### User Interactions
- **Init command**: 1 command (`bitbot init`)
- **Inside config mode**: User creates/edits .devcontainer files
- **Exit**: Simple `exit` command
- **Optional**: Can skip manual creation with helper script

### Error Handling
- **Already initialized**: Clear error with instructions
- **Docker not running**: Auto-start with confirmation
- **No DevContainer CLI**: Helpful install guidance
- **Permission errors**: Suggest checking folder permissions

---

## Decision Points

### Question 1: Create new .devcontainer or use existing?
**If no .devcontainer:** Create from template in config mode
**If .devcontainer exists:** Use existing, allow edits in config mode

### Question 2: What base image to use?
**Options**: Node.js, Python, Ubuntu, Custom
**Default**: Based on project detection (package.json → Node.js, requirements.txt → Python)

### Question 3: Continue with uncommitted changes?
**Recommendation**: Commit first
**User choice**: Can continue anyway (warning only, non-blocking)

---

## Success State

**User knows init succeeded when:**
1. See "✓ Workspace initialized" message
2. Config mode launches automatically
3. .bitbot/ directory exists with proper structure
4. Can exit config mode and launch work mode

**What user can do next:**
1. Run `bitbot work` to start development
2. Run `bitbot vscode` to open in VS Code
3. Run `bitbot config` to edit .devcontainer again (anytime)

---

## Common Issues

### Issue: "Workspace already initialized"
**Cause**: .bitbot/ directory already exists
**Solution**:
1. If intentional, just run `bitbot work`
2. To reinitialize, remove .bitbot/ first: `rm -rf .bitbot/`

### Issue: Config mode exits immediately
**Cause**: tmux session not created properly
**Solution**:
1. Check Docker is running
2. Check devcontainer CLI is available
3. Try again: `bitbot config`

### Issue: .devcontainer not writable in config mode
**Cause**: Incorrect mount configuration
**Solution**:
1. Config mode should NOT have RO mount for .devcontainer
2. Check ~/.bitbot/config-devcontainer/devcontainer.json
3. Ensure no RO mount is specified

### Issue: Changes to .devcontainer not persisting
**Cause**: Editing wrong location or container issue
**Solution**:
1. Ensure editing /workspace/.devcontainer (not /workspace/.devcontainer inside container)
2. Changes should persist on host immediately
3. Verify with `ls -la .devcontainer/` on host after exiting

---

## Best Practices

### Before Init
1. ✅ Navigate to project root (where .git/ is)
2. ✅ Commit any uncommitted work
3. ✅ Ensure Docker is running
4. ✅ Have project requirements ready (Node.js version, Python version, etc.)

### During Config Mode
1. ✅ Use helper script for basic setup
2. ✅ Customize for your project needs
3. ✅ Add project-specific features (git, docker-in-docker, etc.)
4. ✅ Test the config: `devcontainer build --workspace-folder /workspace`
5. ✅ Review mounts (RO for .devcontainer, RW for .bitbot/state)

### After Init
1. ✅ Test work mode: `bitbot work`
2. ✅ Verify .devcontainer is read-only in work mode
3. ✅ Verify bash history persistence across sessions
4. ✅ Commit .devcontainer/ to git (if desired)
5. ✅ Add .bitbot/ to .gitignore (state is local)

---

## Comparison: Work Mode vs Config Mode

| Aspect | Work Mode | Config Mode |
|--------|-----------|-------------|
| **Purpose** | Daily development | Edit infrastructure |
| **DevContainer** | Workspace's .devcontainer/ | Global ~/.bitbot/config-devcontainer/ |
| **Launch** | `bitbot work` | `bitbot config` (or auto-launch from init) |
| **.devcontainer** | Read-only ✓ | Read-write ✓ |
| **Workspace** | /workspace (RW) | /workspace (RW) |
| **When to use** | Write code, run tests | Create/edit .devcontainer, add features |
| **Safety** | Can't break container config | Can edit config (be careful) |

---

## Summary

**Workspace init accomplishes:**
- ✅ Creates .bitbot/ directory structure
- ✅ Creates workspace config.json
- ✅ Ensures .devcontainer/ exists (create or use existing)
- ✅ Automatically launches config mode for setup
- ✅ Readies workspace for work mode

**User learns:**
- ✅ How to initialize a BitBot workspace
- ✅ Config mode is for .devcontainer edits
- ✅ Work mode is for daily development
- ✅ .devcontainer is protected in work mode
- ✅ Bash history persists across sessions

**Next steps after init:**
1. Launch work mode: `bitbot work`
2. Start coding with AI assistance
3. Edit .devcontainer anytime: `bitbot config`
4. Launch in VS Code: `bitbot vscode`

---

**Related Flows:**
- Global first-run: See `FLOW_GLOBAL_INIT.md`
- Work mode session: See `FLOW_WORK_SESSION.md` (future)
- Config mode editing: See `FLOW_CONFIG_MODE.md` (future)
