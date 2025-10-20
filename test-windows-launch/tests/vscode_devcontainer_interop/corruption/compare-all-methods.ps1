# Compare All devcontainer CLI Methods
#
# ⚠️  WARNING: This script intentionally uses Method 1 (WSL direct call)
#     which creates WSL path labels. This is for COMPARISON purposes only.
#     For production use, always use Method 3 (cmd.exe wrapper).
#
# Tests three approaches:
# 1. WSL bash → devcontainer (WSL paths - for comparison)
# 2. PowerShell → devcontainer.cmd (Windows paths)
# 3. WSL bash → cmd.exe → devcontainer.cmd (Windows paths - RECOMMENDED)
#
# Compares the labels each method produces

Write-Host "`n=== Comparing All devcontainer CLI Methods ===" -ForegroundColor Cyan
Write-Host "⚠️  WARNING: Method 1 intentionally creates WSL paths for comparison" -ForegroundColor Yellow
Write-Host "    Use Method 3 for production (Windows paths compatible with VS Code)`n" -ForegroundColor Yellow

$testDir = "C:\Projects\BitBot\test-windows-launch"
$wslPath = "/mnt/c/Projects/BitBot/test-windows-launch"

$results = @()

# Helper function to get labels
function Get-ContainerLabels {
    param($containerName)

    if (-not $containerName) {
        return $null
    }

    $labelsJson = docker inspect $containerName --format "{{json .Config.Labels}}" 2>$null
    if ($labelsJson) {
        return $labelsJson | ConvertFrom-Json
    }
    return $null
}

# Clean up function
function Cleanup-Containers {
    Write-Host "  [i] Cleaning up all test containers..." -ForegroundColor Gray

    # Get containers by IMAGE name (contains test-windows-launch) or by label
    # Container names are random (upbeat_shannon, etc) but images have our pattern
    $containers = docker ps -a --format "{{.Names}}|{{.Image}}" | Where-Object {
        $_ -match "test-windows-launch"
    } | ForEach-Object {
        ($_ -split '\|')[0]  # Extract just the container name
    }

    # Also check by devcontainer label
    $labelContainers = docker ps -a --filter "label=devcontainer.metadata" --format "{{.Names}}|{{.Image}}" | Where-Object {
        $_ -match "test-windows-launch"
    } | ForEach-Object {
        ($_ -split '\|')[0]
    }

    # Combine and deduplicate
    $allContainers = ($containers + $labelContainers) | Select-Object -Unique

    if ($allContainers -and $allContainers.Count -gt 0) {
        # First, stop any running containers
        foreach ($container in $allContainers) {
            if ($container) {  # Skip empty entries
                $status = docker inspect $container --format "{{.State.Status}}" 2>$null
                if ($status -eq "running") {
                    Write-Host "    [>] Stopping: $container" -ForegroundColor Cyan
                    docker stop $container 2>$null | Out-Null
                }
            }
        }

        # Wait a moment for graceful shutdown
        Start-Sleep -Seconds 1

        # Now remove all containers
        foreach ($container in $allContainers) {
            if ($container) {  # Skip empty entries
                Write-Host "    [>] Removing: $container" -ForegroundColor Cyan
                docker rm -f $container 2>$null | Out-Null
            }
        }

        Write-Host "  [+] Cleanup complete ($($allContainers.Count) containers)" -ForegroundColor Green
    } else {
        Write-Host "  [i] No containers to clean up" -ForegroundColor Gray
    }
}

# Method 1: WSL bash → devcontainer
Write-Host "`n[1/3] Testing: WSL bash → devcontainer" -ForegroundColor Yellow
Cleanup-Containers

wsl bash -l -c "cd $wslPath && devcontainer up --workspace-folder . 2>&1" | Out-Null
Start-Sleep -Seconds 1  # Give container time to appear

