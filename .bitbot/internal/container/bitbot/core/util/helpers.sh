#!/bin/bash
# Container BitBot - Helper Utilities
# Shared functions for container-side BitBot commands

# Colors (for use in commands)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export GREY='\033[0;90m'
export RESET='\033[0m'

# Common functions
command_exists() {
    command -v "$1" &>/dev/null
}

# Get workspace path
get_workspace() {
    echo "${WORKSPACE:-/workspace}"
}

# Get BitBot mode
get_bitbot_mode() {
    echo "${BITBOT_MODE:-unknown}"
}

# Check if in work mode
is_work_mode() {
    [[ "${BITBOT_MODE:-}" == "work" ]]
}

# Check if in config mode
is_config_mode() {
    [[ "${BITBOT_MODE:-}" == "config" ]]
}

# Print error message
error() {
    echo -e "${RED}Error: $*${RESET}" >&2
}

# Print warning message
warn() {
    echo -e "${YELLOW}Warning: $*${RESET}" >&2
}

# Print info message
info() {
    echo -e "${BLUE}$*${RESET}"
}

# Print success message
success() {
    echo -e "${GREEN}$*${RESET}"
}
