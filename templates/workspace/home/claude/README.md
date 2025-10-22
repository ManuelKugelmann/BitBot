# Claude Code Shared Configuration

This folder contains globally shared Claude Code instructions for BitBot workspaces.

## Purpose

- **Mounted to:** `/home/bitbot/.claude/` in container
- **Scope:** Global Claude Code instructions shared across all BitBot workspace containers
- **Contains:** CLAUDE.md, custom tools, project templates

## Usage

Place files here that should be available to Claude Code across all BitBot workspace containers:

```
claude/
  CLAUDE.md           # Global Claude instructions
  tools/              # Custom Claude tools
  templates/          # Project templates
```

## Notes

- This is BitBot-workspace-specific shared data (not system-wide ~/.claude)
- Changes here affect all BitBot workspace containers using this template
- Keep instructions focused on workspace development workflows
