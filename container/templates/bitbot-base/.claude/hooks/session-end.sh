#!/usr/bin/env bash
# session-end.sh - SessionEnd hook
# Receives JSON via stdin
#
# Reserved for future cleanup tasks

set -euo pipefail

# Read JSON from stdin (required by hook protocol)
INPUT=$(cat)

# No cleanup needed - environment variables expire with session

exit 0
