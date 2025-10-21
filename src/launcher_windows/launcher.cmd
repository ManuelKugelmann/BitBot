@echo off
REM Test script for launcher.exe

echo.
echo ========================================
echo Launcher Test
echo ========================================
echo.
echo Script: %~nx0
echo Arguments: %*
echo Working Dir: %CD%
echo.

if "%1"=="" (
    echo No arguments provided
) else (
    echo Processing arguments:
    for %%A in (%*) do echo   - %%A
)

echo.
echo Test successful!
exit /b 0
