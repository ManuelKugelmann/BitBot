#!/usr/bin/env bash
# check-bash - Check bash script syntax without executing
# Usage: check-bash <file1> [file2] [file3] ...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/check-bash-syntax.sh" "$@"
