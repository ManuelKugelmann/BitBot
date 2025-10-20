@echo off
REM bitbot.bat - cmd.exe launcher test
REM Converts current path to WSL and launches bitbot.sh

echo Current Windows path: %CD%

REM Convert to WSL path
for /f "usebackq tokens=*" %%i in (`wsl wslpath -a "%CD%"`) do set WSLPATH=%%i
echo Converted WSL path: %WSLPATH%
echo Launching WSL terminal...
echo.

REM Check if Windows Terminal is available (simple check)
where wt >nul 2>nul
if %errorlevel% equ 0 (
    echo Using Windows Terminal
    wt -d Ubuntu --cd "%WSLPATH%" bash -l -c "./bitbot.sh"
) else (
    echo Using default WSL terminal
    wsl -d Ubuntu --cd "%WSLPATH%" bash -l -c "./bitbot.sh"
)
