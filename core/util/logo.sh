#!/usr/bin/env bash
#
# BitBot Logo Display
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

# Color codes - BitBot brand colors
TEAL='\033[38;5;51m'      # Bright teal
NAVY='\033[38;5;24m'      # Navy blue
YELLOW='\033[38;5;226m'   # Bright yellow
GREY='\033[38;5;246m'     # Grey for text
WHITE='\033[38;5;255m'    # White for text
DIM='\033[2m'             # Dim text
RESET='\033[0m'

# Print BitBot logo with version
print_logo() {
    local version
    version=$(get_bitbot_version)
    local current_dir="${1:-$(pwd)}"

    echo ""
    echo -e "${YELLOW}◆${NAVY}━${NAVY}╮ ${TEAL}╭${NAVY}\033[48;5;24m${TEAL}╲${YELLOW}●${TEAL}═${YELLOW}●${TEAL}╱${RESET}${TEAL}╮${RESET} ${NAVY}╭${YELLOW}⬡${RESET}    ${WHITE}BitBot${RESET} ${GREY}v${version}${RESET}"
    echo -e "${YELLOW}○${NAVY}┳${NAVY}┻${YELLOW}▲${RESET}\033[48;5;24m${TEAL}▌${NAVY}╲${TEAL}━${NAVY}╱${TEAL}━${NAVY}╲${TEAL}▐${RESET}${NAVY}┳${NAVY}┻${YELLOW}■${RESET}     ${DIM}${GREY}Secure AI Development Environment${RESET}"
    echo -e " ${NAVY}╰${YELLOW}◇${RESET} ${TEAL}╰\033[48;5;24m${TEAL}▄${NAVY}╱${RESET}${TEAL}━\033[48;5;24m${NAVY}╲${TEAL}▄${RESET}${TEAL}╯${NAVY}╰${YELLOW}○${NAVY}━${YELLOW}□${RESET}  ${DIM}${GREY}${current_dir}${RESET}"
    echo ""
}

export -f print_logo
export -f get_bitbot_version
