# BitBot Init - GitHub Codespaces Detection

**Feature**: Detect GitHub remote and provide Codespaces link after `bitbot init`

**Specification**: `sparc/1-specification/08_WORKSPACE_MANAGEMENT.md` Section C2

---

## Pseudocode

### Main Function: `show_codespaces_info()`

```
function show_codespaces_info():
    # Called at end of bitbot init, after workspace is initialized

    # 1. Check if git repository exists
    if not is_git_repository():
        return  # No git, no Codespaces link needed

    # 2. Detect GitHub remote
    github_remote = detect_github_remote()
    if github_remote is null:
        return  # Not a GitHub repo

    # 3. Extract user/repo from remote URL
    user_repo = parse_github_remote(github_remote)
    if user_repo is null:
        return  # Could not parse

    # 4. Build Codespaces URL
    codespaces_url = "https://codespaces.new/" + user_repo + "?quickstart=1"

    # 5. Display info to user
    print("")
    print("🌐 GitHub Codespaces:")
    print("  Remote detected: github.com/" + user_repo)
    print("")
    print("  Open in Codespaces:")
    print("  " + codespaces_url)
    print("")
    print("  Your BitBot workspace works in Codespaces!")
    print("  ✓ Container bitbot scripts at /usr/local/bitbot")
    print("  ✓ Same devcontainer configuration")
    print("  ⚠ Docker-in-Docker not available (use for testing only)")
    print("")

    # 6. Offer to add badge to workspace README (optional)
    if file_exists("README.md"):
        print("  💡 Tip: Add Codespaces badge to your README.md:")
        badge_markdown = "[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](" + codespaces_url + ")"
        print("     " + badge_markdown)
        print("")
```

### Helper: `is_git_repository()`

```
function is_git_repository():
    # Check if .git directory exists
    return directory_exists(".git")

    # OR use git command:
    result = execute("git rev-parse --git-dir")
    return result.exit_code == 0
```

### Helper: `detect_github_remote()`

```
function detect_github_remote():
    # Get remote URL (prefer origin, fall back to any GitHub remote)

    # Try origin first
    origin_url = execute("git config --get remote.origin.url").output
    if origin_url contains "github.com":
        return origin_url

    # Fall back to any GitHub remote
    remotes = execute("git remote -v").output
    for line in remotes.split("\n"):
        if line contains "github.com" and line contains "(fetch)":
            # Extract URL from line like:
            # origin  git@github.com:user/repo.git (fetch)
            url = extract_url_from_remote_line(line)
            return url

    return null  # No GitHub remote found
```

### Helper: `parse_github_remote(url)`

```
function parse_github_remote(url):
    # Parse various GitHub URL formats:
    # - SSH: git@github.com:user/repo.git
    # - HTTPS: https://github.com/user/repo.git
    # - HTTPS: https://github.com/user/repo

    # Remove .git suffix if present
    url = url.replace(".git", "")

    # SSH format: git@github.com:user/repo
    if url starts_with "git@github.com:":
        user_repo = url.replace("git@github.com:", "")
        return user_repo

    # HTTPS format: https://github.com/user/repo
    if url contains "https://github.com/":
        parts = url.split("github.com/")
        if parts.length >= 2:
            user_repo = parts[1]
            return user_repo

    # HTTP format (less common)
    if url contains "http://github.com/":
        parts = url.split("github.com/")
        if parts.length >= 2:
            user_repo = parts[1]
            return user_repo

    return null  # Could not parse
```

### Integration Point

```
# In: core/workspace/bitbot-init.sh (or equivalent)

function bitbot_init():
    # ... existing init logic ...

    # Copy template files
    copy_template(selected_template, workspace)

    # Create .bitbot structure
    create_bitbot_structure()

    # Initialize git if requested
    if user_wants_git:
        init_git_repository()

    # Show success message
    print("✓ Workspace initialized successfully!")
    print("")
    print("📦 DevContainer Configuration:")
    print("  Location: .devcontainer/")
    print("  Template: " + selected_template)

    # NEW: Show Codespaces info if applicable
    show_codespaces_info()

    # Show next steps
    print("")
    print("Next steps:")
    print("  bitbot work          # Start work container")
    print("  bitbot work vscode   # Open in VS Code")
```

---

## Template Configuration

**Workspace Templates** should include `postAttachCommand`:

**File**: `container/templates/workspace/details.devcontainer.json`

