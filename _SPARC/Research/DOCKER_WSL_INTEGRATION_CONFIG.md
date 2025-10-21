# Docker Desktop WSL Integration Configuration

## Research Date: 2025-10-21

### Manual Configuration (Working)

After manually enabling BitBot-Alpine via Docker Desktop GUI and restarting:

**Settings File**: `%APPDATA%\Docker\settings-store.json`

```json
{
  "AutoStart": false,
  "DisplayedOnboarding": true,
  "EnableDockerAI": true,
  "InferenceCanUseGPUVariant": true,
  "IntegratedWslDistros": [
    "BitBot-Alpine",
    "Ubuntu-22.04"
  ],
  "LastContainerdSnapshotterEnable": 1760964933,
  "LicenseTermsVersion": 2,
  "SettingsVersion": 43,
  "UseContainerdSnapshotter": true,
  "enableIntegrationWithAdditionalDistros": {}
}
```

### Key Fields for WSL Integration

| Field | Value | Purpose |
|-------|-------|---------|
| `IntegratedWslDistros` | Array of distro names | Lists WSL distributions with Docker access |
| `wslEngineEnabled` | `true` (implied) | Enables WSL 2 backend |
| `enableIntegrationWithAdditionalDistros` | Empty object `{}` | Legacy field, kept for compatibility |

### Automated Script Configuration

**Script**: `enable-docker-wsl-integration-simple.ps1`

**What it does**:
1. Reads current settings
2. Enables `wslEngineEnabled: true`
3. Adds distro name to `IntegratedWslDistros` array
4. Ensures `enableIntegrationWithAdditionalDistros` exists (empty)
5. Creates timestamped backup
6. Saves settings with ASCII encoding
7. Attempts to restart Docker Desktop

**Critical Issue**: Docker restart mechanism unreliable
- `--quit` argument doesn't fully terminate Docker
- Settings not reloaded without complete process termination

### Working Docker Stop Method

From `_SPARC/test-windows-launch/tests/stop-docker-for-testing.ps1`:

```powershell
# Method 1: Quit command
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe" `
    -ArgumentList "--quit" -NoNewWindow -Wait

# Method 2: Force stop processes (REQUIRED)
$processes = @(
    "Docker Desktop",
    "com.docker.backend",
    "com.docker.proxy",
    "vpnkit",
    "com.docker.dev-envs",
    "docker",
    "dockerd"
)

foreach ($proc in $processes) {
    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
}

# Method 3: Stop services
Stop-Service -Name "com.docker.service" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "docker" -Force -ErrorAction SilentlyContinue
```

### Verification

**Test Command**:
```bash
wsl -d BitBot-Alpine docker ps
```

**Expected Output** (when working):
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Error Output** (when not integrated):
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

### Comparison: Manual vs Automated

| Aspect | Manual (GUI) | Automated (Script) |
|--------|-------------|-------------------|
| Settings modification | ✅ Correct | ✅ Correct |
| Backup creation | ❌ No backup | ✅ Timestamped backup |
| Docker restart | ✅ Reliable | ❌ Unreliable (`--quit` insufficient) |
| Integration result | ✅ Works | ⚠️ Settings correct but not applied |
| Preserves existing distros | ✅ Yes | ⚠️ Only adds new distro |

### Recommended Improvements

1. **Replace quit command** with force-stop all processes:
   ```powershell
   Stop-Process -Name "Docker Desktop" -Force
   Stop-Process -Name "com.docker.backend" -Force
   ```

2. **Preserve existing IntegratedWslDistros**:
   - Read current array
   - Only add new distro if not present
   - Keep existing distros in array

3. **Increase wait time** after restart:
   - Current: 20 seconds
   - Recommended: 30-40 seconds
   - Add verification loop with timeout

4. **Verify integration** before returning success:
   ```powershell
   $maxAttempts = 15
   for ($i = 0; $i -lt $maxAttempts; $i++) {
       $result = wsl -d $DistroName docker ps 2>&1
       if ($LASTEXITCODE -eq 0) {
           Write-Host "Integration verified!"
           break
       }
       Start-Sleep -Seconds 2
   }
   ```

### Docker Desktop Settings Path

**Windows**: `%APPDATA%\Docker\settings-store.json`

**Full Path**: `C:\Users\{username}\AppData\Roaming\Docker\settings-store.json`

**Alternative**: `settings.json` (older versions)

### Field Reference

Complete settings file typically contains:
- `AutoStart`: Boolean - Start Docker on login
- `DisplayedOnboarding`: Boolean - Onboarding wizard shown
- `IntegratedWslDistros`: Array - WSL distributions with Docker access
- `wslEngineEnabled`: Boolean - WSL 2 backend enabled
- `UseContainerdSnapshotter`: Boolean - Use containerd snapshotter
- `enableIntegrationWithAdditionalDistros`: Object - Legacy compatibility field
- Plus many other Docker Desktop settings

### Testing Notes

- Settings file modification alone is insufficient
- Docker Desktop must fully restart to apply WSL integration
- The `--quit` command is not equivalent to process termination
- Manual restart via GUI consistently works
- Automated restart requires force-stop of all Docker processes

### References

- Docker Desktop Documentation: WSL 2 backend
- Working stop script: `_SPARC/test-windows-launch/tests/stop-docker-for-testing.ps1`
- Helper scripts: `tests/helpers/enable-docker-wsl-integration-simple.ps1`
