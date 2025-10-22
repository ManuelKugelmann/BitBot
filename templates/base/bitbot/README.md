# Inner BitBot Scripts

These scripts are deployed inside the devcontainer to assist AI agents with common tasks.

## Purpose

The "inner bitbot" provides helper utilities for AI agents working inside containers:
- Workspace analysis and tech stack detection
- Devcontainer configuration assistance
- Common development task automation
- Container environment introspection

## Structure

```
bitbot/
├── README.md              # This file
├── bitbot-helper.sh       # Main helper script
└── commands/              # Helper commands
    ├── analyze.sh         # Analyze workspace tech stack
    ├── configure.sh       # Configure devcontainer helpers
    └── status.sh          # Show container environment status
```

## Usage

### From AI Agent (inside container)

```bash
# Get help
/opt/bitbot/bitbot-helper.sh help

# Analyze workspace
/opt/bitbot/bitbot-helper.sh analyze

# Show environment status
/opt/bitbot/bitbot-helper.sh status

# Configure devcontainer
/opt/bitbot/bitbot-helper.sh configure
```

## Installation

These scripts are automatically installed to `/opt/bitbot/` during container build.

## Mode-Specific Behavior

**Work Mode:**
- Provides workspace analysis
- Shows git status and safety warnings
- Helps with development tasks
- Read-only access to .devcontainer

**Config Mode:**
- Provides devcontainer configuration assistance
- Tech stack detection and recommendations
- Read-write access to .devcontainer
- Template suggestions

## Design Principles

- **Non-intrusive**: Helpers are optional, never required
- **Simple**: Plain bash scripts, no dependencies
- **Safe**: No destructive operations without confirmation
- **Helpful**: Provide clear guidance and examples

## Future Enhancements

- MCP service integration
- Template customization wizard
- Automated devcontainer generation
- Project-specific optimizations
