```
◆━╮╭╲●═●╱╮ ╭⬡    BitBot v0.1.0-dev
○┳┻▲▌╲━╱━╲▐┳┻■     Secure AI Development Environment
 ╰◇╰▄╱━╲▄╯╰○━□
```

# BitBot

**Secure Development Environments for AI-Assisted Coding**

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ManuelKugelmann/BitBot?quickstart=1)

BitBot is a cross-platform CLI tool that sandboxes AI coding assistants in isolated container environments, reducing risk when working with AI agents. It enables AI assistants to work freely on your code while protecting critical infrastructure files from accidental modification.

> 💡 **Try BitBot instantly**: Click the badge above to open BitBot in GitHub Codespaces - no local setup required!
>
> ⚠️ **Note**: This badge is for BitBot development only (trunk branch). When you run `bitbot init` in your own projects, you can add a similar badge for your workspace.

---

## Why BitBot?

### The Problem

When working with AI coding assistants like Claude Code, you want them to:

- ✅ Make changes to your application code freely
- ✅ Run tests and debug issues
- ✅ Refactor and improve your codebase
- ✅ Install dependencies and tools

But **not** accidentally:

- ❌ Modify critical infrastructure files (`.devcontainer`, `.github`, `.gitignore`, secrets, Docker configs)
- ❌ Write files outside the project directory
- ❌ Access or modify other projects on your machine
- ❌ Install system-wide packages that affect other projects

### Why DevContainers?

DevContainers are a great standardization that extends plain container definitions with development-specific features, making them perfect for AI-assisted development.

BitBot uses DevContainers to provide isolated, reproducible environments:

**Key Benefits:**

- ✅ **Isolation**: AI changes stay in container, host protected, no dependency conflicts
- ✅ **Reproducible**: Same environment across Windows/macOS/Linux for all developers
- ✅ **Safe**: Reset/rebuild without affecting host, try risky changes safely
- ✅ **Current**: Docker containerization provides reasonable isolation
- 🚧 **WIP**: Full VM sandboxing for maximum security

### BitBot's Two-Mode Solution

### 💚 Work Mode (Default)

- AI can freely modify application code
- `.devcontainer/` files are **read-only** (protected)
- Git safety warnings for uncommitted changes
- Optional rootless Docker (template-dependent)
- Optional full VM sandboxing for enhanced isolation
- Perfect for daily development

### 🔧 Config Mode

- **Read-write** access to `.devcontainer/`
- AI agent optimized for infrastructure tasks
- Use when you need to modify container configuration
- No Docker access (infrastructure editing only)

---

## Features

🔒 **AI Agent Sandboxing**

- **Current**: Docker containerization isolates AI agents to reduce risk
- AI works in controlled environment with limited access
- Infrastructure files protected from accidental modification
- 🚧 **WIP**: Full VM sandboxing for maximum isolation

✨ **Two-Mode Security**

- Work mode protects infrastructure files
- Config mode for safe configuration editing
- Both modes work with VS Code and CLI

🚀 **Cross-Platform**

- **Windows**: Launcher → isolated WSL bash environment
- **macOS**: Native bash
- **Linux**: Native bash

🎯 **VS Code Integration**

- Direct dev container opening (no popup!)
- Container reuse across CLI and VS Code
- Hex-encoded URI protocol for seamless workflow

📦 **Flexible Templates**

- **Workspace template**: Ubuntu + AI tools (Claude Code, Claude Flow, Open Code)
    - Hybrid installation: Official devcontainer features + fallback scripts
    - Shared home folders for persistent AI tool configs (version-controlled)
    - See `templates/workspace/README.md` for details
- Base template: Ubuntu + basic dev environment
- Config template: For managing devcontainer configurations
- 🚧 WIP: Rootless Docker template for Docker-in-Docker workflows
- 🚧 WIP: VM-based template with full Docker for maximum isolation
- 🚧 WIP: Agent steering templates for different workloads

🌐 **Global AI Tool Configuration**

- Single sign-on: Credentials shared across all BitBot workspaces
- Global preferences: Your personal CLAUDE.md and settings apply everywhere
- Workspace isolation: Session data (history, todos) stored per-workspace
- Standard project config: `/workspace/.claude/` works like normal Claude Code
- See `sparc/1-specification/GLOBAL_CLAUDE_CONFIG_SPEC.md` for architecture

🛡️ **Git Safety**

