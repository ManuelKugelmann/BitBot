# Feature: AI Agent Integration & Configuration

## Research References
- Research/AI_AGENT_SAFETY_ARCHITECTURE.md (lines 1-51)
- Claude_info.txt:287-310 (agent config patterns)

## Feature Description
BitBot supports running and configuring multiple AI coding agents (e.g., Claude Code, OpenCode, custom) inside the devcontainer, with flexible agent selection and configuration.

## Implementation Approach
- **Interactive CLI Wizard (Option 3):**
  - BitBot CLI provides a wizard to select and configure the AI agent for each workspace.
  - The wizard writes the agent configuration to a YAML file (e.g., `.bitbot/agent.yml`) in the workspace.
  - Users can re-run the wizard at any time to change agents or update settings.
  - The CLI wizard supports:
    - Agent type selection (Claude, OpenCode, custom)
    - Version selection
    - API key/secret entry (with secure handling)
    - Advanced options (e.g., model, temperature, MCP services)
  - The agent config file is read by the container entrypoint/startup scripts to launch the correct agent with the right settings.
- **Manual Editing Supported:**
  - Advanced users can edit `.bitbot/agent.yml` directly for custom setups.
- **No Container Rebuild Required:**
  - Agent switching and config changes do not require rebuilding the container; only a restart or reload of the agent process.

## Rationale
- The interactive CLI wizard is user-friendly for onboarding and easy agent switching.
- YAML config file provides flexibility and transparency for advanced users.
- Secure handling of API keys and secrets is built into the wizard.
- Aligns with best practices for multi-agent, multi-workspace development environments.
