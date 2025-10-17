@echo off
REM BitBot Installation Script for Windows
REM Sets up environment variables and PATH

title BitBot Installation

echo.
echo ========================================
echo   BitBot Installation for Windows
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Administrative privileges detected - will set system-wide environment
    set INSTALL_SCOPE=SYSTEM
) else (
    echo [INFO] User privileges - will set user environment variables
    set INSTALL_SCOPE=USER
)

REM Get current directory (where BitBot is installed)
set BITBOT_INSTALL_DIR=%~dp0
REM Remove trailing backslash
if "%BITBOT_INSTALL_DIR:~-1%"=="\" set BITBOT_INSTALL_DIR=%BITBOT_INSTALL_DIR:~0,-1%

echo.
echo [INFO] BitBot installation directory: %BITBOT_INSTALL_DIR%
echo.

REM Check if BITBOT_HOME is already set
if defined BITBOT_HOME (
    echo [INFO] BITBOT_HOME is currently set to: %BITBOT_HOME%
    set /p CONTINUE="Continue with installation? This will update the environment. (Y/n): "
    if /i not "%CONTINUE%"=="Y" if /i not "%CONTINUE%"=="" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)

echo [1/3] Setting BITBOT_HOME environment variable...

REM Set BITBOT_HOME environment variable
if "%INSTALL_SCOPE%"=="SYSTEM" (
    setx BITBOT_HOME "%BITBOT_INSTALL_DIR%" /M >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Failed to set system environment. Falling back to user environment.
        setx BITBOT_HOME "%BITBOT_INSTALL_DIR%" >nul 2>&1
    )
) else (
    setx BITBOT_HOME "%BITBOT_INSTALL_DIR%" >nul 2>&1
)

if errorlevel 1 (
    echo [ERROR] Failed to set BITBOT_HOME environment variable
    pause
    exit /b 1
)

echo [SUCCESS] BITBOT_HOME set to: %BITBOT_INSTALL_DIR%

echo.
echo [2/3] Adding BitBot to PATH...

REM Get current PATH
if "%INSTALL_SCOPE%"=="SYSTEM" (
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set CURRENT_PATH=%%b
) else (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set CURRENT_PATH=%%b
)

REM Check if BitBot is already in PATH
echo %CURRENT_PATH% | findstr /C:"%BITBOT_INSTALL_DIR%" >nul
if not errorlevel 1 (
    echo [INFO] BitBot directory is already in PATH
) else (
    REM Add BitBot to PATH
    if defined CURRENT_PATH (
        set NEW_PATH=%CURRENT_PATH%;%BITBOT_INSTALL_DIR%
    ) else (
        set NEW_PATH=%BITBOT_INSTALL_DIR%
    )
    
    if "%INSTALL_SCOPE%"=="SYSTEM" (
        setx PATH "!NEW_PATH!" /M >nul 2>&1
        if errorlevel 1 (
            echo [WARNING] Failed to set system PATH. Falling back to user PATH.
            setx PATH "!NEW_PATH!" >nul 2>&1
        )
    ) else (
        setx PATH "!NEW_PATH!" >nul 2>&1
    )
    
    if errorlevel 1 (
        echo [ERROR] Failed to update PATH
        pause
        exit /b 1
    )
    
    echo [SUCCESS] Added BitBot to PATH
)

echo.
echo [3/3] Creating desktop shortcuts...

REM Create desktop shortcuts using the existing script
if exist "%BITBOT_INSTALL_DIR%\shortcuts\Create-Direct-Shortcuts.ps1" (
    powershell -ExecutionPolicy Bypass -File "%BITBOT_INSTALL_DIR%\shortcuts\Create-Direct-Shortcuts.ps1" >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Failed to create some shortcuts - you can create them manually later
    ) else (
        echo [SUCCESS] Desktop shortcuts created
    )
) else (
    echo [WARNING] Shortcut creation script not found
)

echo.
echo ========================================
echo   BitBot Installation Complete!
echo ========================================
echo.
echo [SUCCESS] BitBot has been installed successfully!
echo.
echo Environment variables set:
echo   BITBOT_HOME = %BITBOT_INSTALL_DIR%
echo   PATH updated to include BitBot directory
echo.
echo Available commands (after restarting your terminal):
echo   bitbot         - Start BitBot in current directory
echo   bitbot.bat     - Windows-specific launcher
echo   bitbot.sh      - Linux/WSL2 launcher
echo.
echo Shortcuts created in: %BITBOT_INSTALL_DIR%
echo   - Start MCP Services.lnk
echo   - Stop MCP Services.lnk  
echo   - MCP Registry.lnk
echo   - Test MCP System.lnk
echo   - And more...
echo.
echo Next steps:
echo 1. Restart your terminal or command prompt
echo 2. Navigate to any project directory
echo 3. Run 'bitbot' to start your AI development environment
echo.
echo For VS Code integration:
echo 1. Open your project in VS Code
echo 2. Run 'bitbot' from the VS Code terminal
echo 3. Use Ctrl+Shift+P and "Dev Containers: Reopen in Container"
echo.

pause