- Warnings for uncommitted changes
- Prompts to review commits before pushing
- Reminds to check for secrets in staged files
- Non-blocking (won't stop your workflow)
- Helps prevent AI from making risky changes to dirty repos

🤖 **Self-Improving System** 🚧 **WIP**

- BitBot self-configuration capabilities
- Agent-driven self-improvement mechanisms
- AI agents can help optimize their own environment

---

## ⚠️ Security Considerations

BitBot provides Docker containerization by default (reasonable isolation). For projects requiring Docker-in-Docker, optional rootless Docker is available with limited isolation.

**📖 For security analysis, isolation levels, attack vectors:**

**See [Extended Documentation](README_EXTENDED.md#docker-in-docker-security-deep-dive)**

---

## Quick Start

### Prerequisites

**All Platforms:**

- Docker Desktop
- VS Code with Dev Containers extension
- Git

**Windows Only:**

- WSL2 enabled

### Installation

**💡 BitBot is Portable**: Install anywhere! No system-wide installation needed. Just clone/extract and add to PATH.

**Recommended: Clone Release Branch (Easy Updates)**

```bash
# Clone release branch for easy updates via git pull
# Replace [INSTALLFOLDER] with your preferred location (e.g., ~/tools/bitbot, /opt/bitbot, etc.)
git clone -b release https://github.com/ManuelKugelmann/BitBot.git [INSTALLFOLDER]/bitbot
cd [INSTALLFOLDER]/bitbot

# Add to PATH (bash) - adjust path to match your chosen location
echo 'export PATH="[INSTALLFOLDER]/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Update later with:
# cd [INSTALLFOLDER]/bitbot && git pull
```

**Alternative: Download Release Archive**

```bash
# Download specific version
wget https://github.com/ManuelKugelmann/BitBot/releases/latest/download/bitbot-v1.0.0.zip

# Extract to your chosen location
unzip bitbot-v1.0.0.zip -d [INSTALLFOLDER]/bitbot

# Add to PATH
echo 'export PATH="[INSTALLFOLDER]/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Example Locations**:

- `~/bitbot` - User home directory
- `~/tools/bitbot` - Personal tools folder
- `/opt/bitbot` - System-wide (requires permissions)
- `/mnt/c/tools/bitbot` - WSL accessing Windows drive

### First Use

1. **Initialize BitBot (one-time):**

   ```bash
   cd [INSTALLFOLDER]/bitbot
   bitbot
   ```

   This runs the first-time setup wizard to configure BitBot preferences.
1. **Initialize your workspace:**

   ```bash
   cd ~/Projects/MyApp
   bitbot init
   ```

   This creates a `.devcontainer/` folder with the base Ubuntu template.
1. **Start working:**

   ```bash
   bitbot work          # Default mode (terminal or VS Code based on setup)
   bitbot work vscode   # Explicitly launch in VS Code
   ```

---

## Usage

### Basic Commands

```bash
# Launch work mode (AI can code, infrastructure protected)
bitbot work
bitbot                 # Same as "bitbot work"

# Launch in VS Code
bitbot vscode
bitbot work vscode

# Edit container configuration
bitbot config

# Initialize new workspace
bitbot init

# Help and version
bitbot help
bitbot version
```

### Example Workflow

**Day-to-day development:**

```bash
cd ~/Projects/MyApp
bitbot work            # Protected mode, code freely with AI
```

**Need to add a VS Code extension?**

```bash
bitbot config          # Opens config mode
# Edit .devcontainer/devcontainer.json
# Add extension to "extensions" array
# Exit and rebuild
bitbot work            # New extension available!
```

**Starting a new project:**

```bash
mkdir ~/Projects/NewProject
cd ~/Projects/NewProject
bitbot init            # Creates .devcontainer/ with template
bitbot work            # Start coding!
```

### GitHub Codespaces Support

BitBot workspaces created with `bitbot init` work seamlessly in GitHub Codespaces!

**Benefits:**
- ✅ Your `.devcontainer` configuration works in Codespaces
- ✅ Container bitbot scripts available at `/usr/local/bitbot`
- ✅ Test and develop from anywhere (no local Docker needed)
- ✅ Share workspace with team via Codespaces link

**After `bitbot init`:**
1. Push your project to GitHub (including `.devcontainer/`)
2. Open in Codespaces from GitHub UI or use direct link
3. BitBot environment loads automatically - you're inside the container!

> **Note**: In Codespaces, you're already running inside your workspace container. No need to run `bitbot work` - just start coding! Container bitbot scripts are available at `/usr/local/bitbot`.

See `dev/tests/CODESPACES-TESTING.md` for details.

---

## Architecture

BitBot uses a **two-mode container system** with separate DevContainers for different security levels:

```
┌─────────────────────────────────────────────────────────────┐
│                         BitBot CLI                          │
│                    (Cross-Platform Router)                  │
└───────────────────┬────────────────┬────────────────────────┘
                    │                │
        ┌───────────▼─────────┐  ┌──▼──────────────────┐
        │    Work Mode        │  │   Config Mode       │
        │  (Infrastructure    │  │  (Infrastructure    │
        │   Protected)        │  │   Editable)         │
        ├─────────────────────┤  ├─────────────────────┤
        │ • Code: RW          │  │ • Code: RW          │
        │ • .devcontainer: RO │  │ • .devcontainer: RW │
        │ • Docker-in-Docker: │  │ • Docker inside: No │
        │   Optional (⚠️)     │  │ • Editing tools only│
        │ • AI: Code-focused  │  │ • AI: Infra-focused │
        └─────────────────────┘  └─────────────────────┘
```

### Mode Switching

Modes run in **separate containers** that can run simultaneously:

- Work mode uses `<workspace>/.devcontainer/`
- Config mode uses `<bitbot>/container/templates/config/`
- Each mode has its own AI agent configuration

### VS Code Integration

Open workspace in VS Code with container auto-launch:

```bash
bitbot vscode    # Opens VS Code in dev container (no popup)
```

**Benefits:** Direct container opening, container reuse, seamless workflow

---

## Project Structure

```
bitbot/
├── bitbot                     # Main CLI router (bash)
├── bitbot.exe                 # Windows launcher (38KB C executable)
├── bitbot.cmd                 # Windows CMD wrapper
├── core/                      # Core runtime scripts
│   ├── global/                # Global commands (first-run setup)
│   ├── workspace/             # Workspace commands (work, config, init)
│   └── util/                  # Utilities (detect, git, prerequisites)
├── templates/                 # DevContainer templates
│   ├── bitbot/                # BitBot internal templates
│   │   ├── base/              # Base template
│   │   ├── config/            # Config mode (infrastructure)
│   │   ├── dev/               # BitBot development
│   │   └── workspace/         # Work mode (AI tools)
│   ├── custom/                # User custom templates
│   └── shared/                # Shared scripts and configs
├── LICENSE                    # MIT License
└── README.md                  # This file
```

---

## Development Status

**Current Status:** 🚧 **Under Development** (Pre-Alpha - Not Yet Tested)

### Implemented Features (Untested)

⚙️ Work mode with read-only `.devcontainer/`

⚙️ Config mode for infrastructure editing

⚙️ VS Code direct container opening

⚙️ Windows launcher → WSL bash

⚙️ Cross-platform bash core (~2600 lines)

⚙️ Git safety warnings

⚙️ Workspace initialization with templates

⚙️ Prerequisite validation

**Note:** MVP implementation complete but requires manual testing before release.

### Roadmap

**Phase 2:**

- [ ] macOS testing and packaging
- [ ] Linux testing and packaging
- [ ] Rootless Docker template for Docker-in-Docker workflows
- [ ] Agent steering templates for different workloads (code, docs, testing)

**Phase 3:**

- [ ] Full VM sandboxing for maximum isolation
- [ ] BitBot self-configuration capabilities
- [ ] Agent-driven self-improvement mechanisms
- [ ] Multi-container orchestration (Docker Compose)
- [ ] MCP service architecture
- [ ] Session management (tmux)

**Future:**

- [ ] Cloud integration (GitHub Codespaces)
- [ ] Team workspace sharing
- [ ] Security scanning integration

---

## Platform-Specific Notes

### Windows

**Isolated WSL Environment:**

- BitBot uses isolated Alpine WSL distro (~8MB)
- Separate from your main WSL distribution
- Installation creates `BitBot-Alpine` automatically

**⚠️ IMPORTANT: Project Location**

Store projects in **WSL filesystem** (`~/projects`), not Windows (`/mnt/c/`):
- WSL: Native ext4 (fast ⭐⭐⭐⭐⭐)
- Windows mount: 9P protocol (10-40x slower ⚠️)

**Quick check:** `pwd` should show `/home/username/...`, not `/mnt/c/...`

**📖 See [Extended Documentation](README_EXTENDED.md#windowswsl-filesystem-performance-analysis) for:**
- Detailed performance analysis and benchmarks
- Windows access to WSL files (junction setup)
- Profiling tools and optimization tips

### macOS / Linux

Native bash execution, no virtualization layer needed.

---

## Contributing

Contributions welcome! This project is under active development.

For contribution guidelines, current priorities, and development setup, see [DEVELOPER.md](DEVELOPER.md).

---

## Documentation

**User Documentation:**

- [README_EXTENDED.md](README_EXTENDED.md) - Detailed security analysis, performance tuning, DevPod integration
- [container/templates/workspace/README.md](container/templates/workspace/README.md) - Workspace template (AI tools)
- [container/templates/config/README.md](container/templates/config/README.md) - Config mode details
- [templates/bitbot/base/README.md](templates/bitbot/base/README.md) - Base template documentation

**Developer Documentation:**

- [DEVELOPER.md](https://github.com/ManuelKugelmann/BitBot/blob/trunk/DEVELOPER.md) - Development setup and contribution guidelines (trunk branch)
- [sparc/1-specification/](sparc/1-specification/) - Complete system specifications (authoritative design docs)
- [sparc/1-specification/README.md](sparc/1-specification/README.md) - Specification overview and index

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright (c) 2025 Manuel Kugelmann, Bitcraft IT Consulting

---

## Author

**Manuel Kugelmann**

Bitcraft IT Consulting

Web: [bitcraft.org](https://bitcraft.org) | LinkedIn: [linkedin.com/in/mkugelmann](https://www.linkedin.com/in/mkugelmann/)

---

## Acknowledgments

Built with the assistance of AI coding tools: Claude, Gemini, GitHub Copilot, Perplexity.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/ManuelKugelmann/BitBot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ManuelKugelmann/BitBot/discussions)

---

**Made with ❤️ for secure AI-assisted coding**