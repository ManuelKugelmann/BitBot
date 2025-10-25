# Testing BitBot in GitHub Codespaces

This guide explains how to test BitBot functionality in GitHub Codespaces.

## Two Scenarios

1. **BitBot Development** (this repository): Uses `postCreateCommand` to test on container creation
2. **BitBot User Workspaces** (after `bitbot init`): Can use `postAttachCommand` for validation on editor attach

## Quick Start

### Option 1: Open in Codespaces (Web)

1. Go to the [BitBot repository](https://github.com/ManuelKugelmann/BitBot)
2. Click the green **Code** button
3. Select **Codespaces** tab
4. Click **Create codespace on trunk** (or your branch)
5. Wait for the container to build (~2-3 minutes first time)

### Option 2: Open in Codespaces (VS Code Desktop)

1. Install the [GitHub Codespaces extension](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces)
2. Open VS Code Command Palette (Ctrl/Cmd+Shift+P)
3. Type "Codespaces: Create New Codespace"
4. Select `ManuelKugelmann/BitBot` repository
5. Choose branch (usually `trunk`)

### Option 3: Use Codespaces Badge

Click this badge to open directly:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ManuelKugelmann/BitBot?quickstart=1)

---

## What Gets Tested

The BitBot repository includes a `.devcontainer` configuration that:

- ✅ Sets up a Linux development environment
- ✅ Installs Node.js LTS
- ✅ Installs Claude Code
- ✅ Includes MinGW for Windows launcher compilation
- ✅ Mounts workspace and BitBot configs
- ✅ Runs as root user (for container management)

---

## Testing Checklist

Once your Codespace is running, test the following:

### 1. Basic BitBot Commands

```bash
# Test BitBot launcher
./bitbot --version
./bitbot help

# Test prerequisite detection
dev/tests/test-prerequisites.sh

# Test platform detection
dev/tests/test-platform-detection.sh

# Test BitBot commands
dev/tests/test-bitbot-commands.sh
```

### 2. Container BitBot Scripts

```bash
# Test container-side BitBot runtime
dev/tests/test-container-bitbot.sh

# Should show all 28 tests passing
```

### 3. Run Full Test Suite

```bash
# Run all tests
cd dev/tests
./run-tests.sh

# Expected: 7/7 test suites passing
```

### 4. Test DevContainer Features

```bash
# Check Docker availability (important for BitBot!)
docker --version
docker ps

# Check if Docker daemon is accessible
docker info

# Check Claude Code installation
claude-code --version  # or claude --version

# Check Node.js
node --version
npm --version
```

### 5. Test BitBot Init (Simulated)

Since Codespaces doesn't support nested containers by default, you can test:

```bash
# Create a test workspace
mkdir -p /tmp/test-workspace
cd /tmp/test-workspace

# Initialize workspace structure (manual simulation)
mkdir -p .devcontainer/bitbot

# Copy container bitbot scripts
cp -r /workspace/container/bitbot/* .devcontainer/bitbot/

# Verify mount target would exist
ls -la .devcontainer/bitbot/

# Test container bitbot scripts directly
.devcontainer/bitbot/bitbot help
.devcontainer/bitbot/core/commands/analyze.sh
.devcontainer/bitbot/core/commands/status.sh
```

---

## Known Limitations in Codespaces

### Docker-in-Docker

GitHub Codespaces has limited Docker socket access:

- ❌ **Cannot run nested containers** (Docker-in-Docker)
- ❌ **Cannot test `bitbot work` or `bitbot config`** (requires creating containers)
- ✅ **Can test CLI commands** that don't require containers
- ✅ **Can test container bitbot scripts** directly
- ✅ **Can run all unit tests** and integration tests

### Workarounds

1. **Test container scripts directly** without running actual containers
2. **Use GitHub Actions** for full integration testing (already configured)
3. **Test locally with WSL/Linux** for full Docker support

---

## CI/CD Integration

BitBot uses GitHub Actions for automated testing:

- View runs: `gh run list`
- View latest: `gh run view`
- Check status: All tests run on every push to `trunk`

See `.github/workflows/tests.yml` for the full test configuration.

---

## Troubleshooting

### Codespace Won't Start

```bash
# Check devcontainer configuration
cat .devcontainer/devcontainer.json

# Check Dockerfile
cat .devcontainer/Dockerfile

# View Codespace logs in GitHub UI
# Settings → Codespaces → Your codespace → View logs
```

### Tests Fail in Codespace

```bash
# Check file permissions
ls -la bitbot core/util/*.sh

# Fix permissions if needed
chmod +x bitbot
chmod +x core/util/*.sh

# Check bash syntax
bash -n bitbot
bash -n core/util/helpers.sh
```

### Docker Not Available

Codespaces may not expose Docker socket:

```bash
# Check if Docker socket exists
ls -la /var/run/docker.sock

# If not available, you can only test:
# - CLI commands (bitbot help, version, etc.)
# - Container bitbot scripts directly
# - Unit tests that don't require Docker
```

---

## What to Test For

### ✅ Should Work

- All shell script syntax validation
- BitBot CLI help and version commands
- Platform detection
- Prerequisite checking (reports missing Docker)
- Container bitbot script execution (without containers)
- File structure validation
- Unit tests

### ❌ Won't Work (Docker Required)

- `bitbot work` - Requires creating work container
- `bitbot config` - Requires creating config container
- `bitbot vscode` - Requires VS Code + containers
- DevContainer builds
- Full integration tests with actual containers

### 🔧 Testing Strategy

For full integration testing:
1. **Codespaces**: Test CLI, scripts, and validation logic
2. **GitHub Actions**: Test full container workflows (automated)
3. **Local WSL/Linux**: Test complete BitBot workflows manually

---

## Reporting Issues

When reporting Codespaces-related issues:

1. Include Codespace logs
2. Run `./dev/tests/run-tests.sh` and include output
3. Check `.devcontainer/devcontainer.json` for any modifications
4. Note your Codespace machine type (2-core, 4-core, etc.)
5. Mention if Docker socket is available: `ls -la /var/run/docker.sock`

---

## User Workspace Codespaces Support

When you run `bitbot init` in your project, BitBot creates a `.devcontainer` configuration that also works in GitHub Codespaces!

### Recommended Setup for User Workspaces

Add to your `.devcontainer/devcontainer.json`:

```json
{
  "postAttachCommand": ".devcontainer/bitbot/bitbot help || echo 'BitBot commands available at /usr/local/bitbot'"
}
```

**Why `postAttachCommand`?**
- Runs when editor attaches (not on every container restart)
- Less intrusive than `postCreateCommand`
- Shows BitBot is available without running full test suite
- User-friendly for workspaces

### Opening Your Workspace in Codespaces

If your project has a GitHub remote:

```bash
# Get Codespaces URL (shown by bitbot init)
https://codespaces.new/YOUR-USERNAME/YOUR-REPO?quickstart=1
```

Or manually:
1. Push your workspace to GitHub (with `.devcontainer` folder)
2. Open repository on GitHub
3. Click **Code** → **Codespaces** → **Create codespace**
4. BitBot will be available at `/usr/local/bitbot`

---

## Next Steps

After verifying BitBot works in Codespaces:

- [x] Add Codespaces badge to README.md (documented)
- [x] Document Docker-in-Docker limitations (complete)
- [x] Codespaces-specific test suite (implemented)
- [x] Add postCreateCommand for BitBot dev (implemented)

See `sparc/1-specification/08_WORKSPACE_MANAGEMENT.md` for workspace architecture.
