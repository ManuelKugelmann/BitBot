#!/bin/bash
# bitbot.sh - WSL bash script test
# This would normally launch containers, for test just launches "claude"

# Load nvm if available (needed for npm-installed tools like claude)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

# Strategy: WSL-first with Windows fallback (don't remove Windows paths)
# This ensures WSL tools are preferred but Windows tools still accessible
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"

echo "============================================"
echo "BitBot Test - Running in WSL (PATH filtered)"
echo "============================================"
echo ""
echo "Current directory: $(pwd)"
echo "Shell: $SHELL"
echo "User: $USER"
echo ""
echo "=== Full PATH ==="
echo "$PATH" | tr ':' '\n' | nl
echo ""
echo "=== Claude Search ==="
which claude 2>/dev/null || echo "Not found in PATH"
echo ""

# Check which claude is available
if command -v claude &> /dev/null; then
    CLAUDE_PATH=$(which claude)
    echo "Claude found at: $CLAUDE_PATH"

    # Check if it's Windows or WSL binary
    if [[ "$CLAUDE_PATH" == /mnt/c/* ]]; then
        echo "⚠️  WARNING: This is the Windows version of Claude!"
        echo "   It may not work properly in WSL terminal."
        echo "   Consider installing Claude in WSL instead."
    else
        echo "✅ WSL version detected"
    fi
    echo ""

    echo "Launching Claude Code..."
    echo "Press Ctrl+C to exit"
    echo ""
    claude
else
    echo "⚠️  Claude not found"
    echo ""
    echo "For testing, simulating interactive terminal:"
    echo "---"

    # Simulate interactive prompt
    read -p "Enter test input (or 'quit' to exit): " input
    while [ "$input" != "quit" ]; do
        echo "You entered: $input"
        echo "✓ Interactive input works!"
        echo ""
        read -p "Enter test input (or 'quit' to exit): " input
    done

    echo ""
    echo "Test complete!"
fi
