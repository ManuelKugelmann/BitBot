@echo off
REM BitBot-Alpine WSL Installation Bootstrap
REM Minimal CMD script - delegates setup to bash

echo.
echo ==========================================
echo  BitBot-Alpine WSL Installer
echo ==========================================
echo.

set "DISTRO_NAME=BitBot-Alpine"
set "INSTALL_PATH=%LOCALAPPDATA%\WSL\%DISTRO_NAME%"
set "ALPINE_VERSION=3.19"
set "ALPINE_URL=https://dl-cdn.alpinelinux.org/alpine/v%ALPINE_VERSION%/releases/x86_64/alpine-minirootfs-%ALPINE_VERSION%.1-x86_64.tar.gz"
set "TEMP_FILE=%TEMP%\alpine-bitbot.tar.gz"

REM Download Alpine rootfs
echo [^>] Downloading Alpine Linux rootfs...
curl -L -o "%TEMP_FILE%" "%ALPINE_URL%"
if %ERRORLEVEL% neq 0 (
    echo [X] Download failed
    exit /b 1
)
echo [+] Downloaded
echo.

REM Import WSL distro
echo [^>] Importing WSL distro...
mkdir "%INSTALL_PATH%" 2>nul
wsl --import %DISTRO_NAME% "%INSTALL_PATH%" "%TEMP_FILE%" --version 2
if %ERRORLEVEL% neq 0 (
    echo [X] Import failed
    del "%TEMP_FILE%" 2>nul
    exit /b 1
)
echo [+] Import successful
echo.

REM Copy setup scripts into WSL
echo [^>] Installing BitBot setup scripts...
set "SETUP_SCRIPT=%~dp0..\container\bitbot\setup-bitbot.sh"
set "DOCKER_SCRIPT=%~dp0..\container\bitbot\lib\enable-docker-integration.sh"

REM Create directories in WSL
wsl -d %DISTRO_NAME% mkdir -p /opt/bitbot/lib

REM Copy scripts (from Windows to WSL)
if exist "%SETUP_SCRIPT%" (
    wsl -d %DISTRO_NAME% sh -c "cat > /opt/bitbot/setup-bitbot.sh" < "%SETUP_SCRIPT%"
    wsl -d %DISTRO_NAME% chmod +x /opt/bitbot/setup-bitbot.sh
) else (
    echo [!] Setup script not found: %SETUP_SCRIPT%
)

if exist "%DOCKER_SCRIPT%" (
    wsl -d %DISTRO_NAME% sh -c "cat > /opt/bitbot/lib/enable-docker-integration.sh" < "%DOCKER_SCRIPT%"
    wsl -d %DISTRO_NAME% chmod +x /opt/bitbot/lib/enable-docker-integration.sh
) else (
    echo [!] Docker integration script not found: %DOCKER_SCRIPT%
)

echo [+] Scripts installed
echo.

REM Run setup inside WSL (bash does all the work!)
echo [^>] Running BitBot setup in WSL...
echo.
wsl -d %DISTRO_NAME% /opt/bitbot/setup-bitbot.sh
if %ERRORLEVEL% neq 0 (
    echo [X] Setup failed
    del "%TEMP_FILE%" 2>nul
    exit /b 1
)

REM Clean up
del "%TEMP_FILE%" 2>nul

echo.
echo ==========================================
echo  Installation Complete!
echo ==========================================
echo.
echo BitBot-Alpine is ready. Run: bitbot work
echo.

exit /b 0
