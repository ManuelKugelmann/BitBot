# Test BitBot Launcher Scripts
#
# This script tests the BitBot entry points and launcher workflow
# without actually building containers.

Write-Host "BitBot Launcher Test" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Test 1: Check WSL availability
Write-Host "[1/7] Checking WSL availability..." -ForegroundColor Yellow
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "    ✓ WSL found" -ForegroundColor Green
} else {
    Write-Host "    ✗ WSL not found" -ForegroundColor Red
    Write-Host "    Install from: https://aka.ms/wsl2" -ForegroundColor White
    exit 1
}

# Test 2: Check if bash script exists
Write-Host "[2/7] Checking bash launcher..." -ForegroundColor Yellow
$bashScript = Join-Path $testDir "bitbot"
if (Test-Path $bashScript) {
    Write-Host "    ✓ bitbot script found" -ForegroundColor Green
} else {
    Write-Host "    ✗ bitbot script not found at: $bashScript" -ForegroundColor Red
    exit 1
}

# Test 3: Convert path to WSL format
Write-Host "[3/7] Converting path to WSL format..." -ForegroundColor Yellow
$wslPath = wsl wslpath -u $bashScript
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ WSL path: $wslPath" -ForegroundColor Green
} else {
    Write-Host "    ✗ Failed to convert path" -ForegroundColor Red
    exit 1
}

# Test 4: Check bash script syntax
Write-Host "[4/7] Checking bash script syntax..." -ForegroundColor Yellow
wsl bash -n $wslPath 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ Bash syntax OK" -ForegroundColor Green
} else {
    Write-Host "    ✗ Bash syntax error" -ForegroundColor Red
    wsl bash -n $wslPath
    exit 1
}

# Test 5: Test bitbot version command
Write-Host "[5/7] Testing 'bitbot version' command..." -ForegroundColor Yellow
$output = wsl bash $wslPath version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ Version command works" -ForegroundColor Green
    Write-Host ""
    $output | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    Write-Host ""
} else {
    Write-Host "    ✗ Version command failed" -ForegroundColor Red
    $output
    exit 1
}

# Test 6: Test bitbot help command
Write-Host "[6/7] Testing 'bitbot help' command..." -ForegroundColor Yellow
$output = wsl bash $wslPath help 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ Help command works" -ForegroundColor Green
} else {
    Write-Host "    ✗ Help command failed" -ForegroundColor Red
    $output
    exit 1
}

# Test 7: Test PowerShell entry point
Write-Host "[7/7] Testing PowerShell entry point..." -ForegroundColor Yellow
$ps1Script = Join-Path $testDir "bitbot.ps1"
if (Test-Path $ps1Script) {
    try {
        $output = & $ps1Script version 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $output -match "BitBot version") {
            Write-Host "    ✓ PowerShell entry point works" -ForegroundColor Green
        } else {
            Write-Host "    ✗ PowerShell entry point failed" -ForegroundColor Red
            Write-Host $output
            exit 1
        }
    } catch {
        Write-Host "    ✗ PowerShell entry point error: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "    ✗ bitbot.ps1 not found" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host ""
Write-Host "✓ All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "Entry points ready:" -ForegroundColor Cyan
Write-Host "  Windows PowerShell:  .\bitbot.ps1 [command] [options]" -ForegroundColor White
Write-Host "  Windows Batch:       .\bitbot.bat [command] [options]" -ForegroundColor White
Write-Host "  WSL/Linux:           ./bitbot [command] [options]" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test terminal mode:    .\bitbot.ps1 work" -ForegroundColor White
Write-Host "  2. Test VS Code mode:     .\bitbot.ps1 vscode" -ForegroundColor White
Write-Host "     (or:                   .\bitbot.ps1 work vscode)" -ForegroundColor Gray
Write-Host "  3. View full help:        .\bitbot.ps1 help" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: Actual container building requires:" -ForegroundColor Yellow
Write-Host "  - Docker running" -ForegroundColor White
Write-Host "  - .devcontainer/devcontainer.json in workspace" -ForegroundColor White
Write-Host "  - VS Code with Dev Containers extension OR standalone devcontainer CLI" -ForegroundColor White
Write-Host ""
