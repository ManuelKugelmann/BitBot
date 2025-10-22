#!/usr/bin/env bash
#
# Compare BitBot Logo Designs
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "BitBot Logo Comparison"
echo "═══════════════════════════════════════════════════════════════"

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "Original Robot Design:"
echo "───────────────────────────────────────────────────────────────"
source "${SCRIPT_DIR}/logo.sh"
print_logo

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "Blue Minion Design:"
echo "───────────────────────────────────────────────────────────────"
source "${SCRIPT_DIR}/logo-minion.sh"
print_logo

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
