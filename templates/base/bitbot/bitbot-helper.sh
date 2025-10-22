#!/bin/bash
# Inner BitBot Helper Script
# Provides utilities for AI agents working inside containers

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[0;90m'
RESET='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="${SCRIPT_DIR}/commands"
WORKSPACE="${WORKSPACE:-/workspace}"

# Main command router
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        analyze)
            "${COMMANDS_DIR}/analyze.sh" "$@"
            ;;
        configure)
            "${COMMANDS_DIR}/configure.sh" "$@"
            ;;
        status)
            "${COMMANDS_DIR}/status.sh" "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown command '${command}'${RESET}" >&2
            echo ""
            show_help
            exit 1
            ;;
    esac
}

show_help() {
    cat <<'EOF'
BitBot Helper - AI Agent Utilities

Usage:
  bitbot-helper <command> [options]

Commands:
  analyze       Analyze workspace tech stack and structure
  configure     Configure devcontainer (config mode only)
  status        Show container environment status
  help          Show this help message

Examples:
  # Analyze current workspace
  bitbot-helper analyze

  # Show container environment
  bitbot-helper status

  # Configure devcontainer (config mode)
  bitbot-helper configure

Environment:
  WORKSPACE     Workspace path (default: /workspace)
  BITBOT_MODE   Current mode (work/config)

For more information, see /opt/bitbot/README.md
EOF
}

# Run main
main "$@"
