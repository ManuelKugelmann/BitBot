
# Feature: Container Safety Policy

## Research References
- Research/CONTAINER_ISOLATION_RESEARCH.md (lines 1-51)
- Research/AI_AGENT_SAFETY_ARCHITECTURE.md (lines 1-51)

## Feature Description — Git-Based Safety Only
BitBot uses a simple, predictable safety model: all infrastructure changes and experimental edits are protected by git push or local bundle backup. There are no runtime/container modes or mode switching. All protection is enforced by requiring a clean git state or a backup before allowing destructive or infrastructure-changing actions.

- The workspace is always writable for the developer and agents, but `.devcontainer/` and other critical files are protected by requiring a git push or bundle before changes.
- Sensitive host resources (host Docker socket, system mounts, host root paths) are never mounted into the devcontainer unless the user explicitly approves and has pushed or backed up the workspace.


### Sketch/Experimental Flows

Sketch mode and sketch flows have been removed from the MVP. All safety is enforced by git push or bundle backup. Experimental or sketch workflows are deferred to future features and will be documented separately if reintroduced.

## Chosen Implementation Approach
- Use bind mounts for the workspace. All protection is via git push or bundle backup, not container modes.
- Do not mount host Docker socket by default; only mount it if the user has pushed or backed up the workspace and explicitly approves.
- The Sketch Flow enforces push-or-bundle backups and uses `git worktree` or temporary clones for safe experimentation.

## Rationale
- Git-based safety is simple, predictable, and easy to audit.
- Protecting `.devcontainer/` and other critical files via git push/bundle reduces accidental environment changes that can affect subsequent runs or other developers.
- Requiring push or bundle backups before sketching lowers the risk of destructive, hard-to-recover changes.
