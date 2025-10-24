# Claude Flow Shared Configuration

This folder contains globally shared Claude Flow instructions for BitBot workspaces.

## Purpose

- **Mounted to:** `/home/bitbot/.claude-flow/` in container
- **Scope:** Global Claude Flow instructions shared across all BitBot workspace containers
- **Contains:** Workflow definitions, automation scripts, flow templates

## Usage

Place files here that should be available to Claude Flow across all BitBot workspace containers:

```
claude-flow/
  workflows/          # Flow workflow definitions
  config.yaml         # Flow configuration
  templates/          # Flow templates
```

## Notes

- This is BitBot-workspace-specific shared data
- Changes here affect all BitBot workspace containers using this template
- Keep workflows focused on workspace automation and development processes
