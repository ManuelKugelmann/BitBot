#!/usr/bin/env bash
#
# BitBot Prerequisites and Dependency Checking
#
# Component: Prerequisites Validation
# Purpose: Check, validate, and auto-fix runtime dependencies
#
# Usage: source this file from other scripts
#

# Source helpers (if not already sourced)
if [[ -z "${BITBOT_HELPERS_LOADED:-}" ]]; then
    # shellcheck source=./helpers.sh
    source "${BITBOT_HOME}/core/util/helpers.sh"
    BITBOT_HELPERS_LOADED=1
fi

# ============================================================================
# Platform Detection
# ============================================================================

detect_platform() {
    # Detect current platform
    # Returns: "wsl" | "macos" | "linux"

    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

# ============================================================================
# Main Validation Function
# ============================================================================

validate_prerequisites() {
    # Quick validation for commands
    # Returns: 0 if all prerequisites met, 1 otherwise
    local command="${1:-}"

    # Skip validation for commands that don't need containers
    case "$command" in
        help|version)
            return 0
            ;;
    esac

    # Check Docker
    if ! check_docker; then
        return 1
    fi

    # Check DevContainer CLI (for commands that launch containers)
    case "$command" in
        work|config|vscode|init)
            if ! check_devcontainer_cli_available; then
                handle_missing_devcontainer_cli
                return 1
            fi
            ;;
    esac

    return 0
}

# ============================================================================
# Docker Checks
# ============================================================================

check_docker() {
    # Check if Docker is installed and running
    # Auto-offers to start if not running
    # Returns: 0 if Docker is ready, 1 otherwise

    # Check if Docker is installed
    if ! command_exists docker; then
        print_error "Docker not found"
        echo ""
        echo "Install Docker Desktop:"
        echo "  https://www.docker.com/products/docker-desktop"
        echo ""
        return 1
    fi

    # Check if Docker is running
    if ! docker ps &>/dev/null; then
        print_warning "Docker is not running"
        echo ""

        # Offer to start Docker
        local should_start
        should_start=$(prompt_yes_no "Start Docker now?" "yes")

        if [[ "$should_start" == "yes" ]]; then
            if start_docker; then
                print_success "Docker started"

                # After starting Docker, check WSL integration (WSL only)
                if ! check_docker_wsl_integration; then
                    return 1
                fi

                return 0
            else
                print_error "Failed to start Docker"
                echo "  Please start Docker Desktop manually and try again"
                return 1
            fi
        else
            echo ""
            echo "Please start Docker Desktop manually and try again"
            return 1
        fi
    fi

    # Docker is running - still check WSL integration (WSL only)
    if ! check_docker_wsl_integration; then
        return 1
    fi

    # Check Docker Compose v2 (quick check)
    if ! docker compose version &>/dev/null; then
        print_warning "Docker Compose v2 not found"
        echo "  Usually bundled with Docker Desktop"
        echo "  Some features may not work"
        echo ""
    fi

    return 0
}

start_docker() {
    # Platform-specific Docker startup
    # Returns: 0 if Docker started successfully, 1 otherwise

    local platform
    platform=$(detect_platform)

    print_step "Starting Docker..."

    case "$platform" in
        wsl)
            # Windows: Start Docker Desktop via PowerShell
            if ! powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null; then
                echo "  Could not auto-start Docker Desktop"
                return 1
            fi
            ;;
        macos)
            # macOS: Start Docker Desktop
            if ! open -a Docker 2>/dev/null; then
                echo "  Could not auto-start Docker Desktop"
                return 1
            fi
            ;;
        linux)
            # Linux: Try systemd
            if command_exists systemctl; then
                if ! sudo systemctl start docker 2>/dev/null; then
                    echo "  Could not auto-start Docker daemon"
                    return 1
                fi
            elif command_exists service; then
                if ! sudo service docker start 2>/dev/null; then
                    echo "  Could not auto-start Docker daemon"
                    return 1
                fi
            else
                echo "  Cannot auto-start Docker on this system"
                return 1
            fi
            ;;
    esac

    # Wait for Docker to be ready (max 60 seconds)
    echo "  Waiting for Docker to start..."

    local timeout=60
    local elapsed=0

    while ! docker ps &>/dev/null; do
        if [[ $elapsed -ge $timeout ]]; then
            echo ""
            echo "  Timeout after ${timeout}s"
            if [[ "$platform" == "wsl" ]]; then
                echo "  Docker Desktop may need more time for WSL integration"
            fi
            echo "  Check Docker Desktop status and try again"
            return 1
        fi

        sleep 2
        elapsed=$((elapsed + 2))

        # Progress indicator
        echo -n "."

        if [[ $((elapsed % 10)) -eq 0 ]]; then
            echo -n " ${elapsed}s"
        fi
    done

    echo ""
    print_success "Docker ready (took ${elapsed}s)"
    return 0
}

