# Git Distribution Branch Strategy Research

**Goal:** Separate clean distribution branch from development branch with minimal overhead
**Requirement:** Users should be able to use `git checkout dist` or `git pull` to get/update clean version
**Date:** 2025-10-21

---

## Summary

Research on maintaining a clean distribution branch alongside development branch without excessive overhead. Distribution branch should exclude dev files (_SPARC/, tests/, .devcontainer/, etc.) while allowing normal git operations (checkout, pull).

---

## Approach Comparison

### Option 1: Orphan Branch with Automated Sync ⭐ RECOMMENDED

**How it works:**
- Create orphan branch (`dist` or `release`) with no shared history
- Automated script/GitHub Action syncs production files from `trunk` to `dist`
- Users: `git clone -b dist` or `git checkout dist`

**Pros:**
- ✓ Minimal overhead once set up
- ✓ Clean branch with no dev clutter
- ✓ Works with normal git operations (checkout, pull)
- ✓ Different commit history (no pollution from dev commits)
- ✓ Can be fully automated with GitHub Actions
- ✓ Users get only what they need

**Cons:**
- ✗ Initial setup required
- ✗ Requires automation script or manual sync
- ✗ Two separate histories (not always a con)

**Overhead:** LOW (after initial setup)

**Best for:** Projects with clear separation between dev and distribution files

---

### Option 2: Git Worktree with Filter Script

**How it works:**
- Use `git worktree` to checkout `dist` branch in separate directory
- Script copies/filters files from trunk to dist worktree
- Commit and push from dist worktree

**Pros:**
- ✓ Both branches exist in same repo
- ✓ Easy to work with both simultaneously
- ✓ Standard git operations work

**Cons:**
- ✗ Requires separate worktree directory (disk space)
- ✗ Manual or scripted sync required
- ✗ More complex workflow

**Overhead:** MEDIUM (extra disk space, manual management)

**Best for:** Developers who need to work on both branches frequently

---

### Option 3: .gitattributes export-ignore ❌ NOT SUITABLE

**How it works:**
- Add `.gitattributes` with `export-ignore` for dev files
- Works with `git archive` to create clean tarballs
- GitHub Release feature uses this

**Pros:**
- ✓ Extremely simple to set up
- ✓ No branch management
- ✓ Works automatically for GitHub Releases

**Cons:**
- ✗ Only works with `git archive` (tarballs/zip)
- ✗ Does NOT work with `git checkout` or `git pull`
- ✗ Users still get dev files if they clone/checkout

**Overhead:** MINIMAL

**Best for:** Release archives only (NOT for this use case)

