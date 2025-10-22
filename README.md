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

BitBot uses DevContainers to provide isolated, reproducible environments:

**Isolation:**
- ✅ AI changes stay inside the container
- ✅ Host system protected from accidental modifications
- ✅ Each workspace has its own isolated environment
- ✅ No conflicts between project dependencies

**Reproducibility:**
- ✅ Same environment for all developers
- ✅ Works identically on Windows, macOS, and Linux
- ✅ Version-controlled environment configuration
- ✅ Easy onboarding for new team members

**Safety:**
- ✅ Container can be reset/rebuilt without affecting host
- ✅ Experiments stay isolated (try risky changes safely)
- ✅ Clean separation of development tools from host system
- ✅ **Current**: Docker containerization provides strong isolation
- 🚧 **WIP**: Full VM sandboxing for maximum security (Docker-in-VM)

### BitBot's Two-Mode Solution

### Work Mode (Default)
- AI can freely modify application code
- `.devcontainer/` files are **read-only** (protected)
- Git safety warnings for uncommitted changes
- Optional rootless Docker (template-dependent)
- Optional full Docker in VM for enhanced isolation
- Perfect for daily development

### Config Mode
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
- **WIP**: Full VM sandboxing for maximum isolation (Docker-in-VM architecture)

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
- Base template: Ubuntu + Node.js + Claude Code + inner BitBot helpers
- WIP: Rootless Docker template for Docker-in-Docker workflows
- WIP: VM-based template with full Docker for maximum isolation
- WIP: Agent steering templates for different workloads

