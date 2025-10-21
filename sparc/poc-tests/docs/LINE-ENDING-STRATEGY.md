# Line Ending Strategy for BitBot Mixed Project

## Overview

BitBot is a **mixed Windows/Linux project** with both:
- **Windows files**: `.ps1`, `.bat`, `.cmd` (require CRLF)
- **Unix files**: `.sh`, bash scripts (require LF)

This requires careful line ending management to prevent corruption.

---

## Git Configuration

### Repository Settings

**File**: `.gitattributes` (checked into repo)
- Explicitly specifies line endings for each file type
- Ensures consistency across all developers
- Prevents line ending corruption

**Git Config**: `core.autocrlf = false`
```bash
git config core.autocrlf false
```

**Why**: Tells git to **keep line endings exactly as they are** in the repository.

---

## How It Works

### 1. Git Behavior

With `core.autocrlf = false`:
- Git stores files **exactly as committed** (no conversion)
- Git checks out files **exactly as stored** (no conversion)
- `.gitattributes` controls line endings explicitly

### 2. .gitattributes Rules

**Strategy**: Only convert files that MUST have specific endings

```gitattributes
# CRITICAL: Unix scripts MUST have LF (bash requirement)
*.sh text eol=lf
*.bash text eol=lf

# CRITICAL: Windows scripts MUST have CRLF (PowerShell/CMD requirement)
*.ps1 text eol=crlf
*.bat text eol=crlf
*.cmd text eol=crlf

# Everything else: Keep as-is (no conversion)

# Binary files - never touch
*.exe binary
*.dll binary
```

**Key point**: Only shell scripts and Windows scripts have forced line endings. Everything else (JSON, Markdown, etc.) is kept exactly as committed.

---

## File Type Guide

| File Type | Line Ending | Why |
|-----------|-------------|-----|
| `.sh`, `.bash` | **LF** (forced) | Unix shell scripts (bash, sh require LF) |
| `bitbot` (no ext) | **LF** (forced) | Bash script executed in WSL |
| `.ps1`, `.bat`, `.cmd` | **CRLF** (forced) | Windows scripts (PowerShell, CMD require CRLF) |
| `.md`, `.txt` | **As-is** | Kept exactly as committed |
| `.json`, `.jsonc` | **As-is** | Kept exactly as committed |
| DevContainer files | **As-is** | Kept exactly as committed |
| `.exe`, `.dll`, `.zip` | **Binary** | Never convert |

---

## Developer Setup

### Initial Setup (Once)

```bash
# Clone repository
git clone https://github.com/ManuelKugelmann/BitBot.git
cd BitBot

# Configure git to keep line endings as-is
git config core.autocrlf false

# Verify setting
git config core.autocrlf
# Output: false
```

### Verify Configuration

```bash
# Check git config
git config --list | grep autocrlf
# Should show: core.autocrlf=false

# Check .gitattributes exists
cat .gitattributes
```

---

## Common Issues

### Issue 1: "LF will be replaced by CRLF" Warning

**Symptom**:
```
warning: LF will be replaced by CRLF in file.ps1
The file will have its original line endings in your working directory
```

**Cause**: You're committing a `.ps1` file with LF endings, but `.gitattributes` specifies CRLF

**Fix**:
- This is **expected and correct**
- Git is converting LF → CRLF as specified
- The warning confirms `.gitattributes` is working

**If unwanted**, the file was created with wrong line endings. Fix with:
```bash
# For PowerShell files (should be CRLF)
unix2dos file.ps1

# For bash files (should be LF)
dos2unix file.sh
```

---

### Issue 2: Bash Script Shows `$'\r': command not found`

**Symptom**:
```bash
./script.sh
./script.sh: line 1: $'\r': command not found
```

**Cause**: Bash script has CRLF line endings (Windows style)

**Fix**:
```bash
# Method 1: Use BitBot tool
.claude/tools/fix-line-endings.sh script.sh

# Method 2: Manual conversion
dos2unix script.sh

# Method 3: sed
sed -i 's/\r$//' script.sh
```

