# Open-VSCodeDevContainer.ps1
# Utility to launch VS Code into a devcontainer using folder URI
#
# Usage:
#   . .\Open-VSCodeDevContainer.ps1
#   Open-VSCodeDevContainer -WorkspacePath "C:\Path\To\Workspace"

function Open-VSCodeDevContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspacePath,

        [Parameter(Mandatory=$false)]
        [string]$ContainerPath = "/workspace",

        [Parameter(Mandatory=$false)]
        [switch]$Verify
    )

    Write-Host "[>] Launching VS Code in devcontainer..." -ForegroundColor Cyan

    # Resolve to absolute path
    $absPath = (Resolve-Path $WorkspacePath -ErrorAction SilentlyContinue).Path
    if (-not $absPath) {
        $absPath = $WorkspacePath
    }

    Write-Host "    Workspace: $absPath" -ForegroundColor Gray

    # Convert Windows path to hex using PowerShell (avoids bash escaping issues)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($absPath)
    $hexPath = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''

    if ($Verify) {
        Write-Host "    Hex: $hexPath" -ForegroundColor Gray

        # Verify hex decoding
        $decodedBytes = for ($i = 0; $i -lt $hexPath.Length; $i += 2) {
            [Convert]::ToByte($hexPath.Substring($i, 2), 16)
        }
        $decodedPath = [System.Text.Encoding]::UTF8.GetString($decodedBytes)

        if ($decodedPath -ne $absPath) {
            Write-Host "    [X] Path encoding verification failed!" -ForegroundColor Red
            Write-Host "        Expected: $absPath" -ForegroundColor Red
            Write-Host "        Got: $decodedPath" -ForegroundColor Red
            return $false
        }
        Write-Host "    [+] Path encoding verified" -ForegroundColor Green
    }

    # Build devcontainer URI
    $devcontainerUri = "vscode-remote://dev-container+$hexPath$ContainerPath"

    if ($Verify) {
        Write-Host "    URI: $devcontainerUri" -ForegroundColor Gray
    }

    # Launch VS Code
    Start-Process "code" -ArgumentList "--folder-uri", $devcontainerUri -NoNewWindow

    Write-Host "    [+] VS Code launched" -ForegroundColor Green

    return $true
}

# Export function if script is dot-sourced
Export-ModuleMember -Function Open-VSCodeDevContainer
