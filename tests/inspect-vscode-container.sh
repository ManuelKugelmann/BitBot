#!/usr/bin/env bash
#
# Inspect VS Code DevContainer Labels
#
# Run this after VS Code has created the devcontainer

set -euo pipefail

echo "=== Finding DevContainers ==="
echo ""

# Find all devcontainers
CONTAINERS=$(docker ps -a --filter "label=devcontainer.local_folder" --format '{{.Names}}')

if [[ -z "$CONTAINERS" ]]; then
    echo "No devcontainers found"
    exit 1
fi

echo "Found devcontainers:"
echo "$CONTAINERS"
echo ""

# Inspect each container
echo "$CONTAINERS" | while read -r CONTAINER; do
    echo "=== Inspecting: $CONTAINER ==="
    echo ""

    # Get local folder label
    LOCAL_FOLDER=$(docker inspect "$CONTAINER" --format '{{index .Config.Labels "devcontainer.local_folder"}}' 2>/dev/null || echo "")

    if [[ -n "$LOCAL_FOLDER" ]]; then
        echo "devcontainer.local_folder: $LOCAL_FOLDER"
        echo ""

        # Analyze path format
        if [[ "$LOCAL_FOLDER" =~ ^/mnt/c/ ]]; then
            echo "Path format: WSL (/mnt/c/...)"
        elif [[ "$LOCAL_FOLDER" =~ ^/mnt/wsl/ ]]; then
            echo "Path format: CORRUPTED (/mnt/wsl/...)"
        elif [[ "$LOCAL_FOLDER" =~ ^[A-Z]:\\ ]] || [[ "$LOCAL_FOLDER" =~ ^[A-Z]:/ ]]; then
            echo "Path format: Windows (C:\\... or C:/...)"
        else
            echo "Path format: Unknown"
        fi
    else
        echo "No devcontainer.local_folder label found"
    fi

    echo ""
    echo "All devcontainer labels:"
    docker inspect "$CONTAINER" --format '{{range $k, $v := .Config.Labels}}{{if eq (slice $k 0 12) "devcontainer"}}{{$k}} = {{$v}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || echo "Failed to get labels"

    echo ""
    echo "---"
    echo ""
done
