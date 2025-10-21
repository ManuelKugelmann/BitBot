# Find Docker Desktop settings.json location

Write-Host "`nSearching for Docker Desktop settings.json..." -ForegroundColor Cyan
Write-Host ""

$possibleLocations = @(
    "$env:APPDATA\Docker\settings.json",
    "$env:LOCALAPPDATA\Docker\settings.json",
    "C:\ProgramData\Docker\settings.json",
    "$env:USERPROFILE\AppData\Roaming\Docker\settings.json",
    "$env:USERPROFILE\AppData\Local\Docker\settings.json"
)

$found = $false

foreach ($path in $possibleLocations) {
    Write-Host "Checking: $path" -ForegroundColor Gray
    if (Test-Path $path) {
        Write-Host "  ✓ FOUND!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Settings file location:" -ForegroundColor White
        Write-Host "  $path" -ForegroundColor Cyan
        $found = $true

        # Show file info
        $item = Get-Item $path
        Write-Host ""
        Write-Host "File details:" -ForegroundColor White
        Write-Host "  Size:         $($item.Length) bytes" -ForegroundColor Gray
        Write-Host "  Last Modified: $($item.LastWriteTime)" -ForegroundColor Gray

        break
    } else {
        Write-Host "  ✗ Not found" -ForegroundColor DarkGray
    }
}

Write-Host ""

if (-not $found) {
    Write-Host "✗ Docker Desktop settings.json not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Docker Desktop hasn't been started yet (start it once)" -ForegroundColor Gray
    Write-Host "  2. Non-standard installation location" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Try running Docker Desktop, wait 30 seconds, then run this script again" -ForegroundColor White
}

Write-Host ""
