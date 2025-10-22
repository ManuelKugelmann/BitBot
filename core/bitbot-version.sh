#!/usr/bin/env bash
#
# BitBot Version Command
#

source "${BITBOT_HOME}/core/util/helpers.sh"
source "${BITBOT_HOME}/core/util/prerequisites.sh"

# Get version from VERSION file
get_version() {
    local version_file="${BITBOT_HOME}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

bitbot_version() {
    local version
    version=$(get_version)

    echo "BitBot version $version"
    echo ""

    # Show comprehensive dependency status
    show_doctor
}

export -f bitbot_version
export -f get_version
