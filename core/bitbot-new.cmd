@echo off
REM BitBot Windows Entry Point (Minimal)
REM Delegates all logic to bash scripts in BitBot-Alpine WSL

REM Check WSL installed
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: WSL not found. Install from: https://aka.ms/wsl2
    exit /b 1
)

REM Check BitBot-Alpine exists (no UTF-16 parsing needed!)
wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% neq 0 (
    REM Not installed - run bootstrap
    call "%~dp0install-bitbot.cmd"
    if %ERRORLEVEL% neq 0 (
        echo Installation failed
        exit /b 1
    )
)

REM Launch BitBot in WSL (bash handles everything)
if "%~1"=="" (
    wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot work
) else (
    wsl -d BitBot-Alpine /opt/bitbot/bin/bitbot %*
)

exit /b %ERRORLEVEL%