docker_is_running() {
    # Check if Docker daemon is accessible
    docker ps &>/dev/null 2>&1
}

check_docker_wsl_integration() {
    # Check if Docker WSL integration is configured (WSL only)
    # If not, offer to configure it automatically
    # Returns: 0 if Docker accessible or integration configured, 1 on failure

    local platform
    platform=$(detect_platform)

    # Only check on WSL
    if [[ "$platform" != "wsl" ]]; then
        return 0
    fi

    # Try docker command
    if docker ps &>/dev/null 2>&1; then
        return 0  # Docker works, all good
    fi

    # Check the error
    local error
    error=$(docker ps 2>&1)

    # Check if it's a WSL integration issue
    if echo "$error" | grep -q "Cannot connect to the Docker daemon"; then
        echo ""
        print_warning "Docker WSL Integration not configured"
        echo ""
        echo "BitBot needs Docker Desktop WSL integration enabled."
        echo ""
        echo "This is a one-time setup that will:"
        echo "  - Stop Docker Desktop"
        echo "  - Enable ${WSL_DISTRO_NAME:-Ubuntu} in Docker settings"
        echo "  - Restart Docker Desktop (~30 seconds)"
        echo ""

        local should_setup
        should_setup=$(prompt_yes_no "Enable Docker WSL integration now?" "yes")

        if [[ "$should_setup" == "yes" ]]; then
            # Get BitBot install directory
            local bitbot_install
            bitbot_install=$(get_bitbot_install_dir)

            local setup_script="${bitbot_install}/tests/helpers/enable-docker-wsl-integration.sh"

            if [[ ! -f "$setup_script" ]]; then
                print_error "Setup script not found: $setup_script"
                echo ""
                echo "Manual setup:"
                echo "  1. Open Docker Desktop"
                echo "  2. Settings → Resources → WSL Integration"
                echo "  3. Enable your WSL distribution"
                echo "  4. Apply & Restart"
                echo ""
                return 1
            fi

            # Run setup script
            echo ""
            if bash "$setup_script" "${WSL_DISTRO_NAME:-Ubuntu}"; then
                echo ""
                print_success "Docker WSL integration configured"
                return 0
            else
                print_error "Failed to configure Docker WSL integration"
                return 1
            fi
        else
            echo ""
            echo "Manual setup required:"
            echo "  1. Open Docker Desktop"
            echo "  2. Settings → Resources → WSL Integration"
            echo "  3. Enable your WSL distribution"
            echo "  4. Apply & Restart"
            echo ""
            return 1
        fi
    fi

    # Other error
    print_error "Docker error: $error"
    return 1
}

# ============================================================================
# DevContainer CLI Checks
# ============================================================================

check_devcontainer_cli_available() {
    # Check if devcontainer CLI is available (any method)
    # Returns: 0 if available, 1 if not

    local cli_status
    cli_status=$(check_devcontainer_cli)

    case "$cli_status" in
        builtin|standalone)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_devcontainer_cli() {
    # Check devcontainer CLI availability
    # Returns: "builtin" | "standalone" | "vscode-only" | "none"

    local has_vscode=false
    local has_extension=false
    local has_standalone=false
    local platform
    platform=$(detect_platform)

    # Check for VS Code
    if command_exists code || command_exists code.exe; then
        has_vscode=true

        # Check for Dev Containers extension
        if check_vscode_extension; then
            has_extension=true
        fi
    fi

    # Check for standalone CLI
    if [[ "$platform" == "wsl" ]]; then
        # Windows/WSL: Check for devcontainer.cmd
        if command_exists devcontainer.cmd; then
            has_standalone=true
        fi
    else
        # macOS/Linux: Check for devcontainer
        if command_exists devcontainer; then
            has_standalone=true
        fi
    fi

    # Return status with priority
    if [[ "$has_extension" == "true" ]]; then
        echo "builtin"  # VS Code with Dev Containers extension (best)
    elif [[ "$has_standalone" == "true" ]]; then
        echo "standalone"  # Standalone @devcontainers/cli
    elif [[ "$has_vscode" == "true" ]]; then
        echo "vscode-only"  # VS Code without extension
    else
        echo "none"  # Nothing found
    fi
}

