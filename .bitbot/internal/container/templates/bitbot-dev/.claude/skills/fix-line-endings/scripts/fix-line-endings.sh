#!/usr/bin/env bash
# fix-line-endings.sh - Convert CRLF to LF line endings
# Usage: fix-line-endings.sh <file1> [file2] [file3] ...

if [[ $# -eq 0 ]]; then
    echo "Usage: fix-line-endings.sh <file1> [file2] [file3] ..."
    echo "Converts CRLF (Windows) to LF (Unix) line endings"
    exit 1
fi

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file" >&2
        continue
    fi

    echo "Fixing: $file"

    # Try dos2unix first (cleaner, preserves permissions)
    if command -v dos2unix &> /dev/null; then
        dos2unix "$file" 2>/dev/null && echo "  ✓ Fixed with dos2unix"
    else
        # Fallback to sed (universal)
        sed -i 's/\r$//' "$file" && echo "  ✓ Fixed with sed"
    fi
done

echo "Done!"
