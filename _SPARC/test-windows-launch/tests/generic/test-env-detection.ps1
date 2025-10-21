# test-env-detection.ps1 - Show all environment variables for detection

Write-Host "=== Environment Detection Test ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Key Environment Variables:" -ForegroundColor Yellow
Write-Host "  TERM_PROGRAM:     $env:TERM_PROGRAM"
Write-Host "  WT_SESSION:       $env:WT_SESSION"
Write-Host "  WT_PROFILE_ID:    $env:WT_PROFILE_ID"
Write-Host "  ConEmuPID:        $env:ConEmuPID"
Write-Host "  SESSIONNAME:      $env:SESSIONNAME"
Write-Host ""

$IsVSCode = $env:TERM_PROGRAM -eq "vscode"
$IsWindowsTerminal = $env:WT_SESSION -ne $null
$IsConhost = (-not $IsVSCode) -and (-not $IsWindowsTerminal)

Write-Host "Detection Results:" -ForegroundColor Green
Write-Host "  VS Code Terminal: $IsVSCode"
Write-Host "  Windows Terminal: $IsWindowsTerminal"
Write-Host "  Classic Conhost:  $IsConhost"
Write-Host ""

Write-Host "Recommended Behavior:"
if ($IsVSCode) {
    Write-Host "  → Run INLINE (stay in VS Code terminal)" -ForegroundColor Cyan
} else {
    Write-Host "  → Launch NEW TERMINAL (better isolation)" -ForegroundColor Cyan
}
