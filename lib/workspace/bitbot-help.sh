#!/usr/bin/env bash
#
# BitBot Help Command
#

source "${BITBOT_HOME}/lib/util/logo.sh"

bitbot_help() {
    # Display logo
    print_logo

    cat <<'EOF'

Usage:
  bitbot <command> [options]

Commands:
  init              Initialize BitBot workspace in current directory
  work [vscode]     Launch work mode devcontainer
  config [vscode]   Launch config mode devcontainer
  vscode            Launch VS Code in work container
  help              Show this help message
  version           Show version and dependency status

Examples:
  bitbot init       # Initialize workspace
  bitbot work       # Start work mode (terminal)
  bitbot work vscode # Start work mode (VS Code)
  bitbot vscode     # Open workspace in VS Code
  bitbot config     # Edit .devcontainer in config mode

Modes:
  work              Development mode (read-only .devcontainer)
  config            Configuration mode (editable .devcontainer)

For more information: https://github.com/anthropics/bitbot
EOF
}

export -f bitbot_help
