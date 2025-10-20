# BitBot PowerShell Entry Point
# Entry Platform: Windows PowerShell
# Forwards all commands to BitBot in WSL Alpine

param(
    [Parameter(Position=0)]
    [string]$Command = "work",

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$distroName = "BitBot-Alpine"

# Show entry platform info for version command
if ($Command -eq "version") {
    Write-Host "Entry Point: Windows PowerShell" -ForegroundColor Cyan
}

# Check if WSL is installed
if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Error "WSL not found. Install from: https://aka.ms/wsl2"
    exit 1
}

# Check if BitBot-Alpine exists
$wslList = wsl --list --quiet | ForEach-Object {
    $cleaned = $_ -replace '\x00', '' -replace '\r', '' -replace '\n', ''
    $cleaned.Trim()
} | Where-Object { $_ -ne '' }

$alpineExists = $wslList -contains $distroName

if ($alpineExists -and $Command -eq "version") {
    Write-Host "Using WSL:     $distroName" -ForegroundColor Cyan
}

if (-not $alpineExists) {
    Write-Host "BitBot-Alpine WSL distribution not found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "BitBot requires a dedicated WSL distribution for isolation." -ForegroundColor White
    Write-Host ""
    $install = Read-Host "Install BitBot-Alpine now? (Y/n)"

    if ($install -eq "" -or $install -eq "y" -or $install -eq "Y") {
        # Install BitBot-Alpine
        Write-Host ""
        Write-Host "Installing BitBot-Alpine..." -ForegroundColor Cyan

        $installScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\archive\manual-building\install-bitbot-wsl.ps1"

        if (Test-Path $installScript) {
            & $installScript

            if ($LASTEXITCODE -ne 0) {
                Write-Error "Installation failed"
                exit 1
            }
        } else {
            Write-Error "Install script not found: $installScript"
            Write-Host "Please run manually or install BitBot-Alpine first." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Installation cancelled. BitBot requires BitBot-Alpine to run." -ForegroundColor Yellow
        exit 1
    }
}

# Get script directory and bash script path (Windows format)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bashScriptWin = Join-Path $scriptDir "bitbot"

# Build argument string
$argString = $Command
if ($Arguments) {
    $argString += " " + ($Arguments -join " ")
}

# Execute in BitBot-Alpine WSL using bash -c with wslpath conversion inside bash
# This avoids PowerShell escaping issues
# TODO: When BitBot is installed in Alpine, use: wsl -d $distroName /opt/bitbot/bin/bitbot $argString
wsl -d $distroName bash -c "`$(wslpath -u '$bashScriptWin') $argString"

# Exit with same code as WSL command
exit $LASTEXITCODE
