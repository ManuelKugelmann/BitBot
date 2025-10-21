# BitBot

**Secure Development Environments for AI-Assisted Coding**

BitBot is a cross-platform CLI tool that creates isolated, AI-safe development environments using Docker containers. It enables AI coding assistants to work freely on your code while protecting critical infrastructure files from accidental modification.

---

## Why BitBot?

When working with AI coding assistants like Claude Code, you want them to:
- ✅ Make changes to your application code freely
- ✅ Run tests and debug issues
- ✅ Refactor and improve your codebase

But **not** accidentally:
- ❌ Break your Docker configuration
- ❌ Modify `.devcontainer` files incorrectly
- ❌ Change CI/CD workflows unintentionally

**BitBot solves this with two-mode containers:**

### Work Mode (Default)
- AI can freely modify application code
- `.devcontainer/` files are **read-only** (protected)
- Git safety warnings for uncommitted changes
- Perfect for daily development

### Config Mode
- **Read-write** access to `.devcontainer/`
- Includes Docker CLI and DevContainer CLI tools
- AI agent optimized for infrastructure tasks
- Use when you need to modify container configuration

---

## Features

✨ **Two-Mode Security**
- Work mode protects infrastructure files
- Config mode for safe configuration editing
- Both modes work with VS Code and CLI

🚀 **Cross-Platform**
- **Windows**: PowerShell/CMD launcher + WSL2
- **macOS**: Native bash
- **Linux**: Native bash

🎯 **VS Code Integration**
- Direct dev container opening (no popup!)
- Container reuse across CLI and VS Code
- Hex-encoded URI protocol for seamless workflow

📦 **Simple Installation**
- Minimal dependencies
- Template system for quick workspace setup
- Windows: ~8MB Alpine WSL distro (no Docker in WSL needed!)

🛡️ **Git Safety**
- Warnings for uncommitted changes
- Non-blocking (won't stop your workflow)
- Helps prevent AI from making risky changes to dirty repos

---

## Quick Start

### Prerequisites

**All Platforms:**
- Docker Desktop
- VS Code with Dev Containers extension
- Git

**Windows Only:**
- WSL2 enabled
- PowerShell 5.1+

### Installation

**Option 1: Download Release (Recommended)**
```bash
# Download latest release
wget https://github.com/ManuelKugelmann/BitBot/releases/latest/download/bitbot-v1.0.0.zip

# Extract
unzip bitbot-v1.0.0.zip -d ~/bitbot

# Add to PATH
echo 'export PATH="$HOME/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Option 2: Clone Repository**
```bash
git clone -b release https://github.com/ManuelKugelmann/BitBot.git ~/bitbot
cd ~/bitbot

# Add to PATH (bash)
echo 'export PATH="$HOME/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Add to PATH (PowerShell on Windows)
# Add ~/bitbot to your system PATH via System Properties
```

### First Use

1. **Navigate to your project:**
   ```bash
   cd ~/Projects/MyApp
   ```

2. **Initialize workspace:**
   ```bash
   bitbot init
   ```
   This creates a `.devcontainer/` folder with a basic Ubuntu template.

3. **Start working:**
   ```bash
   bitbot work          # Default mode (terminal or VS Code based on first-run setup)
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
        │ • Docker: No        │  │ • Docker: Yes       │
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
- No WSL corruption (no Docker CLI in WSL needed)

---

## Project Structure

```
bitbot/
├── bitbot                     # Main CLI router (bash)
├── bitbot.exe                 # Windows launcher (38KB C executable)
├── bitbot.cmd                 # Windows CMD wrapper
├── lib/                       # Implementation libraries
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

**Current Status:** ✅ **MVP Complete** (Windows tested, macOS/Linux pending)

### Implemented Features

✅ Work mode with read-only `.devcontainer/`
✅ Config mode with infrastructure tools
✅ VS Code direct container opening
✅ Windows PowerShell/CMD launcher
✅ Cross-platform bash core (~2600 lines)
✅ Git safety warnings
✅ Workspace initialization with templates
✅ Prerequisite validation

### Roadmap

**Phase 2:**
- [ ] macOS testing and packaging
- [ ] Linux testing and packaging
- [ ] Additional templates (Python, Go, Rust, etc.)
- [ ] Hash matching for CLI-built containers with VS Code

**Phase 3:**
- [ ] Multi-container orchestration (Docker Compose)
- [ ] MCP service architecture
- [ ] Session management (tmux)
- [ ] Workspace cloning from Git repos

**Future:**
- [ ] Cloud integration (GitHub Codespaces)
- [ ] Team workspace sharing
- [ ] Security scanning integration

---

## Platform-Specific Notes

### Windows

BitBot uses a minimal Alpine WSL distro (~8MB) for cross-platform consistency:
- **No Docker CLI in WSL** (avoids WSL corruption issues)
- **No Node.js in WSL** (only needed for VS Code Server)
- Uses Windows interop to call `code.exe`

Installation creates `BitBot-Alpine` WSL distro automatically.

### macOS / Linux

Native bash execution, no virtualization layer needed.

---

## Contributing

Contributions welcome! This project is under active development.

**Current priorities:**
1. macOS/Linux testing
2. Additional templates
3. Documentation improvements

See [CLAUDE.md](CLAUDE.md) for development guidelines.

---

## Release Process

BitBot uses a dual-branch strategy:

- **`trunk`** - Development (includes tests, research, dev tools)
- **`release`** - Clean distribution (production files only)

See [RELEASE.md](RELEASE.md) for complete release instructions.

---

## Documentation

- [RELEASE.md](RELEASE.md) - Release process and branch strategy
- [scripts/README.md](scripts/README.md) - Release management scripts
- [.devcontainer/README.md](.devcontainer/README.md) - Development container setup
- [templates/basic/README.md](templates/basic/README.md) - Basic template documentation
- [config-devcontainer/README.md](config-devcontainer/README.md) - Config mode details

**Architecture & Research:**
- [_SPARC/Claude_Specification/](_SPARC/Claude_Specification/) - Complete specifications
- [_SPARC/pseudocode/](_SPARC/pseudocode/) - Implementation pseudocode
- [_SPARC/Research/](_SPARC/Research/) - Architecture research and decisions

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright (c) 2025 Manuel Kugelmann, Bitcraft IT Consulting

---

## Author

**Manuel Kugelmann**
Bitcraft IT Consulting

---

## Acknowledgments

Built with:
- [DevContainers](https://containers.dev/) - Container development specification
- [Docker](https://www.docker.com/) - Container runtime
- [Claude Code](https://claude.com/claude-code) - AI coding assistant
- [VS Code](https://code.visualstudio.com/) - IDE integration

**Inspired by** the need for safe AI-assisted development with infrastructure protection.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/ManuelKugelmann/BitBot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ManuelKugelmann/BitBot/discussions)

---

**Made with ❤️ for secure AI-assisted coding**
