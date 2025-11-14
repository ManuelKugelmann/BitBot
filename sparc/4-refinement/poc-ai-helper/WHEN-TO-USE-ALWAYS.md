# When to Use the [a]lways Option

## Important: [a]lways is RARE

**Most error handlers DO NOT offer [a]lways** - only specific, hand-picked scenarios where it makes sense.

**Default for most checks**: `allow_always=""` (no [a]lways option)

**Only for specific cases**: `allow_always="true"` (e.g., git push warning)

## Rule of Thumb

**Most checks**: Use `allow_always=""` - simpler prompts, safer defaults

**Rare exceptions**: Use `allow_always="true"` - only for explicitly defined repetitive warnings

---

## ✅ Use [a]lways (allow_always="true")

### Repetitive Warnings/Checks

```bash
# Git push warning
print_error_with_ai_help \
    "About to push to remote" \
    "You're about to push commits to the remote repository..." \
    "Git push safety" \
    "" \
    "true" \
    "Proceed with git push"
```

**Prompt**: `Proceed with git push ? [y]es(once), yes([a]lways), [N]o, help[?]:`

**Why**: User may push many times. After confirming once with AI help, they can choose [a]lways to skip future warnings.

### Runtime Service Checks

```bash
# Docker daemon check (happens every time BitBot runs)
print_error_with_ai_help \
    "Docker daemon not running" \
    "$HELP_DOCKER_DAEMON_NOT_RUNNING" \
    "Docker startup" \
    "autofix_start_docker_daemon" \
    "true" \
    "Start Docker now"
```

**Why**: Repetitive check every time BitBot starts. User can choose "yes always, auto-start Docker".

### Optional Validations

```bash
# Code style check
print_error_with_ai_help \
    "Code style issues detected" \
    "Run 'npm run lint:fix' to auto-fix..." \
    "Code linting" \
    "autofix_run_linter" \
    "true" \
    "Skip linting"
```

**Why**: Happens on every commit/build. User can skip always if they don't care about linting.

### Test Suite Warnings

```bash
# Test coverage warning
print_error_with_ai_help \
    "Test coverage below 80%" \
    "Current coverage: 65%. Add more tests..." \
    "Test coverage" \
    "" \
    "true" \
    "Continue anyway"
```

**Why**: Repetitive check. User can acknowledge once with AI help, then skip always.

---

## ❌ DON'T Use [a]lways (allow_always="")

### Setup/Installation

```bash
# Docker not installed (happens once)
print_error_with_ai_help \
    "Docker not found" \
    "$HELP_DOCKER_NOT_INSTALLED" \
    "Docker installation" \
    "" \
    "" \
    "Continue without Docker"
```

**Prompt**: `Continue without Docker ? [y]es(once), [N]o, help[?]:`

**Why**: One-time setup decision. Not repetitive.

### First-Time Configuration

```bash
# WSL not enabled (one-time)
print_error_with_ai_help \
    "WSL not detected" \
    "$HELP_WSL_NOT_ENABLED" \
    "WSL installation" \
    "autofix_enable_wsl" \
    "" \
    "Enable WSL now"
```

**Why**: Setup happens once. Once WSL is installed, this check never triggers again.

### Critical Safety Checks

```bash
# Destructive operation warning
print_error_with_ai_help \
    "This will DELETE all containers" \
    "This operation cannot be undone..." \
    "Docker system prune" \
    "" \
    "" \
    "Proceed with deletion"
```

**Why**: Critical operation. User should confirm EVERY time, never skip.

### Dependency Version Mismatches

```bash
# Node version mismatch
print_error_with_ai_help \
    "Node.js version mismatch" \
    "Required: v20.x, Found: v18.x..." \
    "Node version upgrade" \
    "" \
    "" \
    "Continue anyway"
```

**Why**: Important compatibility check. Shouldn't be skipped permanently.

---

## Decision Matrix

| Scenario | Frequency | Severity | allow_always | Reason |
|----------|-----------|----------|--------------|---------|
| Git push warning | Every push | Low | ✅ `"true"` | Repetitive, low risk |
| Docker not running | Every run | Medium | ✅ `"true"` | Repetitive, auto-fixable |
| Lint warnings | Every commit | Low | ✅ `"true"` | Repetitive, optional |
| Test coverage low | Every build | Low | ✅ `"true"` | Repetitive, optional |
| Docker not installed | Once | High | ❌ `""` | One-time setup |
| WSL not enabled | Once | High | ❌ `""` | One-time setup |
| Delete all data | Rare | Critical | ❌ `""` | Destructive, must confirm |
| Version mismatch | Rare | Medium | ❌ `""` | Important safety check |

---

## Example Use Cases

### Example 1: Git Push Safety (WITH [a]lways AND fi[x])

**Scenario**: AI warns about pushing to main branch

