# Test: Windows Native devcontainer.cmd (Direct PowerShell)
#
# This tests using devcontainer.cmd directly from PowerShell
# instead of going through WSL bash
#
# Hypothesis: Windows CLI wrapper will use Windows paths in labels,
# matching VS Code's path format

Write-Host "`n=== Windows Native devcontainer.cmd Test ===" -ForegroundColor Cyan

$testDir = "C:\Projects\BitBot\test-windows-launch"
$windowsPathForLabel = $testDir -replace '\\', '\\\\'

# Step 1: Check if devcontainer.cmd exists
Write-Host "`n[1/6] Checking for devcontainer.cmd..." -ForegroundColor Yellow

$devcontainerCmd = Get-Command "devcontainer.cmd" -ErrorAction SilentlyContinue
if (-not $devcontainerCmd) {
    Write-Host "  [X] devcontainer.cmd not found in PATH" -ForegroundColor Red
    Write-Host "  [i] Trying npm global bin path..." -ForegroundColor Gray

    # Try to find it in npm global
    $npmBin = npm bin -g 2>$null
    if ($npmBin) {
        $devcontainerPath = Join-Path $npmBin "devcontainer.cmd"
        if (Test-Path $devcontainerPath) {
            Write-Host "  [+] Found at: $devcontainerPath" -ForegroundColor Green
            $devcontainerCmd = $devcontainerPath
        } else {
            Write-Host "  [X] Not found in npm global bin: $npmBin" -ForegroundColor Red
            Write-Host "`n  Install with: npm install -g @devcontainers/cli"
            exit 1
        }
    } else {
        Write-Host "  [X] npm not found in Windows PATH" -ForegroundColor Red
        exit 1
    }
} else {
    $devcontainerCmd = "devcontainer.cmd"
    Write-Host "  [+] Found: devcontainer.cmd" -ForegroundColor Green
}

# Step 2: Clean up existing containers
Write-Host "`n[2/6] Cleaning up..." -ForegroundColor Yellow
docker ps -a --filter "label=devcontainer.local_folder=$windowsPathForLabel" --format "{{.Names}}" | ForEach-Object {
    if ($_) {
        Write-Host "  [i] Removing: $_" -ForegroundColor Gray
        docker rm -f $_ 2>$null | Out-Null
    }
}
Write-Host "  [+] Cleanup complete`n" -ForegroundColor Green

# Step 3: Build using Windows devcontainer.cmd
Write-Host "[3/6] Building via devcontainer.cmd (Windows native)..." -ForegroundColor Yellow
Write-Host "  [>] Command: devcontainer up --workspace-folder `"$testDir`"" -ForegroundColor Cyan

# Run from the test directory
Push-Location $testDir
& $devcontainerCmd up --workspace-folder "$testDir"
$buildResult = $LASTEXITCODE
Pop-Location

if ($buildResult -ne 0) {
    Write-Host "  [X] Build failed (exit code: $buildResult)" -ForegroundColor Red
    exit 1
}
Write-Host "  [+] Build complete`n" -ForegroundColor Green

# Step 4: Find the container using Windows path label
Write-Host "[4/6] Finding container by Windows path label..." -ForegroundColor Yellow

$container = docker ps --filter "label=devcontainer.local_folder=$windowsPathForLabel" --format "{{.Names}}" | Select-Object -First 1

if (-not $container) {
    Write-Host "  [!] Not found with Windows path, trying direct search..." -ForegroundColor Yellow
    $container = docker ps --format "{{.Names}}" | Select-Object -First 1
}

if (-not $container) {
    Write-Host "  [X] No container found" -ForegroundColor Red
    Write-Host "  [i] Check: docker ps" -ForegroundColor Gray
    exit 1
}

Write-Host "  [+] Found container: $container`n" -ForegroundColor Green

# Step 5: Inspect labels
Write-Host "[5/6] Inspecting labels..." -ForegroundColor Yellow

$labelsJson = docker inspect $container --format "{{json .Config.Labels}}"
$labels = $labelsJson | ConvertFrom-Json

Write-Host "  Key labels:"
$pathLabel = $labels.'devcontainer.local_folder'
$configLabel = $labels.'devcontainer.config_file'

if ($pathLabel) {
    Write-Host "    [+] devcontainer.local_folder = $pathLabel" -ForegroundColor Green

    # Check if it's Windows path or WSL path
    if ($pathLabel -match '^[A-Z]:\\' -or $pathLabel -match '^[a-z]:\\') {
        Write-Host "    [+] Path format: Windows (c:\...)" -ForegroundColor Green
    } elseif ($pathLabel -match '^/mnt/') {
        Write-Host "    [!] Path format: WSL (/mnt/...)" -ForegroundColor Yellow
    } else {
        Write-Host "    [!] Path format: Unknown" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [X] devcontainer.local_folder NOT FOUND" -ForegroundColor Red
}

if ($configLabel) {
    Write-Host "    [+] devcontainer.config_file = $configLabel" -ForegroundColor Green
} else {
    Write-Host "    [X] devcontainer.config_file NOT FOUND" -ForegroundColor Red
}

# Step 6: Test CLI attachment
Write-Host "`n[6/6] Testing CLI can attach..." -ForegroundColor Yellow

Push-Location $testDir
$execOutput = & $devcontainerCmd exec --workspace-folder "$testDir" echo "WINDOWS_CLI_ATTACH_OK" 2>&1
Pop-Location

if ($execOutput -match "WINDOWS_CLI_ATTACH_OK") {
    Write-Host "  [+] Windows CLI can attach to container`n" -ForegroundColor Green
} else {
    Write-Host "  [X] Attachment failed" -ForegroundColor Red
    Write-Host "  Output: $execOutput" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "  [+] Built via Windows native devcontainer.cmd" -ForegroundColor Green
Write-Host "  [+] Container found: $container" -ForegroundColor Green

if ($pathLabel -match '^[A-Z]:\\|^[a-z]:\\') {
    Write-Host "  [+] SUCCESS: Uses Windows path format!" -ForegroundColor Green
    Write-Host "  [+] This should match VS Code's label format" -ForegroundColor Green
} else {
    Write-Host "  [!] Still using WSL path format" -ForegroundColor Yellow
    Write-Host "  [i] Path mismatch may still occur" -ForegroundColor Gray
}

Write-Host "`nContainer is running. Test VS Code discovery:"
Write-Host "  1. Close this container: docker rm -f $container"
Write-Host "  2. Rebuild via Windows CLI: devcontainer.cmd up --workspace-folder `"$testDir`""
Write-Host "  3. Open VS Code: code `"$testDir`""
Write-Host "  4. Check if 'Reopen in Container' appears`n"
