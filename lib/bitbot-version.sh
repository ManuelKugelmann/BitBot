#!/usr/bin/env bash
#
# BitBot Version Command
#

source "${BITBOT_HOME}/lib/util/helpers.sh"
source "${BITBOT_HOME}/lib/util/prerequisites.sh"

bitbot_version() {
    local version="0.1.0-mvp"

    echo "BitBot version $version"
    echo ""

    # Show comprehensive dependency status
    show_doctor
}

export -f bitbot_version
