# BitBot Development Container

Development environment for BitBot with cross-compilation support.

**This devcontainer is an exact copy of `templates/bitbot/dev/`** - BitBot dogfooding its own template system!

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Features:**
  - Node.js LTS (via devcontainer feature)
  - Git (via devcontainer feature)
  - Claude Code (via official feature)
  - Optional: Claude Flow, Open Code
- **Build Tools:**
  - gcc, make, curl, wget
  - **MinGW-w64** (Windows cross-compiler)
  - zip/unzip utilities
- **Shared Configs:** Persistent AI tool configurations

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

### Verify Installation

```bash
# Check MinGW version
x86_64-w64-mingw32-gcc --version

# Test simple compilation
echo 'int main() { return 0; }' > test.c
x86_64-w64-mingw32-gcc test.c -o test.exe
file test.exe
rm test.c test.exe
```

## VS Code Integration

The container includes C/C++ extensions configured for MinGW:
- **C/C++ Extension** - IntelliSense for C code
- **Makefile Tools** - Build automation support

## Usage

### Open in VS Code

```bash
# From project root
code .
# VS Code will prompt to reopen in container
```

### Manual Container Start

```bash
# Using devcontainer CLI
devcontainer up --workspace-folder .

# Using Docker directly
docker build -t bitbot-dev .devcontainer
docker run -it -v $(pwd):/workspace bitbot-dev
```

## Building Release Files

### Build All

```bash
# Build Windows launcher
cd src/launcher_windows
./build.sh

# Run tests
cd ../../tests
./run-tests.sh
```

### Create Release Archive

```bash
# From project root
zip -r bitbot-release.zip \
  bitbot \
  bitbot.exe \
  bitbot.cmd \
  core/ \
  templates/ \
  README.md \
  LICENSE
```

## Troubleshooting

### MinGW Not Found

If `x86_64-w64-mingw32-gcc` is not found, rebuild the container:

```bash
# Rebuild container
devcontainer build --workspace-folder .

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

## Shared Home Folders

BitBot dev container includes persistent AI tool configurations:

```
.devcontainer/home/
  .claude/       → mounted to /root/.claude
  .claude-flow/  → mounted to /root/.claude-flow
  .opencode/     → mounted to /root/.opencode
```

### Why Shared Folders?

- ✅ **Persistent** - Survive container rebuilds
- ✅ **Shared** - Common configs across BitBot dev sessions
- ✅ **BitBot-scoped** - Specific to BitBot project
- ✅ **Version-controlled** - Part of repository (optional)

## Updating This DevContainer

To sync with the latest template:

```bash
# Copy from template
cp templates/bitbot/dev/Dockerfile .devcontainer/
cp templates/bitbot/dev/devcontainer.json .devcontainer/

# Rebuild container
cmd.exe /c "cd /d C:\Projects\BitBot && devcontainer.cmd build --workspace-folder ."
```

## See Also

- [BitBot Dev Template](../templates/bitbot/dev/README.md) - Source template
- [Workspace Template](../templates/bitbot/workspace/README.md) - For BitBot users
- [MinGW-w64 Documentation](https://www.mingw-w64.org/)
- [DevContainer Specification](https://containers.dev/)
- [src/launcher_windows/README.md](../src/launcher_windows/README.md)
