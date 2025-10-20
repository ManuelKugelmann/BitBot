# test-reproduce-corruption.ps1 - Reproduce and diagnose the corruption
#
# ⚠️  WARNING: This script intentionally uses Method 1 (WSL direct call)
#     to REPRODUCE WSL path corruption for debugging purposes.
#     This is NOT the correct method for production use.
#     Use Method 3 (cmd.exe wrapper) for correct Windows path labels.

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Reproduce Corruption Test"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "⚠️  WARNING: Intentionally reproduces WSL path issue" -ForegroundColor Yellow
Write-Host ""

$TestDir = (Get-Location).Path
$WslPath = "/mnt/c/Projects/BitBot/test-windows-launch"

# Step 1: Capture baseline
Write-Host "[1] Baseline: Check WSL environment..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment variables:" -ForegroundColor Yellow
wsl bash -l -c 'env | grep -i "remote\|container\|vscode" | sort'
Write-Host ""
Write-Host "IPC sockets:" -ForegroundColor Yellow
wsl bash -l -c 'ls -la /tmp/vscode-remote-containers* 2>/dev/null || echo "None"'
Write-Host ""

# Step 2: Check container labels BEFORE
Write-Host "[2] Container labels BEFORE devcontainer up..." -ForegroundColor Cyan
docker ps -a --filter "name=test-windows-launch" --format "{{.ID}}" | ForEach-Object {
    Write-Host "Container: $_" -ForegroundColor Yellow
    docker inspect $_ --format '{{range $k,$v := .Config.Labels}}{{$k}}={{$v}}{{println}}{{end}}' | Where-Object { $_ -match "devcontainer|vsch" }
}
Write-Host ""

# Step 3: Run devcontainer up from WSL
Write-Host "[3] Running 'devcontainer up' from WSL..." -ForegroundColor Cyan
Write-Host "[!] This should cause corruption" -ForegroundColor Yellow
Write-Host ""
wsl bash -l -c "cd '$WslPath' && devcontainer up --workspace-folder ."

if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] devcontainer up failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[+] Container started" -ForegroundColor Green
Write-Host ""

# Step 4: Check environment AFTER
Write-Host "[4] WSL environment AFTER container start..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment variables:" -ForegroundColor Yellow
wsl bash -l -c 'env | grep -i "remote\|container\|vscode" | sort'
Write-Host ""
Write-Host "IPC sockets:" -ForegroundColor Yellow
wsl bash -l -c 'ls -la /tmp/vscode-remote-containers* 2>/dev/null || echo "None"'
Write-Host ""

# Step 5: Check container labels AFTER
Write-Host "[5] Container labels AFTER devcontainer up..." -ForegroundColor Cyan
docker ps -a --filter "name=test-windows-launch" --format "{{.ID}}" | ForEach-Object {
    Write-Host "Container: $_" -ForegroundColor Yellow
    docker inspect $_ --format '{{range $k,$v := .Config.Labels}}{{$k}}={{$v}}{{println}}{{end}}' | Where-Object { $_ -match "devcontainer|vsch|local.folder" }
}
Write-Host ""

# Step 6: Wait and check again
Write-Host "[6] Waiting 10 seconds for container to fully start..." -ForegroundColor Cyan
Start-Sleep -Seconds 10
Write-Host ""
Write-Host "Environment after wait:" -ForegroundColor Yellow
wsl bash -l -c 'env | grep -i "remote\|container\|vscode" | sort'
Write-Host ""

# Step 7: Test VS Code (don't open it, just document next step)
Write-Host "[7] Next: Open VS Code and test WSL terminal..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Run in another PowerShell:" -ForegroundColor Yellow
Write-Host "  code $TestDir" -ForegroundColor White
Write-Host ""
Write-Host "In VS Code:" -ForegroundColor Yellow
Write-Host "  1. Open WSL terminal (Ctrl+``)" -ForegroundColor White
Write-Host "  2. Run: pwd" -ForegroundColor White
Write-Host "  3. Expected (corrupted): /mnt/wsl/docker-desktop-bind-mounts/..." -ForegroundColor Red
Write-Host "  4. Expected (correct): $WslPath" -ForegroundColor Green
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Press Enter when you've tested VS Code terminal..."
Read-Host

# Step 8: Check after corruption confirmed
Write-Host ""
Write-Host "[8] Final state check..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment:" -ForegroundColor Yellow
wsl bash -l -c 'env | grep -i "remote\|container\|vscode" | sort'
Write-Host ""
Write-Host "IPC sockets:" -ForegroundColor Yellow
wsl bash -l -c 'ls -la /tmp/vscode-remote-containers* 2>/dev/null || echo "None"'
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Analysis Complete"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Save this output to diagnose the root cause!" -ForegroundColor Yellow
