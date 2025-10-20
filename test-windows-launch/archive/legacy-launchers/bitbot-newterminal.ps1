# bitbot-newterminal.ps1 - New terminal window
# Launches separate terminal for interactive session

$CurrentPath = (Get-Location).Path

# Convert path - must escape backslashes
$CurrentPathEscaped = $CurrentPath -replace '\\', '\\'
$WslPathRaw = wsl wslpath -a "$CurrentPathEscaped" 2>&1
$WslPath = if ($WslPathRaw) { $WslPathRaw.Trim() } else { "" }

Write-Host "=== BitBot New Terminal Test ===" -ForegroundColor Cyan
Write-Host "Windows path: $CurrentPath"
Write-Host "WSL path: $WslPath"
Write-Host ""

# Check if Windows Terminal is available
$WtAvailable = Get-Command wt -ErrorAction SilentlyContinue

if ($WtAvailable) {
    Write-Host "Using Windows Terminal (wt)" -ForegroundColor Green
    # Windows Terminal launches wsl directly
    wt wsl bash -l -c "cd '$WslPath' && ./bitbot.sh && bash"
} else {
    Write-Host "Using default WSL (new window)" -ForegroundColor Yellow
    # Start new conhost window
    Start-Process wsl -ArgumentList "bash","-l","-c","cd '$WslPath' && ./bitbot.sh && bash"
}

Write-Host "New terminal launched!" -ForegroundColor Cyan
