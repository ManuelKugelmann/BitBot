```markdown

# Feature: Workspace State & Metadata (.bitbot/)

## Purpose
Define a minimal, cross-platform on-disk schema for BitBot to track per-workspace state, session metadata, backups, and administrative approvals. The directory is designed to be small, auditable, and not exposed to agent containers by default. Advanced state tracking (detailed agent logs, session replay, stashes, sketches) is deferred to future versions and listed in the Future Features spec.

## Goals
- Track container and session identifiers so BitBot can resume or reattach sessions reliably.
- Record mode switches and setup approvals for auditability.
- Store small, efficient backups (bundles) when required (push-or-bundle policy).
- Keep the format simple (JSON + small files) and OS-agnostic (works on Linux, WSL2, macOS, Windows).

## Directory layout


`.bitbot/`
- `metadata.json` — primary workspace metadata (see schema)
- `sessions/` — per-session metadata files: `<session-id>.json`
- `backups/` — timestamped git bundles and mirror clones (files: `<ts>-<branch>.bundle` or `<ts>-mirror.git/`)
- `approvals.json` — array log of setup approvals (mount-socket, privileged actions)
- `audit.log` — append-only human readable log of actions (ts user action details)
- `agent.yml` — agent configuration created by CLI wizard (if used)

*Note: Stashes and sketches are not part of the MVP and are deferred to future features.*

All files in `.bitbot/` are owned by the workspace owner on the host and are not mounted into agent containers by default.

## `metadata.json` schema

Required fields:
- `workspace_hash` (string): short hash (8-12 hex) uniquely identifying the workspace path.
- `created` (ISO8601 timestamp)
- `last_updated` (ISO8601 timestamp)
- `current_mode` (string): `work` or `setup`
- `container_name` (string): last used container name or label

Optional fields:
- `default_agent` (string)
- `vscode_label` (object): labels used to identify container to VS Code

Example:

```json
{
  "workspace_hash": "a1b2c3d4",
  "created": "2025-10-17T12:00:00Z",
  "last_updated": "2025-10-17T12:34:00Z",
  "current_mode": "work",
  "container_name": "bitbot-dev-a1b2c3d4",
  "default_agent": "claude",
  "vscode_label": { "vsc.local.folder": "/workspace" }
}
```

## `sessions/` files
Each active or historical session has a small JSON file named `<session-id>.json` containing:
- `id` (string)
- `created` (ISO8601)
- `last_accessed` (ISO8601)
- `user` (string)
- `container_id` (string)
- `attached` (bool)
- `tmux_session` (string) — tmux session name inside container
- `notes` (string) — optional user notes

Example:

```json
{
  "id":"sess-20251017T1234",
  "created":"2025-10-17T12:34:00Z",
  "last_accessed":"2025-10-17T12:45:00Z",
  "user":"alice",
  "container_id":"abcdef123456",
  "attached":true,
  "tmux_session":"main",
  "notes":"working on feature X"
}
```

## `backups/` policy
- Files are named `<ts>-<branch>.bundle` (e.g., `20251017T123400-main.bundle`).
- Bundles are created when the push-or-bundle policy is required (sketch flow backlog) or when the user requests an ad-hoc backup.
- Keep a small retention policy (configurable): default retain last 10 bundles.
- Backups must not be mounted into agent containers.

## `approvals.json` and `audit.log`
- `approvals.json` is a small JSON array recording explicit setup approvals. Each entry:
  - `ts`, `user`, `action`, `reason`, `approved_by` (string)
- `audit.log` is an append-only plaintext file with timestamped human-readable entries of actions (container starts, setup approvals, agent launches).

Example approval entry:

```json
{
  "ts":"2025-10-17T12:40:00Z",
  "user":"alice",
  "action":"allow-socket-mount",
  "reason":"need to run compose stack",
  "approved_by":"alice"
}
```


## CLI primitives (expected)
- `bitbot metadata` — show `metadata.json`
- `bitbot session list` — list `sessions/`
- `bitbot session attach <id>` — attach to a session
- `bitbot backup create [--push-if-remote]` — create bundle and return path
- `bitbot approval request --reason "..."` — request a setup approval (writes `approvals.json` and logs)

*Advanced state management (stashes, sketches, session replay) is deferred to future features.*

## Security considerations
- Do not expose `.bitbot/` to agent containers by default. If a user explicitly mounts `.bitbot/` into an agent container, warn and require manual confirmation.
- Protect backups and approvals from accidental modification: recommend host-level ownership that prevents casual writes from containerized processes.

## Migration & compatibility
- If existing legacy BitBot state files exist in `~/.bitbot` or `legacy/`, provide a migration tool that copies required fields into the workspace `.bitbot/` with user confirmation.

## Tests
- Unit tests (bash or python) to validate schema creation and read/write operations.
- Smoke test: create metadata, start session, create backup bundle, simulate approval entry, and verify files exist and permissions are correct.

## Next steps
- Implement CLI primitives and small helper scripts to read/write `.bitbot/` entries, create bundles, and manage session files.
- Integrate these primitives into BitBot's main CLI and entrypoint checks.

```
