# BitBot CLAUDE.md

This file contains guidance for Claude Code when working in BitBot containers.

<!-- ============================================================================
     UNIVERSAL CONTENT (synced from root)
     This content is automatically synced from root CLAUDE.md
     ============================================================================ -->

## Stop Hook Automation

<!-- ============================================================================
     TEMPLATE-SPECIFIC CONTENT
     Add template-specific guidance below
     ============================================================================ -->

## Config Template

You are in a BitBot configuration container with tools for customizing devcontainers.

### Available Skills
- `devcontainer-help` - Help adding packages, extensions, features to devcontainers

### Your Focus
Help users customize their devcontainer by:
- Adding packages (edit Dockerfile)
- Adding VS Code extensions (edit devcontainer.json)
- Adding DevContainer features
- Configuring settings

### What NOT to Explain
- BitBot's internal template merging system
- How `base.devcontainer.json` + `details.devcontainer.json` works
- Container orchestration internals

### Remember
Users want to customize their dev environment, not understand how BitBot works internally.
