#!/bin/bash
#
# Set GitHub repository default branch to 'release'
# Uses GitHub CLI (gh) to update the default branch
#
# Usage: ./scripts/set-default-branch.sh [branch-name]
#

set -e

# Default branch name
DEFAULT_BRANCH="${1:-release}"

echo "========================================"
echo "Set GitHub Default Branch"
echo "========================================"
echo

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "✗ GitHub CLI (gh) not found"
    echo
    echo "Please install GitHub CLI:"
    echo
    echo "  macOS/Linux:"
    echo "    brew install gh"
    echo
    echo "  Debian/Ubuntu:"
    echo "    sudo apt install gh"
    echo
    echo "  Or download from: https://cli.github.com/"
    echo
    echo "After installation, run:"
    echo "  gh auth login"
    echo "  $0 $DEFAULT_BRANCH"
    echo
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "✗ Not authenticated with GitHub"
    echo
    echo "Please authenticate:"
    echo "  gh auth login"
    echo
    echo "Then run this script again:"
    echo "  $0 $DEFAULT_BRANCH"
    echo
    exit 1
fi

# Get current repository
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

if [ -z "$REPO" ]; then
    echo "✗ Not in a GitHub repository"
    echo
    echo "Make sure you're in a cloned GitHub repository."
    echo
    exit 1
fi

echo "Repository: $REPO"
echo

# Get current default branch
CURRENT_DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)

if [ "$CURRENT_DEFAULT" = "$DEFAULT_BRANCH" ]; then
    echo "✓ Default branch is already '$DEFAULT_BRANCH'"
    echo
    exit 0
fi

echo "Current default branch: $CURRENT_DEFAULT"
echo "New default branch:     $DEFAULT_BRANCH"
echo

# Check if target branch exists
echo "→ Checking if '$DEFAULT_BRANCH' branch exists..."

if ! gh api repos/$REPO/branches/$DEFAULT_BRANCH &> /dev/null; then
    echo "✗ Branch '$DEFAULT_BRANCH' does not exist"
    echo
    echo "Please create the branch first:"
    echo "  ./scripts/create-release-branch.sh"
    echo
    echo "Or push it to GitHub:"
    echo "  git push origin $DEFAULT_BRANCH"
    echo
    exit 1
fi

echo "✓ Branch '$DEFAULT_BRANCH' exists"
echo

# Confirm action
read -p "Set default branch to '$DEFAULT_BRANCH'? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Set default branch
echo "→ Setting default branch to '$DEFAULT_BRANCH'..."

if gh repo edit --default-branch "$DEFAULT_BRANCH"; then
    echo
    echo "✓ Default branch updated successfully!"
    echo

    # Verify
    NEW_DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
    echo "Verification:"
    echo "  Default branch is now: $NEW_DEFAULT"
    echo

    if [ "$NEW_DEFAULT" = "$DEFAULT_BRANCH" ]; then
        echo "========================================"
        echo "✓ Success!"
        echo "========================================"
        echo
        echo "Users cloning will now get '$DEFAULT_BRANCH' by default:"
        echo "  git clone https://github.com/$REPO.git"
        echo
        echo "Developers can still access other branches:"
        echo "  git clone -b trunk https://github.com/$REPO.git"
        echo
    else
        echo "⚠ Warning: Verification shows '$NEW_DEFAULT' instead of '$DEFAULT_BRANCH'"
        echo "Please check GitHub repository settings manually."
        echo
    fi
else
    echo
    echo "✗ Failed to set default branch"
    echo
    echo "You may not have admin permissions for this repository."
    echo "Try setting it manually via GitHub web interface:"
    echo "  https://github.com/$REPO/settings/branches"
    echo
    exit 1
fi
