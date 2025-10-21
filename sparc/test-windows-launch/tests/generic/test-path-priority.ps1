# test-path-priority.ps1 - Launch the PATH priority test

$TestDir = (Get-Location).Path
$TestDirEscaped = $TestDir -replace '\\', '\\'
$WslPath = (wsl wslpath -a "$TestDirEscaped").Trim()

Write-Host "=== PATH Priority Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing different PATH configurations..."
Write-Host ""

wsl bash -l -c "cd '$WslPath' && ./test-path-priority.sh"

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
