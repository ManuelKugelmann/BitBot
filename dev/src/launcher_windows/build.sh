#!/bin/bash
#
# Build script for bitbot.exe launcher
# Compiles launcher.c and copies to project root
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "========================================"
echo "Building BitBot Windows Launcher"
echo "========================================"
echo

# Compile with size optimization
echo "→ Compiling launcher.c (optimized for size)..."
x86_64-w64-mingw32-gcc "$SCRIPT_DIR/launcher.c" -o "$SCRIPT_DIR/launcher.exe" \
  -Os \
  -s \
  -ffunction-sections \
  -fdata-sections \
  -Wl,--gc-sections

if [ ! -f "$SCRIPT_DIR/launcher.exe" ]; then
    echo "✗ Build failed: launcher.exe not created"
    exit 1
fi

echo "✓ Compilation successful"
echo

# Copy to project root as bitbot.exe
echo "→ Copying launcher.exe to project root as bitbot.exe..."
cp "$SCRIPT_DIR/launcher.exe" "$PROJECT_ROOT/bitbot.exe"

if [ ! -f "$PROJECT_ROOT/bitbot.exe" ]; then
    echo "✗ Copy failed"
    exit 1
fi

echo "✓ Copied to: $PROJECT_ROOT/bitbot.exe"
echo

# File info
echo "Build complete:"
ls -lh "$SCRIPT_DIR/launcher.exe"
echo

echo "✓ Build successful!"
