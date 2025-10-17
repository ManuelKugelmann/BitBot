# First-Run Experience & Wizard Specification

**Feature ID**: SPEC-09
**Priority**: P1 (Important)
**Status**: Draft
**Depends On**: SPEC-05 (Cross-Platform CLI), SPEC-08 (Workspace Templates), SPEC-10 (Installation)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

Guided first-run experience for new BitBot users. Interactive wizard for setup, workspace creation, and onboarding. Validates prerequisites and configures environment.

**Key Design**: Prerequisite checks + interactive wizard + workspace init + quick start guide = smooth onboarding.

---

## 1. Architecture

### 1.1 First-Run Sequence

```
bitbot (first run)
  ↓
Prerequisite Checks
  ↓
Welcome & Introduction
  ↓
Environment Setup
  ↓
Workspace Initialization
  ↓
Quick Start Guide
  ↓
Launch Workspace
```

### 1.2 First-Run Detection

**Detection methods**:
- No `~/.bitbot/` directory exists
- No `.bitbot/` in current workspace
- `~/.bitbot/first-run` marker file absent

**First-run trigger**:
```bash
# User runs bitbot for first time
$ bitbot

# Detects first run
# Launches wizard instead of normal flow
```

---

## 2. Prerequisite Checks

### 2.1 Required Tools

**Check Docker**:
```bash
if ! command -v docker &>/dev/null; then
  error "Docker not found"
  echo "Install Docker:"
  echo "  macOS/Windows: https://www.docker.com/products/docker-desktop"
  echo "  Linux: https://docs.docker.com/engine/install/"
  exit 1
fi

# Check Docker running
if ! docker ps &>/dev/null; then
  error "Docker is not running"
  echo "Start Docker Desktop and try again"
  exit 1
fi
```

**Check Docker Compose**:
```bash
if ! docker compose version &>/dev/null; then
  error "Docker Compose not found"
  echo "Docker Compose is required (usually bundled with Docker)"
  exit 1
fi
```

**Check WSL2** (Windows only):
```bash
if [[ "$OS" == "windows" ]]; then
  if ! command -v wsl &>/dev/null; then
    error "WSL2 not found"
    echo "Install WSL2: https://aka.ms/wsl2"
    exit 1
  fi
fi
```

### 2.2 Optional Tools

**Check Git**:
```bash
if ! command -v git &>/dev/null; then
  warn "Git not found (recommended)"
  echo "Install: https://git-scm.com/downloads"
  # Continue anyway
fi
```

**Check VS Code**:
```bash
if ! command -v code &>/dev/null; then
  info "VS Code not found (optional)"
  echo "For VS Code integration: https://code.visualstudio.com/"
fi
```

### 2.3 Prerequisite Summary

**Display results**:
```
Checking prerequisites...

✓ Docker installed (24.0.6)
✓ Docker running
✓ Docker Compose available
✓ Git installed (2.42.0)
ℹ VS Code not found (optional)

Ready to proceed!
```

---

## 3. Welcome & Introduction

### 3.1 Welcome Screen

```
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ██████╗ ██╗████████╗██████╗  ██████╗ ████████╗       ║
║   ██╔══██╗██║╚══██╔══╝██╔══██╗██╔═══██╗╚══██╔══╝       ║
║   ██████╔╝██║   ██║   ██████╔╝██║   ██║   ██║          ║
║   ██╔══██╗██║   ██║   ██╔══██╗██║   ██║   ██║          ║
║   ██████╔╝██║   ██║   ██████╔╝╚██████╔╝   ██║          ║
║   ╚═════╝ ╚═╝   ╚═╝   ╚═════╝  ╚═════╝    ╚═╝          ║
║                                                          ║
║            AI-Assisted Development Environment          ║
║                      Version 1.0.0                      ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

Welcome to BitBot!

BitBot provides a containerized development environment with:
  • Two-mode system (work/setup) for safe AI interaction
  • Git-based safety for easy rollback
  • MCP service integration for AI agents
  • Session management with tmux
  • VS Code integration

This wizard will help you:
  1. Set up your environment
  2. Create your first workspace
  3. Launch your development environment

Press Enter to continue...
```

### 3.2 Quick Start vs Full Setup

