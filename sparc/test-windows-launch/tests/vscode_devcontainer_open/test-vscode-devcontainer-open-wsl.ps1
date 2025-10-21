# test-vscode-devcontainer-open-wsl.ps1
# Test: VS Code DevContainer Direct Opening via WSL Roundabout
#
# This uses WSL bash for hex encoding (like BitBot-Alpine would)
# but keeps the PowerShell structure for Windows testing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n===================================" -ForegroundColor Cyan
Write-Host " VS Code DevContainer Test (WSL)"
Write-Host " Direct Open with WSL Hex Encoding"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$workspacePath = "C:\Projects\BitBot\test-windows-launch"
$containerPath = "/workspace"

# Step 1: Clean up existing containers
Write-Host "[1/4] Cleaning up existing containers..." -ForegroundColor Yellow
$existingContainers = wsl bash -c "docker ps -a --format '{{.Names}}' | grep -i 'test-windows-launch' || true"
if ($existingContainers) {
    Write-Host "  [i] Found containers to remove:" -ForegroundColor Gray
    $existingContainers -split "`n" | ForEach-Object {
        if ($_) {
            Write-Host "    - $_" -ForegroundColor Gray
            wsl bash -c "docker rm -f $_ 2>/dev/null || true"
        }
    }
}
Write-Host "  [+] Cleanup complete`n" -ForegroundColor Green

# Step 2: Convert path to hex using WSL bash (Alpine-compatible)
Write-Host "[2/4] Converting path to hex via WSL..." -ForegroundColor Yellow
Write-Host "    Windows Path: $workspacePath" -ForegroundColor White

# Use WSL bash to do hex encoding (using od for Alpine compatibility)
$hexPath = wsl bash -c "printf '%s' '$workspacePath' | od -A n -t x1 | tr -d ' \n'"

Write-Host "    Hex Encoded:  $hexPath" -ForegroundColor White
Write-Host "    Container:    $containerPath" -ForegroundColor White
Write-Host ""

# Verify hex encoding
if ([string]::IsNullOrWhiteSpace($hexPath)) {
    Write-Host "  [X] Hex encoding failed!" -ForegroundColor Red
    Write-Host "  [i] WSL bash may not be available" -ForegroundColor Gray
    exit 1
}
Write-Host "  [+] Hex encoding successful (via WSL bash)" -ForegroundColor Green
Write-Host ""

# Step 3: Build VS Code Direct DevContainer Opening URI and open VS Code
Write-Host "[3/4] Opening VS Code in devcontainer..." -ForegroundColor Yellow

# Build the URI
$uri = "vscode-remote://dev-container+$hexPath$containerPath"
Write-Host "    URI: $uri" -ForegroundColor Gray
Write-Host ""

# Open VS Code with the special URI
code --folder-uri="$uri"

Write-Host "  [+] VS Code launch command sent" -ForegroundColor Green
Write-Host ""

# Step 4: Wait for VS Code to start and verify
Write-Host "[4/4] Waiting for VS Code to initialize..." -ForegroundColor Yellow
Write-Host "  [i] Waiting 10 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Verify container was created
$maxRetries = 6
$retryCount = 0
$containerFound = $false

while ($retryCount -lt $maxRetries -and -not $containerFound) {
    $containers = wsl bash -c "docker ps --format '{{.Names}}' | grep -i 'test-windows-launch' || true"

    if ($containers) {
        $containerFound = $true
        Write-Host "`n  [+] Container created successfully!" -ForegroundColor Green

        $containers -split "`n" | ForEach-Object {
            if ($_) {
                $containerName = $_
                Write-Host "    Container: $containerName" -ForegroundColor Cyan

                # Get container status
                $status = wsl bash -c "docker inspect $containerName --format '{{.State.Status}}'"
                if ($status -eq "running") {
                    Write-Host "    Status:    Running" -ForegroundColor Green
                } else {
                    Write-Host "    Status:    $status" -ForegroundColor Yellow
                }
            }
        }
    } else {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "  [i] Container not found yet, waiting... (attempt $retryCount/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }
    }
}

if (-not $containerFound) {
    Write-Host "`n  [X] No container found after $($maxRetries * 5) seconds" -ForegroundColor Red
    Write-Host "  [i] Check VS Code - it may still be building..." -ForegroundColor Gray
    Write-Host "`n  Manual check: docker ps | grep test-windows-launch"
    exit 1
}

# Summary
Write-Host "`n===================================" -ForegroundColor Cyan
Write-Host " Test Complete"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Method Used:" -ForegroundColor Yellow
Write-Host "  ✓ WSL bash for hex encoding (Alpine-compatible)" -ForegroundColor White
Write-Host "  ✓ PowerShell for VS Code Direct DevContainer Opening URI building" -ForegroundColor White
Write-Host "  ✓ Windows code.exe for direct opening" -ForegroundColor White
Write-Host ""
Write-Host "Expected Result:" -ForegroundColor Yellow
Write-Host "  ✅ VS Code opens directly in dev container" -ForegroundColor Green
Write-Host "  ✅ NO 'Reopen in Container' popup!" -ForegroundColor Green
Write-Host "  ✅ Opens directly at /workspace inside container" -ForegroundColor Green
Write-Host ""
Write-Host "Check:" -ForegroundColor Yellow
Write-Host "  - Bottom-left corner: 'Dev Container: BitBot Test'" -ForegroundColor White
Write-Host "  - Terminal pwd: /workspace" -ForegroundColor White
Write-Host ""
Write-Host "This method demonstrates:" -ForegroundColor Cyan
Write-Host "  • WSL can provide hex encoding (no xxd/PowerShell needed)" -ForegroundColor Gray
Write-Host "  • BitBot-Alpine can do the same (od is in Alpine)" -ForegroundColor Gray
Write-Host "  • VS Code Direct DevContainer Opening works even with cross-platform hex encoding" -ForegroundColor Gray
Write-Host ""
