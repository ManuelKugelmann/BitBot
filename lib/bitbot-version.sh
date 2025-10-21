#!/usr/bin/env bash
#
# BitBot Version Command
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/util/helpers.sh"
source "${SCRIPT_DIR}/util/prerequisites.sh"

bitbot_version() {
    local version="0.1.0-mvp"

    echo "BitBot version $version"
    echo ""

    # Show comprehensive dependency status
    show_doctor
}

export -f bitbot_version
