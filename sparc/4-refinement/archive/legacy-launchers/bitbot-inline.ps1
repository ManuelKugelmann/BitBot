# bitbot-inline.ps1 - Inline execution (no new terminal)
# Output goes directly to current PowerShell window

$CurrentPath = (Get-Location).Path

# Convert path - must escape backslashes
$CurrentPathEscaped = $CurrentPath -replace '\\', '\\'
$WslPathRaw = wsl wslpath -a "$CurrentPathEscaped" 2>&1
$WslPath = if ($WslPathRaw) { $WslPathRaw.Trim() } else { "" }

Write-Host "=== BitBot Inline Test ===" -ForegroundColor Cyan
Write-Host "Windows path: $CurrentPath"
Write-Host "WSL path: $WslPath"
Write-Host ""

if (-not $WslPath) {
    Write-Host "ERROR: Path conversion failed" -ForegroundColor Red
    exit 1
}

# Execute inline - output comes back to this terminal
# IMPORTANT: Use -l (login shell) to load full WSL environment (.bashrc, .profile, etc.)
wsl bash -l -c "cd '$WslPath' && ./bitbot.sh"

Write-Host ""
Write-Host "=== Inline execution finished ===" -ForegroundColor Cyan
