# test-docker.ps1 - Check Docker Desktop prerequisites

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Docker Desktop Check"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker Desktop is installed
Write-Host "[>] Checking if Docker Desktop is installed..." -ForegroundColor Cyan
$DockerExe = Get-Command docker -ErrorAction SilentlyContinue

if (-not $DockerExe) {
    Write-Host "[X] Docker not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://www.docker.com/products/docker-desktop/"
    Write-Host "  2. Install and restart computer"
    Write-Host "  3. Enable WSL 2 backend in Docker Desktop settings"
    exit 1
}

Write-Host "[+] Docker Desktop installed" -ForegroundColor Green
Write-Host "[i] Location: $($DockerExe.Source)" -ForegroundColor Gray
Write-Host ""

# Check if Docker is running
Write-Host "[>] Checking if Docker is running..." -ForegroundColor Cyan
$DockerPs = docker ps 2>&1

if ($DockerPs -match "error during connect" -or $DockerPs -match "daemon is not running") {
    Write-Host "[X] Docker Desktop is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  1. Open Docker Desktop from Start menu"
    Write-Host "  2. Wait ~30 seconds for startup"
    Write-Host "  3. System tray should show 'Docker Desktop is running'"
    Write-Host ""
    exit 1
}

Write-Host "[+] Docker Desktop is running" -ForegroundColor Green
Write-Host ""

# Check Docker version
Write-Host "[>] Docker version:" -ForegroundColor Cyan
docker version --format "  Client: {{.Client.Version}}`n  Server: {{.Server.Version}}"
Write-Host ""

# Check if WSL 2 backend is enabled
Write-Host "[>] Checking WSL integration..." -ForegroundColor Cyan
$WslDockerCheck = wsl bash -l -c "docker ps 2>&1"

if ($WslDockerCheck -match "Cannot connect" -or $WslDockerCheck -match "Is the docker daemon running" -or $WslDockerCheck -match "could not be found") {
    Write-Host "[!] Docker not accessible from WSL" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Enable WSL 2 integration:" -ForegroundColor Yellow
    Write-Host "  1. Open Docker Desktop"
    Write-Host "  2. Settings > Resources > WSL Integration"
    Write-Host "  3. Enable 'Ubuntu' (or your WSL distro)"
    Write-Host "  4. Click 'Apply & Restart'"
    Write-Host ""
    exit 1
}

Write-Host "[+] Docker accessible from WSL" -ForegroundColor Green
Write-Host ""

# Show running containers
Write-Host "[>] Running containers:" -ForegroundColor Cyan
$Containers = docker ps --format "  {{.Names}}: {{.Image}}"
if ($Containers) {
    Write-Host $Containers
} else {
    Write-Host "  (none)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Docker Desktop: Ready!"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[+] All checks passed" -ForegroundColor Green
Write-Host "[i] Ready to run devcontainer tests" -ForegroundColor Gray
