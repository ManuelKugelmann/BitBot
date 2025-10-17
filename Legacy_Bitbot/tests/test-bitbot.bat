@echo off
REM BitBot Windows-Specific Test Suite
REM Tests Windows-only functionality

setlocal enabledelayedexpansion

REM Test counters
set TESTS_PASSED=0
set TESTS_FAILED=0

REM Configuration
set BITBOT_ROOT=%~dp0..
for %%i in ("%BITBOT_ROOT%") do set BITBOT_ROOT=%%~fi

goto :main

:log_test
echo [TEST] %~1
goto :eof

:log_pass
set /a TESTS_PASSED+=1
echo   ✓ %~1
goto :eof

:log_fail
set /a TESTS_FAILED+=1
echo   ✗ %~1
goto :eof

:test_polyglot_script
call :log_test "Polyglot script Windows section"

REM Test that PowerShell section executes
powershell -NoProfile -Command "& { $content = Get-Content '%BITBOT_ROOT%\global\bitbot' -Raw; if ($content -match 'PowerShell section') { exit 0 } else { exit 1 } }" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_pass "PowerShell section found in polyglot script"
) else (
    call :log_fail "PowerShell section missing in polyglot script"
)

REM Test PowerShell execution
powershell -NoProfile -Command "Write-Host 'PowerShell test'; exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_pass "PowerShell execution works"
) else (
    call :log_fail "PowerShell execution failed"
)

goto :eof

:test_path_conversion
call :log_test "Windows path conversion"

REM Test WSL path conversion logic
set TEST_PATH=C:\BitBot
set EXPECTED_WSL=/mnt/c/BitBot

REM Simulate path conversion
powershell -NoProfile -Command "& { $path = '%TEST_PATH%'; $drive = $path.Substring(0,1).ToLower(); $pathPart = $path.Substring(2) -replace '\\\\', '/'; $wslPath = \"/mnt/$drive$pathPart\"; if ($wslPath -eq '%EXPECTED_WSL%') { exit 0 } else { exit 1 } }" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_pass "Windows to WSL path conversion works"
) else (
    call :log_fail "Windows to WSL path conversion failed"
)

goto :eof

:test_environment_detection
call :log_test "Windows environment detection"

REM Test Windows environment variables
if defined WINDIR (
    call :log_pass "WINDIR environment variable detected"
) else (
    call :log_fail "WINDIR environment variable missing"
)

if defined COMSPEC (
    call :log_pass "COMSPEC environment variable detected"
) else (
    call :log_fail "COMSPEC environment variable missing"
)

REM Test WSL detection
if defined WSL_DISTRO_NAME (
    call :log_pass "WSL environment detected"
) else (
    call :log_pass "Native Windows environment detected"
)

goto :eof

:test_script_files
call :log_test "Windows script files"

REM Check for install scripts
if exist "%BITBOT_ROOT%\global\install.bat" (
    call :log_pass "Windows install.bat exists"
) else (
    call :log_fail "Windows install.bat missing"
)

REM Check shortcuts
if exist "%BITBOT_ROOT%\global\shortcuts\Create-Shortcuts.bat" (
    call :log_pass "Windows shortcuts script exists"
) else (
    call :log_fail "Windows shortcuts script missing"
)

if exist "%BITBOT_ROOT%\global\shortcuts\Create-Direct-Shortcuts.ps1" (
    call :log_pass "PowerShell shortcuts script exists"
) else (
    call :log_fail "PowerShell shortcuts script missing"
)

goto :eof

:main
echo ================================
echo BitBot Windows-Specific Tests
echo ================================
echo BitBot Root: %BITBOT_ROOT%
echo.

call :test_polyglot_script
echo.

call :test_path_conversion  
echo.

call :test_environment_detection
echo.

call :test_script_files
echo.

echo ================================
echo Test Results
echo ================================
echo Passed: %TESTS_PASSED%
echo Failed: %TESTS_FAILED%
echo.

if !TESTS_FAILED! equ 0 (
    echo ✓ All Windows-specific tests passed!
    exit /b 0
) else (
    echo ✗ Some Windows-specific tests failed.
    exit /b 1
)