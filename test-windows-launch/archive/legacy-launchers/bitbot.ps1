# bitbot.ps1 - PowerShell launcher test
# Converts current path to WSL and launches bitbot.sh

$CurrentPath = (Get-Location).Path
$WslPath = (wsl wslpath -a "$CurrentPath").Trim()

Write-Host "Current Windows path: $CurrentPath"
Write-Host "Converted WSL path: $WslPath"
Write-Host "Launching WSL terminal..."
Write-Host ""

# Check if Windows Terminal is available
$WtAvailable = Get-Command wt -ErrorAction SilentlyContinue

if ($WtAvailable) {
    Write-Host "Using Windows Terminal"
    wt -d Ubuntu --cd "$WslPath" bash -l -c "./bitbot.sh"
} else {
    Write-Host "Using default WSL terminal"
    wsl -d Ubuntu --cd "$WslPath" bash -l -c "./bitbot.sh"
}
