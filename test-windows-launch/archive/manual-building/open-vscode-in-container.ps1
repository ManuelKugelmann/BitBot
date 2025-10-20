# open-vscode-in-container.ps1 - Open VS Code directly in running devcontainer

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [string]$ContainerName = "vsc-test-windows-launch"
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Open VS Code in DevContainer"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Find running container
Write-Host "[>] Finding container..." -ForegroundColor Cyan
$containerId = docker ps --filter "name=$ContainerName" --format "{{.ID}}" | Select-Object -First 1

if (-not $containerId) {
    Write-Host "[X] No running container found with name: $ContainerName" -ForegroundColor Red
    Write-Host ""
    Write-Host "[i] Start container first:" -ForegroundColor Gray
    Write-Host "    .\test-bitbot-alpine-devcontainer.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Or check running containers:" -ForegroundColor Gray
    Write-Host "    docker ps" -ForegroundColor White
    exit 1
}

Write-Host "[+] Found container: $containerId" -ForegroundColor Green
Write-Host ""

# Get container details
$containerName = docker inspect $containerId --format "{{.Name}}" | ForEach-Object { $_.TrimStart('/') }
Write-Host "[i] Container name: $containerName" -ForegroundColor Gray

# Open VS Code with remote container URI
Write-Host "[>] Opening VS Code..." -ForegroundColor Cyan
Write-Host "[i] Using: --remote attached-container+$containerId" -ForegroundColor Gray

$workspaceFolder = "/workspace"
code --remote "attached-container+$containerId" "$workspaceFolder"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] VS Code opened in container" -ForegroundColor Green
} else {
    Write-Host "[X] Failed to open VS Code (exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[i] Try installing Remote-Containers extension:" -ForegroundColor Gray
    Write-Host "    code --install-extension ms-vscode-remote.remote-containers" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Verify in VS Code"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "In VS Code terminal:" -ForegroundColor Yellow
Write-Host "  pwd                    # Should be: /workspace" -ForegroundColor White
Write-Host "  echo `$DEVCONTAINER    # Should be: true" -ForegroundColor White
Write-Host ""
Write-Host "Bottom-left should show:" -ForegroundColor Yellow
Write-Host "  'Dev Container: BitBot Test'" -ForegroundColor White
