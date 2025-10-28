---
name: check-bash
description: Check bash script syntax without executing or modifying files. Use before committing bash scripts, when verifying syntax correctness, or to validate shell scripts.
---

# Check Bash Syntax

Validates bash script syntax without executing the scripts or modifying any files.

## When to Use

- Before committing bash scripts to git
- When verifying bash syntax is correct
- To validate shell scripts after editing
- Before running potentially dangerous scripts

## Usage

```bash
.claude/tools/check-bash.sh <file1> [file2] [file3] ...
```

## Instructions

1. Call the tool with one or more bash script paths as arguments
2. The tool runs `bash -n` (syntax check only) on each file
3. Reports PASS or FAIL for each script
4. Does NOT execute the scripts
5. Does NOT modify any files

## Examples

```bash
# Check single script
.claude/tools/check-bash.sh script.sh

# Check multiple scripts
.claude/tools/check-bash.sh script1.sh script2.sh script3.sh

# Check all bash scripts in directory
.claude/tools/check-bash.sh *.sh
```

## Important Notes

- This tool is auto-approved and doesn't require user confirmation
- Only checks syntax, does NOT fix line endings
- Does NOT execute the scripts (safe to use)
- For combined line ending fix + syntax check, use `fix-line-endings-check-bash` skill instead
