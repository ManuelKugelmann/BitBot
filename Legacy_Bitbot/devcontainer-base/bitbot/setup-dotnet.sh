#!/bin/bash
# .NET Development Environment Setup Script

set -e

echo "🔧 Setting up .NET development environment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Install global .NET tools
install_dotnet_tools() {
    log_info "Installing .NET global tools..."
    
    # Common development tools
    dotnet tool install --global dotnet-ef 2>/dev/null || log_info "Entity Framework Core tools already installed"
    dotnet tool install --global dotnet-aspnet-codegenerator 2>/dev/null || log_info "ASP.NET Core code generator already installed"
    dotnet tool install --global dotnet-format 2>/dev/null || log_info "dotnet-format already installed"
    dotnet tool install --global dotnet-outdated-tool 2>/dev/null || log_info "dotnet-outdated already installed"
    
    log_success "Global .NET tools installation complete"
}

# Configure NuGet
configure_nuget() {
    log_info "Configuring NuGet sources..."
    
    # Ensure official NuGet source is configured
    dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org 2>/dev/null || true
    
    # Clear NuGet cache to ensure fresh packages
    dotnet nuget locals all --clear >/dev/null 2>&1 || true
    
    log_success "NuGet configuration complete"
}

# Setup development certificates
setup_dev_certs() {
    log_info "Setting up development certificates..."
    
    # Generate HTTPS development certificate
    dotnet dev-certs https --clean >/dev/null 2>&1 || true
    dotnet dev-certs https --trust >/dev/null 2>&1 || true
    
    log_success "Development certificates configured"
}

# Create helpful .NET aliases and functions
create_dotnet_aliases() {
    log_info "Creating .NET aliases and functions..."
    
    # Add to .zshrc if not already present
    if ! grep -q "# .NET Development Aliases" /home/node/.zshrc 2>/dev/null; then
        cat >> /home/node/.zshrc << 'EOF'

# .NET Development Aliases
alias dn="dotnet"
alias dnb="dotnet build"
alias dnr="dotnet run"
alias dnt="dotnet test"
alias dnw="dotnet watch"
alias dnc="dotnet clean"
alias dnrs="dotnet restore"
alias dnp="dotnet publish"

# .NET project creation shortcuts
alias dn-console="dotnet new console"
alias dn-web="dotnet new web"
alias dn-api="dotnet new webapi"
alias dn-mvc="dotnet new mvc"
alias dn-blazor="dotnet new blazorserver"
alias dn-class="dotnet new classlib"
alias dn-test="dotnet new xunit"

# .NET solution management
alias dn-sln="dotnet new sln"
alias dn-add="dotnet sln add"
alias dn-list="dotnet sln list"

# Package management
alias dn-add-pkg="dotnet add package"
alias dn-remove-pkg="dotnet remove package"
alias dn-list-pkg="dotnet list package"
alias dn-outdated="dotnet outdated"

# Entity Framework shortcuts
alias ef="dotnet ef"
alias ef-migration="dotnet ef migrations add"
alias ef-update="dotnet ef database update"
alias ef-drop="dotnet ef database drop"

# Quick project info
function dninfo() {
    echo "🔍 .NET Project Information:"
    echo "📁 Current directory: $(pwd)"
    if [ -f "*.csproj" ] || [ -f "*.sln" ]; then
        echo "📋 Project files:"
        ls -la *.csproj *.sln 2>/dev/null || echo "   No .csproj or .sln files found"
    fi
    echo "🔧 .NET version: $(dotnet --version)"
    echo "📦 Global tools:"
    dotnet tool list -g 2>/dev/null | grep -v "Package Id" | head -5
}

# Quick project creation with common structure
function create-dotnet-project() {
    local project_name="$1"
    local project_type="${2:-console}"
    
    if [ -z "$project_name" ]; then
        echo "Usage: create-dotnet-project <name> [console|web|api|mvc|blazor|class|test]"
        return 1
    fi
    
    echo "🚀 Creating $project_type project: $project_name"
    
    case "$project_type" in
        "console") dotnet new console -n "$project_name" ;;
        "web") dotnet new web -n "$project_name" ;;
        "api") dotnet new webapi -n "$project_name" ;;
        "mvc") dotnet new mvc -n "$project_name" ;;
        "blazor") dotnet new blazorserver -n "$project_name" ;;
        "class") dotnet new classlib -n "$project_name" ;;
        "test") dotnet new xunit -n "$project_name" ;;
        *) 
            echo "❌ Unknown project type: $project_type"
            echo "Available types: console, web, api, mvc, blazor, class, test"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo "✅ Project created successfully!"
        echo "📁 Navigate to: cd $project_name"
        echo "🏃 Run with: dotnet run"
    fi
}
EOF
        log_success ".NET aliases and functions added to .zshrc"
    else
        log_info ".NET aliases already configured"
    fi
}

# Display .NET environment information
show_dotnet_info() {
    log_info "Displaying .NET environment information..."
    
    echo ""
    echo "🔍 .NET Environment Information:"
    echo "================================"
    echo "📌 .NET Version: $(dotnet --version)"
    echo "📌 .NET Runtime Info:"
    dotnet --info | head -10
    echo ""
    echo "🛠️  Global Tools:"
    dotnet tool list -g 2>/dev/null | head -10
    echo ""
    echo "📦 Available Project Templates:"
    dotnet new list | head -15
    echo ""
}

# Main setup function
main() {
    echo "🚀 .NET Development Environment Setup Starting..."
    echo ""
    
    install_dotnet_tools
    configure_nuget
    setup_dev_certs
    create_dotnet_aliases
    show_dotnet_info
    
    echo ""
    log_success ".NET development environment setup complete!"
    echo ""
    echo "💡 Try these commands:"
    echo "  dninfo                          - Show project information"
    echo "  create-dotnet-project MyApp     - Create a new console app"
    echo "  create-dotnet-project MyApi api - Create a new Web API"
    echo "  dn-console                      - Create console project in current dir"
    echo "  dnr                             - dotnet run"
    echo "  dnb                             - dotnet build"
    echo ""
    echo "🔄 Restart your shell or run 'source ~/.zshrc' to use the new aliases"
}

# Run main function
main "$@"