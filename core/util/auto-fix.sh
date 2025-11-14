#!/usr/bin/env bash
#
# BitBot Auto-Fix Functions
#
# Component: Common Utilities
# Purpose: Automatic fixes for common issues (invoked when user chooses 'X')
#
# Usage: source this file, then call autofix_* functions
#

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# ============================================================================
# Docker Auto-Fix Functions
# ============================================================================

autofix_start_docker_daemon() {
    # Attempt to start Docker Desktop automatically
    # Returns: 0 on success, 1 on failure

    print_step "Attempting to start Docker Desktop..."

    # Detect platform
    if grep -q microsoft /proc/version 2>/dev/null; then
        # WSL - start Docker Desktop via Windows
        print_info "Starting Docker Desktop on Windows..."

        # Try to start Docker Desktop via PowerShell
        if command_exists powershell.exe; then
            powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || \
            powershell.exe -Command "Start-Process '\$env:ProgramFiles\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || {
                print_error "Could not find Docker Desktop.exe"
                print_info "Please start Docker Desktop manually from the Start menu"
                return 1
            }
        else
            print_error "PowerShell not available in WSL"
            return 1
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_info "Starting Docker Desktop on macOS..."
        open -a Docker || {
            print_error "Could not find Docker Desktop app"
            return 1
        }

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        print_info "Starting Docker daemon on Linux..."
        if command_exists systemctl; then
            sudo systemctl start docker || {
                print_error "Failed to start Docker daemon"
                print_info "Try manually: sudo systemctl start docker"
                return 1
            }
        else
            print_error "systemctl not available"
            return 1
        fi

    else
        print_error "Unsupported platform: $OSTYPE"
        return 1
    fi

    # Wait for Docker to start (max 60 seconds)
    print_info "Waiting for Docker to initialize (this may take 30-60 seconds)..."
    local timeout=60
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if docker info &>/dev/null; then
            print_success "Docker started successfully"
            return 0
        fi

        echo -n "." >&2
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo "" >&2
    print_error "Docker did not start within ${timeout} seconds"
    print_info "Check Docker Desktop status manually"
    return 1
}

autofix_add_user_to_docker_group() {
    # Add current user to docker group (requires re-login)
    # Returns: 0 on success, 1 on failure

    print_step "Adding user to docker group..."

    local current_user
    current_user=$(whoami)

    # Add user to group
    if sudo usermod -aG docker "$current_user"; then
        print_success "Added $current_user to docker group"
        echo "" >&2

        print_warning "You must log out and log back in for this change to take effect"
        echo "" >&2

        print_info "Quick fix for WSL:"
        echo "  1. Run in PowerShell: wsl --shutdown" >&2
        echo "  2. Restart WSL and run BitBot again" >&2
        echo "" >&2

        print_info "Quick fix for Linux:"
        echo "  1. Log out of your current session" >&2
        echo "  2. Log back in" >&2
        echo "  3. Run BitBot again" >&2
        echo "" >&2

        return 0
    else
        print_error "Failed to add user to docker group"
        print_info "Try manually: sudo usermod -aG docker $current_user"
        return 1
    fi
}

autofix_restart_docker() {
    # Restart Docker daemon/Desktop
    # Returns: 0 on success, 1 on failure

    print_step "Restarting Docker..."

    # Detect platform
    if grep -q microsoft /proc/version 2>/dev/null; then
        # WSL - restart via Windows
        print_info "Restarting Docker Desktop on Windows..."

        if command_exists powershell.exe; then
            # Try to restart Docker Desktop
            powershell.exe -Command "Get-Process 'Docker Desktop' -ErrorAction SilentlyContinue | Stop-Process -Force" 2>/dev/null
            sleep 3
            powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || {
                print_error "Could not restart Docker Desktop"
                return 1
            }
        else
            print_error "PowerShell not available"
            return 1
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_info "Restarting Docker Desktop on macOS..."
        killall "Docker Desktop" 2>/dev/null
        sleep 3
        open -a Docker || {
            print_error "Could not restart Docker Desktop"
            return 1
        }

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        print_info "Restarting Docker daemon on Linux..."
        if command_exists systemctl; then
            sudo systemctl restart docker || {
                print_error "Failed to restart Docker"
                return 1
            }
        else
            print_error "systemctl not available"
            return 1
        fi

    else
        print_error "Unsupported platform: $OSTYPE"
        return 1
    fi

    # Wait for Docker
    print_info "Waiting for Docker to restart..."
    sleep 10

    local timeout=60
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if docker info &>/dev/null; then
            print_success "Docker restarted successfully"
            return 0
        fi

        echo -n "." >&2
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo "" >&2
    print_error "Docker did not restart within ${timeout} seconds"
    return 1
}

# ============================================================================
# WSL Auto-Fix Functions
# ============================================================================

autofix_enable_wsl() {
    # Enable WSL feature on Windows (requires admin + reboot)
    # Returns: 0 if command succeeds, 1 on failure
    # Note: This WILL require a reboot

    print_step "Enabling WSL..."
    print_warning "This requires administrator privileges and will require a reboot"

    if command_exists powershell.exe; then
        print_info "Running: wsl --install"
        echo "" >&2

        # Run wsl --install via PowerShell as admin
        powershell.exe -Command "Start-Process wsl -ArgumentList '--install' -Verb runAs -Wait" || {
            print_error "Failed to enable WSL"
            print_info "Try manually in PowerShell (as Admin): wsl --install"
            return 1
        }

        print_success "WSL installation initiated"
        echo "" >&2

        print_warning "IMPORTANT: You must restart your computer for changes to take effect"
        echo "" >&2
        print_info "After restart:"
        echo "  1. Complete Ubuntu setup (create username/password)" >&2
        echo "  2. Run BitBot again" >&2
        echo "" >&2

        # Ask if user wants to reboot now
        read -r -p "Restart now? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            powershell.exe -Command "Restart-Computer -Force"
        fi

        return 0
    else
        print_error "PowerShell not available"
        return 1
    fi
}

