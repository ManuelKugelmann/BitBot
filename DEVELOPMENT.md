# BitBot Developer Guide

**For end-user documentation, see [README.md](README.md)**

This guide helps you get started with BitBot development.

---

## Quick Start

### Open in GitHub Codespaces (Fastest)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ManuelKugelmann/BitBot?quickstart=1)

- Environment automatically configured
- Test suite runs on creation
- MinGW for Windows launcher compilation
- Claude Code for AI-assisted development
- No local setup required!

### Local Development Setup

**Prerequisites:**
- Docker Desktop
- VS Code with Dev Containers extension
- Git
- WSL2 (Windows only)

**Clone and Setup:**

```bash
git clone https://github.com/ManuelKugelmann/BitBot.git
cd BitBot

# Open in VS Code DevContainer (recommended)
code .
# Then: Reopen in Container when prompted
```

---

## Development Workflow

### Running Tests

```bash
# Run all tests
cd dev/tests
./run-tests.sh

# Run specific test suites
./test-container-bitbot.sh
./test-bitbot-commands.sh

# Quick Codespaces validation
./test-codespaces.sh
```

### Code Quality Tools

```bash
# Check bash syntax
.claude/tools/check-bash script.sh

# Fix line endings and check syntax
.claude/tools/fix-line-endings-check-bash script.sh

# Run with timeout
.claude/tools/run-with-timeout 60 ./test-script.sh
```

**Important**: Always use provided tools instead of raw `dos2unix` or `sed`. These tools are auto-approved.

### Project Structure

```
BitBot/
├── bitbot                    # Main launcher
├── core/                    # Host-side BitBot (shell scripts)
├── container/
│   ├── bitbot/             # Container-side runtime
│   └── templates/          # DevContainer templates
├── dev/
│   ├── scripts/            # Release and build scripts
│   ├── src/                # Source code (Windows launcher)
│   └── tests/              # Test suites
├── sparc/                   # SPARC methodology docs
└── .devcontainer/           # BitBot development container
```

See [.claude/CLAUDE.md](.claude/CLAUDE.md) for detailed guidelines and [sparc/README.md](sparc/README.md) for architecture documentation.

---

## GitHub Codespaces

### What Works

✅ CLI commands, container bitbot scripts, bash validation, unit tests, platform detection

### What Requires Local Environment

❌ `bitbot work`/`bitbot config` (Docker-in-Docker not available in Codespaces)

**Workaround**: Automatically tested in GitHub Actions CI. Test locally with WSL/Linux.

| Environment | Use For | Docker Available |
|-------------|---------|------------------|
| **Codespaces** | Quick edits, code review, script testing | ❌ No |
| **Local WSL/Linux** | Full development, container testing | ✅ Yes |
| **GitHub Actions** | Automated CI/CD, integration tests | ✅ Yes |

---

## Pull Request Process

1. Create branch from `trunk`: `git checkout -b feature/my-feature`
2. Make changes following project guidelines
3. Test: `dev/tests/run-tests.sh`
4. Fix line endings: `.claude/tools/fix-line-endings-check-bash script.sh`
5. Commit with clear messages
6. Push and create PR
7. Wait for CI - all tests must pass

---

## Branch Strategy

- **`trunk`** - Development branch (tests, research, dev tools)
- **`release`** - Clean distribution branch (production files only)

---

## Getting Help

- **Questions?** Open a GitHub Discussion
- **Bug reports?** Create an issue with reproduction steps
- **Testing issues?** Run with verbose output: `bash -x ./test-script.sh`

---

## Additional Resources

- [.claude/CLAUDE.md](.claude/CLAUDE.md) - Project guidelines
- [sparc/README.md](sparc/README.md) - Architecture and specifications
- [dev/tests/README.md](dev/tests/README.md) - Testing guidelines
- [dev/tests/CODESPACES-TESTING.md](dev/tests/CODESPACES-TESTING.md) - Codespaces guide

---

## License

By contributing, you agree that your contributions will be licensed under MIT License.

Thank you for contributing to BitBot! 🤖