```
How would you like to proceed?

1. Quick Start
   Create workspace from template (recommended)
   Fast setup with sensible defaults

2. Custom Setup
   Full configuration wizard
   Fine-tune all settings

3. Import Existing
   Import existing project
   Add BitBot to your project

Choice [1-3]: _
```

---

## 4. Environment Setup

### 4.1 Global Configuration

**User information**:
```
Let's configure BitBot for your account.

? Your name: John Doe
? Your email: john@example.com

✓ Configuration saved to ~/.bitbot/config.yml
```

**Default settings**:
```
Default preferences:

? Default mode [work/setup]: work
? Default shell [bash/zsh]: zsh
? Enable auto-save (sessions) [Y/n]: y
? Auto-save interval (minutes) [15]: 15

✓ Preferences saved
```

### 4.2 Global MCP Services

```
Installing global MCP services...

✓ Downloaded MCP discovery server
✓ Downloaded git-helper service
✓ Downloaded package-manager service

Starting global services...
✓ MCP services started

Global services available at: http://localhost:8080
```

---

## 5. Workspace Initialization

### 5.1 Quick Start Path

**Template selection**:
```
Select a template for your workspace:

  1. Python FastAPI      Web API with Python
  2. Node.js Express     Web server with Node.js
  3. Go Web              Web app with Go
  4. Rust Basic          Rust development
  5. Full Stack          Python backend + React frontend
  6. Browse all...

Choice [1-6]: 1

? Workspace location: /home/user/projects/my-api
? Project name: my-api
? Enable PostgreSQL? [Y/n]: y
? Enable Redis? [y/N]: n

Initializing workspace...
✓ Created .devcontainer/
✓ Created .bitbot/ structure
✓ Installed dependencies
✓ Configured MCP services
✓ Initialized Git repository

✓ Workspace ready!
```

### 5.2 Import Existing Path

**Import wizard**:
```
Import existing project into BitBot

? Project location: /home/user/projects/existing-app

Detecting project type...
✓ Detected: Python project (requirements.txt found)

? Python version [3.11]: 3.11
? Package manager [pip/poetry/pipenv]: pip

? Initialize .devcontainer? [Y/n]: y
? Initialize .bitbot structure? [Y/n]: y
? Initialize Git (if not present)? [Y/n]: n

Importing project...
✓ Created .devcontainer/devcontainer.json
✓ Created .bitbot/ structure
✓ Detected dependencies
✓ Configured MCP services

✓ Project imported!
```

---

## 6. Quick Start Guide

### 6.1 Interactive Tutorial

```
════════════════════════════════════════════════════════
                    QUICK START GUIDE
════════════════════════════════════════════════════════

Your BitBot workspace is ready! Here's how to use it:

1. Launch Work Mode
   $ bitbot work

   This starts your development container with full access
   to your code. Perfect for daily development work.

2. Open in VS Code (optional)
   $ bitbot work --vscode

   Opens VS Code attached to your container.

3. Session Management
   $ bitbot session list        List all sessions
   $ bitbot session new dev     Create new session

4. Setup Mode (for infrastructure changes)
   $ bitbot setup

   Use this mode to modify .devcontainer or Docker configs.

5. Get Help
   $ bitbot help                Show all commands
   $ bitbot status              Check workspace status

════════════════════════════════════════════════════════

Want to see a quick tutorial? [Y/n]: _
```

### 6.2 Interactive Demo

**Tutorial walkthrough**:
```
Let's try a quick demo!

Step 1: Launch work mode
  Command: bitbot work

  [Press Enter to execute]

  ✓ Container started: bitbot-dev-abc123
  ✓ Sessions restored
  ✓ MCP services connected

Step 2: List sessions
  Command: bitbot session list

  [Press Enter to execute]

  Available sessions:
    • work-main (attached)

Step 3: Check MCP services
  Command: bitbot mcp list

  [Press Enter to execute]

  Global Services:
    • git-helper (healthy)
    • package-manager (healthy)

  Workspace Services:
    • filesystem (healthy)
    • git-safety (healthy)

Tutorial complete! You're ready to use BitBot.

[Press Enter to launch workspace]
```

---

## 7. Post-Wizard Actions

### 7.1 Completion Summary

