#!/usr/bin/env bash
#
# BitBot Helper Functions
#
# Component: Common Utilities
# Purpose: Shared utility functions for all BitBot scripts
#
# Usage: source this file from other scripts
#

set -euo pipefail

# ============================================================================
# File System Helpers
# ============================================================================

create_directory() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        mkdir -p "$path"
    fi
}

directory_exists() {
    local path="$1"
    [[ -d "$path" ]]
}

file_exists() {
    local path="$1"
    [[ -f "$path" ]]
}

command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# ============================================================================
# Path Helpers
# ============================================================================

get_current_directory() {
    pwd
}

get_absolute_path() {
    local path="$1"
    realpath "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || echo "$path"
}

get_basename() {
    local path="$1"
    basename "$path"
}

get_dirname() {
    local path="$1"
    dirname "$path"
}

get_bitbot_install_dir() {
    # Get BitBot installation directory from BITBOT_HOME environment variable
    # Fallback to script directory if BITBOT_HOME not set
    if [[ -n "${BITBOT_HOME:-}" ]]; then
        echo "$BITBOT_HOME"
    else
        # Fallback: determine from script location
        # Assumes this file is in {INSTALL}/core/util/helpers.sh
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$script_dir/../.." && pwd
    fi
}

get_global_config_dir() {
    # Get global BitBot config directory ($BITBOT_HOME/global/.bitbot/)
    # Creates directory if it doesn't exist
    # Returns: Path to global .bitbot directory
    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local config_dir="${bitbot_install}/global/.bitbot"

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    echo "$config_dir"
}

get_global_settings_file() {
    # Get global BitBot settings file path ($BITBOT_HOME/global/.bitbot/settings.json)
    # Returns: Path to global settings file
    local config_dir
    config_dir=$(get_global_config_dir)
    echo "${config_dir}/settings.json"
}

get_settings_file() {
    # Context-aware settings file path
    # Returns workspace settings if BITBOT_WORKSPACE set, global settings otherwise
    # Usage: settings=$(get_settings_file)
    if [[ -n "${BITBOT_WORKSPACE:-}" ]]; then
        # Workspace context (container)
        echo "${BITBOT_WORKSPACE}/.bitbot/settings.json"
    else
        # Global context (host)
        get_global_settings_file
    fi
}

# Deprecated alias for backward compatibility
get_global_config_file() {
    get_global_settings_file
}

convert_wsl_to_windows_path() {
    # Convert WSL path to Windows path using wslpath
    # Usage: convert_wsl_to_windows_path <wsl_path>
    # Returns: Windows path (e.g., C:\Users\...)
    # Note: wslpath is always available in WSL environments
    local wsl_path="$1"
    wslpath -w "$wsl_path"
}

convert_windows_to_wsl_path() {
    # Convert Windows path to WSL path using wslpath
    # Usage: convert_windows_to_wsl_path <windows_path>
    # Returns: WSL path (e.g., /mnt/c/...)
    # Note: wslpath is always available in WSL environments
    local windows_path="$1"
    wslpath -u "$windows_path"
}

# ============================================================================
# JSON Helpers
# ============================================================================

