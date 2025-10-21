#!/bin/bash
# BitBot Logo Display Script
# Displays the BitBot ASCII/Unicode logo with detailed robot design

# Color codes - BitBot brand colors
TEAL='\033[38;5;51m'      # Bright teal
NAVY='\033[38;5;24m'      # Navy blue
YELLOW='\033[38;5;226m'   # Bright yellow
GREY='\033[38;5;246m'     # Grey for text
WHITE='\033[38;5;255m'    # White for text
DIM='\033[2m'             # Dim text
RESET='\033[0m'

# Get current directory
CURRENT_DIR=$(pwd)

# BitBot version (could be read from a version file later)
VERSION="0.1.0-dev"

# Print the detailed robot logo
# Using background colors to eliminate black spaces
BG_TEAL='\033[48;5;51m'
BG_NAVY='\033[48;5;24m'

echo ""
echo -e "${YELLOW}◆${NAVY}━${NAVY}╮ ${TEAL}╭${BG_NAVY}${TEAL}╲${YELLOW}●${TEAL}═${YELLOW}●${TEAL}╱${RESET}${TEAL}╮${RESET} ${NAVY}╭${YELLOW}⬡${RESET}    ${WHITE}BitBot${RESET} ${GREY}v${VERSION}${RESET}"
echo -e "${YELLOW}○${NAVY}┳${NAVY}┻${YELLOW}▲${RESET}${BG_NAVY}${TEAL}▌${NAVY}╲${TEAL}━${NAVY}╱${TEAL}━${NAVY}╲${TEAL}▐${RESET}${NAVY}┳${NAVY}┻${YELLOW}■${RESET}     ${DIM}${GREY}AI-Powered Dev Environment${RESET}"
echo -e " ${NAVY}╰${YELLOW}◇${RESET} ${TEAL}╰${BG_NAVY}${TEAL}▄${NAVY}╱${RESET}${TEAL}━${BG_NAVY}${NAVY}╲${TEAL}▄${RESET}${TEAL}╯${NAVY}╰${YELLOW}○${NAVY}━${YELLOW}□${RESET}  ${DIM}${GREY}${CURRENT_DIR}${RESET}"
echo ""