check_vscode_extension() {
    # Check if Dev Containers extension is installed
    # Returns: 0 if installed, 1 if not

    local platform
    platform=$(detect_platform)
    local output

    if [[ "$platform" == "wsl" ]]; then
        # On WSL, check from Windows host
        output=$(powershell.exe -Command "code --list-extensions" 2>/dev/null)
    else
        # Native Linux/macOS
        output=$(code --list-extensions 2>/dev/null)
    fi

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Check if extension is in list
    if echo "$output" | grep -q "ms-vscode-remote.remote-containers"; then
        return 0
    else
        return 1
    fi
}

handle_missing_devcontainer_cli() {
    # Handle missing devcontainer CLI with helpful message

    local cli_status
    cli_status=$(check_devcontainer_cli)

    print_error "DevContainer CLI not available"
    echo ""

    case "$cli_status" in
        vscode-only)
            echo "You have VS Code but Dev Containers extension is missing."
            echo ""
            echo "Install the extension:"
            echo "  1. Open VS Code"
            echo "  2. Extensions view (Ctrl+Shift+X)"
            echo "  3. Search: Dev Containers"
            echo "  4. Install: ms-vscode-remote.remote-containers"
            echo ""
            echo "Or via command line:"
            echo "  code --install-extension ms-vscode-remote.remote-containers"
            ;;
        none)
            echo "Install options:"
            echo ""
            echo "Option 1: VS Code + Dev Containers extension (recommended)"
            echo "  https://code.visualstudio.com/"
            echo "  Extension: ms-vscode-remote.remote-containers"
            echo ""
            echo "Option 2: Standalone CLI (requires Node.js)"
            echo "  npm install -g @devcontainers/cli"
            echo ""

            # Offer to install standalone CLI
            if command_exists npm; then
                echo ""
                local should_install
                should_install=$(prompt_yes_no "Install standalone CLI now?" "no")

                if [[ "$should_install" == "yes" ]]; then
                    install_devcontainer_cli_standalone
                fi
            fi
            ;;
    esac
}

install_devcontainer_cli_standalone() {
    # Install @devcontainers/cli via npm
    # Returns: 0 if successful, 1 otherwise

    if ! command_exists npm; then
        print_error "npm not found"
        echo "Install Node.js from: https://nodejs.org/"
        return 1
    fi

    print_step "Installing @devcontainers/cli..."
    if npm install -g @devcontainers/cli; then
        print_success "@devcontainers/cli installed"
        return 0
    else
        print_error "Installation failed"
        return 1
    fi
}

# ============================================================================
# Comprehensive Status Display (for doctor/version commands)
# ============================================================================

show_doctor() {
    # Show comprehensive dependency status
    echo "BitBot Dependency Status"
    echo "========================"
    echo ""

    # Platform
    local platform
    platform=$(detect_platform)
    echo "Platform: $platform"
    echo ""

    # Docker
    echo "Docker:"
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null | head -n 1)
        echo "  ✓ $docker_version"

        if docker ps &>/dev/null; then
            echo "  ✓ Docker is running"
        else
            echo "  ✗ Docker is not running"
        fi
    else
        echo "  ✗ Docker not installed"
    fi
    echo ""

    # Docker Compose
    echo "Docker Compose:"
    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version 2>/dev/null)
        echo "  ✓ $compose_version"
    else
        echo "  ✗ Docker Compose v2 not found"
    fi
    echo ""

    # DevContainer CLI
    echo "DevContainer CLI:"
    local cli_status
    cli_status=$(check_devcontainer_cli)
    case "$cli_status" in
        builtin)
            echo "  ✓ VS Code builtin (Dev Containers extension)"
            ;;
        standalone)
            local dc_version
            if [[ "$platform" == "wsl" ]]; then
                dc_version=$(devcontainer.cmd --version 2>/dev/null)
            else
                dc_version=$(devcontainer --version 2>/dev/null)
            fi
            echo "  ✓ Standalone CLI ($dc_version)"
            ;;
        vscode-only)
            echo "  ✗ VS Code found, but Dev Containers extension missing"
            ;;
        none)
            echo "  ✗ Not installed"
            ;;
    esac
    echo ""

    # VS Code
    echo "VS Code:"
    if command_exists code || command_exists code.exe; then
        local code_version
        code_version=$(code --version 2>/dev/null | head -n 1)
        echo "  ✓ VS Code installed ($code_version)"

        if check_vscode_extension; then
            echo "  ✓ Dev Containers extension installed"
        else
            echo "  ✗ Dev Containers extension not installed"
        fi
    else
        echo "  ✗ VS Code not installed"
    fi
    echo ""

    # Git
    echo "Git:"
    if command_exists git; then
        local git_version
        git_version=$(git --version 2>/dev/null)
        echo "  ✓ $git_version"
    else
        echo "  ℹ Git not installed (optional)"
    fi
    echo ""
}
