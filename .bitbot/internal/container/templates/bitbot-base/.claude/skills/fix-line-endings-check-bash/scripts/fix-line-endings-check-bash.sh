#!/usr/bin/env bash
# fix-and-check-bash.sh - Fix line endings and check syntax in one step
# Usage: fix-and-check-bash.sh <file1> [file2] [file3] ...

if [[ $# -eq 0 ]]; then
    echo "Usage: fix-and-check-bash.sh <file1> [file2] [file3] ..."
    echo "Fixes CRLF→LF line endings then checks syntax"
    exit 1
fi

errors=0

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file" >&2
        ((errors++))
        continue
    fi

    echo "Processing: $file"

    # Step 1: Fix line endings
    if command -v dos2unix &> /dev/null; then
        dos2unix "$file" 2>/dev/null && echo "  ✓ Fixed line endings (dos2unix)"
    else
        sed -i 's/\r$//' "$file" && echo "  ✓ Fixed line endings (sed)"
    fi

    # Step 2: Check syntax
    if bash -n "$file" 2>&1; then
        echo "  ✓ Syntax OK"
    else
        echo "  ✗ Syntax errors found"
        ((errors++))
    fi
done

if [[ $errors -eq 0 ]]; then
    echo "Done! All files fixed and verified."
    exit 0
else
    echo "Done! $errors file(s) had errors after fixing."
    exit 1
fi
