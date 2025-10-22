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

# Color codes - Blue Minion theme
# Foreground colors
BLUE_FG='\033[38;5;33m'       # Bright blue
YELLOW_FG='\033[38;5;226m'    # Yellow
BLACK_FG='\033[38;5;16m'      # Black
GREY='\033[38;5;246m'         # Grey for text
WHITE='\033[38;5;255m'        # White for text
# Background colors
YELLOW_BG='\033[48;5;226m'    # Yellow background (minion body)
BLUE_BG='\033[48;5;33m'       # Blue background (overalls)
GREY_BG='\033[48;5;240m'      # Grey background (goggle band)
BLACK_BG='\033[48;5;16m'      # Black background
DIM='\033[2m'
RESET='\033[0m'

# Print BitBot Minion logo with version
print_logo() {
    local version
    version=$(get_bitbot_version)
    local current_dir="${1:-$(pwd)}"

    echo ""
    echo -e "  ${YELLOW_FG}◆${BLUE_FG}━╮${RESET} ${GREY_BG}${BLACK_FG}╭━${YELLOW_FG}●═●${BLACK_FG}━╮${RESET} ${BLUE_FG}╭${YELLOW_FG}⬡${RESET}    ${WHITE}BitBot${RESET} ${GREY}v${version}${RESET}"
    echo -e " ${YELLOW_BG}${BLACK_FG}╱━━━━━╲${RESET}${BLUE_BG}${YELLOW_FG}▌━━━▐${RESET}${YELLOW_FG}■${RESET}     ${DIM}${GREY}Secure AI Development${RESET}"
    echo -e " ${YELLOW_BG}${BLACK_FG}│${RESET} ${BLUE_BG}${BLACK_FG}◇${RESET} ${BLACK_BG}${BLUE_FG}┳━┳${RESET} ${BLUE_BG}${BLACK_FG}◇${RESET} ${YELLOW_BG}${BLACK_FG}│${RESET}  ${DIM}${GREY}${current_dir}${RESET}"
    echo -e "  ${YELLOW_BG}${BLACK_FG}╰━━━━━╯${RESET}"
    echo ""
}

export -f print_logo
export -f get_bitbot_version
