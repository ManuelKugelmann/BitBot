#!/usr/bin/env bash
#
# BitBot Minion Logo Display (Alternative Design)
#

set -euo pipefail

# Get version from VERSION file
get_bitbot_version() {
    local version_file="${BITBOT_HOME:-$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

# Color codes - BitBot original color scheme (blues, teal, yellow accents)
# Foreground colors
TEAL='\033[38;5;51m'       # Bright teal
NAVY='\033[38;5;24m'       # Navy blue
YELLOW='\033[38;5;226m'    # Bright yellow
GREY='\033[38;5;246m'      # Grey for text
WHITE='\033[38;5;255m'     # White for text
RED='\033[38;5;196m'       # Red accent
# Background colors
TEAL_BG='\033[48;5;51m'    # Teal background
NAVY_BG='\033[48;5;24m'    # Navy background
YELLOW_BG='\033[48;5;226m' # Yellow background
DIM='\033[2m'
RESET='\033[0m'

# Print BitBot Minion logo with version
print_logo() {
    local version
    version=$(get_bitbot_version)
    local current_dir="${1:-$(pwd)}"

    echo ""
    echo -e "  ${YELLOW}◆${NAVY}━╮${RESET} ${NAVY_BG}${TEAL}╭${YELLOW}●═●${TEAL}╮${RESET} ${NAVY}╭${YELLOW}⬡${RESET}    ${WHITE}BitBot${RESET} ${GREY}v${version}${RESET}"
    echo -e " ${TEAL_BG}${NAVY}╭${TEAL}█████${NAVY}╮${RESET}${NAVY_BG}${TEAL}▌███▐${RESET}${YELLOW}■${RESET}     ${DIM}${GREY}Secure AI Development${RESET}"
    echo -e " ${TEAL_BG}${NAVY}│${RESET}${NAVY_BG}${YELLOW}█${RESET}${NAVY_BG}${TEAL}███${RESET}${NAVY_BG}${YELLOW}█${RESET}${TEAL_BG}${NAVY}│${RESET}  ${DIM}${GREY}${current_dir}${RESET}"
    echo -e "  ${TEAL_BG}${NAVY}╰${TEAL}███${NAVY}╯${RESET}"
    echo ""
}

export -f print_logo
export -f get_bitbot_version
