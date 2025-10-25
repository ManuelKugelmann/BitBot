#!/bin/bash
# Container BitBot - Resume Session
# Resumes existing tmux session or shows selection menu

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../util/helpers.sh"
source "${SCRIPT_DIR}/../util/tmux-utils.sh"

# Show session menu
show_session_menu() {
    local sessions=("$@")
    local count=${#sessions[@]}

    echo -e "${BLUE}Select session to resume:${RESET}"
    echo ""

    local index=1
    for session in "${sessions[@]}"; do
        local session_info="$(get_session_info "$session")"
        echo "  $index) $session_info"
        ((index++))
    done

    echo "  0) Cancel"
    echo ""
    read -p "Choice: " choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return 1
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        echo "${sessions[$((choice - 1))]}"
        return 0
    else
        error "Invalid choice"
        return 1
    fi
}

# Main resume function
main() {
    local session_name="${1:-}"

    if ! tmux_available; then
        error "tmux is not available"
        echo ""
        echo "Please install tmux:"
        echo "  sudo apt-get install tmux"
        exit 1
    fi

    # Get list of sessions
    local sessions="$(list_tmux_sessions)"
    local session_count="$(echo "$sessions" | grep -c '^' || echo 0)"

    if [[ $session_count -eq 0 ]]; then
        warn "No tmux sessions found"
        echo ""
        info "Starting new session..."
        exec "${SCRIPT_DIR}/start.sh" "$@"
        return
    fi

    # If session name provided, try to attach
    if [[ -n "$session_name" ]]; then
        if session_exists "$session_name"; then
            info "Attaching to session '$session_name'..."
            echo ""
            attach_session "$session_name"
            return
        else
            error "Session '$session_name' not found"
            echo ""
            # Fall through to selection
        fi
    fi

    # Convert sessions to array
    local session_array=()
    while IFS= read -r session; do
        [[ -n "$session" ]] && session_array+=("$session")
    done <<< "$sessions"

    # Single session - auto-attach
    if [[ ${#session_array[@]} -eq 1 ]]; then
        local single_session="${session_array[0]}"
        info "Found one session: $single_session"
        echo ""
        info "Attaching..."
        echo ""
        attach_session "$single_session"
        return
    fi

    # Multiple sessions - show menu
    local selected
    if selected="$(show_session_menu "${session_array[@]}")"; then
        echo ""
        info "Attaching to session '$selected'..."
        echo ""
        attach_session "$selected"
    else
        info "Cancelled"
        exit 0
    fi
}

main "$@"
