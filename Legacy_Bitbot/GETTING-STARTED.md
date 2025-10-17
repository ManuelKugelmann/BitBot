# 🚀 Getting Started with BitBot

**Get up and running with BitBot in 5 minutes!**

## Prerequisites

✅ **Docker Desktop** (Windows/macOS) or **Docker Engine** (Linux)  
✅ **bash** shell (WSL, Git Bash, or native Linux/macOS)  
✅ Basic familiarity with containers and development environments  

## Installation

### Step 1: Get BitBot
```bash
# Clone or download BitBot to your preferred location
git clone <repository> /path/to/BitBot
# OR download and extract to C:\BitBot (Windows) or ~/BitBot (Linux/macOS)
```

### Step 2: Verify Installation
```bash
# Run the test suite to verify everything works
cd /path/to/BitBot
./tests/test-bitbot.sh
```

If tests pass, you're ready to go! 🎉

## First Use

### Launch BitBot in Your Project

1. **Navigate to any project directory:**
   ```bash
   cd ~/my-awesome-project
   ```

2. **Launch BitBot:**
   ```bash
   /path/to/BitBot/global/bitbot
   ```

3. **Choose your launch mode** (first run only):
   - **[1] VS Code DevContainer** - Full VS Code integration
   - **[2] Direct Docker Launch** - Terminal-based development

4. **Start developing!** BitBot will:
   - Create a containerized development environment
   - Start MCP services for AI assistance
   - Launch Claude Code in the container
   - Set up tmux sessions for multiple terminals

## What You Get

### 🤖 **AI-Powered Development**
- **Claude Code** running inside the container
- **MCP services** for enhanced AI capabilities
- **Global + workspace-local** service architecture

### 🐳 **Containerized Environment**
- **Consistent development** across machines
- **Pre-configured tools**: git, node, .NET, tmux, zsh
- **Isolated workspace** per project

### 🖥️ **Multiple Access Methods**
- **VS Code DevContainer** - Full IDE experience
- **tmux sessions** - Multiple terminal access
- **Resume capability** - Reconnect to existing sessions

### 🌐 **Service Endpoints**
- **Global MCP Registry**: http://localhost:8080
- **Global MCP Gateway**: http://localhost:8090
- **Workspace MCP Registry**: http://localhost:9080
- **Workspace MCP Gateway**: http://localhost:9090

## Common Commands

### Starting Services
```bash
# Start global MCP services (shared across workspaces)
/path/to/BitBot/global/start-mcp.sh

# Stop global MCP services
/path/to/BitBot/global/stop-mcp.sh
```

### Inside the Container
```bash
# Manage workspace-specific MCP services
workspace-mcp start
workspace-mcp stop
workspace-mcp status

# tmux session management
tmux list-sessions              # List all sessions
tmux attach-session -t <name>   # Attach to specific session
# Ctrl+B, D                     # Detach from session
# Ctrl+B, C                     # Create new window
```

### Testing
```bash
# Quick validation
./tests/test-bitbot.sh

# Full workflow test (starts real services)
./tests/test-workflow.sh

# All tests
./tests/run-tests.sh --with-workflow
```

## Example Workflow

### Scenario: Working on a Node.js Project

1. **Start global services** (once per machine):
   ```bash
   /path/to/BitBot/global/start-mcp.sh
   ```

2. **Navigate to your project**:
   ```bash
   cd ~/my-node-app
   ```

3. **Launch BitBot**:
   ```bash
   /path/to/BitBot/global/bitbot
   ```
   - Choose **Direct Docker Launch** for terminal-based development
   - Container starts with your project mounted at `/workspace`

4. **Inside the container, you get**:
   - Claude Code ready to assist
   - Node.js and npm pre-installed
   - Git configured
   - MCP services available at localhost:9080/9090

5. **Develop normally**:
   ```bash
   npm install
   npm run dev
   # Your app runs inside the container, accessible from host
   ```

6. **Additional terminals**:
   ```bash
   # From host, run BitBot again for more terminals
   /path/to/BitBot/global/bitbot  # Creates additional tmux session
   ```

7. **When done**:
   - `Ctrl+B, D` to detach (session keeps running)
   - Or `exit` to stop the session

## Platform-Specific Notes

### Windows (WSL2 Recommended)
```bash
# Set BitBot location if not in default path
export BITBOT_HOME="/mnt/c/BitBot"

# Launch from any WSL directory
cd /mnt/c/Users/YourName/Projects/my-project
/mnt/c/BitBot/global/bitbot
```

### macOS
```bash
# Ensure Docker Desktop is running
docker info  # Should show Docker info

# Use from any terminal
cd ~/Projects/my-project
~/BitBot/global/bitbot
```

### Linux
```bash
# Ensure Docker service is running
sudo systemctl start docker

# Add user to docker group (one-time setup)
sudo usermod -aG docker $USER
newgrp docker

# Use BitBot
cd ~/Projects/my-project
~/BitBot/global/bitbot
```

## Next Steps

- **Explore MCP services**: Visit http://localhost:8080 for service registry
- **Customize your environment**: Modify container configurations
- **Add custom services**: Extend the MCP service architecture
- **Read the full README**: Comprehensive documentation and advanced usage

## Need Help?

- **Test issues**: Run `./tests/test-bitbot.sh` for validation
- **Service issues**: Check `docker ps` and service logs
- **Path issues**: Set `BITBOT_HOME` environment variable
- **Docker issues**: Ensure Docker Desktop/Engine is running

---

**Happy coding with BitBot! 🤖✨**