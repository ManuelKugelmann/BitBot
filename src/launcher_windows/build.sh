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

# Compile
echo "→ Compiling launcher.c..."
x86_64-w64-mingw32-gcc "$SCRIPT_DIR/launcher.c" -o "$SCRIPT_DIR/bitbot.exe"

if [ ! -f "$SCRIPT_DIR/bitbot.exe" ]; then
    echo "✗ Build failed: bitbot.exe not created"
    exit 1
fi

echo "✓ Compilation successful"
echo

# Copy to project root
echo "→ Copying bitbot.exe to project root..."
cp "$SCRIPT_DIR/bitbot.exe" "$PROJECT_ROOT/bitbot.exe"

if [ ! -f "$PROJECT_ROOT/bitbot.exe" ]; then
    echo "✗ Copy failed"
    exit 1
fi

echo "✓ Copied to: $PROJECT_ROOT/bitbot.exe"
echo

# File info
echo "Build complete:"
ls -lh "$SCRIPT_DIR/bitbot.exe"
echo

echo "✓ Build successful!"