🛡️ **Git Safety**
- Warnings for uncommitted changes
- Prompts to review commits before pushing
- Reminds to check for secrets in staged files
- Non-blocking (won't stop your workflow)
- Helps prevent AI from making risky changes to dirty repos

🤖 **Self-Improving System (WIP)**
- BitBot self-configuration capabilities
- Agent-driven self-improvement mechanisms
- AI agents can help optimize their own environment

---

## ⚠️ Security Considerations

### Docker-in-Docker for Work Containers

If your work container needs Docker (e.g., for building Docker images, running Docker Compose), BitBot will use **rootless Docker-in-Docker** as a temporary solution:

**Current Approach (Interim):**
- Rootless Docker inside work container (no privileged mode)
- Limited isolation - container escape possible by design
- **Use only for trusted AI agents and code**
- Not suitable for untrusted/malicious code execution

**Limitations:**
- ⚠️ Container breakout is possible (rootless Docker shares host kernel)
- ⚠️ AI agent has access to Docker socket (can create containers)
- ⚠️ Not suitable for running untrusted code or adversarial AI testing
- ⚠️ Should only be used with AI agents you trust

**Future (Planned):**
- Full VM-based sandboxing (Docker-in-VM architecture)
- Complete isolation between host and work environment
- Safe for untrusted code and experimental AI agents
- See roadmap for VM sandboxing implementation timeline

**Recommendation:** Until VM isolation is implemented, use work mode without Docker for maximum safety, or only use Docker-in-Docker with AI agents and codebases you fully trust.

### Docker-in-Docker Security Comparison

Different approaches to running Docker inside containers have vastly different security profiles:

| Solution                           | Kernel Sharing                 | Container Escape Risk                   | Setup Complexity | Performance    | Best For             |
|------------------------------------|--------------------------------|-----------------------------------------|------------------|----------------|----------------------|
| **No Docker** (default)            | N/A                            | ✅ None                                 | ⭐ Simple        | ⭐⭐⭐⭐⭐       | Code-only work       |
| **Privileged DinD**                | ✅ Yes (same kernel)           | ⚠️  HIGH - Multiple vectors             | ⭐⭐ Medium       | ⭐⭐⭐⭐         | Trusted dev only     |
| **Rootless Docker-in-Docker**      | ✅ Yes (same kernel)           | ⚠️  MEDIUM - Kernel exploits possible   | ⭐⭐⭐ Complex     | ⭐⭐⭐           | Better than priv     |
| **Docker Socket Mount**            | ✅ Yes (host Docker)           | ⚠️  HIGH - Root equivalent              | ⭐ Simple        | ⭐⭐⭐⭐⭐       | Trusted dev only     |
| **Sysbox Runtime**                 | ✅ Yes (with user namespaces)  | ✅ LOW - User namespace isolation       | ⭐⭐⭐⭐ Hard      | ⭐⭐⭐⭐         | Production-like      |
| **DevPod + VM/Cloud** (target)     | ❌ No (VM/cloud kernel)        | ✅ VERY LOW - VM isolation              | ⭐⭐⭐⭐ Hard      | ⭐⭐⭐           | Untrusted code       |
| **Kata Containers**                | ❌ No (micro-VM per container) | ✅ VERY LOW - VM per container          | ⭐⭐⭐⭐⭐ V.Hard  | ⭐⭐             | Maximum security     |

**Security Risk Details:**

| Approach              | Container Breakout | Host Compromise | Kernel Vulnerabilities | Resource Exhaustion | Privilege Escalation |
|-----------------------|--------------------|-----------------|------------------------|---------------------|----------------------|
| **Privileged DinD**   | ⚠️  HIGH           | ⚠️  HIGH        | ⚠️  HIGH               | ⚠️  HIGH            | ⚠️  HIGH             |
| **Rootless DinD**     | ⚠️  MEDIUM         | ⚠️  MEDIUM      | ⚠️  HIGH               | ⚠️  MEDIUM          | ✅ LOW               |
| **Socket Mount**      | ⚠️  HIGH           | ⚠️  HIGH        | ⚠️  MEDIUM             | ⚠️  HIGH            | ⚠️  HIGH             |
| **Sysbox**            | ✅ LOW             | ✅ LOW          | ⚠️  MEDIUM             | ⚠️  MEDIUM          | ✅ LOW               |
| **DevPod + VM/Cloud** | ✅ VERY LOW        | ✅ VERY LOW     | ✅ LOW                 | ✅ LOW              | ✅ VERY LOW          |
| **Kata Containers**   | ✅ VERY LOW        | ✅ VERY LOW     | ✅ VERY LOW            | ✅ VERY LOW         | ✅ VERY LOW          |

**Specific Attack Vectors:**

<details>
<summary><b>Privileged DinD Attack Examples</b> (click to expand)</summary>

**Device Access Escape:**
```bash
# Inside privileged container - attacker can:
mkdir /mnt/host
mount /dev/sda1 /mnt/host  # Mount host filesystem
# Now has full read/write access to host
```

**Kernel Module Loading:**
```bash
# Can load malicious kernel modules
insmod rootkit.ko  # Compromise entire host
```

**PID Namespace Manipulation:**
```bash
# Access host processes
nsenter -t 1 -m -u -n -i sh  # Escape to host namespace
```
</details>

<details>
<summary><b>Rootless Docker-in-Docker Limitations</b> (click to expand)</summary>

**Still Vulnerable To:**
- Kernel exploits (shares host kernel)
- Container runtime vulnerabilities
- Resource exhaustion attacks
- Side-channel attacks (Spectre/Meltdown)

**Better Than Privileged:**
- Root in container ≠ Root on host (user namespace remapping)
- Limited device access
- Reduced attack surface
</details>

**BitBot's Approach:**

| Phase                 | Solution                            | Security Level | Status                           |
|-----------------------|-------------------------------------|----------------|----------------------------------|
| **Current (MVP)**     | No Docker by default                | ✅ High        | ✅ Implemented                   |
| **Optional (Now)**    | Rootless Docker-in-Docker           | ⚠️  Medium     | 🚧 Available for trusted flows   |
| **Future (Phase 3)**  | DevPod (Docker/VM/Cloud providers)  | ✅ Very High   | 📋 Planned                       |
| **Long-term**         | Kata Containers or VM-per-workspace | ✅ Maximum     | 💡 Research                      |

**DevPod Provider Options** (Phase 3):
- **Docker** (local) - Fast, same as current but via DevPod
- **Multipass** (local VM) - Ubuntu VM isolation on Windows/macOS/Linux
- **AWS/GCP/Azure** (cloud) - Remote development with VM isolation
- **Kubernetes** (cluster) - For team/enterprise deployments
- **SSH** (custom) - Connect to any remote machine

### DevPod on Windows + WSL2 + Docker Desktop

**Compatibility**: ✅ DevPod works with Docker Desktop on Windows via WSL2 integration

**Critical Path Considerations**:

| Storage Location                 | Performance          | DevPod Compatibility | Recommendation |
|----------------------------------|----------------------|----------------------|----------------|
| WSL filesystem (`/home/user/`)   | ⭐⭐⭐⭐⭐ Fast         | ✅ Excellent         | **Use this**   |
| Windows filesystem (`/mnt/c/`)   | ⭐⭐ Slow (10x)       | ⚠️  Path issues      | **Avoid**      |

**Known Issues**:
- ⚠️ **Path Binding**: DevPod may have issues with `/mnt/c/` paths when Docker is in WSL
- ⚠️ **devpod-home**: Setting `devpod-home=/mnt/c/Users/MyUser/` can cause incorrect volume binding
- ✅ **Workaround**: Store projects in WSL filesystem (`/home/user/projects`)
- ✅ **Docker Desktop**: Ensure WSL2 integration is enabled in Docker Desktop settings
- 🔧 **Status**: WSL integration improved significantly as of April 2025

**Recommended Setup for Windows**:
```bash
# 1. Store projects in WSL filesystem
cd ~/projects  # Not /mnt/c/Projects

# 2. Use DevPod with Docker provider
devpod provider add docker
devpod provider use docker

# 3. Verify Docker Desktop WSL2 integration
docker context ls  # Should show WSL context

# 4. Create workspace from WSL path
devpod up ~/projects/my-repo
```

**Alternative for Better Isolation**:
```bash
# Use Multipass provider for VM isolation (doesn't use /mnt/c)
devpod provider add multipass
devpod provider use multipass
devpod up ~/projects/my-repo
```

**Performance Comparison (Windows)**:

| Approach                      | Startup | I/O Performance  | Isolation | Path Issues  |
|-------------------------------|---------|------------------|-----------|--------------|
| DevPod + Docker (WSL paths)   | Fast    | ⭐⭐⭐⭐⭐         | Medium    | ✅ None      |
| DevPod + Docker (/mnt/c)      | Fast    | ⭐⭐             | Medium    | ⚠️  Common   |
| DevPod + Multipass            | Medium  | ⭐⭐⭐⭐           | High      | ✅ None      |

**References:**
- Docker-in-Docker Research: [sparc/0-research/docker-in-docker-research.md](sparc/0-research/docker-in-docker-research.md)
- VM Wrapper Solutions: [sparc/0-research/VM_WRAPPER_SOLUTIONS_RESEARCH.md](sparc/0-research/VM_WRAPPER_SOLUTIONS_RESEARCH.md)
- Container Isolation: [sparc/0-research/CONTAINER_ISOLATION_RESEARCH.md](sparc/0-research/CONTAINER_ISOLATION_RESEARCH.md)

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

**Recommended: Clone Release Branch (Easy Updates)**
```bash
# Clone release branch for easy updates via git pull
git clone -b release https://github.com/ManuelKugelmann/BitBot.git ~/bitbot
cd ~/bitbot

# Add to PATH (bash)
echo 'export PATH="$HOME/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Update later with:
# cd ~/bitbot && git pull
```

**Alternative: Download Release Archive**
```bash
# Download specific version
wget https://github.com/ManuelKugelmann/BitBot/releases/latest/download/bitbot-v1.0.0.zip

# Extract
unzip bitbot-v1.0.0.zip -d ~/bitbot

# Add to PATH
echo 'export PATH="$HOME/bitbot:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### First Use

1. **Initialize BitBot (one-time):**
   ```bash
   cd ~/bitbot
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
- [ ] Full VM sandboxing for maximum isolation (Docker-in-VM architecture)
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

BitBot uses a minimal isolated Alpine WSL distro (~8MB) for cross-platform consistency:
- Isolated environment separate from your main WSL distribution
- Minimal footprint with only essential tools (bash, git, coreutils)
- Uses Windows interop to call `code.exe`

Installation creates `BitBot-Alpine` WSL distro automatically.

#### Project Location and Filesystem Performance

**Critical Performance Impact**: Where you store your projects on Windows/WSL significantly affects development experience.

| Location                      | I/O Performance | Recommendation | Use Case                    |
|-------------------------------|-----------------|----------------|-----------------------------|
| WSL filesystem (`~/projects`) | ⭐⭐⭐⭐⭐ Fast    | ✅ **Use this** | Development, containers     |
| Windows (`/mnt/c/Projects`)   | ⭐⭐ Slow (10x)  | ⚠️  **Avoid**   | Windows-only tools, sharing |

**Performance Tests**:

```bash
# Test 1: File creation speed
# WSL filesystem
time (for i in {1..1000}; do touch ~/test-wsl/file$i.txt; done)
# Result: ~0.5 seconds

# Windows filesystem
time (for i in {1..1000}; do touch /mnt/c/test-win/file$i.txt; done)
# Result: ~5-8 seconds (10-16x slower)

# Test 2: Node.js npm install (typical workload)
# WSL filesystem: ~30 seconds
# Windows filesystem: ~300 seconds (10x slower)

# Test 3: Git operations
# WSL: git status ~0.1s, git diff ~0.2s
# Windows: git status ~1-2s, git diff ~2-5s
```

**Profiling Tools**:

```bash
# Profile filesystem I/O
sudo apt install sysstat
iostat -x 1 10  # Monitor during operations

# Compare dd performance
# WSL filesystem
dd if=/dev/zero of=~/test-wsl.dat bs=1M count=1000 conv=fdatasync
# ~500-800 MB/s

# Windows filesystem
dd if=/dev/zero of=/mnt/c/test-win.dat bs=1M count=1000 conv=fdatasync
# ~50-100 MB/s (5-10x slower)
```

**Why the Difference?**

- **WSL filesystem**: Native ext4, direct kernel access
- **Windows filesystem**: 9P protocol translation layer (Plan 9 Filesystem Protocol)
- **Impact**: Every file operation crosses the WSL↔Windows boundary

**Best Practices**:

✅ **DO**:
- Store BitBot projects in WSL filesystem (`~/projects/`)
- Use WSL-native paths for devcontainers
- Keep git repositories in WSL
- Run `bitbot init` from WSL paths

⚠️ **DON'T**:
- Store projects in `/mnt/c/` for development
- Use Windows paths with containers
- Mix WSL and Windows file access

**Exception**: Use Windows filesystem only when:
- Need Windows-native tools (Visual Studio, Office)
- Sharing files with Windows applications
- Working with large binary files accessed from Windows

**Verification**:

```bash
# Check where you are
pwd
# Good: /home/username/projects/myapp
# Bad:  /mnt/c/Users/username/projects/myapp

# Check filesystem type
df -T .
# Good: Filesystem Type = ext4
# Bad:  Filesystem Type = 9p
```

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
- [templates/base/README.md](templates/base/README.md) - Base template documentation
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
LinkedIn: [linkedin.com/in/mkugelmann](https://www.linkedin.com/in/mkugelmann/)

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

