#!/usr/bin/env bash
# check-bash-syntax.sh - Check bash script syntax without executing
# Usage: check-bash-syntax.sh <file1> [file2] [file3] ...

if [[ $# -eq 0 ]]; then
    echo "Usage: check-bash-syntax.sh <file1> [file2] [file3] ..."
    echo "Checks bash script syntax without executing"
    exit 1
fi

errors=0

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file" >&2
        ((errors++))
        continue
    fi

    echo "Checking: $file"

    # Check syntax with bash -n
    if bash -n "$file" 2>&1; then
        echo "  ✓ Syntax OK"
    else
        echo "  ✗ Syntax errors found"
        ((errors++))
    fi
done

if [[ $errors -eq 0 ]]; then
    echo "Done! All files passed syntax check."
    exit 0
else
    echo "Done! $errors file(s) had errors."
    exit 1
fi
