# Claude Code Configuration (BitBot Dev)

This directory is mounted to `/root/.claude` in the BitBot development container.

## Purpose

Persistent storage for Claude Code configurations during BitBot development:
- Settings
- Command history
- Tool configurations
- Custom instructions

## Mounted To

`/root/.claude` (root user for dev container)

## Persistence

This folder persists across container rebuilds, allowing you to keep your Claude Code settings while developing BitBot itself.
