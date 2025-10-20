#!/bin/bash

# build-devcontainer.sh

# --- Configuration ---
# The absolute path to the project with the .devcontainer folder.
WORKSPACE_FOLDER="/mnt/c/Projects/BitBot/test-windows-launch"

# Host path to cache the VS Code Server installation.
VSCODE_SERVER_CACHE_PATH="$HOME/.vscode-server/cli-cache"

# --- Build Command ---
# This command constructs and executes the devcontainer CLI command with
# the same kinds of mounts and environment variables that VS Code uses internally.

echo "Starting devcontainer build for: $WORKSPACE_FOLDER"

devcontainer up --workspace-folder "$WORKSPACE_FOLDER" \
    --mount "type=bind,source=$VSCODE_SERVER_CACHE_PATH,target=/root/.vscode-server" \
    --mount "type=bind,source=$HOME/.gitconfig,target=/root/.gitconfig,readonly" \
    --mount "type=bind,source=$HOME/.ssh,target=/root/.ssh,readonly" \
    --remote-env "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
    --remote-env "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"

# Note: This script prepares the container. To use it with VS Code, you would still
# use the "Dev Containers: Attach to Running Container..." command from the VS Code palette.
