# Future Features and Roadmap

## Brief Mention: Audit Logging, Advanced Network Limiting, User-Based Runtime Mode Switching
- **Audit Logging:** Planned for future releases. Will log privileged actions, mode switches, and file/network access for compliance and debugging.
- **Advanced Network Limiting:** Future versions will add per-mode network restrictions and firewall rules, especially for sketch mode.
- **User-Based Runtime Mode Switching:** Will allow seamless switching between root, work, and sketch users inside the container via the BitBot CLI.

---

## BitBot CLI UX and Command Structure (Proposal)

### Command Philosophy
- Short, memorable commands (e.g., `bitbot sketch`, `bitbot claude`, `bitbot config`)
- No double-dash flags for common actions
- Composable: `bitbot sketch claude` (mode + agent)
- Context-aware: adapts to workspace state and user config

### Core Commands
```bash
bitbot                # Smart launch (resume or new session)
bitbot new            # Force new session
bitbot list           # List all sessions
bitbot stop           # Stop current session
bitbot kill           # Stop all BitBot containers
 bitbot work           # Launch in work mode
bitbot setup          # Launch in setup mode
bitbot claude         # Use Claude Code agent
bitbot open           # Use OpenCode agent
bitbot config         # Interactive configuration wizard
bitbot template web   # Apply web development template
bitbot doctor         # System diagnostics
bitbot version        # Version info
```

### UX Details
- **Session Management:** BitBot CLI guides the user to resume, create, or switch sessions.
- **Mode Switching:** Performed inside the container via CLI (no container rebuild required).
- **Agent Selection:** CLI wizard for agent selection/configuration; settings stored in `.bitbot/agent.yml`.
- **Help & Discoverability:** `bitbot help` lists all commands and usage examples.

-- **Sketch Flow Git Pre-Check:** BitBot provides a `sketch` utility (CLI or hook) that verifies the Git working tree is clean before starting rough/experimental edits. If dirty, BitBot will prompt the user to `Commit`, `Stash`, `Abort`, or `Force`. Stashes created by BitBot are recorded under `.bitbot/stashes/` with metadata.
-- **Sketch Flow (planned)**: A safe sketch workflow will be implemented in a future release (MVP excludes). The planned flow will require a push-or-bundle backup before sketching, create isolated `git worktree` or temporary clones for experimentation, and ensure agents never receive direct write mounts to the primary workspace. Detailed scripts and CLI helpers will be provided when this feature is implemented.

---

## Next: Workspace State Management and Metadata
- Specification for `.bitbot/` state tracking, session metadata, and mode history will be documented next.

---

## Backlog: Sketch Flow (safe experimental edits)

- Priority: Backlogged for post-MVP (recorded so design and implementation can resume later).
- Goal: Provide a safe, auditable workflow for experimental/agent-driven edits that protects main branches and history.
- Planned behavior (summary):
	- Require push-or-bundle backups before entering sketch workflows.
	- Create isolated `git worktree` or temporary clones under `.bitbot/sketches/` for experiments.
	- Agents operate only on read-only snapshots or these isolated worktrees; they are never given direct write mounts to the primary workspace.
	- Provide CLI helpers (`bitbot sketch-start`, `bitbot sketch-apply`, `bitbot sketch-restore`) and ensure all actions are logged to `.bitbot/audit.log`.
- Next steps when unblocked:
	1. Draft a small script set (backup, start, apply, restore) and include tests for basic restore scenarios.
	2. Add UI/CLI user experience and prompts for push-or-bundle and apply/restore flows.
	3. Integrate agent-runtime policies (resource caps, cap-drop, network isolation) with the sketch scripts.
