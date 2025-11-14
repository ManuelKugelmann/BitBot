@echo off
REM Validate BitBot Installation
REM Purpose: Comprehensive validation of all components
REM Run after: Fresh install or to verify existing setup

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo  BitBot Installation Validation
echo ==========================================
echo.

set PASS_COUNT=0
set FAIL_COUNT=0
set WARN_COUNT=0

REM === Windows Layer Tests ===
echo [Windows Layer]
echo.

echo   [1] WSL2 installed...
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo       [X] FAIL
    set /a FAIL_COUNT+=1
) else (
    echo       [+] PASS
    set /a PASS_COUNT+=1
)

echo   [2] BitBot.exe exists...
if exist "%~dp0..\..\..\..\core\bitbot.exe" (
    echo       [+] PASS
    set /a PASS_COUNT+=1
) else (
    echo       [!] WARN: bitbot.exe not found
    set /a WARN_COUNT+=1
)

echo   [3] BitBot.cmd exists...
if exist "%~dp0..\..\..\..\core\bitbot.cmd" (
    echo       [+] PASS
    set /a PASS_COUNT+=1
) else (
    echo       [X] FAIL
    set /a FAIL_COUNT+=1
)

echo   [4] install-bitbot.cmd exists...
if exist "%~dp0..\..\..\..\core\install-bitbot.cmd" (
    echo       [+] PASS
    set /a PASS_COUNT+=1
) else (
    echo       [X] FAIL
    set /a FAIL_COUNT+=1
)

echo.
echo [WSL Distro]
echo.

echo   [5] BitBot-Alpine exists...
wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo       [X] FAIL: Distro not found
    set /a FAIL_COUNT+=1
    set ALPINE_EXISTS=0
) else (
    echo       [+] PASS
    set /a PASS_COUNT+=1
    set ALPINE_EXISTS=1
)

if %ALPINE_EXISTS% equ 1 (
    echo.
    echo [Packages]
    echo.

    echo   [6] bash installed...
    wsl -d BitBot-Alpine which bash >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo   [7] git installed...
    wsl -d BitBot-Alpine which git >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo   [8] docker-cli installed...
    wsl -d BitBot-Alpine which docker >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo   [9] nodejs installed...
    wsl -d BitBot-Alpine which node >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [10] npm installed...
    wsl -d BitBot-Alpine which npm >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [11] curl installed...
    wsl -d BitBot-Alpine which curl >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [12] jq installed...
    wsl -d BitBot-Alpine which jq >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [13] @devcontainers/cli installed...
    wsl -d BitBot-Alpine devcontainer --version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo       [!] WARN: Not installed
        set /a WARN_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo.
    echo [Directories]
    echo.

    echo  [14] /opt/bitbot/bin exists...
    wsl -d BitBot-Alpine test -d /opt/bitbot/bin
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [15] /opt/bitbot/lib exists...
    wsl -d BitBot-Alpine test -d /opt/bitbot/lib
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo.
    echo [Scripts]
    echo.

    echo  [16] setup-bitbot.sh exists...
    wsl -d BitBot-Alpine test -f /opt/bitbot/setup-bitbot.sh
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [17] enable-docker-integration.sh exists...
    wsl -d BitBot-Alpine test -f /opt/bitbot/lib/enable-docker-integration.sh
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL
        set /a FAIL_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )

    echo  [18] Scripts executable...
    wsl -d BitBot-Alpine test -x /opt/bitbot/setup-bitbot.sh
    if %ERRORLEVEL% neq 0 (
        echo       [X] FAIL: setup-bitbot.sh not executable
        set /a FAIL_COUNT+=1
    ) else (
        wsl -d BitBot-Alpine test -x /opt/bitbot/lib/enable-docker-integration.sh
        if %ERRORLEVEL% neq 0 (
            echo       [X] FAIL: enable-docker-integration.sh not executable
            set /a FAIL_COUNT+=1
        ) else (
            echo       [+] PASS
            set /a PASS_COUNT+=1
        )
    )

    echo.
    echo [Shell Configuration]
    echo.

    echo  [19] Bash as default shell...
    wsl -d BitBot-Alpine grep -q "/bin/bash" /etc/passwd
    if %ERRORLEVEL% neq 0 (
        echo       [!] WARN: Not configured
        set /a WARN_COUNT+=1
    ) else (
        echo       [+] PASS
        set /a PASS_COUNT+=1
    )
)

echo.
echo ==========================================
echo  Validation Summary
echo ==========================================
echo.
echo   Tests Passed:  %PASS_COUNT%
echo   Tests Failed:  %FAIL_COUNT%
echo   Warnings:      %WARN_COUNT%
echo.

if %FAIL_COUNT% gtr 0 (
    echo   Overall: FAIL
    echo.
    echo   Some components are missing or broken.
    echo   Run: test-fresh-install.cmd to reinstall
    echo.
    exit /b 1
) else if %WARN_COUNT% gtr 0 (
    echo   Overall: PASS (with warnings)
    echo.
    echo   Installation complete but some optional components missing.
    echo.
    exit /b 0
) else (
    echo   Overall: PASS
    echo.
    echo   All components installed correctly!
    echo.
    exit /b 0
)
