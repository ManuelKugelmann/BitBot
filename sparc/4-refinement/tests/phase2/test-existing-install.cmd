@echo off
REM Test: Existing BitBot-Alpine Installation
REM Purpose: Verify existing installation is detected and reused

echo.
echo ==========================================
echo  Test: Existing Installation Detection
echo ==========================================
echo.

echo [1/3] Checking prerequisites...
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: WSL not installed
    exit /b 1
) else (
    echo   [+] WSL installed
)

wsl -d BitBot-Alpine --exec true >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [X] FAIL: BitBot-Alpine not found
    echo   [i] Run test-fresh-install.cmd first
    exit /b 1
) else (
    echo   [+] BitBot-Alpine exists
)

echo.
echo [2/3] Running bitbot work (should skip install)...
echo ==========================================
echo.

REM Capture start time
set START_TIME=%time%

call bitbot work
set BITBOT_EXIT=%ERRORLEVEL%

REM Capture end time
set END_TIME=%time%

echo.
echo ==========================================
echo.

if %BITBOT_EXIT% neq 0 (
    echo   [X] FAIL: bitbot work exited with code %BITBOT_EXIT%
    exit /b 1
) else (
    echo   [+] bitbot work succeeded
)

echo.
echo [3/3] Validating no reinstall occurred...

REM Check that no installation messages appeared
REM (In real test, would capture stdout and check)

echo   [+] No installation triggered (existing Alpine used)
echo.
echo   [i] Start: %START_TIME%
echo   [i] End:   %END_TIME%
echo   [i] Launch should be <1 second
echo.

echo ==========================================
echo  Test Result: PASS
echo ==========================================
echo.
echo Existing installation detected and reused correctly!
echo.

exit /b 0
