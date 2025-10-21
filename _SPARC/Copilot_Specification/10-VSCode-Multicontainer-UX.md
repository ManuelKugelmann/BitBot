```markdown
# Feature: VS Code Multicontainer & Subfolder DevContainer UX

## Goals
- Ensure BitBot devcontainers are discoverable and attachable by VS Code.
- Provide best practices for projects with multiple `devcontainer.json` files in subfolders.
- Minimize confusion between host `bitbot` CLI sessions and VS Code's "Open Folder in Container" UX.

## VS Code compatibility basics
- BitBot must ensure containers have labels that allow VS Code to find them:
  - `vsc.local.folder` or `devcontainer.local_folder` pointing to the workspace folder path.
- DevContainer features not required by BitBot's image should not be relied upon; document feature equivalences where used.

## Multicontainer setups
- Keep MCP sibling services outside the devcontainer. Use `docker-compose` on the host or `.bitbot/mcp/docker-compose.yml` for workspace services.
- If a project requires sidecar containers for development tools, prefer `.bitbot/devcontainer-compose.yml` that BitBot can generate; present VS Code with a single primary container while the compose file manages sidecars.


## Multiple `devcontainer.json` files in subfolders

**BitBot supports and recommends a single top-level `.devcontainer/devcontainer.json` per workspace.**

- If subfolder `devcontainer.json` files exist, BitBot will always prefer the root container for CLI and agent workflows to ensure consistency and avoid confusion.
- Subfolder `devcontainer.json` files should only be used for editor settings or VS Code tasks, not for launching separate containers.
- If a user explicitly selects a subfolder container in VS Code, BitBot will warn that CLI/agent features may not work as expected.

**Best Practice:** Always use a single root-level devcontainer for BitBot-managed workspaces.

## VS Code terminal integration
- When VS Code opens a terminal, BitBot ensures the inner container shell launches `bitbot` automatically (optionally via an environment variable or shell rc hook), so the inner and host `bitbot` experience are consistent.

## UX suggestions
- On `bitbot` start, if running under VS Code, BitBot prints a short hint with commands to reattach the VS Code window to the running container (if necessary).
- Provide `bitbot open-vscode` helper to open the current workspace in VS Code attached to the running container (platform-specific wrapper).

## Tests
- Manual integration tests: open workspace in VS Code, confirm container detection, confirm terminals run `bitbot` and tmux session reattachment.

```
