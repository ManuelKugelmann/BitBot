# BitBot Developer Documentation

This document contains links to architecture, specifications, and development resources for BitBot contributors.

**For end-user documentation, see [README.md](README.md)**

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Architecture & Design](#architecture--design)
3. [Development Process](#development-process)
4. [Testing](#testing)
5. [Release Management](#release-management)

---

## Getting Started

### Contributing

Contributions welcome! This project is under active development.

**Current priorities:**
1. macOS/Linux testing
2. Additional templates
3. Documentation improvements

See [CLAUDE.md](CLAUDE.md) for:
- Development guidelines
- Coding standards
- Tool usage
- Line ending conventions

### Project Structure

See [container-bitbot/README.md](container-bitbot/README.md) for container-side BitBot implementation.

---

## Architecture & Design

### SPARC Documentation

BitBot follows the SPARC methodology (Specification, Pseudocode, Architecture, Refinement, Completion):

**Specifications:**
- [sparc/1-specification/](sparc/1-specification/) - Complete feature specifications
- [sparc/1-specification/OVERVIEW.md](sparc/1-specification/OVERVIEW.md) - Architecture overview

**Pseudocode:**
- [sparc/2-pseudocode/](sparc/2-pseudocode/) - Implementation pseudocode
- [sparc/2-pseudocode/INNER_BITBOT.md](sparc/2-pseudocode/INNER_BITBOT.md) - Container BitBot pseudocode
- [sparc/2-pseudocode/FLOW_INNER_BITBOT.md](sparc/2-pseudocode/FLOW_INNER_BITBOT.md) - Container BitBot flow diagrams

**Architecture:**
- [sparc/3-architecture/](sparc/3-architecture/) - Detailed architecture documents
- [sparc/3-architecture/diagrams/](sparc/3-architecture/diagrams/) - System diagrams

**Research:**
- [sparc/0-research/](sparc/0-research/) - Research documents and decisions
- [sparc/0-research/docker-in-docker-research.md](sparc/0-research/docker-in-docker-research.md) - Docker security analysis
- [sparc/0-research/VM_WRAPPER_SOLUTIONS_RESEARCH.md](sparc/0-research/VM_WRAPPER_SOLUTIONS_RESEARCH.md) - VM isolation research
- [sparc/0-research/CONTAINER_ISOLATION_RESEARCH.md](sparc/0-research/CONTAINER_ISOLATION_RESEARCH.md) - Container isolation analysis

**Completion:**
- [sparc/5-completion/](sparc/5-completion/) - Implementation tracking and TODOs

### Component Documentation

**DevContainers:**
- [.devcontainer/README.md](.devcontainer/README.md) - Development container setup
- [templates/base/README.md](templates/base/README.md) - Base template documentation
- [config-devcontainer/README.md](config-devcontainer/README.md) - Config mode details

**Container BitBot:**
- [container-bitbot/README.md](container-bitbot/README.md) - Container-side BitBot implementation

---

## Development Process

### Branch Strategy

BitBot uses a dual-branch strategy:

- **`trunk`** - Development branch (includes tests, research, dev tools)
- **`release`** - Clean distribution branch (production files only)

### Workflow

1. Develop on `trunk` branch
2. Test thoroughly
3. Run release script to create clean distribution
4. Push to both branches

---

## Testing

### Test Scripts

**Core Tests:**
- [tests/test-prerequisites.sh](tests/test-prerequisites.sh) - Prerequisite validation tests
- [tests/test-workspace-init.sh](tests/test-workspace-init.sh) - Workspace initialization tests

**Windows/WSL Tests:**
- [tests/test-windows-launch.sh](tests/test-windows-launch.sh) - Windows launcher tests
- [tests/test-filesystem-performance.sh](tests/test-filesystem-performance.sh) - WSL filesystem performance tests

**PowerShell Scripts:**
- [tests/enable-docker-wsl-integration-simple.ps1](tests/enable-docker-wsl-integration-simple.ps1) - Docker WSL integration setup

### Running Tests

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test
./tests/test-prerequisites.sh

# Run with verbose output
VERBOSE=1 ./tests/run-tests.sh
```

---

## Release Management

### Release Process

See [RELEASE.md](RELEASE.md) for complete release instructions.

### Release Scripts

**Main Scripts:**
- [scripts/create-release.sh](scripts/create-release.sh) - Create clean release from trunk
- [scripts/README.md](scripts/README.md) - Release script documentation

**Helper Scripts:**
- [scripts/verify-release.sh](scripts/verify-release.sh) - Verify release branch
- [scripts/cleanup-release.sh](scripts/cleanup-release.sh) - Clean up old releases

### Creating a Release

```bash
# Create release from trunk
./scripts/create-release.sh

# Verify release
./scripts/verify-release.sh

# Push to remote
git push origin trunk release
```

---

## Additional Resources

**User Documentation:**
- [README.md](README.md) - Main user documentation
- [README_EXTENDED.md](README_EXTENDED.md) - Extended documentation (security, performance)

**Community:**
- **Issues**: [GitHub Issues](https://github.com/ManuelKugelmann/BitBot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ManuelKugelmann/BitBot/discussions)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright (c) 2025 Manuel Kugelmann, Bitcraft IT Consulting