read_json_value() {
    # Read a simple JSON value by key (basic parsing, no jq required)
    # Usage: read_json_value <file> <key>
    local file="$1"
    local key="$2"

    if ! file_exists "$file"; then
        return 1
    fi

    # Try jq if available
    if command_exists jq; then
        # Use --arg to safely pass the key to avoid injection
        jq -r --arg k "$key" '.[$k] // empty' "$file" 2>/dev/null || echo ""
        return 0
    fi

    # Fallback: basic grep/sed parsing
    # Handles simple JSON like: {"key": "value", "key2": true}
    # Escape special regex characters in key
    local escaped_key
    escaped_key=$(printf '%s\n' "$key" | sed 's/[[\.*^$/]/\\&/g')
    grep -o "\"${escaped_key}\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null | \
        sed -E 's/.*:[[:space:]]*"?([^",}]*)"?.*/\1/' | \
        head -n 1
}

write_json() {
    # Write a simple JSON object to file
    # Usage: write_json <file> <json_string>
    local file="$1"
    local json="$2"

    echo "$json" > "$file"
}

create_config_json() {
    # Create a config.json file with given key-value pairs
    # Usage: create_config_json <file> key1 value1 [key2 value2 ...]
    local file="$1"
    shift

    local json="{"
    local first=true

    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            json="${json},"
        fi

        # Detect boolean/number vs string
        if [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" =~ ^[0-9]+$ ]]; then
            json="${json}\"${key}\": ${value}"
        else
            json="${json}\"${key}\": \"${value}\""
        fi
    done

    json="${json}}"

    write_json "$file" "$json"
}

update_json_value() {
    # Update a single value in a JSON file
    # Usage: update_json_value <file> <key> <value>
    local file="$1"
    local key="$2"
    local value="$3"

    if ! file_exists "$file"; then
        print_error "Settings file not found: $file"
        return 1
    fi

    # Try jq if available
    if command_exists jq; then
        local temp_file="${file}.tmp"
        # Use --arg to safely pass key and value to avoid injection
        jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" > "$temp_file" && mv "$temp_file" "$file"
        return 0
    fi

    # Fallback: sed replacement (basic)
    # Escape special characters in key and value for sed
    local escaped_key escaped_value
    escaped_key=$(printf '%s\n' "$key" | sed 's/[\/&]/\\&/g')
    escaped_value=$(printf '%s\n' "$value" | sed 's/[\/&]/\\&/g')
    sed -i.bak "s/\"${escaped_key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"${escaped_key}\": \"${escaped_value}\"/" "$file"
    rm -f "${file}.bak"
}

merge_configs() {
    # Merge two config files: workspace overrides global
    # Returns merged config as JSON string (printed to stdout)
    # Usage: merge_configs <global_config_path> <workspace_config_path>
    local global_config="$1"
    local workspace_config="$2"

    # If only global exists, return it
    if ! file_exists "$workspace_config"; then
        cat "$global_config" 2>/dev/null || echo "{}"
        return 0
    fi

    # If only workspace exists, return it
    if ! file_exists "$global_config"; then
        cat "$workspace_config" 2>/dev/null || echo "{}"
        return 0
    fi

    # Both exist - merge using jq if available
    if command_exists jq; then
        jq -s '.[0] * .[1]' "$global_config" "$workspace_config" 2>/dev/null || echo "{}"
        return 0
    fi

    # Fallback: simple merge (workspace wins)
    # For MVP, just use workspace config if both exist and no jq
    cat "$workspace_config"
}

get_merged_workspace_config() {
    # Get merged config for a workspace (merged settings)
    # Usage: get_merged_workspace_config <workspace_path>
    local workspace_path="$1"

    local global_settings
    global_settings=$(get_global_settings_file)
    local workspace_settings="${workspace_path}/.bitbot/settings.json"

    merge_configs "$global_settings" "$workspace_settings"
}

get_config_value() {
    # Get a merged config value for a workspace
    # Usage: get_config_value <workspace_path> <key>
    local workspace_path="$1"
    local key="$2"

    local merged_config
    merged_config=$(get_merged_workspace_config "$workspace_path")

    if command_exists jq; then
        # Use --arg to safely pass the key to avoid injection
        echo "$merged_config" | jq -r --arg k "$key" '.[$k] // empty'
    else
        # Escape special regex characters in key
        local escaped_key
        escaped_key=$(printf '%s\n' "$key" | sed 's/[[\.*^$/]/\\&/g')
        echo "$merged_config" | grep -o "\"${escaped_key}\"[[:space:]]*:[[:space:]]*[^,}]*" | \
            sed -E 's/.*:[[:space:]]*"?([^",}]*)"?.*/\1/' | \
            head -n 1
    fi
}

get_setting() {
    # Context-aware setting value retrieval
    # Returns setting from workspace or global settings based on context
    # Usage: value=$(get_setting <key>)
    local key="$1"

    if [[ -n "${BITBOT_WORKSPACE:-}" ]]; then
        # Workspace context - check merged workspace + global settings
        get_config_value "$BITBOT_WORKSPACE" "$key"
    else
        # Global context - check global settings only
        local settings_file
        settings_file=$(get_global_settings_file)
        if [[ -f "$settings_file" ]]; then
            read_json_value "$settings_file" "$key"
        fi
    fi
}

update_setting() {
    # Context-aware setting update
    # Updates setting in workspace or global settings based on context
    # Usage: update_setting <key> <value>
    local key="$1"
    local value="$2"

    local settings_file
    settings_file=$(get_settings_file)

    # Ensure settings file exists
    if [[ ! -f "$settings_file" ]]; then
        local settings_dir
        settings_dir=$(dirname "$settings_file")
        mkdir -p "$settings_dir"
        echo "{}" > "$settings_file"
    fi

    update_json_value "$settings_file" "$key" "$value"
}

# ============================================================================
# Prompt Helpers
# ============================================================================

prompt_yes_no() {
    # Prompt for yes/no input with default
    # Usage: prompt_yes_no <question> <default> [choice_env_var]
    # Returns: "yes" or "no"
    #
    # Args:
    #   $1 - question: The question to ask
    #   $2 - default: Default answer ("yes" or "no")
    #   $3 - choice_env_var: (optional) Environment variable name to check for non-interactive choice
    #
    # Example:
    #   answer=$(prompt_yes_no "Continue?" "yes" "BITBOT_CHOICE_CONTINUE")
    #   # Can be overridden with: BITBOT_CHOICE_CONTINUE=no
    local question="$1"
    local default="${2:-}"
    local choice_env_var="${3:-}"
    local response

    # Check if choice provided via environment variable (non-interactive mode)
    if [[ -n "$choice_env_var" ]]; then
        local choice_value="${!choice_env_var:-}"
        if [[ -n "$choice_value" ]]; then
            # Validate choice value
            case "$choice_value" in
                y|yes|Y|YES)
                    echo "yes"
                    return 0
                    ;;
                n|no|N|NO)
                    echo "no"
                    return 0
                    ;;
                *)
                    print_warning "Invalid value for $choice_env_var: '$choice_value' (expected 'yes' or 'no')"
                    # Fall through to interactive prompt
                    ;;
            esac
        fi
    fi

    # Interactive prompt
    # Display question with default indicator
    if [[ "$default" == "yes" ]]; then
        read -r -p "$question (Y/n): " response
    elif [[ "$default" == "no" ]]; then
        read -r -p "$question (y/N): " response
    else
        read -r -p "$question (y/n): " response
    fi

    # Handle empty response (use default)
    if [[ -z "$response" ]] && [[ -n "$default" ]]; then
        echo "$default"
        return 0
    fi

    # Parse response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]' | xargs)

    case "$response" in
        y|yes)
            echo "yes"
            return 0
            ;;
        n|no)
            echo "no"
            return 0
            ;;
        *)
            print_warning "Invalid input, please enter 'y' or 'n'"
            prompt_yes_no "$question" "$default" "$choice_env_var"
            ;;
    esac
}

