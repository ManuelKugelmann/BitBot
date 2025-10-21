#!/bin/bash
set -e

# C++ Development Setup Script for Ubuntu 22.04
# Installs C++ build tools, CMake, and development libraries

echo "Starting C++ development setup..."

# Set noninteractive frontend for apt
export DEBIAN_FRONTEND=noninteractive

# Install C++ development tools
echo "Installing C++ build tools and libraries..."
apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    gcc \
    gdb \
    cmake \
    make \
    ninja-build \
    pkg-config \
    libssl-dev \
    libncurses-dev \
    libpthread-stubs0-dev \
    clang \
    clang-format \
    clang-tidy \
    lldb \
    valgrind \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify installations
echo "Verifying C++ toolchain installation..."
g++ --version
cmake --version
clang++ --version

echo "C++ development setup completed successfully!"
echo ""
echo "Installed tools:"
echo "  - GCC/G++ (default compiler)"
echo "  - Clang/Clang++ (alternative compiler)"
echo "  - CMake (build system)"
echo "  - GDB/LLDB (debuggers)"
echo "  - Valgrind (memory debugger)"
echo "  - clang-format, clang-tidy (code formatting and linting)"
