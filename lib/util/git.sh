#!/usr/bin/env bash
#
# BitBot Git Utilities
#
# Component: Git safety and recommendations
# Purpose: Git status checking and recommendations
#
# Usage: source this file from other scripts
#

# Source helpers (if not already sourced)
if [[ -z "${BITBOT_HELPERS_LOADED:-}" ]]; then
    # shellcheck source=./helpers.sh
    source "${BITBOT_HOME}/lib/util/helpers.sh"
    BITBOT_HELPERS_LOADED=1
fi

# ============================================================================
# Git Push Recommendation
# ============================================================================

recommend_git_push_before_init() {
    # Show git recommendations before initialization
    # BitBot will create files and AI agent will modify .devcontainer
    # Recommend git setup and pushing current state first
    local workspace_path="$1"

    # Check if recommendation is disabled in config
    local skip_push=$(get_config_value "$workspace_path" "skip_push_recommendation" 2>/dev/null || echo "false")
    if [[ "$skip_push" == "true" ]]; then
        # User has disabled git push recommendations - skip silently
        return 0
    fi

    # Check if git is installed
    if ! command_exists git; then
        # Git not installed - skip silently
        return 0
    fi

    # Check if this is a git repository
    if [[ ! -d "${workspace_path}/.git" ]]; then
        # Not a git repo - recommend creating one
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ ℹ️  RECOMMENDATION: Initialize git repository           │"
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""
        echo "BitBot AI agent will modify files in this workspace."
        echo "Git helps you track and revert changes if needed."
        echo ""
        echo "Recommended steps:"
        echo "  \$ git init"
        echo "  \$ git add ."
        echo "  \$ git commit -m \"Initial commit\""
        echo "  \$ git remote add origin <url>"
        echo "  \$ git push -u origin main"
        echo ""

        local choice
        choice=$(prompt_choice "What would you like to do?" 0 \
            "Exit and set up git" \
            "Skip this time" \
            "Skip permanently (update config)")
        echo ""

        case $choice in
            0)
                # Exit so user can set up git
                echo "Please set up git and run 'bitbot init' again."
                exit 0
                ;;
            2)
                # Skip permanently - update workspace config
                update_json_value "${workspace_path}/.bitbot/config.json" "skip_push_recommendation" "true" 2>/dev/null || {
                    # Config doesn't exist yet - will be created during init
                    :
                }
                print_success "Will skip git push recommendations for this workspace"
                echo ""
                ;;
            *)
                # Skip this time - just continue
                ;;
        esac

        return 0
    fi

    # Check if there's a remote configured
    local remotes
    remotes=$(cd "$workspace_path" && git remote -v 2>/dev/null)
    if [[ -z "$remotes" ]]; then
        # No remote - recommend adding one
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ ℹ️  RECOMMENDATION: Add git remote                      │"
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""
        echo "No git remote configured. Adding a remote allows you to:"
        echo "  • Back up your work to a remote server"
        echo "  • Easily revert AI agent changes if needed"
        echo "  • Collaborate with others"
        echo ""
        echo "Recommended steps:"
        echo "  \$ git remote add origin <url>"
        echo "  \$ git push -u origin main"
        echo ""

        local choice
        choice=$(prompt_choice "What would you like to do?" 0 \
            "Exit and add remote" \
            "Skip this time" \
            "Skip permanently (update config)")
        echo ""

        case $choice in
            0)
                # Exit so user can add remote
                echo "Please add a remote and run 'bitbot init' again."
                exit 0
                ;;
            2)
                # Skip permanently - update workspace config
                update_json_value "${workspace_path}/.bitbot/config.json" "skip_push_recommendation" "true" 2>/dev/null || {
                    :
                }
                print_success "Will skip git push recommendations for this workspace"
                echo ""
                ;;
            *)
                # Skip this time - just continue
                ;;
        esac

        return 0
    fi

    # Check git status
    local status_output
    status_output=$(cd "$workspace_path" && git status 2>/dev/null)

    # Check if there are unpushed commits or uncommitted changes
    if echo "$status_output" | grep -qE "(ahead|modified:|Untracked)"; then
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ ⚠️  RECOMMENDATION: Push to remote before init          │"
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""
        echo "BitBot will create .bitbot/ and .devcontainer files."
        echo "AI agent will then modify your .devcontainer configuration."
        echo "Push your current state first to easily revert if needed."
        echo ""

        # Show current git status
        echo "$status_output"
        echo ""

        echo "Recommended steps:"
        echo "  \$ git add .         # Stage changes (if needed)"
        echo "  \$ git commit -m \"...\" # Commit (if needed)"
        echo "  \$ git push          # Push to remote"
        echo ""

        local choice
        choice=$(prompt_choice "What would you like to do?" 0 \
            "Exit and push changes" \
            "Skip this time" \
            "Skip permanently (update config)")
        echo ""

        case $choice in
            0)
                # Exit so user can push
                echo "Please push your changes and run 'bitbot init' again."
                exit 0
                ;;
            2)
                # Skip permanently - update workspace config
                update_json_value "${workspace_path}/.bitbot/config.json" "skip_push_recommendation" "true" 2>/dev/null || {
                    :
                }
                print_success "Will skip git push recommendations for this workspace"
                echo ""
                ;;
            *)
                # Skip this time - just continue
                ;;
        esac
    fi
}

