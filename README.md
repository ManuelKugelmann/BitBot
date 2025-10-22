```
◆━╮╭╲●═●╱╮ ╭⬡    BitBot v0.1.0-dev
○┳┻▲▌╲━╱━╲▐┳┻■     Secure AI Development Environment
 ╰◇╰▄╱━╲▄╯╰○━□
```

# BitBot

**Secure Development Environments for AI-Assisted Coding**

BitBot is a cross-platform CLI tool that sandboxes AI coding assistants in isolated container environments, reducing risk when working with AI agents. It enables AI assistants to work freely on your code while protecting critical infrastructure files from accidental modification.

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
- Base template: Ubuntu + BitBot (Claude Code, Claude Flow, Open Code)
- 🚧 WIP: Rootless Docker template for Docker-in-Docker workflows
- 🚧 WIP: VM-based template with full Docker for maximum isolation
- 🚧 WIP: Agent steering templates for different workloads

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

**📖 For detailed security analysis, isolation levels, attack vectors, and future VM architecture:**
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

2. **Initialize your workspace:**
   ```bash
   cd ~/Projects/MyApp
   bitbot init
   ```
   This creates a `.devcontainer/` folder with the base Ubuntu template.

3. **Start working:**
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
- Config mode uses `<bitbot>/config-devcontainer/`
- Each mode has its own AI agent configuration

### VS Code Integration

BitBot uses hex-encoded URIs for direct dev container opening:

```bash
# Behind the scenes:
bitbot vscode
  → Converts path to hex
  → Opens: vscode-remote://dev-container+{HEX_PATH}/workspace
  → VS Code opens directly in container (no popup!)
```

**Benefits:**
- No "Reopen in Container" popup
- Container reuse (VS Code reuses same container)
- No WSL corruption (avoids non-.cmd wrapped devcontainer CLI)

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
├── templates/                 # Workspace templates
│   └── basic/                 # Ubuntu + Node.js + Claude Code
├── config-devcontainer/       # Config mode DevContainer
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

**⚠️ CRITICAL: Project Location Matters!**

Store projects in **WSL filesystem** (`~/projects`), **NOT** Windows filesystem (`/mnt/c/`):

| Location | Performance | Status |
|----------|-------------|--------|
| `~/projects` (WSL) | ⭐⭐⭐⭐⭐ Fast | ✅ Use this |
| `/mnt/c/` (Windows) | ⭐⭐ Slow (10-40x) | ⚠️ Avoid |

**Why?**
- WSL filesystem: Native ext4 (fast)
- Windows mount: 9P protocol translation (slow)
- Impact: File ops, git, npm install all 10-40x slower

**Quick Check:**
```bash
pwd  # Should be /home/username/..., NOT /mnt/c/...
df -T .  # Should show ext4, NOT 9p
```

**Windows Access to WSL Files:**

Create junction for convenient Windows access:
```cmd
REM Run as Administrator
mklink /J C:\WSL-Home \\wsl$\Ubuntu\home\username
```

**📖 For detailed performance analysis, profiling tools, and shortcuts:**
**See [Extended Documentation](README_EXTENDED.md#windowswsl-filesystem-performance-analysis)**

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
- [templates/base/README.md](templates/base/README.md) - Base template documentation
- [config-devcontainer/README.md](config-devcontainer/README.md) - Config mode details

**Developer Documentation:**
- See [DEVELOPER.md](https://github.com/ManuelKugelmann/BitBot/blob/trunk/DEVELOPER.md) on trunk branch for architecture, specs, and contribution guidelines

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

