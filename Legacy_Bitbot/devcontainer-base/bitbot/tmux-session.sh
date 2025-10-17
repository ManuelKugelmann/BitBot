#!/bin/bash
# BitBot Tmux Session Manager
# Manages tmux sessions for workspace persistence with multiple session support

set -e

WORKSPACE_NAME=$(basename /workspace)
BASE_SESSION_NAME="bitbot-${WORKSPACE_NAME}"

create_bitbot_session() {
    local session_name="$1"
    local session_number="$2"
    
    echo "Creating new tmux session: $session_name"
    
    # Create new session with Claude window
    tmux new-session -d -s "$session_name" -n "claude" -c /workspace
    
    # Start Claude in the first window with session info
    tmux send-keys -t "$session_name:claude" "clear && echo 'Welcome to BitBot Development Environment' && echo 'Session: $session_name' && echo 'Powered by Claude Code + MCP Services' && echo '' && echo 'Starting Claude Code...' && echo '' && claude" Enter
    
    # Create additional windows for development
    tmux new-window -t "$session_name" -n "terminal" -c /workspace
    tmux new-window -t "$session_name" -n "git" -c /workspace
    
    # Set default window to claude
    tmux select-window -t "$session_name:claude"
    
    echo "Session created successfully"
}

attach_to_session() {
    local session_name="$1"
    echo "Attaching to session: $session_name"
    exec tmux attach-session -t "$session_name"
}

list_workspace_sessions() {
    echo "BitBot sessions for workspace '$WORKSPACE_NAME':"
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^$BASE_SESSION_NAME" || true)
    if [ -z "$sessions" ]; then
        echo "  No active sessions found"
        return 1
    else
        echo "$sessions" | while read -r session; do
            local status=$(tmux list-sessions -F "#{session_name}: #{session_attached} clients attached" 2>/dev/null | grep "^$session:")
            echo "  $status"
        done
        return 0
    fi
}

get_next_session_number() {
    local max_num=0
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^$BASE_SESSION_NAME" || true)
    
    if [ -n "$sessions" ]; then
        echo "$sessions" | while read -r session; do
            if [[ "$session" == "$BASE_SESSION_NAME" ]]; then
                echo "1"
            elif [[ "$session" =~ ^${BASE_SESSION_NAME}-([0-9]+)$ ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        done | sort -n | tail -1 | xargs -I {} expr {} + 1
    else
        echo "1"
    fi
}

interactive_session_menu() {
    echo "=========================================="
    echo "  BitBot Session Manager"
    echo "  Workspace: $WORKSPACE_NAME"
    echo "=========================================="
    echo ""
    
    # Check for existing sessions
    if list_workspace_sessions; then
        echo ""
        echo "Options:"
        echo "  [1] Resume an existing session"
        echo "  [2] Create a new session"
        echo "  [3] List all sessions"
        echo "  [q] Quit"
        echo ""
        read -p "Choose an option [1-3, q]: " choice
        
        case "$choice" in
            "1")
                resume_existing_session
                ;;
            "2")
                create_new_session
                ;;
            "3")
                list_workspace_sessions
                echo ""
                interactive_session_menu
                ;;
            "q"|"Q")
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                echo ""
                interactive_session_menu
                ;;
        esac
    else
        echo ""
        echo "No existing sessions found. Creating first session..."
        create_new_session
    fi
}

resume_existing_session() {
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^$BASE_SESSION_NAME" || true)
    
    if [ -z "$sessions" ]; then
        echo "No sessions to resume."
        return 1
    fi
    
    echo ""
    echo "Available sessions to resume:"
    local i=1
    local session_array=()
    
    echo "$sessions" | while read -r session; do
        local attached=$(tmux list-sessions -F "#{session_name} #{session_attached}" 2>/dev/null | grep "^$session " | awk '{print $2}')
        local status="detached"
        if [ "$attached" != "0" ]; then
            status="attached"
        fi
        echo "  [$i] $session ($status)"
        session_array+=("$session")
        ((i++))
    done
    
    # Recreate array in subshell context
    local session_array=($(echo "$sessions"))
    
    echo ""
    read -p "Select session number [1-${#session_array[@]}]: " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#session_array[@]}" ]; then
        local selected_session="${session_array[$((selection-1))]}"
        attach_to_session "$selected_session"
    else
        echo "Invalid selection."
        resume_existing_session
    fi
}

create_new_session() {
    local next_num=$(get_next_session_number)
    local new_session_name
    
    if [ "$next_num" -eq 1 ]; then
        new_session_name="$BASE_SESSION_NAME"
    else
        new_session_name="$BASE_SESSION_NAME-$next_num"
    fi
    
    create_bitbot_session "$new_session_name" "$next_num"
    attach_to_session "$new_session_name"
}

case "${1:-interactive}" in
    "new")
        create_new_session
        ;;
    "attach")
        # Legacy mode - attach to first available session or create new
        local first_session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^$BASE_SESSION_NAME" | head -1 || true)
        if [ -n "$first_session" ]; then
            attach_to_session "$first_session"
        else
            create_new_session
        fi
        ;;
    "interactive"|"menu")
        interactive_session_menu
        ;;
    "list")
        list_workspace_sessions
        ;;
    "kill")
        if [ -n "$2" ]; then
            # Kill specific session
            if tmux has-session -t "$2" 2>/dev/null; then
                tmux kill-session -t "$2"
                echo "Session $2 terminated"
            else
                echo "No session named $2 found"
            fi
        else
            # Kill all workspace sessions
            local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^$BASE_SESSION_NAME" || true)
            if [ -n "$sessions" ]; then
                echo "$sessions" | while read -r session; do
                    tmux kill-session -t "$session"
                    echo "Session $session terminated"
                done
            else
                echo "No workspace sessions found"
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {interactive|new|attach|list|kill [session_name]}"
        echo "  interactive - Show interactive session menu (default)"
        echo "  new         - Create a new session"
        echo "  attach      - Attach to first available session or create new"
        echo "  list        - List all workspace sessions"
        echo "  kill        - Kill all workspace sessions or specific session"
        ;;
esac