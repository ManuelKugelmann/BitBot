# Test: Fully Automated VS Code DevContainer Launch
#
# This uses VS Code's URI scheme to open directly in a container
# No manual "Reopen in Container" clicks needed

Write-Host "`n=== Automated VS Code DevContainer Test ===" -ForegroundColor Cyan

$testDir = "C:\Projects\BitBot\test-windows-launch"
$wslPath = "/mnt/c/Projects/BitBot/test-windows-launch"

# Step 1: Clean up ALL containers for this workspace
Write-Host "`n[1/4] Cleaning up existing containers..." -ForegroundColor Yellow
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

# Step 2: Launch VS Code with devcontainer URI
Write-Host "[2/4] Launching VS Code in devcontainer..." -ForegroundColor Yellow

# Load utility function (now in same directory)
. "$PSScriptRoot\Open-VSCodeDevContainer.ps1"

# Launch VS Code
Write-Host ""
Open-VSCodeDevContainer -WorkspacePath $testDir -Verify | Out-Null

# Step 3: Wait for VS Code to start
Write-Host "`n[3/4] Waiting for VS Code to initialize..." -ForegroundColor Yellow
Write-Host "  [i] Waiting 10 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Step 4: Verify container was created
Write-Host "`n[4/4] Verifying container creation..." -ForegroundColor Yellow

$maxRetries = 6
$retryCount = 0
$containerFound = $false

while ($retryCount -lt $maxRetries -and -not $containerFound) {
    $containers = wsl bash -c "docker ps --format '{{.Names}}' | grep -i 'test-windows-launch' || true"

    if ($containers) {
        $containerFound = $true
        Write-Host "  [+] Container created successfully!" -ForegroundColor Green

        $containers -split "`n" | ForEach-Object {
            if ($_) {
                $containerName = $_
                Write-Host "    Container: $containerName" -ForegroundColor Cyan

                # Get labels
                $labelsJson = wsl bash -c "docker inspect $containerName --format '{{json .Config.Labels}}'"
                Write-Host "`n  Labels found:"

                $labels = $labelsJson | ConvertFrom-Json
                $labels.PSObject.Properties | ForEach-Object {
                    if ($_.Name -match 'devcontainer|vsc|vsch') {
                        Write-Host "    [+] $($_.Name) = $($_.Value)" -ForegroundColor Green
                    }
                }

                # Check if it's running
                $status = wsl bash -c "docker inspect $containerName --format '{{.State.Status}}'"
                if ($status -eq "running") {
                    Write-Host "`n  [+] Container is running!" -ForegroundColor Green
                } else {
                    Write-Host "`n  [!] Container exists but not running (status: $status)" -ForegroundColor Yellow
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
    Write-Host "  [X] No container found after $($maxRetries * 5) seconds" -ForegroundColor Red
    Write-Host "  [i] Check VS Code - it may still be building..." -ForegroundColor Gray
    Write-Host "`n  Manual check: docker ps | grep test-windows-launch"
    exit 1
}

# Summary
Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "  [+] VS Code launched with devcontainer URI" -ForegroundColor Green
Write-Host "  [+] Container created and verified" -ForegroundColor Green
Write-Host "`nVS Code should now be open in the devcontainer."
Write-Host "Check bottom-left corner: should show 'Dev Container: BitBot Test'`n"
