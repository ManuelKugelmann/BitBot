---
name: fix-line-endings
description: Fix CRLF (Windows) to LF (Unix) line endings in files. Use when encountering line ending issues, Windows-style line breaks, or `/bin/bash: line 1: $'\r': command not found` errors.
---

# Fix Line Endings

Converts CRLF (Windows) line endings to LF (Unix) line endings in files.

## When to Use

- Encountering `/bin/bash: line 1: $'\r': command not found` errors
- Files created/edited on Windows need Unix line endings
- Shell scripts failing due to carriage return characters
- After creating or editing bash scripts

## Usage

```bash
.claude/tools/fix-line-endings.sh <file1> [file2] [file3] ...
```

## Instructions

1. Call the tool with one or more file paths as arguments
2. The tool will convert CRLF to LF in each file
3. Tool uses `dos2unix` if available, falls back to `sed`
4. Reports success for each file

## Examples

```bash
# Fix single file
.claude/tools/fix-line-endings.sh script.sh

# Fix multiple files
.claude/tools/fix-line-endings.sh script1.sh script2.sh script3.sh

# Fix all bash scripts in directory
.claude/tools/fix-line-endings.sh *.sh
```

## Important Notes

- This tool is auto-approved and doesn't require user confirmation
- Only converts line endings, does NOT check syntax
- For combined fix + syntax check, use `fix-line-endings-check-bash` skill instead
- Safe to run multiple times on same file
