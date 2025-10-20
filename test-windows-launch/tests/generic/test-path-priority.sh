#!/bin/bash
# test-path-priority.sh - Test PATH priority in WSL

echo "============================================"
echo "WSL PATH Priority Test"
echo "============================================"
echo ""

echo "=== Original PATH ==="
echo "$PATH" | tr ':' '\n' | nl
echo ""

# Test 1: Windows paths included
echo "=== Test 1: With Windows Paths ==="
export PATH_WITH_WINDOWS="$PATH"
export PATH="$PATH_WITH_WINDOWS"

echo "code command: $(which code 2>/dev/null || echo 'not found')"
echo "docker command: $(which docker 2>/dev/null || echo 'not found')"
echo "claude command: $(which claude 2>/dev/null || echo 'not found')"
echo ""

# Test 2: Windows paths filtered out
echo "=== Test 2: Without Windows Paths ==="
export PATH_NO_WINDOWS=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/[a-z]' | tr '\n' ':' | sed 's/:$//')
export PATH="$PATH_NO_WINDOWS"

echo "code command: $(which code 2>/dev/null || echo 'not found')"
echo "docker command: $(which docker 2>/dev/null || echo 'not found')"
echo "claude command: $(which claude 2>/dev/null || echo 'not found')"
echo ""

# Test 3: WSL first, Windows fallback
echo "=== Test 3: WSL Priority + Windows Fallback ==="
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH_WITH_WINDOWS"

echo "First 10 PATH entries:"
echo "$PATH" | tr ':' '\n' | head -10 | nl
echo ""
echo "code command: $(which code 2>/dev/null || echo 'not found')"
echo "docker command: $(which docker 2>/dev/null || echo 'not found')"
echo "claude command: $(which claude 2>/dev/null || echo 'not found')"
echo ""

# Load nvm and retest
echo "=== Test 4: With nvm Loaded ==="
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    echo "✅ nvm loaded"
else
    echo "⚠️  nvm not found"
fi

export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH_WITH_WINDOWS"

echo "code command: $(which code 2>/dev/null || echo 'not found')"
echo "docker command: $(which docker 2>/dev/null || echo 'not found')"
echo "claude command: $(which claude 2>/dev/null || echo 'not found')"
echo ""

echo "============================================"
echo "Recommendation:"
echo "============================================"
echo ""
echo "Strategy: WSL-first with Windows fallback"
echo ""
echo "PATH order:"
echo "  1. /usr/local/bin (WSL system)"
echo "  2. /usr/bin (WSL system)"
echo "  3. ~/.nvm/.../bin (nvm node/npm)"
echo "  4. ~/.local/bin (user-installed)"
echo "  5. /mnt/c/.../... (Windows fallback)"
echo ""
echo "This ensures:"
echo "  ✅ WSL Claude preferred over Windows Claude"
echo "  ✅ WSL Docker preferred (if installed)"
echo "  ✅ Windows tools still accessible (code, etc.)"
echo "  ✅ No 'command not found' errors"
