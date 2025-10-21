# Stop Docker Desktop for Testing
# This script stops Docker Desktop and prevents auto-restart

Write-Host "`n=== Stopping Docker Desktop for Testing ===" -ForegroundColor Cyan
Write-Host ""

# Method 1: Use Docker Desktop CLI to quit
Write-Host "[1/3] Sending quit command via Docker Desktop CLI..." -ForegroundColor Yellow

$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktopPath) {
    # Docker Desktop has a --quit command
    Start-Process -FilePath $dockerDesktopPath -ArgumentList "--quit" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "  ✓ Quit command sent" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Docker Desktop.exe not found at default path" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Method 2: Stop all Docker processes
Write-Host "`n[2/3] Stopping Docker processes..." -ForegroundColor Yellow

$processes = @(
    "Docker Desktop",
    "com.docker.backend",
    "com.docker.proxy",
    "vpnkit",
    "com.docker.dev-envs",
    "docker",
    "dockerd"
)

foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc..." -ForegroundColor Gray
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  ✓ Processes stopped" -ForegroundColor Green

Start-Sleep -Seconds 2

# Method 3: Stop Docker services
Write-Host "`n[3/3] Stopping Docker services..." -ForegroundColor Yellow

$services = @(
    "com.docker.service",
    "docker"
)

foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "  Stopping service: $svc..." -ForegroundColor Gray
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  ✓ Services stopped" -ForegroundColor Green

# Wait for full shutdown
Write-Host "`nWaiting 5 seconds for complete shutdown..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Verify Docker is stopped
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
Write-Host ""

$dockerTest = docker ps 2>&1
$dockerExitCode = $LASTEXITCODE

if ($dockerExitCode -ne 0) {
    Write-Host "✓ Docker is STOPPED (docker ps fails)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Error message from docker ps:" -ForegroundColor White
    Write-Host "  $dockerTest" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✓ Ready for testing Docker auto-start!" -ForegroundColor Green
} else {
    Write-Host "⚠ Docker appears to still be running" -ForegroundColor Yellow
    Write-Host "  docker ps succeeded - Docker Desktop may have auto-restarted" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Trying more aggressive shutdown..." -ForegroundColor Yellow

    # Kill with taskkill
    taskkill /F /IM "Docker Desktop.exe" 2>$null
    taskkill /F /IM "com.docker.backend.exe" 2>$null

    Start-Sleep -Seconds 3

    $dockerTest2 = docker ps 2>&1
    $dockerExitCode2 = $LASTEXITCODE

    if ($dockerExitCode2 -ne 0) {
        Write-Host "  ✓ Docker stopped after aggressive kill" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Docker still running - auto-restart may be enabled in Docker Desktop settings" -ForegroundColor Red
        Write-Host ""
        Write-Host "To disable auto-start:" -ForegroundColor White
        Write-Host "  1. Open Docker Desktop Settings" -ForegroundColor Gray
        Write-Host "  2. General → Uncheck 'Start Docker Desktop when you log in'" -ForegroundColor Gray
        Write-Host "  3. Resources → Uncheck 'Auto-start Docker Desktop'" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now test Docker auto-start:" -ForegroundColor White
Write-Host "  cd test-windows-launch\tests" -ForegroundColor Gray
Write-Host "  ..\scripts\bitbot.ps1 work" -ForegroundColor Gray
Write-Host ""
Write-Host "Expected behavior:" -ForegroundColor White
Write-Host "  Starting Docker..." -ForegroundColor Gray
Write-Host "  Waiting for Docker to start..." -ForegroundColor Gray
Write-Host "  .......... 10s.......... 20s.......... 30s......" -ForegroundColor Gray
Write-Host "  ✓ Docker is ready (took Xs)" -ForegroundColor Gray
Write-Host ""
