@echo off
:: Create Desktop Shortcuts for MCP Services
:: Run this script to create desktop shortcuts

echo Creating desktop shortcuts for MCP services...

:: Get desktop path
set DESKTOP=%USERPROFILE%\Desktop

:: Create Start MCP Services shortcut
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Start MCP Services.lnk'); $Shortcut.TargetPath = 'C:\DevEnvironments\mcp-services\scripts\start-mcp.bat'; $Shortcut.WorkingDirectory = 'C:\DevEnvironments\mcp-services'; $Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,137'; $Shortcut.Description = 'Start MCP Services for DevContainers'; $Shortcut.Save()"

:: Create Stop MCP Services shortcut
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Stop MCP Services.lnk'); $Shortcut.TargetPath = 'C:\DevEnvironments\mcp-services\scripts\stop-mcp.bat'; $Shortcut.WorkingDirectory = 'C:\DevEnvironments\mcp-services'; $Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,131'; $Shortcut.Description = 'Stop MCP Services'; $Shortcut.Save()"

:: Create MCP Registry shortcut (opens in browser)
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\MCP Registry.lnk'); $Shortcut.TargetPath = 'http://localhost:8080'; $Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,14'; $Shortcut.Description = 'Open MCP Registry Web Interface'; $Shortcut.Save()"

echo.
echo ✅ Desktop shortcuts created:
echo   📱 Start MCP Services.lnk
echo   📱 Stop MCP Services.lnk  
echo   📱 MCP Registry.lnk
echo.
echo 🎯 You can now use these shortcuts to manage MCP services!

pause