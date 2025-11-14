#!/bin/bash
# BitBot AI Helper - Bash wrapper for AI assistance
#
# Provides intelligent help for beginners with zero setup required.
# Uses Node.js helper that tries free AI APIs, falls back to curated help.
#
# Usage:
#   source ai-helper.sh
#   ask_ai "context" "question"
#   ask_ai "Docker error" "How to install Docker on Windows?"

# Auto-detect location based on context
if [ -n "$BITBOT_HOME" ]; then
    # Running from BitBot installation (outside container)
    BITBOT_AI_HELPER="${BITBOT_AI_HELPER:-$BITBOT_HOME/core/util/ai-helper/ai-helper.js}"
else
    # Running inside container
    BITBOT_AI_HELPER="${BITBOT_AI_HELPER:-/usr/local/bitbot/util/ai-helper/ai-helper.js}"
fi

# Ask AI for help (tries AI, falls back to static help)
ask_ai() {
    local context="$1"
    local question="$2"

    if [ -z "$context" ] || [ -z "$question" ]; then
        echo "Usage: ask_ai 'context' 'question'" >&2
        return 1
    fi

    # Check if Node.js and helper exist
    if command -v node &>/dev/null && [ -f "$BITBOT_AI_HELPER" ]; then
        node "$BITBOT_AI_HELPER" "$context" "$question"
    else
        # Fallback if Node.js not available
        echo "💡 Tip: Install Docker Desktop from https://docker.com/products/docker-desktop"
    fi
}

# Show AI-powered help for command errors
ai_suggest() {
    local command="$1"
    local error_msg="$2"

    echo ""
    echo "💡 AI Assistant:"
    ask_ai "$command error" "$error_msg"
    echo ""
}

# Export functions
export -f ask_ai
export -f ai_suggest