**Verdict:** ❌ Does not meet requirement (users can't git checkout clean version)

---

### Option 4: Subtree Split ❌ NOT SUITABLE

**How it works:**
- Extract subdirectory as separate branch/repo
- Use `git subtree split --prefix=src/ -b dist`

**Pros:**
- ✓ Creates clean branch with only subset
- ✓ Maintains commit history for extracted files

**Cons:**
- ✗ Only works for extracting a SINGLE directory
- ✗ Cannot exclude files (only include one folder)
- ✗ Not suitable for "exclude dev files" pattern
- ✗ Complex to maintain

**Overhead:** MEDIUM-HIGH

**Best for:** Extracting a subdirectory as standalone project

**Verdict:** ❌ Not suitable (we need to exclude files, not extract a single folder)

---

### Option 5: Git Filter-Branch/Filter-Repo ❌ TOO HEAVY

**How it works:**
- Rewrite git history to remove unwanted files
- Create permanent filtered view

**Pros:**
- ✓ Completely removes files from history
- ✓ Can reduce repo size

**Cons:**
- ✗ REWRITES COMMIT HISTORY (dangerous)
- ✗ Very complex and error-prone
- ✗ Requires force push
- ✗ Breaks existing clones
- ✗ Overkill for this use case

**Overhead:** VERY HIGH

**Best for:** One-time history cleanup, not ongoing distribution

**Verdict:** ❌ Too heavy, too risky

---

## Recommended Solution: Orphan Branch with Automation

### Implementation Plan

#### Step 1: Create Orphan Branch

```bash
# Create orphan branch (no shared history)
git checkout --orphan dist

# Remove all files from staging
git rm -rf .

# Copy only distribution files
cp ../trunk/bitbot.exe .
cp ../trunk/bitbot .
cp ../trunk/README.md .
# ... copy other dist files

# Create .gitignore for dist branch
cat > .gitignore << 'EOF'
# Distribution branch - exclude dev files
_SPARC/
tests/
.devcontainer/
src/
*.log
EOF

# Initial commit
git add .
git commit -m "Initial distribution branch"

# Push
git push -u origin dist
```

#### Step 2: Automation Script

Create `scripts/sync-dist-branch.sh`:

```bash
#!/bin/bash
#
# Sync trunk branch to dist branch
# Copies only production files, excludes dev clutter
#

set -e

TRUNK_BRANCH="trunk"
DIST_BRANCH="dist"
TEMP_DIR=$(mktemp -d)

echo "Syncing $TRUNK_BRANCH → $DIST_BRANCH..."

# List of files/folders to include in distribution
DIST_FILES=(
    "bitbot.exe"
    "bitbot"
    "bitbot.cmd"
    "README.md"
    "LICENSE"
    # Add other dist files here
)

# Clone current repo to temp directory
git clone . "$TEMP_DIR"
cd "$TEMP_DIR"

# Checkout dist branch
git checkout "$DIST_BRANCH"

# Remove all files except .git
find . -maxdepth 1 ! -name .git ! -name . -exec rm -rf {} \;

# Checkout distribution files from trunk
git checkout "$TRUNK_BRANCH" -- "${DIST_FILES[@]}"

# Commit if there are changes
if ! git diff --quiet; then
    git add .
    git commit -m "Sync from $TRUNK_BRANCH @ $(git rev-parse --short $TRUNK_BRANCH)"
    git push origin "$DIST_BRANCH"
    echo "✓ Distribution branch updated"
else
    echo "✓ No changes to sync"
fi

# Cleanup
cd -
rm -rf "$TEMP_DIR"
```

#### Step 3: GitHub Action (Optional - Automated)

Create `.github/workflows/sync-dist.yml`:

```yaml
name: Sync Distribution Branch

on:
  push:
    branches:
      - trunk
  workflow_dispatch:

jobs:
  sync-dist:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Sync to dist branch
        run: |
          # Checkout dist branch
          git checkout dist || git checkout --orphan dist

          # Remove all files except .git
          git rm -rf . || true

          # Copy distribution files from trunk
          git checkout trunk -- bitbot.exe bitbot bitbot.cmd README.md LICENSE

          # Commit and push
          git add .
          git commit -m "Sync from trunk @ ${{ github.sha }}" || exit 0
          git push origin dist
```

#### Step 4: User Instructions

Add to README.md:

```markdown
## Installation

### For Users (Clean Distribution)

```bash
# Clone distribution branch only
git clone -b dist https://github.com/user/BitBot.git

# Or checkout dist branch
git checkout dist

# Update
git pull
```

### For Developers (Full Repository)

```bash
# Clone development branch (default)
git clone https://github.com/user/BitBot.git

# Includes all development files:
# - _SPARC/ (research, planning)
# - tests/
# - .devcontainer/
# - src/
```
```

---

## File Selection Strategy

### Include in Distribution (dist branch)

```
✓ bitbot.exe          (Windows launcher)
✓ bitbot              (Bash entry point)
✓ bitbot.cmd          (Windows entry point)
✓ README.md           (User documentation)
✓ LICENSE             (License file)
✓ .gitignore          (Dist-specific)
✓ CHANGELOG.md        (If exists)
```

### Exclude from Distribution (trunk only)

```
✗ _SPARC/             (Research, planning, dev docs)
✗ tests/              (Test files and test workspaces)
✗ .devcontainer/      (Development container config)
✗ src/                (Source code - binaries are built)
✗ scripts/            (Development scripts)
✗ .github/            (GitHub Actions - optional)
✗ CLAUDE.md           (AI assistant instructions)
✗ *.log               (Log files)
✗ .vscode/            (Editor config)
```

---

## Alternative: Dual .gitignore Approach

Instead of separate branches, use branch-specific .gitignore:

**NOT RECOMMENDED** - This doesn't actually exclude files from the branch, just from being tracked. Files already tracked remain visible.

---

## Maintenance Workflow

### Manual Sync (if not using GitHub Actions)

```bash
# After making changes to distribution files in trunk
git checkout trunk
git add bitbot.exe bitbot.cmd README.md
git commit -m "Update launcher"
git push

# Sync to dist branch
./scripts/sync-dist-branch.sh

# Or manually:
git checkout dist
git checkout trunk -- bitbot.exe bitbot.cmd README.md
git commit -m "Sync from trunk"
git push
git checkout trunk
```

### Automated Sync (with GitHub Actions)

- Push to `trunk` → GitHub Action automatically syncs to `dist`
- No manual intervention required
- Users always get latest clean version on `dist` branch

---

## Testing Strategy

### Before Deploying

```bash
# Test that dist branch has only expected files
git checkout dist
ls -la

# Should see ONLY:
# - bitbot.exe
# - bitbot
# - bitbot.cmd
# - README.md
# - LICENSE
# - .gitignore
# - .git/

# Should NOT see:
# - _SPARC/
# - tests/
# - src/
# - .devcontainer/
```

### Verify User Experience

```bash
# Simulate user clone
cd /tmp
git clone -b dist https://github.com/user/BitBot.git bitbot-test
cd bitbot-test
ls -la

# Verify clean checkout
# Run basic functionality test
./bitbot --version
```

---

## Pros and Cons Summary

### Orphan Branch Approach

**Pros:**
- ✓ Minimal overhead after setup
- ✓ Clean separation (different histories)
- ✓ Works with standard git operations
- ✓ Users get only what they need
- ✓ Can be fully automated
- ✓ No disk space overhead (unlike worktrees)
- ✓ Clear purpose for each branch

**Cons:**
- ✗ Initial setup required
- ✗ Need automation script or GitHub Action
- ✗ Two histories to maintain
- ✗ Manual sync if not automated

### Overall Recommendation

**Use orphan branch with GitHub Actions automation:**
1. Set up once
2. Automated sync on every trunk push
3. Zero maintenance overhead
4. Clean user experience
5. Clear separation of concerns

---

## Implementation Checklist

- [ ] Create orphan `dist` branch
- [ ] Add initial distribution files
- [ ] Create `.gitignore` for dist branch
- [ ] Test dist branch checkout
- [ ] Create sync script (`scripts/sync-dist-branch.sh`)
- [ ] Test manual sync
- [ ] (Optional) Create GitHub Action for automated sync
- [ ] Update README.md with user/developer instructions
- [ ] Document which files go in dist vs trunk
- [ ] Test user experience (clone -b dist)
- [ ] Verify no dev files in dist branch

---

## References

- [Git Orphan Branches - Graphite Guide](https://graphite.dev/guides/git-orphan-branches)
- [Git Worktrees - 2024 Blog](https://www.redpill-linpro.com/techblog/2024/01/31/git_worktrees.html)
- [Using .gitattributes export-ignore](https://feeding.cloud.geek.nz/posts/excluding-files-from-git-archive/)
- [Git Subtrees - Mastering Guide](https://medium.com/@porteneuve/mastering-git-subtrees-943d29a798ec)

---

## Notes

- Distribution branch is for **end users** who just want to use BitBot
- Trunk branch is for **developers** who want to contribute or understand internals
- GitHub defaults to showing trunk branch (development)
- Users can easily access dist branch with `-b dist` flag
- No duplication of commit history (orphan = separate history)
- Sync script can be run manually or automated via CI/CD
