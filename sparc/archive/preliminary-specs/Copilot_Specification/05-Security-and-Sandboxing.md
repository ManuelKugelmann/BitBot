
# Feature: Security Architecture & Sandbox Enforcement

## Research References
- Research/AI_AGENT_SAFETY_ARCHITECTURE.md (lines 1-51)
- Research/CONTAINER_ISOLATION_RESEARCH.md (lines 1-51)

## Feature Description
BitBot provides reasonable sandboxing for AI coding agents, focusing on file access and host isolation, while not limiting the developer’s workflow.

## Implementation Approach
- **File Access Control:**
  - All protection is via git push or bundle backup, not container modes. The workspace is always writable, but `.devcontainer/` and other critical files are protected by requiring a git push or bundle before changes.
  - Use Docker bind mounts and volume options to enforce read-only/read-write as needed, but do not rely on runtime/container modes.
- **Host Isolation:**
  - Containers run with user namespaces and capability dropping (no privileged mode by default).
  - No access to host filesystems outside the workspace mount (no /, /home, /mnt, etc.).
  - No Docker socket mount by default (prevents container from controlling host Docker).
  - No access to host Windows shares, Samba, or other networked filesystems by default. (If needed, these can be explicitly mounted by the user, but are not exposed by default.)
- **Networking:**
  - No network restrictions initially; container has the same network access as the host.
  - Future: Add network limiting and firewall rules as needed.
- **Logging:**
  - No audit logging in the initial implementation.
  - Future: Add logging of privileged actions and file/network access.
- **Sketch flow: push-or-bundle rule**:
  - Before starting a sketch flow session, BitBot enforces that the current branch is either:
    1. Pushed to a configured remote (preferred), OR
    2. Backed up as a timestamped local bundle in `.bitbot/backups/` (automatically created when no remote is configured).
  - If neither is true, BitBot prompts the user to push, create a bundle, stash, or abort. This ensures there is a recoverable snapshot in case of destructive edits.
- **Agent execution isolation**:
  - Agents must never be given direct write access to the main workspace. When an agent needs source files, BitBot provides a read-only snapshot (git archive, tar.gz) or runs the agent against an isolated `git worktree` created under `.bitbot/sketches/`.
  - Agent containers are run with restricted capabilities (`--cap-drop=ALL`), resource limits (`--memory`, `--cpus`, `--pids-limit`), and on isolated networks.

## Future-hardening (deferred but recommended)
- Implement optional network-level policies for agent containers (deny-all except allowed hosts).
- Add an audit pipeline to ship `.bitbot/audit.log` entries to an external server for centralized logging (if the organization permits it).
- Consider host filesystem snapshot integration (btrfs/LVM/ZFS) for extremely large repos to enable fast rollbacks.

## Future Features
- Add network restrictions and firewall rules as needed.
- Implement audit logging for privileged actions.
- Explore further isolation for host network shares (Windows/Samba) if required by user feedback.

## Rationale
- Focuses on strong file access and host isolation, which are the most critical for AI agent sandboxing.
- Leaves networking and logging for future iterations to keep the initial implementation simple and developer-friendly.
