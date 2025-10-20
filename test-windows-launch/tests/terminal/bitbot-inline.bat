@echo off
REM bitbot-inline.bat - Inline execution (no new terminal)

echo === BitBot Inline Test ===
echo Current Windows path: %CD%

REM Convert to WSL path
for /f "usebackq tokens=*" %%i in (`wsl wslpath -a "%CD%"`) do set WSLPATH=%%i
echo WSL path: %WSLPATH%
echo.

REM Execute inline - output comes back to this cmd window
wsl bash -c "cd '%WSLPATH%' && ./bitbot.sh"

echo.
echo === Inline execution finished ===