autofix_upgrade_wsl_to_v2() {
    # Upgrade WSL 1 to WSL 2
    # Returns: 0 on success, 1 on failure

    print_step "Upgrading to WSL 2..."

    if command_exists powershell.exe; then
        print_info "Setting default WSL version to 2..."
        powershell.exe -Command "wsl --set-default-version 2" || {
            print_error "Failed to set WSL default version"
            return 1
        }

        print_info "Converting existing Ubuntu distribution to WSL 2..."
        powershell.exe -Command "wsl --set-version Ubuntu 2" || {
            print_warning "Could not convert Ubuntu to WSL 2"
            print_info "This may take a few minutes. Check progress with: wsl --list --verbose"
        }

        print_success "WSL 2 upgrade initiated"
        print_info "Verify with: wsl --list --verbose"
        return 0
    else
        print_error "PowerShell not available"
        return 1
    fi
}

# ============================================================================
# Git Auto-Fix Functions
# ============================================================================

autofix_install_git() {
    # Install git automatically (Linux/WSL only)
    # Returns: 0 on success, 1 on failure

    print_step "Installing Git..."

    # Detect OS
    if command_exists apt-get; then
        # Debian/Ubuntu
        print_info "Installing Git via apt..."
        sudo apt-get update || true
        if sudo apt-get install -y git; then
            print_success "Git installed successfully"
            git --version >&2
            return 0
        else
            print_error "Failed to install Git"
            return 1
        fi

    elif command_exists apk; then
        # Alpine
        print_info "Installing Git via apk..."
        if sudo apk add --no-cache git; then
            print_success "Git installed successfully"
            git --version >&2
            return 0
        else
            print_error "Failed to install Git"
            return 1
        fi

    elif command_exists yum; then
        # RHEL/CentOS
        print_info "Installing Git via yum..."
        if sudo yum install -y git; then
            print_success "Git installed successfully"
            git --version >&2
            return 0
        else
            print_error "Failed to install Git"
            return 1
        fi

    else
        print_error "Unsupported package manager"
        print_info "Please install Git manually:"
        echo "  • Windows: https://git-scm.com/download/win" >&2
        echo "  • macOS: brew install git" >&2
        echo "  • Linux: sudo apt install git" >&2
        return 1
    fi
}

# ============================================================================
# DevContainer Auto-Fix Functions
# ============================================================================

autofix_install_devcontainer_cli() {
    # Install DevContainer CLI via npm
    # Returns: 0 on success, 1 on failure

    print_step "Installing DevContainer CLI..."

    # Check if npm available
    if ! command_exists npm; then
        print_error "npm not found - Node.js is required"
        print_info "Install Node.js first: https://nodejs.org/"
        return 1
    fi

    print_info "Installing @devcontainers/cli globally..."
    if npm install -g @devcontainers/cli; then
        print_success "DevContainer CLI installed"
        devcontainer --version >&2
        return 0
    else
        print_error "Failed to install DevContainer CLI"
        print_info "Try manually: npm install -g @devcontainers/cli"
        return 1
    fi
}

autofix_clear_docker_cache() {
    # Clear Docker build cache
    # Returns: 0 on success, 1 on failure

    print_step "Clearing Docker cache..."
    print_warning "This will remove all unused Docker images and containers"

    read -r -p "Proceed? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Skipping cache clear"
        return 1
    fi

    if docker system prune -a -f; then
        print_success "Docker cache cleared"
        return 0
    else
        print_error "Failed to clear Docker cache"
        return 1
    fi
}

autofix_increase_docker_memory() {
    # Guide user to increase Docker memory (can't be automated)
    # Returns: 1 (always - user must do manually)

    print_step "Docker memory adjustment needed"
    print_info "This must be done manually in Docker Desktop:"
    echo "" >&2
    echo "  1. Open Docker Desktop" >&2
    echo "  2. Click Settings (gear icon)" >&2
    echo "  3. Go to: Resources → Advanced" >&2
    echo "  4. Increase Memory to 4GB or more" >&2
    echo "  5. Click 'Apply & Restart'" >&2
    echo "" >&2

    print_info "After adjusting memory, run BitBot again"
    return 1  # User must do manually
}

# ============================================================================
# Node.js Auto-Fix Functions
# ============================================================================

autofix_install_nodejs() {
    # Install Node.js automatically (Alpine/Linux)
    # Returns: 0 on success, 1 on failure

    print_step "Installing Node.js..."

    if command_exists apk; then
        # Alpine
        print_info "Installing Node.js via apk..."
        if sudo apk add --no-cache nodejs npm; then
            print_success "Node.js installed"
            node --version >&2
            return 0
        else
            print_error "Failed to install Node.js"
            return 1
        fi

    elif command_exists apt-get; then
        # Debian/Ubuntu
        print_info "Installing Node.js via NodeSource repository..."

        # Add NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || {
            print_error "Failed to add NodeSource repository"
            return 1
        }

        # Install Node.js
        if sudo apt-get install -y nodejs; then
            print_success "Node.js installed"
            node --version >&2
            return 0
        else
            print_error "Failed to install Node.js"
            return 1
        fi

    else
        print_error "Unsupported package manager"
        print_info "Please install Node.js manually: https://nodejs.org/"
        return 1
    fi
}