```
════════════════════════════════════════════════════════
                  SETUP COMPLETE!
════════════════════════════════════════════════════════

Your BitBot environment is ready:

Workspace: /home/user/projects/my-api
Template: Python FastAPI
Mode: work (default)

Next steps:

  1. Launch workspace:
     $ cd /home/user/projects/my-api
     $ bitbot work

  2. Read documentation:
     https://docs.bitbot.dev/getting-started

  3. Join community:
     https://github.com/bitbot-dev/bitbot/discussions

════════════════════════════════════════════════════════

Launch workspace now? [Y/n]: _
```

### 7.2 First-Run Marker

**Mark first-run complete**:
```bash
# Create marker file
mkdir -p ~/.bitbot
touch ~/.bitbot/first-run-complete

# Store wizard choices
cat > ~/.bitbot/first-run-info.yml <<EOF
completed_at: $(date -Iseconds)
wizard_version: 1.0.0
workspace_created: /home/user/projects/my-api
template_used: python-fastapi
EOF
```

---

## 8. Error Handling

### 8.1 Prerequisite Failures

**Docker not installed**:
```
✗ Docker not found

BitBot requires Docker to run development containers.

Install Docker:
  macOS/Windows: https://www.docker.com/products/docker-desktop
  Linux: https://docs.docker.com/engine/install/

After installing, run: bitbot

Exiting wizard...
```

**Docker not running**:
```
✗ Docker is not running

Please start Docker Desktop and try again.

  macOS: Open Docker Desktop app
  Windows: Open Docker Desktop app
  Linux: sudo systemctl start docker

Then run: bitbot
```

### 8.2 Wizard Interruption

**User cancels**:
```
Wizard cancelled.

You can restart the wizard anytime with:
  bitbot init --wizard

Or get help:
  bitbot help

Partial configuration saved to: ~/.bitbot/wizard-state.yml
Resume with: bitbot init --resume
```

### 8.3 Recovery Options

**Resume wizard**:
```bash
bitbot init --resume

# Loads ~/.bitbot/wizard-state.yml
# Continues from last completed step
```

**Skip wizard**:
```bash
bitbot init --no-wizard --template python-basic

# Non-interactive initialization
# Uses defaults
```

---

## 9. Testing Strategy

### 9.1 Wizard Tests

- WZ-01: First-run detection works
- WZ-02: Prerequisite checks accurate
- WZ-03: Template selection functional
- WZ-04: Workspace initialization completes
- WZ-05: Tutorial walkthrough works
- WZ-06: Error handling graceful
- WZ-07: Resume from interruption

### 9.2 Platform Tests

- PT-01: Wizard on Linux
- PT-02: Wizard on macOS
- PT-03: Wizard on Windows/WSL2
- PT-04: All prerequisite checks per platform

---

## 10. Success Criteria

**Functional**:
- [ ] First-run detected correctly
- [ ] Prerequisites checked thoroughly
- [ ] Wizard completes end-to-end
- [ ] Workspace initializes successfully
- [ ] Tutorial helpful and clear
- [ ] Errors handled gracefully

**Usability**:
- [ ] Wizard intuitive for beginners
- [ ] Clear instructions
- [ ] Fast completion (<5 minutes)
- [ ] Recovery from errors possible

**Documentation**:
- [ ] Welcome message clear
- [ ] Quick start guide helpful
- [ ] Links to documentation provided
- [ ] Common issues addressed

---

## 11. Implementation Phases

**Phase 1: Core Wizard**:
- First-run detection
- Prerequisite checks
- Basic workspace initialization
- Completion summary

**Phase 2: Template Integration**:
- Template selection UI
- Template wizard prompts
- Quick start vs custom paths
- Import existing project

**Phase 3: Tutorial**:
- Interactive tutorial
- Step-by-step walkthrough
- Demo commands
- Help system integration

**Phase 4: Polish**:
- Error recovery
- Resume from interruption
- Platform-specific instructions
- Telemetry (optional, opt-in)

---

## 12. References

**Related Specifications**:
- SPEC-05: Cross-Platform CLI (wizard commands)
- SPEC-08: Workspace Template System (template selection)
- SPEC-10: Installation & Distribution (installation flow)

**External Resources**:
- CLI wizard best practices
- Onboarding UX patterns

**Research Sources**:
- User feedback on initial setup complexity
- Industry standard onboarding flows (Homebrew, npm init, etc.)

---

**Status**: **Draft**
**Implementation Priority**: P1 (Important for adoption)
**Next Steps**: SPEC-10 (Installation & Distribution)
