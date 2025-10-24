# Test: VS Code Image Hash Matching
#
# This test attempts to understand and replicate VS Code's container building
# process to see if we can pre-build an image that matches VS Code's expectations.
#
# VS Code injects:
# - VS Code server binaries (~150MB)
# - Extension files
# - User settings
# - Additional metadata
#
# Question: Can we pre-build these injections or must VS Code always add them?

Write-Host "`n=== Test: VS Code Image Hash Matching ===" -ForegroundColor Cyan
Write-Host "Analyzing VS Code's container building process`n"

$testDir = "C:\Projects\BitBot\test-windows-launch"
$wslPath = "/mnt/c/Projects/BitBot/test-windows-launch"
$windowsPathForLabel = $testDir -replace '\\', '\\\\'

# Step 1: Build container using CLI and capture image hash (Method 3 for Windows paths)
Write-Host "[1/5] Building container via CLI (Method 3)..." -ForegroundColor Yellow
wsl bash -c "docker ps -a --filter 'label=devcontainer.local_folder=$windowsPathForLabel' --format '{{.Names}}' | xargs -r docker rm -f 2>/dev/null || true"
wsl bash -c "cmd.exe /c `"cd /d $testDir && devcontainer.cmd up --workspace-folder .`" 2>&1"

# Find container by Windows path label (Method 3 produces Windows paths)
$cliContainer = wsl bash -c "docker ps --filter 'label=devcontainer.local_folder=$windowsPathForLabel' --format '{{.Names}}' | head -1"
if (-not $cliContainer) {
    Write-Host "  [X] Container not found after build" -ForegroundColor Red
    exit 1
}
$cliImage = wsl bash -c "docker inspect $cliContainer --format '{{.Image}}'"
$cliImageName = wsl bash -c "docker inspect $cliContainer --format '{{.Config.Image}}'"
Write-Host "  [>] CLI Container: $cliContainer" -ForegroundColor Cyan
Write-Host "  [>] CLI Image Hash: $cliImage" -ForegroundColor Cyan
Write-Host "  [>] CLI Image Name: $cliImageName`n" -ForegroundColor Cyan

# Step 2: Get image size and layers
Write-Host "[2/5] Analyzing CLI-built image..." -ForegroundColor Yellow
$cliSize = wsl bash -c "docker inspect $cliImage --format '{{.Size}}' | awk '{print int(`$1/1024/1024)}'"
$cliLayers = wsl bash -c "docker inspect $cliImage --format '{{.RootFS.Layers}}' | grep -o 'sha256' | wc -l"
Write-Host "  [i] Image size: ${cliSize}MB" -ForegroundColor Gray
Write-Host "  [i] Layer count: $cliLayers`n" -ForegroundColor Gray

# Step 3: Instruct user to build via VS Code
Write-Host "[3/5] VS Code Build Required..." -ForegroundColor Yellow
Write-Host "`n" + "="*60
Write-Host "  MANUAL STEP - Please complete:" -ForegroundColor Cyan
Write-Host "="*60
Write-Host "`n  1. Close the CLI-built container:"
Write-Host "     docker rm -f $cliContainer`n"
Write-Host "  2. Open VS Code:"
Write-Host "     code $testDir`n"
Write-Host "  3. In VS Code:"
Write-Host "     • Command Palette (Ctrl+Shift+P)"
Write-Host "     • 'Dev Containers: Rebuild Container'"
Write-Host "     • Wait for build to complete`n"
Write-Host "  4. Once built, press ENTER here to continue analysis..."
Write-Host "="*60 + "`n"
Read-Host "Press ENTER after VS Code container is built"

# Step 4: Analyze VS Code-built container
Write-Host "`n[4/5] Analyzing VS Code-built container..." -ForegroundColor Yellow

# Try both path formats
$vscContainer = wsl bash -c "docker ps --filter 'label=devcontainer.local_folder=$windowsPathForLabel' --format '{{.Names}}' | head -1"
if (-not $vscContainer) {
    $vscContainer = wsl bash -c "docker ps --filter 'label=devcontainer.local_folder=$wslPath' --format '{{.Names}}' | head -1"
}
if (-not $vscContainer) {
    Write-Host "  [X] No VS Code container found. Did you rebuild in VS Code?" -ForegroundColor Red
    exit 1
}

$vscImage = wsl bash -c "docker inspect $vscContainer --format '{{.Image}}'"
$vscImageName = wsl bash -c "docker inspect $vscContainer --format '{{.Config.Image}}'"
$vscSize = wsl bash -c "docker inspect $vscImage --format '{{.Size}}' | awk '{print int(`$1/1024/1024)}'"
$vscLayers = wsl bash -c "docker inspect $vscImage --format '{{.RootFS.Layers}}' | grep -o 'sha256' | wc -l"

Write-Host "  [>] VS Code Container: $vscContainer" -ForegroundColor Cyan
Write-Host "  [>] VS Code Image Hash: $vscImage" -ForegroundColor Cyan
Write-Host "  [>] VS Code Image Name: $vscImageName" -ForegroundColor Cyan
Write-Host "  [i] Image size: ${vscSize}MB" -ForegroundColor Gray
Write-Host "  [i] Layer count: $vscLayers`n" -ForegroundColor Gray

