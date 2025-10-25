# Contributing to BitBot

Thank you for your interest in contributing to BitBot! This guide will help you get started with development.

---

## Quick Start for Contributors

### 1. Open in GitHub Codespaces (Fastest)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ManuelKugelmann/BitBot?quickstart=1)

Click the badge above to open BitBot's development environment in Codespaces:
- Environment automatically configured with all dependencies
- Test suite runs automatically on creation
- MinGW for Windows launcher compilation
- Claude Code for AI-assisted development
- No local setup required!

### 2. Local Development Setup

**Prerequisites:**
- Docker Desktop
- VS Code with Dev Containers extension (optional)
- Git
- WSL2 (Windows only)

**Clone and Setup:**

```bash
# Clone the repository
git clone https://github.com/ManuelKugelmann/BitBot.git
cd BitBot

# Option A: Open in VS Code DevContainer (recommended)
code .
# Then: Reopen in Container when prompted

# Option B: Use BitBot itself for development
./bitbot work
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
./test-platform-detection.sh

# Quick Codespaces validation
./test-codespaces.sh
```

### Code Quality

```bash
# Check bash syntax (use these tools!)
.claude/tools/check-bash script.sh

# Fix line endings and check syntax
.claude/tools/fix-line-endings-check-bash script.sh

# Run with timeout (for tests)
.claude/tools/run-with-timeout 60 ./test-script.sh
```

**Important**: Always use the provided tools instead of raw commands like `dos2unix` or `sed`. These tools are auto-approved and don't require user confirmation.

### Project Structure

```
BitBot/
├── bitbot                    # Main launcher (bash)
├── bitbot.cmd               # Windows CMD launcher
├── core/                    # Host-side BitBot (shell scripts)
├── container/
│   ├── bitbot/             # Container-side runtime
│   └── templates/          # DevContainer templates
├── dev/
│   ├── scripts/            # Release and build scripts
│   ├── src/                # Source code (Windows launcher)
│   └── tests/              # Test suites
├── sparc/                   # SPARC methodology docs
│   ├── 0-research/
│   ├── 1-specification/
│   ├── 2-pseudocode/
│   ├── 3-architecture/
│   └── 4-refinement/
└── .devcontainer/           # BitBot development container
```

See `.claude/CLAUDE.md` for detailed project structure and guidelines.

---

## GitHub Codespaces for BitBot Development

### What Works in Codespaces

When developing BitBot in Codespaces, you can:

✅ **Test and validate:**
- CLI commands (`bitbot help`, `bitbot --version`)
- Container bitbot scripts (`container/bitbot/*`)
- Bash syntax validation
- Unit tests
- Platform detection
- Helper utilities

✅ **Develop features:**
- Edit source code
- Write tests
- Update documentation
- Review PRs

### What Requires Local Environment

Some BitBot features require Docker-in-Docker, which isn't available in Codespaces:

❌ **Container orchestration:**
- `bitbot work` / `bitbot config` (create containers from host)
- Full integration tests with actual containers
- DevContainer builds

**Workaround**: These are automatically tested in GitHub Actions CI on every push. You can also test locally with WSL/Linux.

### Codespaces vs Local vs CI

| Environment | Use For | Docker Available |
|-------------|---------|------------------|
| **Codespaces** | Quick edits, code review, script testing | ❌ No |
| **Local WSL/Linux** | Full development, container testing | ✅ Yes |
| **GitHub Actions** | Automated CI/CD, integration tests | ✅ Yes |

---

## Testing Guidelines

### Test Organization

All tests are in `dev/tests/`:
- `run-tests.sh` - Run all test suites
- `test-*.sh` - Individual test suites
- `test-codespaces.sh` - Codespaces-specific validation

### Writing Tests

Follow the existing test structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test helpers
pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    pass_count=$((pass_count + 1))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    fail_count=$((fail_count + 1))
}

# Your tests here
```

See `dev/tests/README.md` for detailed testing guidelines.

---

## Documentation

### SPARC Methodology

BitBot follows the SPARC process:

- **0-research/**: Background research, constraints
- **1-specification/**: Requirements, use cases
- **2-pseudocode/**: Algorithm design
- **3-architecture/**: System design
- **4-refinement/**: POCs, iterations
- **5-completion/**: Completion metadata

Place documentation in the appropriate SPARC folder.

### Naming Conventions

- Shell scripts: `kebab-case.sh`
- Documentation: `kebab-case.md` (root), `UPPERCASE.md` (SPARC research), `01_NUMBERED.md` (specs)
- Directories: `lowercase` or `kebab-case`

---

## Pull Request Process

1. **Create a branch** from `trunk`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** following project guidelines

3. **Test your changes**:
   ```bash
   dev/tests/run-tests.sh
   ```

4. **Fix line endings** (if applicable):
   ```bash
   .claude/tools/fix-line-endings-check-bash changed-file.sh
   ```

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add feature: brief description

   Detailed explanation of what changed and why.

   - Bullet points for key changes
   - Reference issues if applicable"
   ```

6. **Push and create PR**:
   ```bash
   git push origin feature/my-feature
   ```

7. **Wait for CI** - All tests must pass

---

## Getting Help

- **Questions?** Open a discussion on GitHub
- **Bug reports?** Create an issue with:
  - Steps to reproduce
  - Expected vs actual behavior
  - Environment (OS, Docker version, etc.)
  - Relevant logs

- **Testing issues?** Run with verbose output:
  ```bash
  bash -x ./test-script.sh
  ```

---

## Code of Conduct

- Be respectful and constructive
- Focus on the code, not the person
- Help others learn and grow
- Follow project conventions

---

## License

By contributing, you agree that your contributions will be licensed under the same license as BitBot.

---

## Additional Resources

- [SPARC Methodology](sparc/README.md)
- [Project Guidelines](.claude/CLAUDE.md)
- [Test Suite Documentation](dev/tests/README.md)
- [Codespaces Testing Guide](dev/tests/CODESPACES-TESTING.md)
- [Extended Documentation](README-EXTENDED.md)

Thank you for contributing to BitBot! 🤖
