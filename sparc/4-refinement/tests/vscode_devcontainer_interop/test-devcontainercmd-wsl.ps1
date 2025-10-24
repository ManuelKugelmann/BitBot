# Test: WSL Calling Windows devcontainer.cmd Wrapper
#
# This tests calling devcontainer.cmd from WSL bash
# (WSL → Windows wrapper → Docker)
#
# This is the "roundabout via WSL" approach

Write-Host "`n=== WSL → Windows devcontainer.cmd Test ===" -ForegroundColor Cyan

$testDir = "C:\Projects\BitBot\test-windows-launch"
$wslPath = "/mnt/c/Projects/BitBot/test-windows-launch"
$windowsPathForLabel = $testDir -replace '\\', '\\\\'

# Step 1: Check if devcontainer.cmd is accessible from WSL
Write-Host "`n[1/6] Checking if WSL can call devcontainer.cmd..." -ForegroundColor Yellow

$devcontainerCheck = wsl bash -c "which devcontainer.cmd 2>/dev/null || command -v devcontainer.cmd 2>/dev/null"
if (-not $devcontainerCheck) {
    Write-Host "  [!] devcontainer.cmd not in WSL PATH" -ForegroundColor Yellow
    Write-Host "  [i] Trying to find Windows npm global bin..." -ForegroundColor Gray

    # Get npm global bin from Windows, convert to WSL path
    $npmBin = npm bin -g 2>$null
    if ($npmBin) {
        # Convert C:\Users\... to /mnt/c/Users/...
        $npmBinWsl = $npmBin -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' -replace '/mnt/([A-Z])', { "/mnt/$($_.Groups[1].Value.ToLower())" }
        $devcontainerWsl = "$npmBinWsl/devcontainer.cmd"

        Write-Host "  [i] Trying: $devcontainerWsl" -ForegroundColor Gray
        $testCmd = wsl bash -c "test -f '$devcontainerWsl' && echo 'found'"

        if ($testCmd -eq "found") {
            Write-Host "  [+] Found Windows devcontainer.cmd via WSL path" -ForegroundColor Green
            $devcontainerPath = $devcontainerWsl
        } else {
            Write-Host "  [X] Not accessible from WSL" -ForegroundColor Red
            Write-Host "`n  Solution: Add to Windows PATH and restart"
            exit 1
        }
    } else {
        Write-Host "  [X] Cannot find npm" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  [+] devcontainer.cmd accessible from WSL" -ForegroundColor Green
    $devcontainerPath = "devcontainer.cmd"
}

# Step 2: Clean up
Write-Host "`n[2/6] Cleaning up..." -ForegroundColor Yellow
wsl bash -c "docker ps -a --filter 'label=devcontainer.local_folder=$windowsPathForLabel' --format '{{.Names}}' | xargs -r docker rm -f 2>/dev/null || true"
Write-Host "  [+] Cleanup complete`n" -ForegroundColor Green

# Step 3: Build using devcontainer.cmd via WSL (through cmd.exe)
Write-Host "[3/6] Building via WSL → cmd.exe → devcontainer.cmd..." -ForegroundColor Yellow

# .cmd files must be called through cmd.exe from WSL
# To avoid quote escaping hell, use --workspace-folder with current directory (.)
Write-Host "  [>] Command: cmd.exe /c `"cd $testDir && devcontainer.cmd up --workspace-folder .`"" -ForegroundColor Cyan

# Change to Windows directory and use . as path - avoids quote escaping issues
wsl bash -c "cmd.exe /c `"cd /d $testDir && devcontainer.cmd up --workspace-folder .`" 2>&1"
$buildResult = $LASTEXITCODE

if ($buildResult -ne 0) {
    Write-Host "  [X] Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  [+] Build complete`n" -ForegroundColor Green

# Step 4: Find container (try both path formats)
Write-Host "[4/6] Finding container..." -ForegroundColor Yellow

# Try Windows path first
$container = wsl bash -c "docker ps --filter 'label=devcontainer.local_folder=$windowsPathForLabel' --format '{{.Names}}' | head -1"

if (-not $container) {
    Write-Host "  [!] Not found with Windows path, trying WSL path..." -ForegroundColor Yellow
    $container = wsl bash -c "docker ps --filter 'label=devcontainer.local_folder=$wslPath' --format '{{.Names}}' | head -1"
}

if (-not $container) {
    Write-Host "  [!] Not found with label, getting latest..." -ForegroundColor Yellow
    $container = wsl bash -c "docker ps --format '{{.Names}}' | head -1"
}

if (-not $container) {
    Write-Host "  [X] No container found" -ForegroundColor Red
    exit 1
}

Write-Host "  [+] Found: $container`n" -ForegroundColor Green

# Step 5: Inspect labels
Write-Host "[5/6] Inspecting labels..." -ForegroundColor Yellow

$labelsJson = wsl bash -c "docker inspect $container --format '{{json .Config.Labels}}'"
$labels = $labelsJson | ConvertFrom-Json

Write-Host "  Key labels:"
$pathLabel = $labels.'devcontainer.local_folder'
$configLabel = $labels.'devcontainer.config_file'

if ($pathLabel) {
    Write-Host "    [+] devcontainer.local_folder = $pathLabel" -ForegroundColor Green

    # Detect path format
    if ($pathLabel -match '^[A-Z]:\\|^[a-z]:\\') {
        Write-Host "    [+] Format: Windows path" -ForegroundColor Green
    } elseif ($pathLabel -match '^/mnt/') {
        Write-Host "    [!] Format: WSL path" -ForegroundColor Yellow
    } else {
        Write-Host "    [!] Format: Unknown" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [X] devcontainer.local_folder NOT FOUND" -ForegroundColor Red
}

if ($configLabel) {
    Write-Host "    [+] devcontainer.config_file = $configLabel" -ForegroundColor Green
}

# Step 6: Test attachment
Write-Host "`n[6/6] Testing CLI attachment..." -ForegroundColor Yellow

# Use current directory approach to avoid quoting issues
$execOutput = wsl bash -c "cmd.exe /c `"cd /d $testDir && devcontainer.cmd exec --workspace-folder . echo WSL_WRAPPER_OK`" 2>&1"

if ($execOutput -match "WSL_WRAPPER_OK") {
    Write-Host "  [+] WSL → cmd.exe → devcontainer.cmd → container works`n" -ForegroundColor Green
} else {
    Write-Host "  [X] Attachment failed" -ForegroundColor Red
    Write-Host "  [i] Output: $execOutput" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "  [+] Built via WSL → Windows wrapper" -ForegroundColor Green
Write-Host "  [+] Container: $container" -ForegroundColor Green

if ($pathLabel -match '^[A-Z]:\\|^[a-z]:\\') {
    Write-Host "  [+] SUCCESS: Uses Windows paths!" -ForegroundColor Green
    Write-Host "  [+] Should match VS Code label format" -ForegroundColor Green
} elseif ($pathLabel -match '^/mnt/') {
    Write-Host "  [!] WARNING: Still uses WSL paths" -ForegroundColor Yellow
    Write-Host "  [i] Path mismatch with VS Code may occur" -ForegroundColor Gray
} else {
    Write-Host "  [?] Unexpected path format" -ForegroundColor Yellow
}

Write-Host "`nNext: Test VS Code discovery of this container`n"
