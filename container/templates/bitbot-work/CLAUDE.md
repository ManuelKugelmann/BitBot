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

## AI Workspace Template

You are in an AI-powered workspace optimized for development.

### What's Included
- All base features (git, node, Claude Code)
- Shared home folders for AI tool configs
- MCP service integration (if configured)
- Persistent `.claude/` settings

### Shared Home Folders
User's AI tool configurations are persisted:
- `.claude/` → Synced to container
- `.opencode/` → Synced to container
- `.claude-flow/` → Synced to container

### MCP Integration
If MCP services are configured, you can access:
- File operations
- Git operations
- Custom project tools

Query available services: `curl http://mcp-discovery:8080/api/services`

### Your Focus
Help users with:
- AI-assisted development workflows
- Code generation and refactoring
- Test writing
- Documentation
- Git workflows

This is a standard development workspace - users can customize it like any devcontainer.