prompt_choice() {
    # Prompt for choice from numbered list
    # Usage: prompt_choice <question> <default_index> [choice_env_var] <choice1> <choice2> ...
    # Returns: selected choice index (0-based)
    #
    # Args:
    #   $1 - question: The question to ask
    #   $2 - default_index: Default choice index (0-based)
    #   $3 - choice_env_var: (optional) Environment variable name to check for non-interactive choice
    #        If empty string "", no environment variable check is performed
    #   $4+ - choices: List of choice strings
    #
    # Example:
    #   choice=$(prompt_choice "What to do?" 0 "BITBOT_CHOICE_ACTION" "Option 1" "Option 2" "Option 3")
    #   # Can be overridden with: BITBOT_CHOICE_ACTION=1 (0-based index)
    local question="$1"
    local default_index="$2"
    local choice_env_var="$3"
    shift 3
    local choices=("$@")
    local response

    # Check if choice provided via environment variable (non-interactive mode)
    if [[ -n "$choice_env_var" ]]; then
        local choice_value="${!choice_env_var:-}"
        if [[ -n "$choice_value" ]]; then
            # Validate choice value is numeric
            if [[ "$choice_value" =~ ^[0-9]+$ ]]; then
                # Validate range (0-based)
                if [[ $choice_value -ge 0 ]] && [[ $choice_value -lt ${#choices[@]} ]]; then
                    echo "$choice_value"
                    return 0
                else
                    print_warning "Invalid value for $choice_env_var: '$choice_value' (expected 0-$((${#choices[@]}-1)))"
                    # Fall through to interactive prompt
                fi
            else
                print_warning "Invalid value for $choice_env_var: '$choice_value' (expected numeric index)"
                # Fall through to interactive prompt
            fi
        fi
    fi

    # Interactive prompt
    # Display question (to stderr so it's not captured by command substitution)
    echo "$question" >&2
    echo "" >&2

    # Display choices with numbers
    for i in "${!choices[@]}"; do
        local number=$((i + 1))
        if [[ $i -eq $default_index ]]; then
            echo "  [${number}] ${choices[$i]} (default)" >&2
        else
            echo "  [${number}] ${choices[$i]}" >&2
        fi
    done

    echo "" >&2
    read -r -p "Choice [$((default_index + 1))]: " response

    # Handle empty response (use default)
    if [[ -z "$response" ]]; then
        echo "$default_index"
        return 0
    fi

    # Parse numeric response
    response=$(echo "$response" | xargs)

    # Validate numeric input
    if ! [[ "$response" =~ ^[0-9]+$ ]]; then
        print_warning "Invalid choice, please enter a number"
        prompt_choice "$question" "$default_index" "$choice_env_var" "${choices[@]}"
        return 0
    fi

    # Validate range
    if [[ $response -ge 1 ]] && [[ $response -le ${#choices[@]} ]]; then
        echo $((response - 1))  # Convert to 0-based index
        return 0
    else
        print_warning "Invalid choice, please enter a number between 1 and ${#choices[@]}"
        prompt_choice "$question" "$default_index" "$choice_env_var" "${choices[@]}"
        return 0
    fi
}

prompt_user_input() {
    # Prompt for user input with optional default
    # Usage: prompt_user_input <prompt> [default]
    local prompt_text="$1"
    local default="${2:-}"
    local response

    if [[ -n "$default" ]]; then
        read -r -p "$prompt_text [$default]: " response
        echo "${response:-$default}"
    else
        read -r -p "$prompt_text: " response
        echo "$response"
    fi
}

# ============================================================================
# Output Formatting Helpers
# ============================================================================

print_success() {
    local message="$1"
    echo "[+] $message"
}

print_info() {
    local message="$1"
    echo "[i] $message"
}

print_warning() {
    local message="$1"
    echo "[!] $message"
}

print_error() {
    local message="$1"
    echo "[X] $message" >&2
}

print_step() {
    local message="$1"
    echo "[>] $message"
}

# ============================================================================
# AI-Enhanced Error Helpers (Flow B: AI on Request)
# ============================================================================

print_error_with_ai_help() {
    # Show error with curated help, offer AI assistance and auto-fix
    # Usage: print_error_with_ai_help <error_message> <curated_help> <ai_context> <auto_fix_function> <allow_always> <prompt_message> [preference_key]
    #
    # Prompt format: "<prompt> ? [y]es, [a]lways, [N]o, help[?], fi[x]"
    # Note: [a]lways only shown if allow_always="true", fi[x] only if auto_fix_function provided
    #
    # Args:
    #   $1 - error_message: The error message to display
    #   $2 - curated_help: Pre-written help text (instant, covers 80% of cases)
    #   $3 - ai_context: Context string for AI query (e.g., "Docker installation")
    #   $4 - auto_fix_function: Function name for auto-fix ("" if not available)
    #   $5 - allow_always: "true" to show [a]lways option, "" for setup/one-time decisions
    #   $6 - prompt_message: Context-aware prompt (e.g., "Continue without Docker", "Start Docker now")
    #   $7 - preference_key: (optional) Config key for saving [a]lways preference (e.g., "skip-git-push-warning")
    #
    # Returns:
    #   0 = continue (user chose 'y' or 'a')
    #   1 = exit (user chose 'N')
    #   2 = retry (after successful auto-fix)
    #
    # Example - setup (no 'always', no auto-fix): [y/N/?]
    #   print_error_with_ai_help \
    #       "Docker not found" \
    #       "$HELP_DOCKER_NOT_INSTALLED" \
    #       "Docker installation" \
    #       "" \
    #       "" \
    #       "Continue without Docker"
    #
    # Example - runtime check (with 'always', with auto-fix, with preference): [y/a/N/?/x]
    #   print_error_with_ai_help \
    #       "Docker daemon not running" \
    #       "$HELP_DOCKER_DAEMON_NOT_RUNNING" \
    #       "Docker startup" \
    #       "autofix_start_docker_daemon" \
    #       "true" \
    #       "Start Docker now" \
    #       "skip-docker-daemon-check"

    local error_message="$1"
    local curated_help="$2"
    local ai_context="$3"
    local auto_fix_function="${4:-}"
    local allow_always="${5:-}"
    local prompt_message="${6:-What would you like to do}"
    local preference_key="${7:-}"

    # Check if preference already saved (skip prompt if user chose [a]lways before)
    if [[ -n "$preference_key" ]] && [[ "$allow_always" == "true" ]]; then
        local saved_pref
        saved_pref=$(get_setting "$preference_key" 2>/dev/null || echo "")

        # If preference is "true", skip prompt
        if [[ "$saved_pref" == "true" ]]; then
            return 0  # Skip prompt, user chose [a]lways before
        fi
    fi

    # Show error
    print_error "$error_message"
    echo "" >&2

    # Show curated help (instant)
    echo -e "$curated_help" >&2
    echo "" >&2

    # Build prompt with conditional options
    # Base: "[y]es, [N]o, help[?]"
    # Add [a]lways if allow_always="true"
    # Add fi[x] if auto_fix_function provided
    local prompt_suffix="[y]es"

    if [[ "$allow_always" == "true" ]]; then
        prompt_suffix="${prompt_suffix}, [a]lways"
    fi

    prompt_suffix="${prompt_suffix}, [N]o, help[?]"

    if [[ -n "$auto_fix_function" ]] && command -v "$auto_fix_function" &>/dev/null; then
        prompt_suffix="${prompt_suffix}, fi[x]"
    fi

    # Prompt with dynamically built options
    local response
    read -r -p "$prompt_message ? $prompt_suffix: " response

    # Handle response (exact single character matching to differentiate from arbitrary text)
    case "$response" in
        [Aa])
            # User chose "yes always" (exact 'a' or 'A')
            if [[ "$allow_always" == "true" ]]; then
                echo "" >&2

                # Save preference if preference_key provided
                if [[ -n "$preference_key" ]]; then
                    update_setting "$preference_key" "true"
                    print_info "Saved preference: $preference_key"
                else
                    print_info "Continuing (preference not saved - no preference key provided)"
                fi

                echo "" >&2
                return 0
            else
                # [a]lways not available for this check
                print_warning "Option 'a' (always) not available for this operation"
                echo "" >&2
                print_error_with_ai_help "$error_message" "$curated_help" "$ai_context" "$auto_fix_function" "$allow_always" "$prompt_message" "$preference_key"
                return $?
            fi
            ;;
        [Xx])
            # User requested auto-fix (exact 'x' or 'X')
            if [[ -n "$auto_fix_function" ]] && command -v "$auto_fix_function" &>/dev/null; then
                echo "" >&2
                echo "⚙ Attempting automatic fix..." >&2
                echo "" >&2

                # Call auto-fix function
                if "$auto_fix_function"; then
                    echo "" >&2
                    print_success "Auto-fix completed successfully"
                    echo "" >&2
                    return 2  # Signal to retry the check
                else
                    echo "" >&2
                    print_error "Auto-fix failed"
                    echo "" >&2

                    # Offer to continue anyway or exit
                    read -r -p "Continue anyway ? [y]es, [N]o: " response
                    case "$response" in
                        [Yy]*)
                            return 0
                            ;;
                        *)
                            return 1
                            ;;
                    esac
                fi
            else
                print_warning "Auto-fix not available for this issue"
                echo "" >&2
                return 1
            fi
            ;;
        [\?])
            # User requested AI help (exact '?')
            echo "" >&2
            echo "💡 AI Assistant:" >&2

            # Source AI helper
            local bitbot_install
            bitbot_install=$(get_bitbot_install_dir)
            if [[ -f "$bitbot_install/core/util/ai-helper/ai-helper.sh" ]]; then
                # shellcheck source=/dev/null
                source "$bitbot_install/core/util/ai-helper/ai-helper.sh"

                # Call AI helper with full context
                ask_ai "$ai_context" "$error_message - How to fix this issue? $curated_help" >&2
            else
                echo "AI helper not available (install Node.js for AI features)" >&2
                echo "Showing curated help instead:" >&2
                echo -e "$curated_help" >&2
            fi

            echo "" >&2

            # Re-offer ALL choices after showing AI help
            # Support conversational mode: any text = follow-up question to AI
            echo "Next steps:" >&2
            echo "  • Type 'y' to continue" >&2
            if [[ "$allow_always" == "true" ]]; then
                echo "  • Type 'a' to save preference (always)" >&2
            fi
            echo "  • Type 'N' to exit" >&2
            if [[ -n "$auto_fix_function" ]] && command -v "$auto_fix_function" &>/dev/null; then
                echo "  • Type 'x' to auto-fix" >&2
            fi
            echo "  • Ask another question (AI will respond)" >&2
            echo "" >&2
            read -r -p "Your choice: " response

            # Handle response (exact matching for commands, else conversational)
            case "$response" in
                [Aa])
                    # Yes always - save preference (exact 'a' or 'A')
                    if [[ "$allow_always" == "true" ]]; then
                        echo "" >&2

                        # Save preference if preference_key provided
                        if [[ -n "$preference_key" ]]; then
                            update_setting "$preference_key" "true"
                            print_info "Saved preference: $preference_key"
                        else
                            print_info "Continuing (preference not saved - no preference key provided)"
                        fi

                        echo "" >&2
                        return 0
                    else
                        print_warning "Option 'a' (always) not available"
                        echo "" >&2
                        print_error_with_ai_help "$error_message" "$curated_help" "$ai_context" "$auto_fix_function" "$allow_always" "$prompt_message" "$preference_key"
                        return $?
                    fi
                    ;;
                [Xx])
                    # User wants auto-fix after seeing AI help (exact 'x' or 'X')
                    if [[ -n "$auto_fix_function" ]] && command -v "$auto_fix_function" &>/dev/null; then
                        echo "" >&2
                        echo "⚙ Attempting automatic fix..." >&2
                        echo "" >&2

                        if "$auto_fix_function"; then
                            echo "" >&2
                            print_success "Auto-fix completed successfully"
                            echo "" >&2
                            return 2  # Signal to retry
                        else
                            echo "" >&2
                            print_error "Auto-fix failed"
                            echo "" >&2
                            read -r -p "Continue anyway ? [y]es, [N]o: " response
                            [[ "$response" == [Yy] ]] && return 0 || return 1
                        fi
                    else
                        print_warning "Auto-fix not available"
                        return 1
                    fi
                    ;;
                [Yy])
                    # Yes once - continue (exact 'y' or 'Y')
                    return 0
                    ;;
                [Nn])
                    # No - exit (exact 'n' or 'N')
                    return 1
                    ;;
                "")
                    # Empty input - default to no (exit)
                    return 1
                    ;;
                *)
                    # Anything else = follow-up question to AI (conversational mode)
                    echo "" >&2
                    echo "💡 AI Assistant:" >&2

                    # Source AI helper
                    local bitbot_install
                    bitbot_install=$(get_bitbot_install_dir)
                    if [[ -f "$bitbot_install/core/util/ai-helper/ai-helper.sh" ]]; then
                        # shellcheck source=/dev/null
                        source "$bitbot_install/core/util/ai-helper/ai-helper.sh"

                        # Ask follow-up question
                        ask_ai "$ai_context" "$response" >&2
                    else
                        echo "AI helper not available" >&2
                    fi

                    # Recurse - offer choices again after answering
                    echo "" >&2
                    print_error_with_ai_help "$error_message" "$curated_help" "$ai_context" "$auto_fix_function" "$allow_always" "$prompt_message" "$preference_key"
                    return $?
                    ;;
            esac
            ;;
        [Yy])
            # User wants to continue once (exact 'y' or 'Y')
            return 0
            ;;
        [Nn])
            # User wants to exit (exact 'n' or 'N')
            return 1
            ;;
        "")
            # Empty input - default to no (exit)
            return 1
            ;;
        *)
            # Anything else - treat as conversational input for first-level prompt
            echo "" >&2
            print_warning "Did you mean to ask a question? Type '?' for AI help, then ask your question."
            echo "" >&2
            print_warning "Or choose: y, a (always), N (exit), ? (help), x (auto-fix)"
            echo "" >&2
            print_error_with_ai_help "$error_message" "$curated_help" "$ai_context" "$auto_fix_function" "$allow_always" "$prompt_message" "$preference_key"
            return $?
            ;;
    esac
}

ask_ai_help() {
    # Quick wrapper to get AI help for a topic
    # Usage: ask_ai_help <context> <question>
    #
    # Example:
    #   ask_ai_help "Docker installation" "How to install Docker Desktop on Windows?"

    local context="$1"
    local question="$2"

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)

    if [[ -f "$bitbot_install/core/util/ai-helper/ai-helper.sh" ]]; then
        # shellcheck source=/dev/null
        source "$bitbot_install/core/util/ai-helper/ai-helper.sh"
        ask_ai "$context" "$question"
    else
        echo "AI helper not available (install Node.js for AI features)"
        return 1
    fi
}

# ============================================================================
# Timestamp Helpers
# ============================================================================

current_timestamp() {
    iso8601_timestamp
}

iso8601_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ============================================================================
# Miscellaneous Helpers
# ============================================================================

read_file() {
    # Read entire file to stdout
    local file="$1"
    cat "$file" 2>/dev/null || echo ""
}

write_file() {
    # Write content to file
    local file="$1"
    local content="$2"
    echo "$content" > "$file"
}

append_to_file() {
    # Append content to file
    local file="$1"
    local content="$2"
    echo "$content" >> "$file"
}
