# Release Process

This document describes how to create and publish a BitBot release.

---

## Prerequisites

- Push access to `trunk` and `release` branches
- Ability to create tags
- GitHub Actions enabled

---

## Release Workflow

### 1. Prepare Release on Trunk

Work on the `trunk` branch until ready for release:

```bash
# Make changes on trunk
git checkout trunk
# ... make changes ...
git commit -m "Add new feature"
git push origin trunk
```

**Verify:**
- ✓ All tests pass on trunk
- ✓ Documentation updated
- ✓ CHANGELOG.md updated (if exists)

---

### 2. Sync to Release Branch

Sync trunk changes to the release branch:

```bash
# Option A: Use sync script (recommended)
./scripts/sync-release-branch.sh

# Option B: Manual via GitHub Actions
# Go to: Actions → Sync Release Branch → Run workflow

# Option C: Create release branch (first time only)
./scripts/create-release-branch.sh
```

**Verify sync:**
```bash
git checkout release
git pull
ls -la
# Should see ONLY release files (no _SPARC/, tests/, etc.)
```

---

### 3. Create Version Tag

Tag the release branch with a version:

```bash
# Make sure you're on release branch
git checkout release
git pull

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag to GitHub
git push origin v1.0.0
```

**Tag format:** `v<major>.<minor>.<patch>` (e.g., v1.0.0, v1.2.3)

---

### 4. Automatic Release Creation

GitHub Actions automatically:

1. **Detects tag** (v*)
2. **Checks out release branch**
3. **Creates zip archive:**
   - `bitbot-v1.0.0.zip`
   - Contains all release files
   - Excludes dev files (.git, .log, etc.)
4. **Generates checksums:**
   - `CHECKSUMS.txt` with SHA256
5. **Creates GitHub Release:**
   - Uploads zip and checksums
   - Generates release notes
   - Publishes release

**Monitor:**
- Go to: Actions → Create Release
- Wait for workflow to complete (~1-2 minutes)

---

### 5. Verify Release

Check the GitHub Release:

1. **Go to:** Releases → v1.0.0
2. **Verify assets:**
   - ✓ `bitbot-v1.0.0.zip` exists
   - ✓ `CHECKSUMS.txt` exists
3. **Test download:**
   ```bash
   wget https://github.com/ManuelKugelmann/BitBot/releases/download/v1.0.0/bitbot-v1.0.0.zip
   unzip -l bitbot-v1.0.0.zip
   # Verify contents
   ```

---

## Setting Default Branch to Release

**Purpose:** When users clone without specifying a branch, they get the clean release version.

### Recommended: Use Script

```bash
./scripts/set-default-branch.sh
```

**What it does:**
- Checks if `gh` CLI is installed
- Verifies authentication
- Checks if release branch exists
- Sets default branch to 'release'
- Verifies the change worked

**Alternative branch:**
```bash
./scripts/set-default-branch.sh trunk  # Set trunk as default
```

---

### Alternative: GitHub CLI Manually

```bash
gh repo edit --default-branch release
```

---

### Alternative: GitHub Web UI

1. Go to repository on GitHub
2. Click **Settings** (top right)
3. Click **Branches** (left sidebar)
4. Under "Default branch", click **Switch to another branch**
5. Select **release**
6. Click **Update**
7. Confirm the change

### What Changes:

**Before (trunk default):**
```bash
git clone https://github.com/ManuelKugelmann/BitBot.git
# Gets: trunk with _SPARC/, tests/, .devcontainer/, etc.
```

**After (release default):**
```bash
git clone https://github.com/ManuelKugelmann/BitBot.git
# Gets: release with bitbot, core/, templates/, LICENSE only
```

**Developers can still access trunk:**
```bash
git clone -b trunk https://github.com/ManuelKugelmann/BitBot.git
```

---

## Branch Strategy

### Trunk Branch (Development)

**Purpose:** Active development
**Contains:**
- All source code
- Development tools (_SPARC/, tests/, src/)
- CI/CD workflows (.github/)
- Documentation (CLAUDE.md)

**Workflow:**
- Developers work here
- Run tests here
- Merge PRs here

---

### Release Branch (Distribution)

**Purpose:** Clean distribution for users
**Contains:**
- `bitbot` (main executable)
- `bitbot.exe` (Windows launcher)
- `bitbot.cmd` (Windows wrapper)
- `core/` (all scripts)
- `templates/` (devcontainer templates, including config mode)
- `README.md` (user docs)
- `LICENSE` (MIT)

**Excludes:**
- `_SPARC/` (research, planning)
- `tests/` (test suite)
- `src/` (source code)
- `.devcontainer/` (dev environment)
- `scripts/` (dev scripts)
- `.github/` (CI/CD)

**Workflow:**
- Synced from trunk (manually)
- Tagged for releases
- Users clone this by default

---

## Release Checklist

Before creating a release:

- [ ] All features complete and tested
- [ ] Tests pass on trunk
- [ ] Documentation updated (README.md)
- [ ] CHANGELOG.md updated (if exists)
- [ ] Version number decided (semver)
- [ ] Sync trunk → release
- [ ] Verify release branch is clean
- [ ] Create and push tag
- [ ] Verify GitHub Actions workflow succeeds
- [ ] Verify GitHub Release created
- [ ] Test download and installation
- [ ] Announce release (if applicable)

---

## Version Numbering (Semantic Versioning)

Format: `v<major>.<minor>.<patch>`

- **Major (v2.0.0):** Breaking changes
- **Minor (v1.1.0):** New features (backward compatible)
- **Patch (v1.0.1):** Bug fixes (backward compatible)

**Examples:**
- `v1.0.0` - Initial release
- `v1.0.1` - Bug fix
- `v1.1.0` - New feature added
- `v2.0.0` - Breaking change

---

## Troubleshooting

### Tag Already Exists

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0

# Recreate tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

### Release Workflow Failed

1. Check Actions tab for error details
2. Common issues:
   - Release branch doesn't exist
   - Missing files in release branch
   - Permissions issue
3. Fix and re-run workflow

---

### Wrong Files in Release Zip

1. Check release branch contents:
   ```bash
   git checkout release
   ls -la
   ```
2. If wrong files present, sync again:
   ```bash
   ./scripts/sync-release-branch.sh
   ```
3. Delete and recreate tag

---

## Manual Release (Fallback)

If GitHub Actions fails, create release manually:

```bash
# Checkout release branch
git checkout release
git pull

# Create zip
zip -r bitbot-v1.0.0.zip \
  bitbot bitbot.exe bitbot.cmd \
  core/ templates/ \
  README.md LICENSE

# Generate checksum
sha256sum bitbot-v1.0.0.zip > CHECKSUMS.txt

# Create GitHub Release manually via web UI
# Upload zip and CHECKSUMS.txt
```

---

## See Also

- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Semantic Versioning](https://semver.org/)
- [sync-release-branch.sh](scripts/sync-release-branch.sh)
- [release.yml](.github/workflows/release.yml)
