#!/bin/bash
# BitBot Installation Script for Linux/WSL2
# Sets up environment variables and PATH

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "========================================"
echo "   BitBot Installation for Linux/WSL2"
echo "========================================"
echo ""

# Get current directory (where BitBot is installed)
BITBOT_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "BitBot installation directory: $BITBOT_INSTALL_DIR"
echo ""

# Check if BITBOT_HOME is already set
if [[ -n "$BITBOT_HOME" ]]; then
    log_info "BITBOT_HOME is currently set to: $BITBOT_HOME"
    read -p "Continue with installation? This will update the environment. (Y/n): " CONTINUE
    if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Determine shell configuration file
SHELL_CONFIG=""
if [[ -n "$ZSH_VERSION" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [[ -n "$BASH_VERSION" ]]; then
    if [[ -f "$HOME/.bashrc" ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
    SHELL_NAME="bash"
else
    log_warning "Unknown shell, defaulting to .bashrc"
    SHELL_CONFIG="$HOME/.bashrc"
    SHELL_NAME="unknown"
fi

log_info "Detected shell: $SHELL_NAME"
log_info "Configuration file: $SHELL_CONFIG"

echo ""
echo "[1/3] Setting up BITBOT_HOME environment variable..."

# Remove any existing BITBOT_HOME entries
if [[ -f "$SHELL_CONFIG" ]]; then
    # Create backup
    cp "$SHELL_CONFIG" "$SHELL_CONFIG.bitbot.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Created backup: $SHELL_CONFIG.bitbot.backup.*"
    
    # Remove existing BITBOT_HOME entries
    sed -i '/export BITBOT_HOME=/d' "$SHELL_CONFIG" 2>/dev/null || true
    sed -i '/# BitBot Environment/d' "$SHELL_CONFIG" 2>/dev/null || true
fi

# Add BITBOT_HOME to shell configuration
{
    echo ""
    echo "# BitBot Environment"
    echo "export BITBOT_HOME=\"$BITBOT_INSTALL_DIR\""
} >> "$SHELL_CONFIG"

log_success "BITBOT_HOME added to $SHELL_CONFIG"

echo ""
echo "[2/3] Adding BitBot to PATH..."

# Check if BitBot is already in PATH
if echo "$PATH" | grep -q "$BITBOT_INSTALL_DIR"; then
    log_info "BitBot directory is already in PATH"
else
    # Add BitBot to PATH in shell configuration
    {
        echo "export PATH=\"\$BITBOT_HOME:\$PATH\""
    } >> "$SHELL_CONFIG"
    
    log_success "Added BitBot to PATH in $SHELL_CONFIG"
fi

echo ""
echo "[3/3] Setting up shortcuts and permissions..."

# Make BitBot scripts executable
chmod +x "$BITBOT_INSTALL_DIR/bitbot"
chmod +x "$BITBOT_INSTALL_DIR/bitbot.sh"
chmod +x "$BITBOT_INSTALL_DIR/bitbot.bat" 2>/dev/null || true
chmod +x "$BITBOT_INSTALL_DIR/scripts/linux/"*.sh 2>/dev/null || true

log_success "Made BitBot scripts executable"

# For WSL2, check if we can access Windows shortcuts
if [[ -n "$WSL_DISTRO_NAME" ]] || [[ $(uname -r) == *microsoft* ]]; then
    log_info "WSL2 detected - Windows shortcuts are available in the BitBot directory"
    if command -v powershell.exe >/dev/null 2>&1; then
        log_info "PowerShell available - you can create shortcuts with:"
        echo "  powershell.exe -ExecutionPolicy Bypass -File \"$BITBOT_INSTALL_DIR/shortcuts/Create-Direct-Shortcuts.ps1\""
    fi
fi

echo ""
echo "========================================"
echo "   BitBot Installation Complete!"
echo "========================================"
echo ""
log_success "BitBot has been installed successfully!"
echo ""
echo "Environment variables set:"
echo "  BITBOT_HOME = $BITBOT_INSTALL_DIR"
echo "  PATH updated to include BitBot directory"
echo ""
echo "Available commands (after restarting your terminal):"
echo "  bitbot         - Start BitBot in current directory"
echo "  bitbot.sh      - Linux/WSL2 launcher"
echo ""
echo "Configuration updated in: $SHELL_CONFIG"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source $SHELL_CONFIG"
echo "2. Navigate to any project directory"  
echo "3. Run 'bitbot' to start your AI development environment"
echo ""
echo "For VS Code integration:"
echo "1. Open your project in VS Code"
echo "2. Run 'bitbot' from the VS Code terminal"
echo "3. Use Ctrl+Shift+P and \"Dev Containers: Reopen in Container\""
echo ""

# Offer to source the configuration immediately
read -p "Would you like to reload your shell configuration now? (Y/n): " RELOAD
if [[ ! "$RELOAD" =~ ^[Nn]$ ]]; then
    source "$SHELL_CONFIG"
    log_success "Shell configuration reloaded"
    echo ""
    echo "You can now use 'bitbot' command immediately!"
fi