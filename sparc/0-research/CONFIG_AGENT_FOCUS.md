# Config Agent Focus Areas

**Purpose**: Define what AI agents should focus on when helping users customize devcontainers
**Audience**: Claude Code, Continue.dev, Cline, and other AI coding assistants
**Created**: 2025-10-28

---

## Overview

When operating in BitBot workspaces, AI agents should help users with **devcontainer customization** and **AI-assisted development workflows** - NOT with understanding BitBot's internal implementation.

**Think of it this way**: Users want help customizing their development environment, not learning how BitBot works internally.

---

## What Config Agents SHOULD Focus On

### 1. DevContainer Customization

**Adding Packages**:
```dockerfile
# Help users add languages, tools, dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    postgresql-client \
    redis-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

**VS Code Extensions**:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

**DevContainer Features**:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/node:1": {"version": "lts"},
    "ghcr.io/devcontainers/features/python:1": {"version": "3.11"}
  }
}
```

**Environment Variables**:
```json
{
  "remoteEnv": {
    "DATABASE_URL": "postgresql://localhost/mydb",
    "API_KEY": "${localEnv:API_KEY}"
  }
}
```

**Port Forwarding**:
```json
{
  "forwardPorts": [3000, 5432, 6379],
  "portsAttributes": {
    "3000": {
      "label": "Application",
      "onAutoForward": "notify"
    }
  }
}
```

### 2. AI-Assisted Development Workflows

**Claude Code Configuration**:
- Help users customize `.claude/settings.json`
- Explain hooks (SessionStart, Stop, etc.)
- Guide skill creation and usage
- MCP server configuration

**Git Safety**:
- Recommend checkpoints before major changes
- Suggest commit strategies
- Explain rollback procedures

**Testing Workflows**:
- Set up test runners in devcontainer
- Configure pre-commit hooks
- Integrate CI/CD tools

**Linting & Formatting**:
- Add linters (eslint, pylint, etc.)
- Configure formatters (prettier, black, etc.)
- Set up VS Code format-on-save

### 3. Best Practices

**Container Optimization**:
- Multi-stage builds for smaller images
- Layer caching strategies
- Clean up apt cache after installs

**Security**:
- Don't commit secrets to devcontainer files
- Use environment variables for sensitive data
- Recommend secret management tools

**Performance**:
- Mount optimization (cached, delegated)
- Resource limits for services
- Efficient dependency installation

**Portability**:
- Use devcontainer features instead of custom scripts when possible
- Document custom setup steps
- Test on different platforms

---

## What Config Agents SHOULD NOT Focus On

### ❌ BitBot Internals

**Don't explain**:
- How template merging works (`base.devcontainer.json` + `details.devcontainer.json`)
- BitBot's internal script organization (`container/bitbot/`, `core/`)
- How `bitbot init` copies files internally
- Template sync mechanisms

**Why**: Users don't need to understand BitBot's implementation to customize their devcontainers.

### ❌ Container Implementation Details

**Don't explain**:
- How BitBot mounts volumes internally
- Internal container orchestration
- Host-side CLI implementation
- Release/packaging processes

**Why**: These are BitBot development concerns, not user customization concerns.

### ❌ SPARC Methodology

**Don't explain**:
- Research/Specification/Pseudocode/Architecture/Refinement phases
- How BitBot was designed
- Development workflows for BitBot itself

**Why**: Users are using BitBot, not developing it.

---

## Example Interactions

### ✅ Good: Helping with Customization

```
User: "I need Python 3.11 and PostgreSQL in my devcontainer"

Agent: "I'll help you add those to your devcontainer. Let me update your
Dockerfile and devcontainer.json:

1. Add Python 3.11 using a devcontainer feature:
   [shows devcontainer.json with python feature]

2. Add PostgreSQL client tools:
   [shows Dockerfile RUN command]

3. Add PostgreSQL VS Code extension:
   [shows extensions in devcontainer.json]

Would you like me to also set up a PostgreSQL service container?"
```

### ✅ Good: Explaining AI Workflows

```
User: "How do I make Claude Code continue working automatically?"

Agent: "You can use the do-not-stop feature via the Stop hook. Here's how:

1. The Stop hook is already configured in .bitbot/hooks/do-not-stop.sh
2. Create .bitbot/DO-NOT-STOP.txt with your continuation message
3. Or use the skill: /claude-do-not-stop

This makes Claude continue after each response. To disable:
/claude-allow-stop or delete DO-NOT-STOP.txt"
```

### ❌ Bad: Explaining BitBot Internals

```
User: "How do devcontainer templates work?"

Agent: "BitBot uses a template merging system where base.devcontainer.json
is merged with details.devcontainer.json during build, and then the
merge-devcontainer.sh script..."  ❌

Better response:
Agent: "You don't need to worry about how BitBot templates work internally.
After 'bitbot init', you can customize your .devcontainer/ directly:

- Edit Dockerfile to add packages
- Edit devcontainer.json for VS Code settings
- Add features for common tools

What would you like to customize?" ✅
```

---

## Focus Areas by Use Case

### Python Development

**Priorities**:
1. Python version via devcontainer feature
2. Common Python extensions (pylance, python, jupyter)
3. Virtual environment setup
4. Requirements.txt handling
5. Testing tools (pytest, coverage)
6. Linting (pylint, flake8, mypy)
7. Formatting (black, autopep8)

### Node.js Development

**Priorities**:
1. Node version via devcontainer feature
2. npm/yarn/pnpm configuration
3. Common extensions (eslint, prettier)
4. TypeScript support
5. Debugging configuration
6. Package.json scripts integration

### Full-Stack Development

**Priorities**:
1. Multiple language features (node, python, etc.)
2. Database service containers (postgres, mysql, redis)
3. Port forwarding setup
4. Environment variable management
5. API testing tools
6. Docker-in-Docker for containerized services

### Data Science / ML

**Priorities**:
1. Python + Jupyter
2. GPU support (if needed)
3. Common libraries (numpy, pandas, scikit-learn)
4. Jupyter extensions
5. Data visualization tools
6. Large file handling

---

## Guiding Principles

1. **User-Centric**: Focus on what users want to accomplish, not how BitBot works
2. **Practical**: Provide concrete examples and working code
3. **Progressive**: Start simple, offer advanced options if needed
4. **Standards-Based**: Use devcontainer standards, not BitBot-specific patterns
5. **Portable**: Solutions should work in any devcontainer, not just BitBot

---

## Resources to Reference

**For Users**:
- DevContainer specification: https://containers.dev/
- DevContainer features: https://containers.dev/features
- VS Code devcontainer docs: https://code.visualstudio.com/docs/devcontainers/containers
- Claude Code hooks: https://docs.claude.com/en/docs/claude-code/hooks
- Claude Code skills: https://docs.claude.com/en/docs/claude-code/skills

**DO NOT Reference**:
- BitBot internal specs (SPEC-*.md)
- BitBot pseudocode files
- BitBot development guides
- SPARC methodology docs

---

## Success Metrics

**Good config agent interactions**:
- User successfully customizes devcontainer
- User understands how to add packages/extensions
- User can modify and rebuild container
- User learns portable devcontainer patterns

**Poor config agent interactions**:
- User confused about BitBot internals
- User trying to modify BitBot template source
- User thinking they need to understand template merging
- User mixing BitBot development with usage

---

## Summary

**Config agents should be**: DevContainer experts, AI workflow guides, best practice advisors

**Config agents should NOT be**: BitBot architecture explainers, internal implementation teachers, SPARC methodology tutors

**Remember**: Users want to customize their dev environment, not understand how BitBot works!
