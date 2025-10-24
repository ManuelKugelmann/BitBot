# BitBot Workflow Scenarios & Open Questions

_Last updated: 2025-10-17_

## 1. Architectural Decision: Use @devcontainers/cli
- **Current plan:** Use @devcontainers/cli for container orchestration and workspace management.
- **Rationale:** Simpler, more maintainable, leverages upstream features. If it proves insufficient, can switch to custom Compose in a future update.
- **Open:** Document any @devcontainers/cli limitations as they arise.

---

## 2. Usage Scenarios & Open Points

### Scenario 1: Normal Development (Work Mode)
- User runs `bitbot work` (or just `bitbot`) in project directory.
- BitBot launches devcontainer using @devcontainers/cli.
- `.bitbot/` (except setup/) is mounted; `.devcontainer/` is read-only; AI agent available; tmux session started.
- User develops, opens more terminals, stops session.
- **Open:** Workspace hash, session resume, error surfacing, Docker validation.

### Scenario 2: Infrastructure Change (Setup Mode)
- User runs `bitbot setup --allow-socket --reason ...`.
- BitBot launches setup container via @devcontainers/cli with elevated mounts.
- User/AI edits `.devcontainer/`, runs audits, applies changes.
- **Open:** Approval workflow, atomic apply, rollback, audit surfacing.

### Scenario 3: AI-Assisted Setup (VS Code)
- User runs `bitbot setup --vscode`.
- VS Code opens in setup container; AI agent assists with config.
- **Open:** VS Code integration, agent action tracking, fallback if VS Code unavailable.

### Scenario 4: Safe Experimentation & Git Protection
- User creates experimental Git branch for AI-assisted changes.
- BitBot checks git state, prompts for backup/commit before major changes.
- AI agent works in work mode on experimental branch; user reviews/merges.
- **Open:** Git safety integration details (SPEC-02A), backup/checkpoint workflow, rollback procedures.

### Scenario 5: MCP Service Management
- User runs `bitbot mcp ...` commands.
- BitBot manages MCP services via @devcontainers/cli/Compose.
- **Open:** Global vs workspace MCP, health/status, logs.

### Scenario 6: First-Run Experience & Configuration
- User runs `bitbot` in new workspace; wizard guides through setup.
- **Open:** Wizard implementation, error handling, config persistence.

---

## 3. Next Steps
- Review/answer open points per scenario.
- Update specs as @devcontainers/cli integration details are validated.
- Add acceptance criteria/user stories for each workflow.
- Document fallback/error handling for each step.

---

_This document is a living reference for workflow-driven spec refinement and open questions tracking._
