#!/bin/bash
#
# Sync trunk branch to release branch
# Copies only production files, excludes dev clutter
#
# Usage: ./scripts/sync-release-branch.sh
#

set -e

TRUNK_BRANCH="trunk"
RELEASE_BRANCH="release"
TEMP_DIR=$(mktemp -d)

echo "========================================"
echo "Syncing Release Branch"
echo "========================================"
echo

# List of files/folders to include in release
RELEASE_FILES=(
    "VERSION"
    "bitbot"
    "bitbot.exe"
    "bitbot.cmd"
    "lib"
    "templates"
    "config-devcontainer"
    "README.md"
    "LICENSE"
)

echo "→ Source branch: $TRUNK_BRANCH"
echo "→ Target branch: $RELEASE_BRANCH"
echo "→ Release files:"
for file in "${RELEASE_FILES[@]}"; do
    echo "  - $file"
done
echo

# Clone current repo to temp directory
echo "→ Cloning repository to temp directory..."
git clone . "$TEMP_DIR" --quiet
cd "$TEMP_DIR"

# Check if release branch exists
if git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
    echo "→ Checking out existing release branch..."
    git checkout "$RELEASE_BRANCH" --quiet
else
    echo "→ Creating new orphan release branch..."
    git checkout --orphan "$RELEASE_BRANCH" --quiet
    git rm -rf . --quiet 2>/dev/null || true
fi

# Remove all files except .git
echo "→ Cleaning release branch..."
find . -maxdepth 1 ! -name .git ! -name . -exec rm -rf {} \; 2>/dev/null || true

# Checkout release files from trunk
echo "→ Copying release files from $TRUNK_BRANCH..."
for file in "${RELEASE_FILES[@]}"; do
    if git cat-file -e "$TRUNK_BRANCH:$file" 2>/dev/null; then
        git checkout "$TRUNK_BRANCH" -- "$file" --quiet 2>/dev/null || {
            echo "  ⚠ Warning: $file not found in $TRUNK_BRANCH, skipping"
        }
    else
        echo "  ⚠ Warning: $file not found in $TRUNK_BRANCH, skipping"
    fi
done

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

    echo "→ Pushing to origin/$RELEASE_BRANCH..."
    git push origin "$RELEASE_BRANCH" --quiet

    echo
    echo "✓ Release branch updated successfully"
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
echo "Users can now access clean release:"
echo "  git clone -b $RELEASE_BRANCH <repo-url>"
echo "  git checkout $RELEASE_BRANCH"
echo
