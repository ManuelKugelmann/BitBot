#!/bin/bash
set -e

# Unity C# Development Setup Script
# Installs .NET SDK and Unity-specific development tools

echo "Starting Unity C# development setup..."

# Set noninteractive frontend for apt
export DEBIAN_FRONTEND=noninteractive

# Install .NET SDK for C# development
echo "Installing .NET SDK..."
wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

apt-get update && apt-get install -y --no-install-recommends \
    dotnet-sdk-8.0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify dotnet installation
dotnet --version

echo "Unity C# development setup completed successfully!"
echo ""
echo "Note: C# language server tools (csharp-ls, dotnet-format) can be installed"
echo "by the user as needed using: dotnet tool install --global <tool-name>"
