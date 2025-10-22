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
echo "Rounded Variant:"
echo "───────────────────────────────────────────────────────────────"
source "${SCRIPT_DIR}/logo-rounded.sh"
print_logo

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "Monospace-Only Variant:"
echo "───────────────────────────────────────────────────────────────"
source "${SCRIPT_DIR}/logo-mono.sh"
print_logo

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
