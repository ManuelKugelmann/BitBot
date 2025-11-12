#!/bin/bash
set -e

# Wrapper for shared installation scripts
# This allows templates to customize which shared scripts to run

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_SCRIPTS="$SCRIPT_DIR/../../scripts"

# Install AI tools
if [ -f "$SHARED_SCRIPTS/install-ai-tools.sh" ]; then
    bash "$SHARED_SCRIPTS/install-ai-tools.sh"
fi

# Optionally install additional dev tools
# Uncomment to enable:
# if [ -f "$SHARED_SCRIPTS/install-dev-tools.sh" ]; then
#     bash "$SHARED_SCRIPTS/install-dev-tools.sh"
# fi
