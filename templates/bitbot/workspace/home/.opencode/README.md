# OpenCode Shared Configuration

This folder contains globally shared OpenCode instructions for BitBot workspaces.

## Purpose

- **Mounted to:** `/home/bitbot/.opencode/` in container
- **Scope:** Global OpenCode instructions shared across all BitBot workspace containers
- **Contains:** Code templates, snippets, configuration

## Usage

Place files here that should be available to OpenCode across all BitBot workspace containers:

```
opencode/
  templates/          # Code templates
  snippets/           # Code snippets
  config.yaml         # OpenCode configuration
```

## Notes

- This is BitBot-workspace-specific shared data
- Changes here affect all BitBot workspace containers using this template
- Keep templates focused on workspace development patterns
