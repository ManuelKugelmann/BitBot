#!/bin/bash
# Git Worktree Manager for Claude Code Multi-Agent Workflows
# Manages isolated worktrees for each Claude instance

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREY='\033[0;90m'
RESET='\033[0m'

# Configuration
# Default to .worktrees/ in project root (git feature, not BitBot-specific)
# Can override with WORKTREE_BASE environment variable
get_default_worktree_base() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$git_root" ]]; then
        echo "${git_root}/.worktrees"
    else
        echo "$HOME/.worktrees"
    fi
}

WORKTREE_BASE="${WORKTREE_BASE:-$(get_default_worktree_base)}"
BRANCH_PREFIX="${BRANCH_PREFIX:-claude}"
MAIN_BRANCH="${MAIN_BRANCH:-trunk}"

# Get git root directory
get_git_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Generate timestamp-based branch name
generate_branch_name() {
    local prefix="${1:-$BRANCH_PREFIX}"
    echo "${prefix}-$(date +%Y%m%d-%H%M%S)"
}

# Show help
show_help() {
    cat <<EOF
${CYAN}Git Worktree Manager - Multi-Agent Claude Code Workflows${RESET}

${YELLOW}Usage:${RESET}
  worktree-manager <command> [options]

${YELLOW}Commands:${RESET}
  create [name]     Create new worktree with timestamped branch
  list              List all worktrees
  sync              Sync current worktree with main branch
  remove <name>     Remove a worktree and its branch
  switch <name>     Switch to existing worktree
  clean             Remove merged worktrees
  status            Show status of all worktrees
  help              Show this help message

${YELLOW}Examples:${RESET}
  # Create new worktree for this Claude instance
  worktree-manager create

  # Create named worktree
  worktree-manager create feature-auth

  # Sync with main branch (pull latest changes)
  worktree-manager sync

  # List all worktrees
  worktree-manager list

  # Show status of all worktrees
  worktree-manager status

  # Remove finished worktree
  worktree-manager remove claude-20251025-140530

${YELLOW}Environment Variables:${RESET}
  WORKTREE_BASE     Base directory for worktrees (default: [project]/.worktrees)
  BRANCH_PREFIX     Branch name prefix (default: claude)
  MAIN_BRANCH       Main branch to sync with (default: trunk)

${YELLOW}Workflow:${RESET}
  1. Each Claude instance creates its own worktree
  2. Work in isolated directory with dedicated branch
  3. Regularly sync with main branch to get updates
  4. Create PRs or merge when work is complete
  5. Clean up merged worktrees

${YELLOW}Benefits:${RESET}
  • Isolated workspaces - no conflicts between Claude instances
  • Parallel work - multiple features simultaneously
  • Clean separation - each task in its own branch
  • Easy cleanup - remove worktrees when done
  • Fast switching - instant context changes

EOF
}

# Create new worktree
cmd_create() {
    local name="$1"
    local git_root

    git_root="$(get_git_root)" || {
        echo -e "${RED}Error: Not in a git repository${RESET}" >&2
        exit 1
    }

    # Generate branch name if not provided
    if [[ -z "$name" ]]; then
        name="$(generate_branch_name)"
        echo -e "${BLUE}Generated branch name: ${name}${RESET}"
    elif [[ "$name" != "$BRANCH_PREFIX"* ]]; then
        # Add prefix if not already present
        name="${BRANCH_PREFIX}-${name}"
        echo -e "${BLUE}Using branch name: ${name}${RESET}"
    fi

    # Create worktree base directory if it doesn't exist
    mkdir -p "$WORKTREE_BASE"

    local worktree_path="${WORKTREE_BASE}/${name}"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        echo -e "${YELLOW}Worktree already exists: ${worktree_path}${RESET}"
        echo -e "${BLUE}To switch to it, use: cd ${worktree_path}${RESET}"
        return 0
    fi

    # Create worktree with new branch from main
    echo -e "${BLUE}Creating worktree: ${worktree_path}${RESET}"
    echo -e "${GREY}Based on: ${MAIN_BRANCH}${RESET}"
    echo ""

    if git worktree add -b "$name" "$worktree_path" "$MAIN_BRANCH"; then
        echo ""
        echo -e "${GREEN}✓ Worktree created successfully${RESET}"
        echo ""
        echo -e "${CYAN}Next steps:${RESET}"
        echo -e "  1. cd ${worktree_path}"
        echo -e "  2. Start working on your task"
        echo -e "  3. Run '${GREY}worktree-manager sync${RESET}' regularly to get updates"
        echo ""
        echo -e "${GREY}To return to main worktree:${RESET}"
        echo -e "  cd ${git_root}"
        echo ""
    else
        echo -e "${RED}✗ Failed to create worktree${RESET}" >&2
        exit 1
    fi
}

# List all worktrees
cmd_list() {
    echo -e "${CYAN}Git Worktrees:${RESET}"
    echo ""
    git worktree list
}

