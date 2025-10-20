# Future Features and Roadmap

## Brief Mention: Audit Logging, Advanced Network Limiting
- **Audit Logging:** Planned for future releases. Will log privileged actions, mode switches, and file/network access for compliance and debugging.
- **Advanced Network Limiting:** Future versions will add per-mode network restrictions and firewall rules for work and setup modes.

---

## BitBot CLI UX and Command Structure (Proposal)

### Command Philosophy
- Short, memorable commands (e.g., `bitbot work`, `bitbot claude`, `bitbot config`)
- No double-dash flags for common actions
- Composable: `bitbot work vscode --agent claude` (mode + interface + agent)
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
- **Mode Switching:** Work and setup are separate containers managed by host CLI (no runtime switching inside containers).
- **Agent Selection:** CLI wizard for agent selection/configuration; settings stored in `.bitbot/agent.yml`.
- **Help & Discoverability:** `bitbot help` lists all commands and usage examples.

-- **Experimental Workflow Git Pre-Check:** BitBot provides Git safety checks that verify the working tree is clean before AI-assisted changes. If dirty, BitBot will prompt the user to `Commit`, `Stash`, `Abort`, or `Force`. Git safety is integrated via SPEC-02A.
-- **Experimental Workflows (planned)**: Safe experimental workflows using Git branches will be enhanced in future releases. Uses standard Git workflows (experimental branches, worktrees) rather than a separate mode. Detailed in SPEC-02A (Git Safety Integration).

---

## Next: Workspace State Management and Metadata
- Specification for `.bitbot/` state tracking, session metadata, and mode history will be documented next.

---

## Backlog: Enhanced Experimental Git Workflows

- Priority: Backlogged for post-MVP (recorded so design and implementation can resume later).
- Goal: Provide enhanced Git-based workflows for experimental/agent-driven edits using standard Git features (branches, worktrees).
- **Note**: NOT a separate "sketch mode" - uses work mode with Git branch workflows (see SPEC-02A).
- Planned enhancements (summary):
	- Automated backup via Git bundle before experimental branches
	- Helper commands for creating isolated `git worktree` for experiments
	- CLI helpers for experimental workflow management
	- All actions logged to `.bitbot/audit.log`
- Next steps when unblocked:
	1. Enhance Git safety MCP tools (SPEC-02A)
	2. Add workflow management CLI commands
	3. Integrate with AI agent instructions for experimental branch usage
