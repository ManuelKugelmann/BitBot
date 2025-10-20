# Debug: What containers exist and what labels do they have?

Write-Host "`n=== Container Discovery Debug ===" -ForegroundColor Cyan

$wslPath = "/mnt/c/Projects/BitBot/test-windows-launch"

# Find ALL containers (not just by label)
Write-Host "`n[1] All running containers:" -ForegroundColor Yellow
wsl bash -c "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

# Find containers related to this folder
Write-Host "`n[2] Containers with 'test-windows-launch' in name:" -ForegroundColor Yellow
$relatedContainers = wsl bash -c "docker ps --format '{{.Names}}' | grep -i 'test-windows-launch' || echo 'None found'"
Write-Host $relatedContainers

# Find containers with devcontainer labels
Write-Host "`n[3] Containers with ANY devcontainer label:" -ForegroundColor Yellow
$devContainers = wsl bash -c "docker ps --filter 'label=devcontainer.metadata' --format '{{.Names}}' || docker ps --filter 'label=vsch.local.folder' --format '{{.Names}}' || echo 'None found'"
Write-Host $devContainers

# Inspect the most recently created container
Write-Host "`n[4] Most recent container details:" -ForegroundColor Yellow
$latestContainer = wsl bash -c "docker ps -l --format '{{.Names}}'"
Write-Host "  Container name: $latestContainer"

if ($latestContainer) {
    Write-Host "`n  All labels on this container:"
    $allLabels = wsl bash -c "docker inspect $latestContainer --format '{{json .Config.Labels}}'"

    # Parse and display nicely
    $labels = $allLabels | ConvertFrom-Json
    $labels.PSObject.Properties | ForEach-Object {
        if ($_.Name -match 'devcontainer|vsc|vsch') {
            Write-Host "    [+] $($_.Name) = $($_.Value)" -ForegroundColor Green
        } else {
            Write-Host "    [i] $($_.Name) = $($_.Value)" -ForegroundColor Gray
        }
    }

    # Check the image
    Write-Host "`n  Image info:"
    $image = wsl bash -c "docker inspect $latestContainer --format '{{.Config.Image}}'"
    $imageHash = wsl bash -c "docker inspect $latestContainer --format '{{.Image}}'"
    Write-Host "    Image name: $image"
    Write-Host "    Image hash: $imageHash"

    # Check workspace mount
    Write-Host "`n  Mounts:"
    wsl bash -c "docker inspect $latestContainer --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{println}}{{end}}'" | ForEach-Object {
        if ($_ -match 'test-windows-launch') {
            Write-Host "    [+] $_" -ForegroundColor Green
        } else {
            Write-Host "    [i] $_" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "If VS Code built a container, it should appear above."
Write-Host "Check the labels to see what VS Code actually uses for discovery.`n"