# Sync current worktree with main branch
cmd_sync() {
    local git_root
    local current_branch

    git_root="$(get_git_root)" || {
        echo -e "${RED}Error: Not in a git repository${RESET}" >&2
        exit 1
    }

    current_branch="$(git branch --show-current)"

    echo -e "${BLUE}Syncing worktree with ${MAIN_BRANCH}...${RESET}"
    echo -e "${GREY}Current branch: ${current_branch}${RESET}"
    echo ""

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${RESET}"
        echo ""
        git status --short
        echo ""
        read -p "Continue with sync? (y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Sync cancelled${RESET}"
            exit 0
        fi
    fi

    # Fetch latest changes
    echo -e "${BLUE}Fetching latest changes...${RESET}"
    git fetch origin

    # Merge main branch into current branch
    echo -e "${BLUE}Merging ${MAIN_BRANCH} into ${current_branch}...${RESET}"
    if git merge "origin/${MAIN_BRANCH}" --no-edit; then
        echo ""
        echo -e "${GREEN}✓ Sync completed successfully${RESET}"
        echo ""
        echo -e "${GREY}Your branch is now up to date with ${MAIN_BRANCH}${RESET}"
    else
        echo ""
        echo -e "${RED}✗ Merge conflicts detected${RESET}"
        echo ""
        echo -e "${YELLOW}Resolve conflicts manually:${RESET}"
        echo -e "  1. Fix conflicts in the files listed above"
        echo -e "  2. git add <resolved-files>"
        echo -e "  3. git commit"
        echo ""
        exit 1
    fi
}

# Remove worktree
cmd_remove() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Worktree name required${RESET}" >&2
        echo "Usage: worktree-manager remove <name>"
        exit 1
    fi

    local worktree_path="${WORKTREE_BASE}/${name}"

    # Check if worktree exists
    if [[ ! -d "$worktree_path" ]]; then
        echo -e "${RED}Error: Worktree not found: ${worktree_path}${RESET}" >&2
        exit 1
    fi

    echo -e "${YELLOW}Warning: This will remove the worktree and its branch${RESET}"
    echo -e "${GREY}Path: ${worktree_path}${RESET}"
    echo ""
    read -p "Are you sure? (y/N): " response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Removal cancelled${RESET}"
        exit 0
    fi

    # Remove worktree
    echo -e "${BLUE}Removing worktree...${RESET}"
    if git worktree remove "$worktree_path" --force; then
        echo -e "${GREEN}✓ Worktree removed${RESET}"

        # Remove branch if it exists
        if git show-ref --verify --quiet "refs/heads/${name}"; then
            echo -e "${BLUE}Removing branch: ${name}${RESET}"
            git branch -D "$name"
            echo -e "${GREEN}✓ Branch removed${RESET}"
        fi
    else
        echo -e "${RED}✗ Failed to remove worktree${RESET}" >&2
        exit 1
    fi
}

# Show status of all worktrees
cmd_status() {
    local git_root
    git_root="$(get_git_root)" || {
        echo -e "${RED}Error: Not in a git repository${RESET}" >&2
        exit 1
    }

    echo -e "${CYAN}Worktree Status:${RESET}"
    echo ""

    # Get worktree list
    while IFS= read -r line; do
        local path branch
        path=$(echo "$line" | awk '{print $1}')
        branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')

        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${CYAN}Path:${RESET} $path"
        echo -e "${CYAN}Branch:${RESET} $branch"
        echo ""

        # Change to worktree and get status
        (
            cd "$path" || exit

            # Check for uncommitted changes
            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                echo -e "${YELLOW}Status:${RESET} Uncommitted changes"
                git status --short | head -5
                echo ""
            else
                echo -e "${GREEN}Status:${RESET} Clean"
                echo ""
            fi

            # Check commits ahead/behind
            local ahead behind
            ahead=$(git rev-list --count "origin/${MAIN_BRANCH}..HEAD" 2>/dev/null || echo "0")
            behind=$(git rev-list --count "HEAD..origin/${MAIN_BRANCH}" 2>/dev/null || echo "0")

            if [[ $ahead -gt 0 ]]; then
                echo -e "${GREEN}Ahead:${RESET} $ahead commits"
            fi
            if [[ $behind -gt 0 ]]; then
                echo -e "${YELLOW}Behind:${RESET} $behind commits (run 'worktree-manager sync')"
            fi
            if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]; then
                echo -e "${GREY}Up to date with ${MAIN_BRANCH}${RESET}"
            fi
        )
        echo ""
    done < <(git worktree list --porcelain | grep -E "^worktree|^branch" | paste -d' ' - - | sed 's/worktree //; s/branch //')

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Clean up merged worktrees
cmd_clean() {
    echo -e "${BLUE}Checking for merged branches...${RESET}"
    echo ""

    # Fetch latest
    git fetch origin

    # Find merged branches
    local merged_branches
    merged_branches=$(git branch --merged "origin/${MAIN_BRANCH}" | grep "^  ${BRANCH_PREFIX}-" | sed 's/^  //' || true)

    if [[ -z "$merged_branches" ]]; then
        echo -e "${GREEN}No merged worktrees to clean${RESET}"
        return 0
    fi

    echo -e "${YELLOW}Merged branches found:${RESET}"
    echo "$merged_branches"
    echo ""
    read -p "Remove these worktrees? (y/N): " response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleanup cancelled${RESET}"
        return 0
    fi

    # Remove each merged worktree
    while IFS= read -r branch; do
        local worktree_path="${WORKTREE_BASE}/${branch}"

        if [[ -d "$worktree_path" ]]; then
            echo -e "${BLUE}Removing: ${branch}${RESET}"
            git worktree remove "$worktree_path" --force 2>/dev/null || true
            git branch -d "$branch" 2>/dev/null || true
            echo -e "${GREEN}✓ Removed${RESET}"
        fi
    done <<< "$merged_branches"

    echo ""
    echo -e "${GREEN}Cleanup complete${RESET}"
}

# Main command router
main() {
    local command="${1:-help}"

    case "$command" in
        create)
            shift
            cmd_create "${1:-}"
            ;;
        list)
            cmd_list
            ;;
        sync)
            cmd_sync
            ;;
        remove)
            shift
            cmd_remove "${1:-}"
            ;;
        status)
            cmd_status
            ;;
        clean)
            cmd_clean
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

main "$@"