$container1 = docker ps --format "{{.Names}}" | Select-Object -First 1
if ($container1) {
    $labels1 = Get-ContainerLabels $container1

    $results += [PSCustomObject]@{
        Method = "WSL → devcontainer"
        Container = $container1
        PathLabel = $labels1.'devcontainer.local_folder'
        ConfigLabel = $labels1.'devcontainer.config_file'
        Success = $true
    }
    Write-Host "  [+] Success: $container1" -ForegroundColor Green
    Write-Host "      Path: $($labels1.'devcontainer.local_folder')" -ForegroundColor Gray
} else {
    $results += [PSCustomObject]@{
        Method = "WSL → devcontainer"
        Container = "Failed"
        PathLabel = "N/A"
        ConfigLabel = "N/A"
        Success = $false
    }
    Write-Host "  [X] Failed" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Method 2: PowerShell → devcontainer.cmd
Write-Host "`n[2/3] Testing: PowerShell → devcontainer.cmd" -ForegroundColor Yellow
Cleanup-Containers

$devcontainerCmd = Get-Command "devcontainer.cmd" -ErrorAction SilentlyContinue
if ($devcontainerCmd) {
    Push-Location $testDir
    & devcontainer.cmd up --workspace-folder "$testDir" 2>&1 | Out-Null
    Pop-Location

    Start-Sleep -Seconds 1  # Give container time to appear

    $container2 = docker ps --format "{{.Names}}" | Select-Object -First 1
    if ($container2) {
        $labels2 = Get-ContainerLabels $container2

        $results += [PSCustomObject]@{
            Method = "PS → devcontainer.cmd"
            Container = $container2
            PathLabel = $labels2.'devcontainer.local_folder'
            ConfigLabel = $labels2.'devcontainer.config_file'
            Success = $true
        }
        Write-Host "  [+] Success: $container2" -ForegroundColor Green
        Write-Host "      Path: $($labels2.'devcontainer.local_folder')" -ForegroundColor Gray
    } else {
        $results += [PSCustomObject]@{
            Method = "PS → devcontainer.cmd"
            Container = "Failed"
            PathLabel = "N/A"
            ConfigLabel = "N/A"
            Success = $false
        }
        Write-Host "  [X] Failed" -ForegroundColor Red
    }
} else {
    $results += [PSCustomObject]@{
        Method = "PS → devcontainer.cmd"
        Container = "N/A"
        PathLabel = "N/A"
        ConfigLabel = "N/A"
        Success = $false
    }
    Write-Host "  [!] devcontainer.cmd not found in PATH" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# Method 3: WSL → VS Code's bundled devcontainer.cmd
Write-Host "`n[3/3] Testing: WSL → VS Code bundled devcontainer.cmd" -ForegroundColor Yellow
Cleanup-Containers

# Find VS Code's bundled CLI - use simple approach
$winUser = [Environment]::UserName
$vscodeCliWin = "$env:APPDATA\Code\User\globalStorage\ms-vscode-remote.remote-containers\cli-bin\devcontainer.cmd"

if (Test-Path $vscodeCliWin) {
    Write-Host "  [i] Found VS Code CLI: $vscodeCliWin" -ForegroundColor Gray

    # .cmd files must be called through cmd.exe from WSL
    # Use current directory to avoid quote escaping issues
    Write-Host "  [>] Running via cmd.exe wrapper (cd then execute)" -ForegroundColor Gray
    $output = wsl bash -c "cmd.exe /c `"cd /d $testDir && devcontainer.cmd up --workspace-folder .`" 2>&1"

    # Show any errors
    if ($output -match "error|failed|command not found") {
        Write-Host "  [!] Output: $output" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 2  # Give container time to start

    $container3 = docker ps --format "{{.Names}}" | Select-Object -First 1
    if ($container3) {
        $labels3 = Get-ContainerLabels $container3

        $results += [PSCustomObject]@{
            Method = "WSL → VSCode bundled CLI"
            Container = $container3
            PathLabel = $labels3.'devcontainer.local_folder'
            ConfigLabel = $labels3.'devcontainer.config_file'
            Success = $true
        }
        Write-Host "  [+] Success: $container3" -ForegroundColor Green
        Write-Host "      Path: $($labels3.'devcontainer.local_folder')" -ForegroundColor Gray
    } else {
        $results += [PSCustomObject]@{
            Method = "WSL → VSCode bundled CLI"
            Container = "Failed"
            PathLabel = "N/A"
            ConfigLabel = "N/A"
            Success = $false
        }
        Write-Host "  [X] Failed - no container created" -ForegroundColor Red
        Write-Host "  [i] Check if VS Code CLI requires VS Code to be running" -ForegroundColor Gray
    }
} else {
    $results += [PSCustomObject]@{
        Method = "WSL → VSCode bundled CLI"
        Container = "N/A"
        PathLabel = "N/A"
        ConfigLabel = "N/A"
        Success = $false
    }
    Write-Host "  [!] VS Code bundled CLI not found at: $vscodeCliWin" -ForegroundColor Yellow
    Write-Host "  [i] Install VS Code + Dev Containers extension" -ForegroundColor Gray
}

# Comparison Report
Write-Host "`n=== Comparison Results ===" -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize | Out-String | Write-Host

# Analyze path formats
Write-Host "=== Path Format Analysis ===" -ForegroundColor Cyan

foreach ($result in $results) {
    if ($result.Success) {
        Write-Host "`n$($result.Method):" -ForegroundColor Yellow

        $path = $result.PathLabel
        if ($path -match '^[A-Z]:\\|^[a-z]:\\') {
            Write-Host "  [+] Windows path format: $path" -ForegroundColor Green
        } elseif ($path -match '^/mnt/') {
            Write-Host "  [!] WSL path format: $path" -ForegroundColor Yellow
        } else {
            Write-Host "  [?] Unknown format: $path" -ForegroundColor Gray
        }
    }
}

# Recommendations
Write-Host "`n=== Recommendation ===" -ForegroundColor Cyan

$windowsPathCount = ($results | Where-Object { $_.PathLabel -match '^[A-Z]:\\|^[a-z]:\\' }).Count
$wslPathCount = ($results | Where-Object { $_.PathLabel -match '^/mnt/' }).Count

if ($windowsPathCount -gt 0) {
    Write-Host "[+] Method(s) using Windows paths found!" -ForegroundColor Green
    Write-Host "    These should match VS Code's label format" -ForegroundColor Green

    $winMethod = $results | Where-Object { $_.PathLabel -match '^[A-Z]:\\|^[a-z]:\\' } | Select-Object -First 1
    Write-Host "`n    Recommended: $($winMethod.Method)" -ForegroundColor Cyan
} else {
    Write-Host "[!] All methods use WSL paths" -ForegroundColor Yellow
    Write-Host "    Path mismatch with VS Code will occur" -ForegroundColor Yellow
    Write-Host "    Consider using URI-based attachment instead" -ForegroundColor Yellow
}

Write-Host ""
