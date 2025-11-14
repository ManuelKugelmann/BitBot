@echo off
REM Test: Fresh BitBot-Alpine Installation
REM Purpose: Simulate fresh install by unregistering existing Alpine
REM WARNING: This DESTROYS existing BitBot-Alpine distro!

echo.
echo ==========================================
echo  Test: Fresh BitBot-Alpine Installation
echo ==========================================
echo.
echo WARNING: This will UNREGISTER existing BitBot-Alpine!
echo.
set /p CONTINUE="Continue? (Y/n): "

if /i "%CONTINUE%"=="n" (
    echo Test cancelled.
    exit /b 0
)

echo.
echo [1/5] Creating backup (if exists)...
wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   Backing up existing Alpine...
    wsl -d BitBot-Alpine --export "%TEMP%\bitbot-alpine-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%.tar"
    if %ERRORLEVEL% neq 0 (
        echo   [!] Backup failed, but continuing...
    ) else (
        echo   [+] Backup saved to: %TEMP%\bitbot-alpine-backup-*.tar
    )
) else (
    echo   [i] No existing Alpine to backup
)

echo.
echo [2/5] Unregistering BitBot-Alpine...
wsl --unregister BitBot-Alpine >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [i] Alpine not registered (fresh state)
) else (
    echo   [+] Alpine unregistered
)

echo.
echo [3/5] Verifying Alpine removed...
wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   [X] FAIL: Alpine still exists!
    exit /b 1
) else (
    echo   [+] Alpine removed successfully
)

echo.
echo [4/5] Running fresh install: bitbot work
echo.
echo ==========================================
call bitbot work
set BITBOT_EXIT=%ERRORLEVEL%

echo.
echo ==========================================
echo.
echo [5/5] Validating installation...

if %BITBOT_EXIT% neq 0 (
    echo   [X] FAIL: bitbot work exited with code %BITBOT_EXIT%
    exit /b 1
)

wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: BitBot-Alpine not created
    exit /b 1
) else (
    echo   [+] BitBot-Alpine exists
)

wsl -d BitBot-Alpine which bash >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: bash not installed
    exit /b 1
) else (
    echo   [+] bash installed
)

wsl -d BitBot-Alpine which git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: git not installed
    exit /b 1
) else (
    echo   [+] git installed
)

wsl -d BitBot-Alpine which docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: docker-cli not installed
    exit /b 1
) else (
    echo   [+] docker-cli installed
)

wsl -d BitBot-Alpine which node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: nodejs not installed
    exit /b 1
) else (
    echo   [+] nodejs installed
)

wsl -d BitBot-Alpine which jq >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: jq not installed
    exit /b 1
) else (
    echo   [+] jq installed
)

wsl -d BitBot-Alpine devcontainer --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [!] WARN: @devcontainers/cli not installed
) else (
    echo   [+] @devcontainers/cli installed
)

echo.
echo ==========================================
echo  Test Result: PASS
echo ==========================================
echo.
echo Fresh installation completed successfully!
echo.

exit /b 0
