# bitbot-launch-vscode.ps1 - Launch VS Code with Docker Desktop corruption workaround

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " BitBot VS Code Launcher"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Function to detect WSL corruption
function Test-WSLCorruption {
    Write-Host "[>] Checking WSL state..." -ForegroundColor Cyan

    $testPwd = wsl bash -c "pwd" 2>&1

    if ($testPwd -match "docker-desktop-bind-mounts") {
        Write-Host "[!] Docker Desktop corruption detected" -ForegroundColor Yellow
        return $true
    }

    Write-Host "[+] WSL state is clean" -ForegroundColor Green
    return $false
}

# Function to fix WSL corruption
function Repair-WSLService {
    Write-Host "[>] Restarting WSL service..." -ForegroundColor Cyan

    try {
        Restart-Service -Name "WslService" -Force -ErrorAction Stop
        Start-Sleep -Seconds 3

        # Verify fix
        $testPwd = wsl bash -c "pwd" 2>&1
        if ($testPwd -match "docker-desktop-bind-mounts") {
            Write-Host "[X] Restart failed to fix corruption" -ForegroundColor Red
            return $false
        }

        Write-Host "[+] WSL service restarted successfully" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "[X] Failed to restart WSL service: $_" -ForegroundColor Red
        Write-Host "[i] Trying fallback method..." -ForegroundColor Gray

        # Fallback: taskkill (but warn about Docker)
        taskkill /f /im wslservice.exe 2>$null
        Start-Sleep -Seconds 3

        Write-Host "[!] WSL service killed - Docker may need restart" -ForegroundColor Yellow
        return $true
    }
}

# Check and fix if needed
if (Test-WSLCorruption) {
    if (-not (Repair-WSLService)) {
        Write-Host ""
        Write-Host "[X] Could not fix WSL corruption" -ForegroundColor Red
        Write-Host "[i] VS Code WSL terminals may show wrong paths" -ForegroundColor Gray
        Write-Host ""

        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    }
}

Write-Host ""
Write-Host "[>] Launching VS Code..." -ForegroundColor Cyan
code "$Path"

Write-Host "[+] VS Code launched" -ForegroundColor Green
Write-Host ""
Write-Host "[i] VS Code WSL terminals should now use correct paths" -ForegroundColor Gray