```bash
# Auto-fix function for git push (commits and pushes)
autofix_git_commit_and_push() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)

    # Prompt for commit message or use default
    echo "Commit message (or press Enter for auto-generated): " >&2
    read -r commit_msg

    if [ -z "$commit_msg" ]; then
        commit_msg="Auto-commit: changes on $branch"
    fi

    # Commit and push
    if git add . && git commit -m "$commit_msg"; then
        if git push origin "$branch"; then
            echo "✓ Committed and pushed successfully"
            return 0
        else
            echo "✗ Push failed"
            return 1
        fi
    else
        echo "✗ Commit failed"
        return 1
    fi
}

check_git_push_safety() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        # Check if user has saved preference
        if [ -f ".bitbot/preferences/skip-git-push-warning" ]; then
            return 0  # User chose "always" before
        fi

        print_error_with_ai_help \
            "Pushing to protected branch: $current_branch" \
            "You're about to push directly to $current_branch.

Consider:
  • Create a feature branch: git checkout -b feature/my-feature
  • Push to feature branch instead
  • Create a pull request for review

Or continue if you're sure." \
            "Git push to main branch safety" \
            "autofix_git_commit_and_push" \
            "true" \
            "Push to $current_branch anyway"

        local result=$?
        if [ $result -eq 0 ]; then
            # If user chose 'a' (always), preference is saved
            # Next time this check is skipped
            return 0
        elif [ $result -eq 2 ]; then
            # Auto-fix (x) completed - committed and pushed
            return 0
        else
            return 1  # User said no
        fi
    fi
}
```

**First time** (user asks for help, then auto-commits):
```
Pushing to protected branch: main ? [y]es(once), yes([a]lways), [N]o, help[?], fi[x]: ?

💡 AI Assistant:
Pushing directly to main can be risky in team environments. Best practices:
1. Use feature branches for new work
2. Create pull requests for code review
3. Use branch protection rules

However, if you're working solo or this is a personal project, it's fine to push directly!

Next steps:
  • Type 'y' to continue (once)
  • Type 'a' to always continue (save preference)
  • Type 'N' to exit
  • Type 'x' to auto-fix
  • Ask another question (AI will respond)

Your choice: x

⚙ Attempting automatic fix...
Commit message (or press Enter for auto-generated): Update documentation

✓ Committed and pushed successfully

[+] Auto-fix completed successfully
```

**Second time** (user chooses 'always'):
```
Pushing to protected branch: main ? [y]es(once), yes([a]lways), [N]o, help[?], fi[x]: a

[i] Saving preference: always continue for this check
```

**Future pushes**: Check skipped automatically (preference saved).

### Example 2: Docker Not Installed (NO [a]lways)

**Scenario**: First-time setup, Docker missing

```bash
check_docker_installed() {
    if ! command -v docker &>/dev/null; then
        print_error_with_ai_help \
            "Docker not found" \
            "$HELP_DOCKER_NOT_INSTALLED" \
            "Docker Desktop installation for beginners" \
            "" \
            "" \
            "Continue without Docker"

        [ $? -eq 0 ] || return 1
    fi
}
```

**Prompt**: `Continue without Docker ? [y]es(once), [N]o, help[?]:`

**Why no [a]lways**:
- This is a one-time setup issue
- Once Docker is installed, check passes forever
- No need for "always skip" - the problem goes away permanently

---

## Implementation Pattern

### For Repetitive Checks (WITH [a]lways)

```bash
check_something_repetitive() {
    # Check preference file first
    if [ -f ".bitbot/preferences/skip-something" ]; then
        return 0  # User chose [a]lways before
    fi

    if [ condition_fails ]; then
        print_error_with_ai_help \
            "Error message" \
            "Help text" \
            "AI context" \
            "autofix_function_or_empty" \
            "true" \
            "Action prompt"

        result=$?
        if [ $result -eq 0 ]; then
            # TODO: Save preference if user chose 'a'
            return 0
        else
            return 1
        fi
    fi
}
```

### For One-Time Checks (NO [a]lways)

```bash
check_something_onetime() {
    if [ condition_fails ]; then
        print_error_with_ai_help \
            "Error message" \
            "Help text" \
            "AI context" \
            "autofix_function_or_empty" \
            "" \
            "Action prompt"

        [ $? -eq 0 ] || return 1
    fi
}
```

---

## Summary

**Use [a]lways for**:
- ✅ Repetitive warnings (git push, test coverage)
- ✅ Runtime service checks (Docker daemon)
- ✅ Optional validations (linting, formatting)
- ✅ Low-risk checks users may want to skip

**DON'T use [a]lways for**:
- ❌ One-time setup (Docker installation, WSL)
- ❌ Critical safety checks (destructive operations)
- ❌ Important compatibility (version mismatches)
- ❌ Things that fix themselves (once installed, always works)

**Golden Rule**: If the user might see this prompt **many times** and it's **safe to skip**, use `allow_always="true"`.
