# BitBot Development Template

Development environment for BitBot itself, combining AI tools with cross-compilation support.

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Features:**
  - Node.js LTS
  - Git
  - Claude Code (official feature)
  - Optional: Claude Flow, Open Code
- **Build Tools:**
  - gcc, make, curl, wget
  - **MinGW-w64** (Windows cross-compiler)
  - zip/unzip utilities
- **Shared Configs:** Persistent AI tool configurations

## Purpose

This template is specifically for **developing BitBot itself** - it's BitBot dogfooding its own workspace features! It combines:

| From Workspace Template | From Dev Container      |
| ----------------------- | ----------------------- |
| Claude Code feature     | MinGW cross-compiler    |
| Shared home folders     | C/C++ extensions        |
| Feature-based installs  | Windows build tools     |
| Persistent configs      | Root user (dev access)  |

## Shared Home Folders

BitBot dev container includes persistent AI tool configurations:

```
.devcontainer/home/
  claude/       → mounted to /root/.claude
  claude-flow/  → mounted to /root/.claude-flow
  opencode/     → mounted to /root/.opencode
```

### Why Shared Folders?

- ✅ **Persistent** - Survive container rebuilds
- ✅ **Shared** - Common configs across BitBot dev sessions
- ✅ **BitBot-scoped** - Specific to BitBot project
- ✅ **Version-controlled** - Part of repository (optional)

## Windows Cross-Compilation

This container includes MinGW-w64 for compiling Windows executables from Linux.

### Compile launcher.exe

```bash
# From project root
cd src/launcher_windows
./build.sh

# Or manually
x86_64-w64-mingw32-gcc launcher.c -o launcher.exe \
  -Os \
  -s \
  -ffunction-sections \
  -fdata-sections \
  -Wl,--gc-sections
```

### Test Compilation

```bash
# Check if binary is Windows executable
file src/launcher_windows/launcher.exe
# Output: PE32+ executable (console) x86-64, for MS Windows

# Check size
ls -lh src/launcher_windows/launcher.exe
# Should be ~38KB
```

### Available Compilers

- **Native:** `gcc` (for Linux binaries)
- **Cross-compile:** `x86_64-w64-mingw32-gcc` (for Windows binaries)

## VS Code Integration

The container includes C/C++ extensions configured for MinGW:
- **C/C++ Extension** - IntelliSense for C code
- **Makefile Tools** - Build automation support

Compiler paths pre-configured:
- `/usr/bin/x86_64-w64-mingw32-gcc`
- IntelliSense mode: `gcc-x64`

## Usage

### Using BitBot Template System

```bash
# Generate devcontainer from this template
templates/shared/scripts/merge-devcontainer.sh templates/bitbotdev

# This will merge:
# - templates/shared/base.devcontainer.json (common base)
# - templates/bitbotdev/details.devcontainer.json (template specifics)
# → templates/bitbotdev/devcontainer.json
```

### Copy to Root for Dogfooding

```bash
# Copy generated files to root .devcontainer
cp templates/bitbotdev/devcontainer.json .devcontainer/
cp templates/bitbotdev/Dockerfile .devcontainer/
cp -r templates/bitbotdev/home .devcontainer/

# Rebuild container
devcontainer.cmd build --workspace-folder .
```

### Manual Container Start

```bash
# Using devcontainer CLI (from Windows/WSL)
cmd.exe /c "cd /d C:\Projects\BitBot && devcontainer.cmd up --workspace-folder ."

# Using Docker directly
docker build -t bitbot-dev templates/bitbotdev
docker run -it -v $(pwd):/workspace bitbot-dev
```

## Building BitBot

### Build Windows Launcher

```bash
# Build launcher.exe with MinGW
cd src/launcher_windows
./build.sh

# Verify it's a Windows executable
file launcher.exe
```

### Run Tests

```bash
# Run all tests
cd tests
./run-tests.sh

# Run specific test
./test-container-bitbot.sh
```

### Create Release Archive

```bash
# From project root
zip -r bitbot-release.zip \
  bitbot \
  bitbot.exe \
  bitbot.cmd \
  lib/ \
  templates/ \
  config-devcontainer/ \
  README.md \
  LICENSE
```

## Enabling Optional Features

### Enable Claude Flow

Uncomment in `details.devcontainer.json`:
```json
"features": {
  "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
  "ghcr.io/anthropics/devcontainer-features/claude-flow:0.3": {
    "version": "latest"
  }
}
```

### Enable Open Code

Uncomment in `details.devcontainer.json`:
```json
"features": {
  "ghcr.io/opencode-dev/features/open-code:0.1": {
    "version": "latest"
  }
}
```

## Differences from Workspace Template

| Aspect           | Workspace Template  | BitBot Dev Template |
| ---------------- | ------------------- | ------------------- |
| **User**         | `/home/bitbot`      | `root`              |
| **Purpose**      | AI workspaces       | BitBot development  |
| **MinGW**        | ❌ Not included      | ✅ Included          |
| **C/C++ Tools**  | ❌ Not included      | ✅ Included          |
| **Mount Target** | `/home/bitbot/...`  | `/root/...`         |
| **Extensions**   | Minimal             | C/C++, Makefile     |

## Troubleshooting

### MinGW Not Found

If `x86_64-w64-mingw32-gcc` is not found, rebuild the container:

```bash
# Rebuild container
cmd.exe /c "cd /d C:\Projects\BitBot && devcontainer.cmd build --workspace-folder ."

# Or in VS Code
# Command Palette → Dev Containers: Rebuild Container
```

### Compilation Errors

```bash
# Verify MinGW installation
dpkg -l | grep mingw

# Should show:
# mingw-w64
# gcc-mingw-w64-x86-64
# binutils-mingw-w64-x86-64
```

### Shared Folders Not Mounting

Ensure `.devcontainer/home/` exists:
```bash
mkdir -p .devcontainer/home/{claude,claude-flow,opencode}
```

### Permission Issues

Run in container:
```bash
chmod 755 /root/.claude
chmod 755 /root/.claude-flow
chmod 755 /root/.opencode
```

## See Also

- [Workspace Template](../workspace/README.md) - For BitBot users
- [MinGW-w64 Documentation](https://www.mingw-w64.org/)
- [DevContainer Specification](https://containers.dev/)
- [src/launcher_windows/README.md](../../src/launcher_windows/README.md)
