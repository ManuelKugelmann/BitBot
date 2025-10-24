#!/bin/bash
# Container BitBot - Start Claude Session
# Launches Claude Code in tmux session with mode selection

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh" 2>/dev/null || true

# TODO: Implement according to pseudocode in sparc/2-pseudocode/INNER_BITBOT.md
# See: FUNCTION start_claude_session(args)

echo "TODO: Implement start command"
echo "This will:"
echo "  1. Check for existing tmux sessions"
echo "  2. Offer to resume or create new"
echo "  3. Ask for launch mode: --resume, interactive, or custom"
echo "  4. Create tmux session and launch Claude Code"
echo ""
echo "For now, you can manually start Claude:"
echo "  tmux new-session -s claude-\$(date +%Y%m%d-%H%M) claude --resume"