**Prevention**: Ensure `.gitattributes` has:
```gitattributes
*.sh text eol=lf
```

---

### Issue 3: PowerShell Script Fails

**Symptom**: PowerShell script has parse errors or doesn't execute

**Cause**: Script has LF endings instead of CRLF

**Fix**:
```bash
# Convert to CRLF
unix2dos script.ps1

# Or with sed
sed -i 's/$/\r/' script.ps1
```

**Prevention**: Ensure `.gitattributes` has:
```gitattributes
*.ps1 text eol=crlf
```

---

## Best Practices

### ✅ DO

- **Always check** `.gitattributes` is committed
- **Set** `core.autocrlf = false` after cloning
- **Use BitBot tools** for line ending fixes:
  - `fix-line-endings.sh` - Convert to LF
  - `fix-and-check-bash.sh` - Convert to LF and check syntax
- **Commit** files with correct line endings for their type
- **Test scripts** after editing on different platform

### ❌ DON'T

- Don't set `core.autocrlf = true` or `input` (causes issues)
- Don't manually edit binary files
- Don't use `git add -A` without checking warnings
- Don't ignore "LF will be replaced" warnings
- Don't edit bash scripts in Windows Notepad (adds CRLF)

---

## Cross-Platform Editing

### Recommended Editors

**VS Code** (Best for mixed projects):
```json
// .vscode/settings.json
{
  "files.eol": "\n",  // Default to LF
  "files.associations": {
    "*.ps1": "powershell",
    "*.sh": "shellscript"
  }
}
```

VS Code automatically respects `.gitattributes` and shows current line ending in status bar.

**Vim**:
```vim
:set fileformat=unix    " For .sh files
:set fileformat=dos     " For .ps1 files
```

**Notepad++**:
- Edit → EOL Conversion → Unix (LF) for `.sh`
- Edit → EOL Conversion → Windows (CRLF) for `.ps1`

---

## Verification Tools

### Check File Line Endings

```bash
# Show line ending type
file script.sh
# Output: ASCII text

file script.ps1
# Output: ASCII text, with CRLF line terminators

# Show actual bytes
od -c script.sh | head -5
# LF: shows \n
# CRLF: shows \r\n
```

### Verify .gitattributes Working

```bash
# Check what git will do to a file
git check-attr -a file.sh
# Output: file.sh: text: auto eol: lf

git check-attr -a file.ps1
# Output: file.ps1: text: auto eol: crlf
```

---

## Technical Details

### Why `core.autocrlf = false`?

**Option**: `core.autocrlf = true` (Windows default)
- Converts LF → CRLF on checkout
- Converts CRLF → LF on commit
- **Problem**: Breaks mixed projects (converts everything)

**Option**: `core.autocrlf = input` (Linux recommendation)
- Keeps LF on checkout
- Converts CRLF → LF on commit
- **Problem**: Corrupts Windows scripts (removes CRLF)

**Option**: `core.autocrlf = false` ✅ (Mixed project)
- No automatic conversion
- Respects `.gitattributes` explicitly
- **Best for**: Projects with both Windows and Unix files

### Git Attributes Priority

1. **`.gitattributes`** (checked-in, highest priority)
2. **`.git/info/attributes`** (local, per-repo)
3. **Core config** (`core.autocrlf`, `core.eol`)

With `.gitattributes` + `autocrlf=false`, the attributes file has full control.

---

## Summary

**Strategy**: Explicit line ending control via `.gitattributes`

**Settings**:
- `core.autocrlf = false` ✓
- `.gitattributes` specifies all file types ✓

**Result**:
- Bash scripts always have LF ✓
- PowerShell scripts always have CRLF ✓
- Works consistently across Windows/WSL/Linux ✓

---

**Status**: ✅ Configured and tested  
**Date**: 2025-10-20  
**References**: 
- [Git Attributes Documentation](https://git-scm.com/docs/gitattributes)
- [GitHub Line Ending Guide](https://docs.github.com/en/get-started/getting-started-with-git/configuring-git-to-handle-line-endings)
