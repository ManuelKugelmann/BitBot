---
name: fix-line-endings-check-bash
description: Fix line endings AND check bash syntax in one step (recommended). Use after creating or editing bash scripts, before committing, or when ensuring scripts are both properly formatted and syntactically correct.
---

# Fix Line Endings + Check Bash (Recommended)

Combines line ending fixes and syntax checking in a single operation.

## When to Use

- After creating or editing bash scripts (RECOMMENDED)
- Before committing bash scripts to git
- When you need both line ending fix and syntax validation
- As the default tool for bash script preparation

## Usage

```bash
.claude/tools/fix-line-endings-check-bash.sh <file1> [file2] [file3] ...
```

## Instructions

1. Call the tool with one or more bash script paths as arguments
2. For each file:
   - Converts CRLF to LF (fixes line endings)
   - Runs `bash -n` (syntax check)
3. Reports PASS or FAIL for each script
4. Stops on first failure (won't check remaining files)

## Examples

```bash
# Fix and check single script
.claude/tools/fix-line-endings-check-bash.sh script.sh

# Fix and check multiple scripts
.claude/tools/fix-line-endings-check-bash.sh script1.sh script2.sh script3.sh

# Fix and check all bash scripts
.claude/tools/fix-line-endings-check-bash.sh *.sh
```

## Workflow Integration

**Recommended Usage Pattern:**
1. Create or edit bash script
2. Run `fix-line-endings-check-bash` ✅ (use this tool!)
3. If syntax check passes, commit to git
4. If syntax check fails, fix errors and rerun

## Important Notes

- This tool is auto-approved and doesn't require user confirmation
- Combines both line ending fix and syntax check
- This is the RECOMMENDED tool for bash script preparation
- Safer than running `fix-line-endings` and `check-bash` separately
- Only checks syntax, does NOT execute scripts