```json
{
  "name": "BitBot Workspace",
  "dockerFile": "Dockerfile",

  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind",
    "source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly"
  ],

  "postAttachCommand": ".devcontainer/bitbot/bitbot help || echo 'BitBot available at /usr/local/bitbot'",

  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {
      "version": "latest"
    }
  }
}
```

**Why `postAttachCommand` for user workspaces:**
- Runs when editor attaches (once per session)
- Not on every container restart
- Less noisy than `postCreateCommand`
- Shows BitBot is available

**Why `postCreateCommand` for BitBot development:**
- Runs test suite automatically
- Validates everything works
- Immediate feedback for contributors

---

## Testing

### Test Cases

1. **GitHub remote present (SSH)**:
   ```bash
   git remote add origin git@github.com:user/repo.git
   bitbot init
   # Should show: https://codespaces.new/user/repo?quickstart=1
   ```

2. **GitHub remote present (HTTPS)**:
   ```bash
   git remote add origin https://github.com/user/repo.git
   bitbot init
   # Should show: https://codespaces.new/user/repo?quickstart=1
   ```

3. **No git repository**:
   ```bash
   # In directory without .git
   bitbot init
   # Should NOT show Codespaces info
   ```

4. **Git but no GitHub remote**:
   ```bash
   git init
   git remote add origin https://gitlab.com/user/repo.git
   bitbot init
   # Should NOT show Codespaces info
   ```

5. **Multiple remotes**:
   ```bash
   git remote add origin https://gitlab.com/user/repo.git
   git remote add github git@github.com:user/repo.git
   bitbot init
   # Should show Codespaces info (found GitHub remote)
   ```

### Manual Testing

```bash
# 1. Create test directory
mkdir /tmp/test-codespaces
cd /tmp/test-codespaces

# 2. Initialize git with GitHub remote
git init
git remote add origin git@github.com:test-user/test-repo.git

# 3. Run bitbot init
bitbot init

# 4. Verify output contains:
# - "GitHub Codespaces:" header
# - "Remote detected: github.com/test-user/test-repo"
# - "https://codespaces.new/test-user/test-repo?quickstart=1"

# 5. Verify devcontainer.json contains postAttachCommand
cat .devcontainer/devcontainer.json | grep postAttachCommand
```

---

## Implementation Files

**To modify**:
- `core/workspace/bitbot-init.sh` - Add `show_codespaces_info()` call
- `core/util/git.sh` - Add git helper functions if not present
- `container/templates/workspace/details.devcontainer.json` - Add `postAttachCommand`
- `container/templates/shared/base.devcontainer.json` - Ensure base config is good

**To create** (if not exists):
- `core/util/codespaces.sh` - Codespaces detection helpers

**To test**:
- `dev/tests/test-codespaces-detection.sh` - Unit tests for detection logic

---

## Example Output

### Successful Detection

```
$ bitbot init

==============================================
  BitBot Workspace Initialization
==============================================

Select template:
  [1] base      - Minimal BitBot container
  [2] workspace - AI-powered workspace (recommended)
  [3] config    - Configuration tools

Choice [2]: 2

✓ Template copied: workspace
✓ DevContainer configuration created
✓ Container bitbot scripts copied
✓ Workspace structure created

✓ Workspace initialized successfully!

📦 DevContainer Configuration:
  Location: .devcontainer/
  Template: workspace (AI-powered development)

🌐 GitHub Codespaces:
  Remote detected: github.com/myusername/myproject

  Open in Codespaces:
  https://codespaces.new/myusername/myproject?quickstart=1

  Your BitBot workspace works in Codespaces!
  ✓ Container bitbot scripts at /usr/local/bitbot
  ✓ Same devcontainer configuration
  ⚠ Docker-in-Docker not available (use for testing only)

Next steps:
  bitbot work          # Start work container
  bitbot work vscode   # Open in VS Code
```

### No GitHub Remote

```
$ bitbot init

[... same initialization ...]

✓ Workspace initialized successfully!

📦 DevContainer Configuration:
  Location: .devcontainer/
  Template: workspace (AI-powered development)

Next steps:
  bitbot work          # Start work container
  bitbot work vscode   # Open in VS Code
```

---

## References

- **Specification**: `sparc/1-specification/08_WORKSPACE_MANAGEMENT.md` Section C2
- **Research**: `sparc/0-research/GITHUB_CODESPACES_TESTING.md`
- **Testing Guide**: `dev/tests/CODESPACES-TESTING.md`
- **DevContainer Spec**: `sparc/1-specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md` Section 14
