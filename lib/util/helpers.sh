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
        # Assumes this file is in {INSTALL}/lib/util/helpers.sh
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        echo "$(cd "$script_dir/../.." && pwd)"
    fi
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
        jq -r ".${key} // empty" "$file" 2>/dev/null || echo ""
        return 0
    fi

    # Fallback: basic grep/sed parsing
    # Handles simple JSON like: {"key": "value", "key2": true}
    grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null | \
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
        print_error "Config file not found: $file"
        return 1
    fi

    # Try jq if available
    if command_exists jq; then
        local temp_file="${file}.tmp"
        jq ".${key} = \"${value}\"" "$file" > "$temp_file" && mv "$temp_file" "$file"
        return 0
    fi

    # Fallback: sed replacement (basic)
    sed -i.bak "s/\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"${key}\": \"${value}\"/" "$file"
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
    # Get merged config for a workspace
    # Usage: get_merged_workspace_config <workspace_path>
    local workspace_path="$1"

    local bitbot_install=$(get_bitbot_install_dir)
    local global_config="${bitbot_install}/config.json"
    local workspace_config="${workspace_path}/.bitbot/config.json"

    merge_configs "$global_config" "$workspace_config"
}

get_config_value() {
    # Get a merged config value for a workspace
    # Usage: get_config_value <workspace_path> <key>
    local workspace_path="$1"
    local key="$2"

    local merged_config=$(get_merged_workspace_config "$workspace_path")

    if command_exists jq; then
        echo "$merged_config" | jq -r ".${key} // empty"
    else
        echo "$merged_config" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[^,}]*" | \
            sed -E 's/.*:[[:space:]]*"?([^",}]*)"?.*/\1/' | \
            head -n 1
    fi
}

# ============================================================================
# Prompt Helpers
# ============================================================================

prompt_yes_no() {
    # Prompt for yes/no input with default
    # Usage: prompt_yes_no <question> <default>
    # Returns: "yes" or "no"
    local question="$1"
    local default="${2:-}"
    local response

    # Display question with default indicator
    if [[ "$default" == "yes" ]]; then
        read -p "$question (Y/n): " response
    elif [[ "$default" == "no" ]]; then
        read -p "$question (y/N): " response
    else
        read -p "$question (y/n): " response
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
            prompt_yes_no "$question" "$default"
            ;;
    esac
}

prompt_choice() {
    # Prompt for choice from numbered list
    # Usage: prompt_choice <question> <default_index> <choice1> <choice2> ...
    # Returns: selected choice index (0-based)
    local question="$1"
    local default_index="$2"
    shift 2
    local choices=("$@")
    local response

    # Display question
    echo "$question"
    echo ""

    # Display choices with numbers
    for i in "${!choices[@]}"; do
        local number=$((i + 1))
        if [[ $i -eq $default_index ]]; then
            echo "  ${number}. ${choices[$i]} (default)"
        else
            echo "  ${number}. ${choices[$i]}"
        fi
    done

    echo ""
    read -p "Choice [$((default_index + 1))]: " response

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
        prompt_choice "$question" "$default_index" "${choices[@]}"
        return 0
    fi

    # Validate range
    if [[ $response -ge 1 ]] && [[ $response -le ${#choices[@]} ]]; then
        echo $((response - 1))  # Convert to 0-based index
        return 0
    else
        print_warning "Invalid choice, please enter a number between 1 and ${#choices[@]}"
        prompt_choice "$question" "$default_index" "${choices[@]}"
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
        read -p "$prompt_text [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt_text: " response
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
