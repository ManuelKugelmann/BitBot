# Create Direct Shortcut Files for MCP Services
# Creates .lnk files that can be dragged to desktop, taskbar, or any location

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
# Use BITBOT_HOME if set, otherwise default to $BitBotRoot
if ($env:BITBOT_HOME) {
    $ShortcutDir = "$env:BITBOT_HOME\shortcuts"
    $BitBotRoot = $env:BITBOT_HOME
} else {
    $ShortcutDir = "$BitBotRoot\shortcuts"
    $BitBotRoot = "$BitBotRoot"
}

Write-Host "Creating MCP Service Shortcuts..." -ForegroundColor Cyan
Write-Host "Location: $ShortcutDir" -ForegroundColor Gray

# Create WScript Shell object
$WshShell = New-Object -comObject WScript.Shell

# 1. Start MCP Services Shortcut
Write-Host "Creating 'Start MCP Services.lnk'..." -ForegroundColor Green
$StartShortcut = $WshShell.CreateShortcut("$ShortcutDir\Start MCP Services.lnk")
$StartShortcut.TargetPath = "$BitBotRoot\scripts\windows\start-mcp.bat"
$StartShortcut.WorkingDirectory = "$BitBotRoot"
$StartShortcut.IconLocation = "C:\Windows\System32\shell32.dll,137"
$StartShortcut.Description = "Start Global MCP Services for DevContainers"
$StartShortcut.WindowStyle = 1
$StartShortcut.Save()

# 2. Stop MCP Services Shortcut
Write-Host "Creating 'Stop MCP Services.lnk'..." -ForegroundColor Green
$StopShortcut = $WshShell.CreateShortcut("$ShortcutDir\Stop MCP Services.lnk")
$StopShortcut.TargetPath = "$BitBotRoot\scripts\windows\stop-mcp.bat"
$StopShortcut.WorkingDirectory = "$BitBotRoot"
$StopShortcut.IconLocation = "C:\Windows\System32\shell32.dll,131"
$StopShortcut.Description = "Stop Global MCP Services"
$StopShortcut.WindowStyle = 1
$StopShortcut.Save()

# 3. MCP Registry Web Interface Shortcut
Write-Host "Creating 'MCP Registry.lnk'..." -ForegroundColor Green
$RegistryShortcut = $WshShell.CreateShortcut("$ShortcutDir\MCP Registry.lnk")
$RegistryShortcut.TargetPath = "http://localhost:8080"
$RegistryShortcut.IconLocation = "C:\Windows\System32\shell32.dll,14"
$RegistryShortcut.Description = "Open MCP Registry Web Interface (http://localhost:8080)"
$RegistryShortcut.Save()

# 4. Test Workflow Shortcut
Write-Host "Creating 'Test MCP System.lnk'..." -ForegroundColor Green
$TestShortcut = $WshShell.CreateShortcut("$ShortcutDir\Test MCP System.lnk")
$TestShortcut.TargetPath = "$BitBotRoot\scripts\windows\test-workflow.bat"
$TestShortcut.WorkingDirectory = "$BitBotRoot"
$TestShortcut.IconLocation = "C:\Windows\System32\shell32.dll,23"
$TestShortcut.Description = "Test the entire MCP system workflow"
$TestShortcut.WindowStyle = 1
$TestShortcut.Save()

# 5. Open BitBot Folder Shortcut
Write-Host "Creating 'BitBot Folder.lnk'..." -ForegroundColor Green
$FolderShortcut = $WshShell.CreateShortcut("$ShortcutDir\BitBot Folder.lnk")
$FolderShortcut.TargetPath = "$BitBotRoot"
$FolderShortcut.IconLocation = "C:\Windows\System32\shell32.dll,4"
$FolderShortcut.Description = "Open BitBot folder in Explorer"
$FolderShortcut.Save()

# 6. Start WSL2 MCP Services (if WSL2 is available)
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "Creating 'Start MCP Services (WSL2).lnk'..." -ForegroundColor Green
    $WSLStartShortcut = $WshShell.CreateShortcut("$ShortcutDir\Start MCP Services (WSL2).lnk")
    $WSLStartShortcut.TargetPath = "wsl"
    $WSLStartShortcut.Arguments = "-e bash -c 'cd /mnt/c/BitBot && ./scripts/linux/start-mcp.sh; read -p ""Press Enter to close...""'"
    $WSLStartShortcut.WorkingDirectory = "$BitBotRoot"
    $WSLStartShortcut.IconLocation = "C:\Windows\System32\shell32.dll,165"
    $WSLStartShortcut.Description = "Start MCP Services using WSL2"
    $WSLStartShortcut.WindowStyle = 1
    $WSLStartShortcut.Save()
    
    # 7. Stop WSL2 MCP Services
    Write-Host "Creating 'Stop MCP Services (WSL2).lnk'..." -ForegroundColor Green
    $WSLStopShortcut = $WshShell.CreateShortcut("$ShortcutDir\Stop MCP Services (WSL2).lnk")
    $WSLStopShortcut.TargetPath = "wsl"
    $WSLStopShortcut.Arguments = "-e bash -c 'cd /mnt/c/BitBot && ./scripts/linux/stop-mcp.sh'"
    $WSLStopShortcut.WorkingDirectory = "$BitBotRoot"
    $WSLStopShortcut.IconLocation = "C:\Windows\System32\shell32.dll,28"
    $WSLStopShortcut.Description = "Stop MCP Services using WSL2"
    $WSLStopShortcut.WindowStyle = 1
    $WSLStopShortcut.Save()
    
    # 8. Test WSL2 Workflow
    Write-Host "Creating 'Test MCP System (WSL2).lnk'..." -ForegroundColor Green
    $WSLTestShortcut = $WshShell.CreateShortcut("$ShortcutDir\Test MCP System (WSL2).lnk")
    $WSLTestShortcut.TargetPath = "wsl"
    $WSLTestShortcut.Arguments = "-e bash -c 'cd /mnt/c/BitBot && ./scripts/linux/test-workflow.sh; read -p ""Press Enter to close...""'"
    $WSLTestShortcut.WorkingDirectory = "$BitBotRoot"
    $WSLTestShortcut.IconLocation = "C:\Windows\System32\shell32.dll,24"
    $WSLTestShortcut.Description = "Test MCP System workflow using WSL2"
    $WSLTestShortcut.WindowStyle = 1
    $WSLTestShortcut.Save()
} else {
    Write-Host "WSL2 not detected, skipping WSL2 shortcuts..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Shortcuts created successfully!" -ForegroundColor Green
Write-Host "Location: $ShortcutDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available shortcuts:" -ForegroundColor White
Write-Host "  Start MCP Services.lnk" -ForegroundColor Gray
Write-Host "  Stop MCP Services.lnk" -ForegroundColor Gray
Write-Host "  MCP Registry.lnk" -ForegroundColor Gray
Write-Host "  Test MCP System.lnk" -ForegroundColor Gray
Write-Host "  BitBot Folder.lnk" -ForegroundColor Gray
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "  Start MCP Services (WSL2).lnk" -ForegroundColor Gray
    Write-Host "  Stop MCP Services (WSL2).lnk" -ForegroundColor Gray
    Write-Host "  Test MCP System (WSL2).lnk" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Drag these .lnk files to Desktop, Taskbar, or any folder" -ForegroundColor Yellow

# Cleanup
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null