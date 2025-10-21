# open-devcontainer.ps1 - Open VS Code in devcontainer using labels

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Open VS Code in DevContainer"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Find devcontainer using labels (devcontainer CLI method)
Write-Host "[>] Finding devcontainer by labels..." -ForegroundColor Cyan

# devcontainer CLI uses devcontainer.local_folder label
$containers = docker ps --filter="label=devcontainer.local_folder" --format "{{.ID}}:{{.Names}}:{{.Label `"devcontainer.local_folder`"}}"

if (-not $containers) {
    Write-Host "[X] No running devcontainers found" -ForegroundColor Red
    Write-Host ""
    Write-Host "[i] Start devcontainer first:" -ForegroundColor Gray
    Write-Host "    wsl -d BitBot-Alpine bash -l -c `"cd /mnt/c/Projects/BitBot/test-windows-launch && devcontainer up --workspace-folder .`"" -ForegroundColor White
    Write-Host ""
    Write-Host "Or check all containers:" -ForegroundColor Gray
    Write-Host "    docker ps" -ForegroundColor White
    exit 1
}

# Parse container info
$containerInfo = $containers -split ':'
$containerId = $containerInfo[0]
$containerName = $containerInfo[1]

Write-Host "[+] Found devcontainer:" -ForegroundColor Green
Write-Host "    ID:   $containerId" -ForegroundColor White
Write-Host "    Name: $containerName" -ForegroundColor White
Write-Host ""

# Open VS Code using remote container URI
Write-Host "[>] Opening VS Code in container..." -ForegroundColor Cyan
code --folder-uri "vscode-remote://attached-container+$containerId/workspace"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] VS Code launched" -ForegroundColor Green
} else {
    Write-Host "[X] Failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[i] Trying alternative method..." -ForegroundColor Gray
    code --remote "attached-container+$containerId" "/workspace"
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Verify in VS Code"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bottom-left should show:" -ForegroundColor Yellow
Write-Host "  'Dev Container: ...'" -ForegroundColor White
Write-Host ""
Write-Host "In terminal:" -ForegroundColor Yellow
Write-Host "  pwd → /workspace" -ForegroundColor White
Write-Host "  echo `$DEVCONTAINER → true" -ForegroundColor White
