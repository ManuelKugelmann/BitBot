@echo off
REM BitBot Windows Entry Point (Minimal)
REM Delegates all logic to bash scripts in BitBot-Alpine WSL

REM Check WSL installed
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WSL not found.
    echo.
    echo BitBot requires WSL2 to run.
    echo.
    set /p INSTALL="Install WSL2 now? (requires admin ^& reboot) (Y/n): "

    if /i "%INSTALL%"=="n" (
        echo.
        echo Manual install: https://aka.ms/wsl2
        exit /b 1
    )

    echo.
    echo Installing WSL2 (this may take a few minutes)...
    wsl --install

    if %ERRORLEVEL% neq 0 (
        echo.
        echo Installation failed. Try manual install: https://aka.ms/wsl2
        exit /b 1
    )

    echo.
    echo WSL2 installed! Please REBOOT Windows, then run bitbot again.
    echo.
    pause
    exit /b 0
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
