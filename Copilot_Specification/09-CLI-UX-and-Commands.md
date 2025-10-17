```markdown

# Feature: BitBot CLI UX & Command Reference

## Goals
- Minimal, cross-platform CLI binary `bitbot` with short, discoverable commands.
- Make common operations one-word verbs (e.g., `bitbot work`, `bitbot setup`, `bitbot list`).
- Commands are scriptable and non-interactive when flags are provided; interactive by default for first-run and setup flows.
- Record actions and approvals in `.bitbot/` for auditability.
- Advanced CLI features (agent management, MCP, etc.) are deferred to future versions and listed in the Future Features spec.


## Top-level commands (surface)
- `bitbot` — smart-launch: resumes an existing session or creates a new one.
- `bitbot work` — start or attach to workspace (default mode).
- `bitbot setup` — start Setup mode (requires explicit `--allow-socket` or `--approve`).
- `bitbot list` — list sessions and containers for current workspace.
- `bitbot stop` — stop the active session/container for workspace.
- `bitbot kill` — stop all BitBot containers on host (global).
- `bitbot config` — interactive wizard to set workspace defaults and agent configs.

*Note: Sketch mode and related flows have been removed. All safety is enforced via git push/bundle and startup warnings.*

## Per-command contracts

Each contract documents: inputs, outputs, side-effects (files, containers), audit entries, exit codes.

1) `bitbot` (smart-launch)
- Inputs: none (optional flags: `--non-interactive`, `--workspace`)
- Behavior: If a single detached session exists for the workspace, attach; if multiple, prompt to choose; if none, start `bitbot work`.
- Outputs: prints chosen session id or container name; returns 0 on attach/start success.
- Side-effects: may create `sessions/<id>.json` and update `metadata.json`.
- Audit: write `Started session <id>` to `.bitbot/audit.log`.
- Exit codes: 0 success, 4 workspace not initialized, 1 generic error.

2) `bitbot work`
- Inputs: optional `--non-interactive`, `--workspace`.
- Behavior: ensure workspace `.bitbot/metadata.json` exists (initialize if needed), start or attach to a work-mode container (rootless Docker for agents not exposed). If container missing, `docker-compose -f .bitbot/docker-compose.yml up -d` or use host-compose flow.
- Outputs: container name and attached tmux session.
- Side-effects: writes `metadata.json` and a `sessions/<id>.json` file.
- Audit: append `work start` entry to `audit.log`.
- Exit codes: 0 success, 4 workspace not initialized, 1 generic error.

3) `bitbot setup --allow-socket --reason "..."`
- Inputs: `--allow-socket` (required for socket mount), `--reason` (required), `--non-interactive` optional.
- Behavior: verify user intent; in interactive mode prompt; in non-interactive mode require `--reason`. Append approval entry to `.bitbot/approvals.json` and `audit.log`. Start container with socket mount and elevated mounts.
- Outputs: approval JSON blob and container name.
- Side-effects: writes to `approvals.json`, `audit.log`, and may update `metadata.json`.
- Audit: record detailed approval entry (ts, user, reason, flags).
- Exit codes: 0 success, 3 security check failed (lack of required flags), 1 generic error.

4) `bitbot list`
- Inputs: none.
- Behavior: enumerate `sessions/*.json` and running BitBot containers for the workspace; print a table.
- Outputs: list of sessions (id, user, last_accessed, attached).
- Side-effects: none.
- Exit codes: 0 success.

5) `bitbot stop`
- Inputs: optional `--session <id>`; default stops current session/container.
- Behavior: stop tmux session and optionally stop container (configurable). Update `sessions/<id>.json` `attached=false` and update `metadata.json.last_updated`.
- Audit: append `stop session <id>` to `audit.log`.
- Exit codes: 0 success, 4 session not found.

6) `bitbot kill`
- Inputs: none or `--confirm` / `--non-interactive` required in scripts.
- Behavior: stops all BitBot-managed containers (ask for confirmation interactively; auto-confirm needed for non-interactive).
- Audit: append `kill` entry with list of stopped containers.
- Exit codes: 0 success.

7) `bitbot config`
- Inputs: interactive; can accept flags for default agent, memory limits, etc.
- Behavior: write values to `.bitbot/metadata.json` and `.bitbot/agent.yml` as appropriate.
- Outputs: prints saved config location.
- Exit codes: 0 success.

8) `bitbot mcp <list|start|stop|logs|restart>`
- Inputs: subcommand and optional service name; `--non-interactive` supported.
- Behavior:
	- `list`: read `.bitbot/mcp/docker-compose.yml` (if exists) and show declared services and their status (running/stopped).
	- `start`: run `docker-compose -f .bitbot/mcp/docker-compose.yml up -d` (in workspace or host depending on mode).
	- `stop`: `docker-compose -f ... down` for workspace stack.
	- `logs`: `docker-compose -f ... logs --tail=200 <service>` and print output.
- Side-effects: may start/stop sibling containers.
- Audit: record start/stop actions to `audit.log` and `approvals.json` if privileged actions are required.

9) `bitbot agent <start|stop|list|exec> <agent-name>`
- Inputs: agent name (e.g., `claude`), optional flags for `--prompt-file` or `--read-only-snapshot`.
- Behavior: manages agent lifecycle. Agents run as sibling containers started by BitBot; by default agents do not mount the live workspace. When `exec` is used, BitBot runs a command in the agent container and returns output.
- Side-effects: starts/stops agent containers, logs to `audit.log`.

10) `bitbot doctor`
- Inputs: none.
- Behavior: run a small set of checks: docker daemon reachable (host), rootless docker status inside container, `.bitbot/` health, MCP discovery endpoint health, disk space.
- Outputs: JSON or human-readable diagnostics.
- Exit codes: 0 success, non-zero if checks fail.

## Test matrix (happy path + edge cases)

For each command, validate:
- Happy path: normal input, expected side-effects, audit lines.
- Edge case 1: workspace uninitialized (no `.bitbot/`) — expect exit code 4 and helpful message.
- Edge case 2: non-interactive mode when interactive choice would be required — expect early failure with code 2 or 3 depending on reason.

Example test cases:
- `bitbot` when no sessions exist: starts work session and writes `sessions/<id>.json`.
- `bitbot setup` without `--reason`: fails with exit code 3 and does not write approvals.
- `bitbot mcp start --non-interactive` with missing compose file: exits with code 4 and helpful message.

## Concurrency and locking

BitBot must guard against concurrent modifications of `sessions/` and `metadata.json`:
- Use an atomic lockfile mechanism (e.g., `flock` on a file inside `.bitbot/lock`) when writing state.
- If lock acquisition fails within a timeout, return a clear error and suggest retry.


## Per-command contracts

Each contract documents: inputs, outputs, side-effects (files, containers), audit entries, exit codes. See above for minimal commands; advanced features are deferred.

## Implementation notes
- CLI is minimal for MVP. Interactive flows are provided for first-run and setup. Advanced features (agent management, MCP, etc.) are deferred to future versions and listed in the Future Features spec.
- `--force`: bypass safety checks (use sparingly; recorded in audit log).
