#!/bin/bash
#
# Create initial dist branch (orphan)
# Run this once to set up the distribution branch
#
# Usage: ./scripts/create-dist-branch.sh
#

set -e

TRUNK_BRANCH="trunk"
DIST_BRANCH="dist"

echo "========================================"
echo "Creating Distribution Branch"
echo "========================================"
echo

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "✗ Error: Not in a git repository"
    exit 1
fi

# Check if dist branch already exists
if git rev-parse --verify "$DIST_BRANCH" >/dev/null 2>&1; then
    echo "✗ Error: Branch '$DIST_BRANCH' already exists"
    echo
    echo "To recreate it, first delete the existing branch:"
    echo "  git branch -D $DIST_BRANCH"
    echo "  git push origin --delete $DIST_BRANCH"
    echo
    exit 1
fi

# Check if we're on trunk branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$TRUNK_BRANCH" ]; then
    echo "⚠ Warning: Currently on branch '$CURRENT_BRANCH', not '$TRUNK_BRANCH'"
    echo "Switching to $TRUNK_BRANCH..."
    git checkout "$TRUNK_BRANCH"
fi

echo "→ Creating orphan branch: $DIST_BRANCH"
git checkout --orphan "$DIST_BRANCH"

echo "→ Removing all files from staging..."
git rm -rf . 2>/dev/null || true

echo "→ Copying distribution files..."
# Copy files from working directory (they're still there, just unstaged)
git checkout "$TRUNK_BRANCH" -- bitbot.exe bitbot README.md LICENSE 2>/dev/null || {
    echo "  ⚠ Warning: Some distribution files may not exist yet"
}

# Create dist-specific .gitignore
echo "→ Creating .gitignore for dist branch..."
cat > .gitignore << 'EOF'
# Distribution branch - exclude dev files
_SPARC/
tests/
.devcontainer/
src/
scripts/
.github/
.vscode/
*.log
CLAUDE.md
EOF

git add .

echo "→ Creating initial commit..."
git commit -m "Initial distribution branch"

echo "→ Pushing to origin/$DIST_BRANCH..."
git push -u origin "$DIST_BRANCH"

echo
echo "✓ Distribution branch created successfully!"
echo
echo "Switch back to trunk:"
echo "  git checkout $TRUNK_BRANCH"
echo
echo "Users can now access clean distribution:"
echo "  git clone -b $DIST_BRANCH <repo-url>"
echo "  git checkout $DIST_BRANCH"
echo
echo "To sync changes in the future:"
echo "  ./scripts/sync-dist-branch.sh"
echo
