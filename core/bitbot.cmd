@echo off
REM BitBot Windows Entry Point
REM Entry Platform: Windows cmd.exe / PowerShell
REM Forwards all commands to BitBot in WSL Alpine

set "DISTRO_NAME=BitBot-Alpine"

REM Show entry platform info for version command
if "%~1"=="version" (
    echo Entry Point: Windows cmd.exe
)

REM Check if WSL is installed
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: WSL not found. Install from: https://aka.ms/wsl2
    exit /b 1
)

REM Check if BitBot-Alpine exists using PowerShell (handles UTF-16 better)
powershell -NoProfile -Command "$list = wsl --list --quiet | ForEach-Object { $_.Trim() -replace '\x00', '' }; if ($list -contains '%DISTRO_NAME%') { exit 0 } else { exit 1 }" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if "%~1"=="version" (
        echo Using WSL:     %DISTRO_NAME%
    )
)
if %ERRORLEVEL% neq 0 (
    echo BitBot-Alpine WSL distribution not found.
    echo.
    echo BitBot requires a dedicated WSL distribution for isolation.
    echo.
    set /p INSTALL="Install BitBot-Alpine now? (Y/n): "

    if /i "%INSTALL%"=="n" (
        echo Installation cancelled. BitBot requires BitBot-Alpine to run.
        exit /b 1
    )

    echo.
    echo Installing BitBot-Alpine...

    REM Call install script
    set "INSTALL_SCRIPT=%~dp0..\archive\manual-building\install-bitbot-wsl.ps1"
    powershell -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%"

    if %ERRORLEVEL% neq 0 (
        echo Installation failed.
        exit /b 1
    )
)

REM Get script directory and bash script path
set "SCRIPT_DIR=%~dp0"
set "BASH_SCRIPT=%SCRIPT_DIR%bitbot"

REM Execute in BitBot-Alpine WSL using bash -c with wslpath conversion inside bash
REM This avoids Windows path escaping issues
REM TODO: When BitBot is installed in Alpine, use: wsl -d %DISTRO_NAME% /opt/bitbot/bin/bitbot %*
if "%~1"=="" (
    wsl -d %DISTRO_NAME% bash -c "$(wslpath -u '%BASH_SCRIPT%') work"
) else (
    wsl -d %DISTRO_NAME% bash -c "$(wslpath -u '%BASH_SCRIPT%') %*"
)

REM Exit with same code
exit /b %ERRORLEVEL%
