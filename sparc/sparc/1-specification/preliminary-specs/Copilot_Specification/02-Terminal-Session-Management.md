# Feature: Terminal Session Management

## Research Reference
- Research/terminal-session-management-research.md (lines 1-51)

## Feature Description
BitBot provides persistent, resumable terminal sessions inside the devcontainer for every workspace.

### Chosen Multiplexer: tmux
- **Why tmux?**
  - Battle-tested, scriptable, and available in all major Linux distributions
  - Lightweight and efficient for container use
  - Deep ecosystem and automation support
  - Well-documented and widely understood by developers
- **Resume/attach is guided via the BitBot CLI** (no need for zellij's UI features)

## Implementation Approach
- Install tmux in every devcontainer
- BitBot CLI manages session creation, listing, and resumption
- Each workspace gets a named tmux session (e.g., `bitbot-myproject`)
- Multiple sessions per workspace are supported (e.g., `bitbot-myproject-2`)
- Session state persists across container restarts

## Rationale
- tmux is the industry standard for terminal multiplexing in devcontainers
- No extra dependencies or large binaries required
- CLI-driven session management keeps the workflow simple and scriptable