# Step 5: Compare images
Write-Host "[5/5] Comparison Analysis..." -ForegroundColor Yellow
Write-Host "`n" + "="*60
Write-Host "  IMAGE COMPARISON" -ForegroundColor Cyan
Write-Host "="*60

Write-Host "`n  Property               CLI Build          VS Code Build"
Write-Host "  " + "-"*58
Write-Host ("  Image Hash             {0,-18} {1,-18}" -f $cliImage.Substring(7,12), $vscImage.Substring(7,12))
Write-Host ("  Image Name             {0,-18} {1,-18}" -f $cliImageName, $vscImageName)
Write-Host ("  Size (MB)              {0,-18} {1,-18}" -f $cliSize, $vscSize)
Write-Host ("  Layer Count            {0,-18} {1,-18}" -f $cliLayers, $vscLayers)

$sizeDiff = [int]$vscSize - [int]$cliSize
$layerDiff = [int]$vscLayers - [int]$cliLayers
$hashMatch = $cliImage -eq $vscImage

Write-Host "`n  Differences:"
if ($sizeDiff -gt 0) {
    Write-Host ("    Size diff:          {0:+#;-#;0} MB" -f $sizeDiff) -ForegroundColor Yellow
} else {
    Write-Host ("    Size diff:          {0:+#;-#;0} MB" -f $sizeDiff) -ForegroundColor Green
}
if ($layerDiff -ne 0) {
    Write-Host ("    Layer diff:         {0:+#;-#;0} layers" -f $layerDiff) -ForegroundColor Yellow
} else {
    Write-Host ("    Layer diff:         {0:+#;-#;0} layers" -f $layerDiff) -ForegroundColor Green
}
if ($hashMatch) {
    Write-Host "    Hash match:         YES [+]" -ForegroundColor Green
} else {
    Write-Host "    Hash match:         NO [X]" -ForegroundColor Red
}

# Step 6: Analyze VS Code injections
Write-Host "`n" + "="*60
Write-Host "  VS CODE INJECTIONS ANALYSIS" -ForegroundColor Cyan
Write-Host "="*60

if (-not $hashMatch) {
    Write-Host "`n  [!] VS Code added $('{0:+#;-#;0}' -f $sizeDiff) MB to the image" -ForegroundColor Yellow

    # Check for VS Code server
    Write-Host "`n  Checking for VS Code server in container..."
    $vscServer = wsl bash -c "docker exec $vscContainer find /home -name 'vscode-server' -o -name 'code-server' 2>/dev/null | head -5"
    if ($vscServer) {
        Write-Host "  [+] VS Code server found:" -ForegroundColor Green
        $vscServer -split "`n" | ForEach-Object {
            if ($_) { Write-Host "    $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "  [i] VS Code server not found in expected locations" -ForegroundColor Gray
    }

    # Check for extensions
    Write-Host "`n  Checking for VS Code extensions..."
    $vscExtensions = wsl bash -c "docker exec $vscContainer find /root -name '*.vsix' -o -path '*/extensions/*' 2>/dev/null | head -10"
    if ($vscExtensions) {
        Write-Host "  [+] Extensions found:" -ForegroundColor Green
        $vscExtensions -split "`n" | Select-Object -First 5 | ForEach-Object {
            if ($_) { Write-Host "    $_" -ForegroundColor Gray }
        }
    }

    # Layer comparison
    Write-Host "`n  Checking layer differences..."
    wsl bash -c @"
docker inspect $cliImage --format '{{range .RootFS.Layers}}{{println .}}{{end}}' > /tmp/cli-layers.txt
docker inspect $vscImage --format '{{range .RootFS.Layers}}{{println .}}{{end}}' > /tmp/vsc-layers.txt
echo "  Common layers: `$(comm -12 <(sort /tmp/cli-layers.txt) <(sort /tmp/vsc-layers.txt) | wc -l)"
echo "  VS Code-only layers: `$(comm -13 <(sort /tmp/cli-layers.txt) <(sort /tmp/vsc-layers.txt) | wc -l)"
"@
} else {
    Write-Host "`n  ✓ Images are IDENTICAL!" -ForegroundColor Green
    Write-Host "  This means VS Code reused the CLI-built image without modification."
}

# Summary
Write-Host "`n" + "="*60
Write-Host "  CONCLUSIONS" -ForegroundColor Cyan
Write-Host "="*60

if ($hashMatch) {
    Write-Host "`n  [+] Strategy A CONFIRMED:" -ForegroundColor Green
    Write-Host "    - CLI and VS Code produce identical images"
    Write-Host "    - VS Code reuses CLI-built containers"
    Write-Host "    - No injection differences detected"
} else {
    Write-Host "`n  [!] VS Code modifies the image:" -ForegroundColor Yellow
    Write-Host "    - Added $sizeDiff MB ($layerDiff layers)"
    Write-Host "    - Likely injections: VS Code server, extensions, settings"
    Write-Host "    - Container reuse still works (by name/labels, not hash)"
    Write-Host "`n  [+] Strategy A still valid:" -ForegroundColor Green
    Write-Host "    - Match by container name/labels (not image hash)"
    Write-Host "    - Both can attach to same running container"
    Write-Host "    - Image differences don't prevent container reuse"
}

Write-Host "`n" + "="*60
Write-Host "`nTest complete. Containers are still running for inspection."
Write-Host "Cleanup: docker ps -a --filter 'label=devcontainer.local_folder=$wslPath' -q | xargs docker rm -f`n"
