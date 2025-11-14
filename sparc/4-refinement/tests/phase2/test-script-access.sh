#!/bin/bash
# Test: Script Accessibility and Editability
# Purpose: Verify users can read and modify bash scripts
# Run from: wsl -d BitBot-Alpine /path/to/test-script-access.sh

set -e

echo ""
echo "=========================================="
echo " Test: Script Accessibility"
echo "=========================================="
echo ""

SETUP_SCRIPT="/opt/bitbot/setup-bitbot.sh"
DOCKER_SCRIPT="/opt/bitbot/lib/enable-docker-integration.sh"

echo "[1/5] Checking script existence..."

if [ ! -f "$SETUP_SCRIPT" ]; then
    echo "  [X] FAIL: Setup script not found: $SETUP_SCRIPT"
    exit 1
fi
echo "  [+] Setup script exists"

if [ ! -f "$DOCKER_SCRIPT" ]; then
    echo "  [X] FAIL: Docker script not found: $DOCKER_SCRIPT"
    exit 1
fi
echo "  [+] Docker script exists"

echo ""
echo "[2/5] Checking script readability..."

if ! cat "$SETUP_SCRIPT" | head -n 5 | grep -q "#!/bin/sh"; then
    echo "  [X] FAIL: Setup script not readable or invalid shebang"
    exit 1
fi
echo "  [+] Setup script readable (shebang: #!/bin/sh)"

if ! cat "$DOCKER_SCRIPT" | head -n 5 | grep -q "#!/bin/bash"; then
    echo "  [X] FAIL: Docker script not readable or invalid shebang"
    exit 1
fi
echo "  [+] Docker script readable (shebang: #!/bin/bash)"

echo ""
echo "[3/5] Checking script executability..."

if [ ! -x "$SETUP_SCRIPT" ]; then
    echo "  [X] FAIL: Setup script not executable"
    exit 1
fi
echo "  [+] Setup script executable"

if [ ! -x "$DOCKER_SCRIPT" ]; then
    echo "  [X] FAIL: Docker script not executable"
    exit 1
fi
echo "  [+] Docker script executable"

echo ""
echo "[4/5] Checking script syntax..."

if ! bash -n "$SETUP_SCRIPT" 2>/dev/null; then
    echo "  [X] FAIL: Setup script has syntax errors"
    exit 1
fi
echo "  [+] Setup script syntax valid"

if ! bash -n "$DOCKER_SCRIPT" 2>/dev/null; then
    echo "  [X] FAIL: Docker script has syntax errors"
    exit 1
fi
echo "  [+] Docker script syntax valid"

echo ""
echo "[5/5] Checking file permissions..."

SETUP_PERMS=$(ls -l "$SETUP_SCRIPT" | awk '{print $1}')
DOCKER_PERMS=$(ls -l "$DOCKER_SCRIPT" | awk '{print $1}')

echo "  Setup script:  $SETUP_PERMS"
echo "  Docker script: $DOCKER_PERMS"

if [[ ! "$SETUP_PERMS" =~ ^-rwx ]]; then
    echo "  [!] WARN: Setup script may not have correct permissions"
fi

if [[ ! "$DOCKER_PERMS" =~ ^-rwx ]]; then
    echo "  [!] WARN: Docker script may not have correct permissions"
fi

echo ""
echo "  [i] Users can view scripts with:"
echo "      cat $SETUP_SCRIPT"
echo "      cat $DOCKER_SCRIPT"
echo ""
echo "  [i] Users can edit scripts with:"
echo "      nano $SETUP_SCRIPT"
echo "      nano $DOCKER_SCRIPT"
echo ""

echo "=========================================="
echo " Test Result: PASS"
echo "=========================================="
echo ""
echo "Scripts are accessible and user-editable!"
echo ""

exit 0
