# test-direct-powershell.ps1 - Direct PowerShell test (no WSL roundabout)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Direct PowerShell Test"
Write-Host " (No WSL Roundabout)"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$workspacePath = "C:\Projects\BitBot\test-windows-launch"
$vscodeCli = "$env:APPDATA\Code\User\globalStorage\ms-vscode-remote.remote-containers\cli-bin\devcontainer.cmd"

# Check VS Code CLI exists
Write-Host "[>] Checking VS Code devcontainer CLI..." -ForegroundColor Cyan
if (-not (Test-Path $vscodeCli)) {
    Write-Host "[X] Not found: $vscodeCli" -ForegroundColor Red
    Write-Host "[i] Install Dev Containers extension in VS Code" -ForegroundColor Gray
    exit 1
}
Write-Host "[+] Found: $vscodeCli" -ForegroundColor Green
Write-Host ""

# Test WSL paths BEFORE
Write-Host "[>] WSL state BEFORE (from PowerShell)..." -ForegroundColor Cyan
$beforeUbuntu = wsl -d Ubuntu-22.04 bash -c "pwd"
$beforeAlpine = wsl -d BitBot-Alpine bash -c "pwd"
Write-Host "    Ubuntu-22.04:  $beforeUbuntu" -ForegroundColor White
Write-Host "    BitBot-Alpine: $beforeAlpine" -ForegroundColor White
Write-Host ""

# Run devcontainer up directly from PowerShell
Write-Host "[>] Running devcontainer up (direct PowerShell)..." -ForegroundColor Cyan
Write-Host "[i] Command: $vscodeCli up --workspace-folder `"$workspacePath`"" -ForegroundColor Gray
Write-Host ""

& $vscodeCli up --workspace-folder "$workspacePath"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] devcontainer up failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[+] devcontainer up completed" -ForegroundColor Green
Write-Host ""

# Test WSL paths AFTER
Write-Host "[>] WSL state AFTER (from PowerShell)..." -ForegroundColor Cyan
$afterUbuntu = wsl -d Ubuntu-22.04 bash -c "pwd"
$afterAlpine = wsl -d BitBot-Alpine bash -c "pwd"
Write-Host "    Ubuntu-22.04:  $afterUbuntu" -ForegroundColor White
Write-Host "    BitBot-Alpine: $afterAlpine" -ForegroundColor White
Write-Host ""

# Check for corruption
$corrupted = $false
if ($afterUbuntu -match "docker-desktop-bind-mounts") {
    Write-Host "[X] Ubuntu-22.04 CORRUPTED" -ForegroundColor Red
    $corrupted = $true
}
if ($afterAlpine -match "docker-desktop-bind-mounts") {
    Write-Host "[X] BitBot-Alpine CORRUPTED" -ForegroundColor Red
    $corrupted = $true
}

if (-not $corrupted) {
    Write-Host "[+] NO CORRUPTION - Paths are clean!" -ForegroundColor Green
}

Write-Host ""

# Show container info
Write-Host "[>] Container created:" -ForegroundColor Cyan
$containers = docker ps --filter="label=devcontainer.local_folder" --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
Write-Host $containers
Write-Host ""

# Open VS Code
Write-Host "[>] Opening VS Code..." -ForegroundColor Cyan
code "$workspacePath"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Test Complete"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  WSL Corruption: $(if ($corrupted) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($corrupted) { 'Red' } else { 'Green' })
Write-Host ""
Write-Host "In VS Code:" -ForegroundColor Yellow
Write-Host "  1. Click 'Reopen in Container'" -ForegroundColor White
Write-Host "  2. Check if it uses the container we just created" -ForegroundColor White
Write-Host "  3. Or if it creates a NEW container" -ForegroundColor White