# ============================================================================
# Git Safety Checks
# ============================================================================

check_git_safety() {
    # Check git status and warn about uncommitted changes and secrets
    # Non-blocking - warns but doesn't prevent initialization
    local workspace_path="$1"

    # Check if safety checks are disabled in config
    local skip_safety=$(get_config_value "$workspace_path" "skip_safety_checks" 2>/dev/null || echo "false")
    if [[ "$skip_safety" == "true" ]]; then
        # User has disabled git safety checks - skip silently
        return 0
    fi

    # Check if git is installed
    if ! command_exists git; then
        # Git not installed - skip
        return 0
    fi

    # Check if this is a git repository
    if [[ ! -d "${workspace_path}/.git" ]]; then
        # Already handled by recommend_git_push_before_init
        return 0
    fi

    # Check git status
    local status_output
    status_output=$(cd "$workspace_path" && git status --porcelain 2>/dev/null)

    if [[ -n "$status_output" ]]; then
        # Has uncommitted changes (only shown if user skipped push recommendation)
        print_warning "Git repository has uncommitted changes"
        echo ""
        cd "$workspace_path" && git status --short
        echo ""
        echo "    Recommendation: Commit or stash changes before AI work"
        echo "    This allows you to easily revert AI changes if needed."
        echo ""
    fi

    # Check if there's a remote
    local remotes
    remotes=$(cd "$workspace_path" && git remote -v 2>/dev/null)

    if [[ -n "$remotes" ]]; then
        # Generic warning about AI agents and secrets
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ ⚠️  AI AGENT SAFETY WARNING                             │"
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""
        echo "  WARNING: AI agents may accidentally commit secrets:"
        echo "    • API keys, tokens, passwords"
        echo "    • Environment variables (.env files)"
        echo "    • SSH keys, certificates"
        echo "    • Database credentials"
        echo ""
        echo "  Recommendations:"
        echo "    1. Review ALL changes before committing/pushing"
        echo "    2. Use .gitignore for sensitive files"
        echo "    3. Consider using git-secrets or similar tools"
        echo "    4. Never commit credentials - use environment variables"
        echo ""

        local choice
        choice=$(prompt_choice "What would you like to do?" 1 \
            "Exit and review .gitignore" \
            "Skip this time" \
            "Skip permanently (update config)")
        echo ""

        case $choice in
            0)
                # Exit so user can review .gitignore
                echo "Please review your .gitignore and run the command again."
                exit 0
                ;;
            2)
                # Skip permanently - update workspace config
                update_json_value "${workspace_path}/.bitbot/config.json" "skip_safety_checks" "true" 2>/dev/null || {
                    :
                }
                print_success "Will skip safety warnings for this workspace"
                echo ""
                ;;
            *)
                # Skip this time - just continue
                ;;
        esac
    fi
}
