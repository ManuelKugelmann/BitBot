# bitbot-smart.ps1 - Auto-detect environment and choose method
# Detects VS Code terminal and uses inline, otherwise launches new terminal

$CurrentPath = (Get-Location).Path
$CurrentPathEscaped = $CurrentPath -replace '\\', '\\'
$WslPathRaw = wsl wslpath -a "$CurrentPathEscaped" 2>&1
$WslPath = if ($WslPathRaw) { $WslPathRaw.Trim() } else { "" }

Write-Host "=== BitBot Smart Launcher ===" -ForegroundColor Cyan
Write-Host "Windows path: $CurrentPath"
Write-Host "WSL path: $WslPath"
Write-Host ""

if (-not $WslPath) {
    Write-Host "ERROR: Path conversion failed" -ForegroundColor Red
    exit 1
}

# Detect environment
$IsVSCode = $env:TERM_PROGRAM -eq "vscode"
$IsWindowsTerminal = $env:WT_SESSION -ne $null
$IsConhost = (-not $IsVSCode) -and (-not $IsWindowsTerminal)

Write-Host "Environment Detection:" -ForegroundColor Yellow
Write-Host "  VS Code Terminal: $IsVSCode"
Write-Host "  Windows Terminal: $IsWindowsTerminal"
Write-Host "  Classic Conhost:  $IsConhost"
Write-Host ""

if ($IsVSCode) {
    Write-Host "Running INLINE (VS Code integrated terminal)" -ForegroundColor Green
    wsl bash -l -c "cd '$WslPath' && ./bitbot.sh"
} else {
    Write-Host "Launching NEW TERMINAL" -ForegroundColor Green
    $WtAvailable = Get-Command wt -ErrorAction SilentlyContinue

    if ($WtAvailable) {
        Write-Host "  Using Windows Terminal (wt)"
        wt wsl bash -l -c "cd '$WslPath' && ./bitbot.sh && bash"
    } else {
        Write-Host "  Using default WSL terminal"
        Start-Process wsl -ArgumentList "bash","-l","-c","cd '$WslPath' && ./bitbot.sh && bash"
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
