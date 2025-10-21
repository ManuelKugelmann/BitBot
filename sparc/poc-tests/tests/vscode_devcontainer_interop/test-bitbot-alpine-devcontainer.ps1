# test-bitbot-alpine-devcontainer.ps1 - Test complete BitBot Alpine → DevContainer → VS Code flow

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$projectPath = "/mnt/c/Projects/BitBot/test-windows-launch"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " BitBot Alpine DevContainer Test"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check BitBot-Alpine exists
Write-Host "[>] Checking BitBot-Alpine..." -ForegroundColor Cyan
$wslList = wsl --list --quiet | ForEach-Object { $_.Trim() -replace '\x00', '' }
if (-not ($wslList -contains "BitBot-Alpine")) {
    Write-Host "[X] BitBot-Alpine not found" -ForegroundColor Red
    Write-Host "[i] Run: .\install-bitbot-wsl.ps1" -ForegroundColor Gray
    exit 1
}
Write-Host "[+] BitBot-Alpine found" -ForegroundColor Green
Write-Host ""

# Convert WSL path to Windows path for cmd.exe
$windowsPath = "C:\Projects\BitBot\test-windows-launch"

# Build devcontainer (Method 3: via cmd.exe for Windows path labels)
Write-Host "[>] Building devcontainer (Method 3: Windows paths)..." -ForegroundColor Cyan
Write-Host "[i] This may take a few minutes on first run" -ForegroundColor Gray
Write-Host "[i] Using cmd.exe wrapper from BitBot-Alpine for Windows path labels" -ForegroundColor Gray

wsl -d BitBot-Alpine bash -c "cmd.exe /c `"cd /d $windowsPath && devcontainer.cmd build --workspace-folder .`" 2>&1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Build complete with Windows path labels" -ForegroundColor Green
Write-Host ""

# Start devcontainer (Method 3)
Write-Host "[>] Starting devcontainer (Method 3: Windows paths)..." -ForegroundColor Cyan
wsl -d BitBot-Alpine bash -c "cmd.exe /c `"cd /d $windowsPath && devcontainer.cmd up --workspace-folder .`" 2>&1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Start failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Container started with Windows path labels" -ForegroundColor Green
Write-Host ""

# Open VS Code in container
Write-Host "[>] Opening VS Code in container..." -ForegroundColor Cyan

# Get container info (should have Windows path labels now)
$containerInfo = wsl bash -c "docker ps --format '{{.Names}}' | grep -i 'test-windows-launch' | head -1"

# Option 1: Use Windows code.exe with --folder-uri to open in container
# This requires the Dev Containers extension
Write-Host "[i] Method: Open folder in Windows VS Code, then auto-attach" -ForegroundColor Gray
code "$windowsPath"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Next Steps"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[!] VS Code opened - watch for popup:" -ForegroundColor Yellow
Write-Host "    'Reopen in Container'" -ForegroundColor White
Write-Host ""
Write-Host "Click the popup to attach to container" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or manually:" -ForegroundColor Yellow
Write-Host "  1. Ctrl+Shift+P" -ForegroundColor White
Write-Host "  2. 'Dev Containers: Reopen in Container'" -ForegroundColor White
Write-Host ""
Write-Host "Then verify in VS Code terminal:" -ForegroundColor Yellow
Write-Host "  pwd                    # Should be: /workspace" -ForegroundColor White
Write-Host "  echo `$DEVCONTAINER    # Should be: true" -ForegroundColor White
Write-Host ""
Write-Host "Bottom-left should show:" -ForegroundColor Yellow
Write-Host "  'Dev Container: BitBot Test'" -ForegroundColor White
