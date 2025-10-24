# BitBot Scripts

Development and release automation scripts.

---

## Release Management

### create-release-branch.sh

**Purpose:** One-time setup to create the orphan release branch

**Usage:**
```bash
./scripts/create-release-branch.sh
```

**What it does:**
1. Creates orphan `release` branch (no shared history with trunk)
2. Copies only release files (excludes _SPARC/, tests/, etc.)
3. Creates release-specific .gitignore
4. Pushes release branch to origin
5. Switches back to trunk

**Run this:** Once, before first release

---

### sync-release-branch.sh

**Purpose:** Sync changes from trunk to release branch

**Usage:**
```bash
./scripts/sync-release-branch.sh
```

**What it does:**
1. Clones repo to temp directory
2. Checks out/creates release branch
3. Removes all files
4. Copies release files from trunk
5. Commits and pushes if changes detected
6. Cleans up temp directory

**Run this:** Before each release, when trunk has changes to publish

**Files included:**
- VERSION (version identifier)
- bitbot (main executable)
- bitbot.exe (Windows launcher)
- bitbot.cmd (Windows wrapper)
- core/ (core runtime scripts)
- templates/ (devcontainer templates)
- config-devcontainer/ (config mode)
- README.md
- LICENSE

**Files excluded:**
- _SPARC/ (research, planning)
- tests/ (test suite)
- src/ (source code)
- .devcontainer/ (dev environment)
- scripts/ (dev scripts)
- .github/ (CI/CD workflows)

---

### set-default-branch.sh

**Purpose:** Set GitHub repository default branch

**Usage:**
```bash
# Set release as default
./scripts/set-default-branch.sh

# Or specify branch
./scripts/set-default-branch.sh trunk
```

**What it does:**
1. Checks if `gh` CLI installed and authenticated
2. Gets current repository and default branch
3. Verifies target branch exists
4. Prompts for confirmation
5. Sets default branch
6. Verifies change succeeded

**Requirements:**
- GitHub CLI (`gh`) installed
- Authenticated: `gh auth login`
- Admin access to repository

**When users clone after this:**
```bash
git clone https://github.com/user/BitBot.git
# Gets 'release' branch by default (clean version)
```

---

## Typical Release Workflow

### 1. Development

```bash
# Work on trunk
git checkout trunk
# ... make changes ...
git commit -m "Add feature"
git push origin trunk
```

---

### 2. Prepare Release

```bash
# Sync trunk to release
./scripts/sync-release-branch.sh

# Verify release branch
git checkout release
git pull
ls -la  # Should see only release files
```

---

### 3. Tag Version

```bash
# Tag release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions automatically:
# - Creates bitbot-v1.0.0.zip
# - Generates CHECKSUMS.txt
# - Publishes GitHub Release
```

---

### 4. Set Default Branch (One-time)

```bash
# After first release
./scripts/set-default-branch.sh

# Verify
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
# Should output: release
```

---

## Script Maintenance

### Testing Scripts

Before running on production:

1. **Test in fork:**
   ```bash
   # Fork repository
   git clone https://github.com/yourname/BitBot.git
   cd BitBot

   # Test scripts
   ./scripts/create-release-branch.sh
   ./scripts/sync-release-branch.sh
   ```

2. **Verify output:**
   ```bash
   git checkout release
   ls -la
   # Verify only release files present
   ```

3. **Clean up test:**
   ```bash
   git branch -D release
   git push origin --delete release
   ```

---

### Adding New Release Files

To include new files in release branch:

1. **Edit sync-release-branch.sh:**
   ```bash
   # Update RELEASE_FILES array
   RELEASE_FILES=(
       "VERSION"
       "bitbot"
       "bitbot.exe"
       "bitbot.cmd"
       "core"
       "templates"
       "config-devcontainer"
       "README.md"
       "LICENSE"
       "NEW_FILE"  # Add here
   )
   ```

2. **Edit create-release-branch.sh:**
   ```bash
   # Update file list
   git checkout "$TRUNK_BRANCH" -- \
       VERSION \
       bitbot \
       bitbot.exe \
       core \
       ...
       NEW_FILE \  # Add here
   ```

3. **Edit .github/workflows/release.yml:**
   ```yaml
   # Update zip command
   zip -r bitbot-v${{ steps.version.outputs.version }}.zip \
     VERSION \
     bitbot \
     bitbot.exe \
     core/ \
     ...
     NEW_FILE \  # Add here
   ```

4. **Test:**
   ```bash
   ./scripts/sync-release-branch.sh
   git checkout release
   ls -la  # Verify NEW_FILE present
   ```

---

## Troubleshooting

### Script: Permission Denied

```bash
chmod +x scripts/*.sh
```

---

### Script: Branch Already Exists

```bash
# Delete and recreate
git branch -D release
git push origin --delete release
./scripts/create-release-branch.sh
```

---

### Script: gh CLI Not Found

```bash
# Install GitHub CLI
# macOS/Linux:
brew install gh

# Debian/Ubuntu:
sudo apt install gh

# Authenticate
gh auth login
```

---

### Script: Not Authenticated

```bash
gh auth login
# Follow prompts
```

---

### Script: No Permission

You need admin access to:
- Set default branch
- Create/delete branches

Ask repository owner for permissions.

---

## See Also

- [RELEASE.md](../RELEASE.md) - Complete release process
- [.github/workflows/](../.github/workflows/) - Automated workflows
- [GitHub CLI Docs](https://cli.github.com/manual/)
