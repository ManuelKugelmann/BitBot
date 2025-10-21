#!/bin/bash
#
# Sync trunk branch to dist branch
# Copies only production files, excludes dev clutter
#
# Usage: ./scripts/sync-dist-branch.sh
#

set -e

TRUNK_BRANCH="trunk"
DIST_BRANCH="dist"
TEMP_DIR=$(mktemp -d)

echo "========================================"
echo "Syncing Distribution Branch"
echo "========================================"
echo

# List of files/folders to include in distribution
DIST_FILES=(
    "bitbot.exe"
    "bitbot"
    "README.md"
    "LICENSE"
)

echo "→ Source branch: $TRUNK_BRANCH"
echo "→ Target branch: $DIST_BRANCH"
echo "→ Distribution files:"
for file in "${DIST_FILES[@]}"; do
    echo "  - $file"
done
echo

# Clone current repo to temp directory
echo "→ Cloning repository to temp directory..."
git clone . "$TEMP_DIR" --quiet
cd "$TEMP_DIR"

# Check if dist branch exists
if git rev-parse --verify "$DIST_BRANCH" >/dev/null 2>&1; then
    echo "→ Checking out existing dist branch..."
    git checkout "$DIST_BRANCH" --quiet
else
    echo "→ Creating new orphan dist branch..."
    git checkout --orphan "$DIST_BRANCH" --quiet
    git rm -rf . --quiet 2>/dev/null || true
fi

# Remove all files except .git
echo "→ Cleaning dist branch..."
find . -maxdepth 1 ! -name .git ! -name . -exec rm -rf {} \; 2>/dev/null || true

# Checkout distribution files from trunk
echo "→ Copying distribution files from $TRUNK_BRANCH..."
for file in "${DIST_FILES[@]}"; do
    if git cat-file -e "$TRUNK_BRANCH:$file" 2>/dev/null; then
        git checkout "$TRUNK_BRANCH" -- "$file" --quiet 2>/dev/null || {
            echo "  ⚠ Warning: $file not found in $TRUNK_BRANCH, skipping"
        }
    else
        echo "  ⚠ Warning: $file not found in $TRUNK_BRANCH, skipping"
    fi
done

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

# Add all files
git add .

# Commit if there are changes
if git diff --cached --quiet; then
    echo
    echo "✓ No changes to sync"
else
    TRUNK_COMMIT=$(git rev-parse --short "$TRUNK_BRANCH")
    echo "→ Committing changes..."
    git commit -m "Sync from $TRUNK_BRANCH @ $TRUNK_COMMIT" --quiet

    echo "→ Pushing to origin/$DIST_BRANCH..."
    git push origin "$DIST_BRANCH" --quiet

    echo
    echo "✓ Distribution branch updated successfully"
    echo "  Synced from: $TRUNK_BRANCH @ $TRUNK_COMMIT"
fi

# Cleanup
cd - >/dev/null
rm -rf "$TEMP_DIR"

echo
echo "========================================"
echo "✓ Sync complete"
echo "========================================"
echo
echo "Users can now access clean distribution:"
echo "  git clone -b $DIST_BRANCH <repo-url>"
echo "  git checkout $DIST_BRANCH"
echo
