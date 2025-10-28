#!/usr/bin/env bash
# get-session-info.sh - Utility to get Claude PID and Session ID
# Source this file in other scripts to access:
#   - CLAUDE_PID variable
#   - SESSION_ID variable
#
# Uses environment variables set by SessionStart hook.

# Use environment variables exported by SessionStart hook
SESSION_ID="${CLAUDE_SESSION_ID:-}"
CLAUDE_PID="${CLAUDE_PID:-}"

# Export for use by sourcing script
export CLAUDE_PID
export SESSION_ID
