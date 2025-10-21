#!/bin/bash
#
# Create initial release branch (orphan)
# Run this once to set up the release branch
#
# Usage: ./scripts/create-release-branch.sh
#

set -e

TRUNK_BRANCH="trunk"
RELEASE_BRANCH="release"

echo "========================================"
echo "Creating Release Branch"
echo "========================================"
echo

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "✗ Error: Not in a git repository"
    exit 1
fi

# Check if release branch already exists
if git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
    echo "✗ Error: Branch '$RELEASE_BRANCH' already exists"
    echo
    echo "To recreate it, first delete the existing branch:"
    echo "  git branch -D $RELEASE_BRANCH"
    echo "  git push origin --delete $RELEASE_BRANCH"
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

echo "→ Creating orphan branch: $RELEASE_BRANCH"
git checkout --orphan "$RELEASE_BRANCH"

echo "→ Removing all files from staging..."
git rm -rf . 2>/dev/null || true

echo "→ Copying release files..."
# Copy files from working directory (they're still there, just unstaged)
git checkout "$TRUNK_BRANCH" -- \
    bitbot \
    bitbot.exe \
    bitbot.cmd \
    lib \
    templates \
    config-devcontainer \
    README.md \
    LICENSE \
    2>/dev/null || {
    echo "  ⚠ Warning: Some release files may not exist yet"
}

# Create release-specific .gitignore
echo "→ Creating .gitignore for release branch..."
cat > .gitignore << 'EOF'
# Release branch - exclude dev files
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
git commit -m "Initial release branch"

echo "→ Pushing to origin/$RELEASE_BRANCH..."
git push -u origin "$RELEASE_BRANCH"

echo
echo "✓ Release branch created successfully!"
echo
echo "Switch back to trunk:"
echo "  git checkout $TRUNK_BRANCH"
echo
echo "Users can now access clean release:"
echo "  git clone -b $RELEASE_BRANCH <repo-url>"
echo "  git checkout $RELEASE_BRANCH"
echo
echo "To sync changes in the future:"
echo "  ./scripts/sync-release-branch.sh"
echo
