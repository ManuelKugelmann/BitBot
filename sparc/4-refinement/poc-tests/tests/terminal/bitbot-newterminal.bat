@echo off
REM bitbot-newterminal.bat - New terminal window

echo === BitBot New Terminal Test ===
echo Current Windows path: %CD%

REM Convert to WSL path
for /f "usebackq tokens=*" %%i in (`wsl wslpath -a "%CD%"`) do set WSLPATH=%%i
echo WSL path: %WSLPATH%
echo.

REM Check if Windows Terminal is available
where wt >nul 2>nul
if %errorlevel% equ 0 (
    echo Using Windows Terminal (wt)
    start wt wsl -e bash -c "cd '%WSLPATH%' && ./bitbot.sh; exec bash -l"
) else (
    echo Using default WSL (new window)
    start wsl -e bash -c "cd '%WSLPATH%' && ./bitbot.sh; exec bash -l"
)

echo New terminal launched!
