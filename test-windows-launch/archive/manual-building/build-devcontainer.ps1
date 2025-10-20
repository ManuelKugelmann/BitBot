# build-devcontainer.ps1

# --- Configuration ---
# The absolute path to the project with the .devcontainer folder.
$workspaceFolder = "C:\Projects\BitBot\test-windows-launch"

# Host path to cache the VS Code Server installation.
$vscodeServerCachePath = "$env:USERPROFILE\.vscode-server\cli-cache"

# --- Build Command ---
# We use "splatting" to pass arguments to the devcontainer CLI. This is a
# more robust method in PowerShell that avoids issues with quotes and spaces.
$devcontainerArgs = @{
    "workspace-folder" = $workspaceFolder
    "mount"              = @(
        "type=bind,source=$vscodeServerCachePath,target=/root/.vscode-server",
        "type=bind,source=$env:USERPROFILE\.gitconfig,target=/root/.gitconfig,readonly",
        "type=bind,source=$env:USERPROFILE\.ssh,target=/root/.ssh,readonly"
    )
    "remote-env"         = @(
        "WAYLAND_DISPLAY=$env:WAYLAND_DISPLAY",
        "XDG_RUNTIME_DIR=$env:XDG_RUNTIME_DIR"
    )
}

Write-Host "Starting devcontainer build for: $workspaceFolder"

# Execute the command with the splatted arguments
devcontainer up @devcontainerArgs

# Note: This script prepares the container. To use it with VS Code, you would still
# use the "Dev Containers: Attach to Running Container..." command from the VS Code palette.