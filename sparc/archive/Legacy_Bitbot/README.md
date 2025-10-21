# BitBot

**AI-Powered Development Environment with Containerized Claude Code + MCP Services**

BitBot provides a streamlined way to launch containerized development environments with Claude Code and Model Context Protocol (MCP) services. It supports both global and workspace-local MCP services using Docker containers and tmux session management.

## 🚀 Quick Start

1. **Clone or download BitBot** to your preferred location (e.g., `C:\BitBot`)

2. **Start development in any project:**
   ```bash
   # Navigate to your project directory
   cd /path/to/your/project
   
   # Launch BitBot
   /path/to/BitBot/global/bitbot
   ```

3. **Choose your launch mode:**
   - **VS Code DevContainer**: Full VS Code integration with devcontainer
   - **Direct Docker**: Command-line focused with tmux sessions

4. **Start coding** with Claude Code + MCP services!

## 📁 Project Structure

```
BitBot/
├── global/                          # Global scripts and services
│   ├── bitbot                      # Main entry script (polyglot bash/PowerShell)
│   ├── bitbot-core.sh              # Core logic and container management
│   ├── mcp/                        # Global MCP services
│   │   └── docker-compose.yml      # Global MCP compose configuration
│   ├── shortcuts/                  # Windows shortcuts utilities
│   ├── start-mcp.sh, stop-mcp.sh   # MCP service management
│   └── setup-devcontainer.sh       # DevContainer configuration generator
├── devcontainer-base/               # Development container foundation
│   ├── Dockerfile.base             # Base development container
│   ├── docker-compose.yml          # Main devcontainer compose
│   └── bitbot/                     # Container-internal scripts
│       ├── bitbot                  # Internal session manager
│       ├── mcp/                    # Workspace MCP services
│       │   └── docker-compose.yml  # Workspace MCP compose
│       └── workspace-mcp.sh        # Workspace MCP manager
├── shared/                          # Shared service implementations
│   ├── registry/                   # MCP service registry
│   ├── simple-mcp/                 # Test MCP service
│   └── tools/                      # Shared MCP tools (extensible)
├── tests/                          # Test suite
└── config/                         # Configuration templates
```

## 🏗️ Architecture

### Dual MCP Service Architecture

BitBot runs **two levels** of MCP services:

1. **Global MCP Services** (`global/mcp/`)
   - Shared across all workspaces
   - Ports: 8080 (registry), 8090 (gateway)
   - Network: `mcp-network`

2. **Workspace MCP Services** (`devcontainer-base/bitbot/mcp/`)
   - Specific to each workspace/project
   - Ports: 9080 (registry), 9090 (gateway)
   - Network: `workspace-mcp-network`
   - Includes workspace hash for isolation

### Shared Services Model

Both global and workspace services use the same underlying implementations from `shared/`:
- **Single source of truth** for service code
- **Environment-based configuration** (global vs workspace mode)
- **Easy to extend** with new tools and services

### Container Session Management

- **tmux-based sessions** for multiple terminal access
- **Automatic session creation** and management
- **Resume capability** for existing sessions
- **Multiple concurrent sessions** per workspace

## 🚢 Launch Modes

### VS Code DevContainer Mode
- Generates `.devcontainer/devcontainer.json`
- Full VS Code devcontainer integration
- Automatically opens in VS Code
- Preferred for VS Code users

### Direct Docker Mode
- Launches container immediately
- tmux-based session management
- Command-line focused development
- Great for terminal-based workflows

## 🌐 MCP Services

### Built-in Services

- **MCP Registry** - Service discovery and capability management
- **Simple MCP** - Test service for connectivity validation
- **MCP Gateway** - HTTP proxy for service access

### Service Endpoints

**Global Services:**
- Registry: http://localhost:8080
- Gateway: http://localhost:8090

**Workspace Services:**
- Registry: http://localhost:9080
- Gateway: http://localhost:9090

### Adding Custom Services

1. Create service in `shared/tools/my-service/`
2. Add to appropriate docker-compose.yml
3. Services auto-register with registry

## 🔧 Configuration

### Environment Variables

- `BITBOT_HOME` - Override default BitBot location
- `TZ` - Timezone (defaults to UTC)
- `WORKSPACE_HASH` - Unique workspace identifier (auto-generated)

### Timezone Support

All containers automatically use host timezone:
- `TZ` environment variable
- `/etc/localtime` volume mount
- Timezone args in Docker builds

## 🧪 Testing

### Quick Validation
```bash
./tests/test-bitbot.sh
```

### Full Test Suite
```bash
./tests/run-tests.sh --with-workflow
```

### Windows-Specific Tests
```cmd
tests\test-bitbot.bat
```

**Test Coverage:**
- ✅ Script syntax validation
- ✅ Dockerfile and compose validation
- ✅ DevContainer generation
- ✅ MCP service configuration
- ✅ Real HTTP endpoint testing
- ✅ Complete workflow validation

## 🖥️ Platform Support

### Linux / macOS
- Native Docker support
- Full bash script functionality
- Direct execution

### Windows
- **WSL2** (recommended) - Full Linux experience
- **Docker Desktop** - Native Windows containers
- **PowerShell** - Polyglot script support

### Requirements
- **Docker** (Docker Desktop on Windows/macOS)
- **bash** (available in WSL, Git Bash, or native)
- **tmux** (installed in container)

## 📚 Usage Examples

### Basic Development Session
```bash
# Start in any project directory
cd ~/my-project
/path/to/BitBot/global/bitbot

# First run: choose launch mode
# Subsequent runs: auto-resume or create additional sessions
```

### Managing MCP Services
```bash
# Start global MCP services
/path/to/BitBot/global/start-mcp.sh

# Stop global MCP services
/path/to/BitBot/global/stop-mcp.sh

# Inside container: manage workspace services
workspace-mcp start
workspace-mcp status
workspace-mcp logs
```

### Multiple Sessions
```bash
# First terminal gets main session
/path/to/BitBot/global/bitbot

# Additional terminals get additional sessions
/path/to/BitBot/global/bitbot  # Creates bitbot-workspace-2, bitbot-workspace-3, etc.
```

### Session Management (inside container)
```bash
# List all sessions
tmux list-sessions

# Attach to specific session
tmux attach-session -t bitbot-workspace-2

# Detach from session
Ctrl+B, D

# Create new window
Ctrl+B, C
```

## 🔍 Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- For WSL: Enable WSL2 integration in Docker Desktop
- Check `docker info` works

### Service Issues
- Check service health: `curl http://localhost:8080/health`
- View logs: `docker-compose logs` in MCP directory
- Restart services: `docker-compose restart`

### Container Issues
- Check container status: `docker ps`
- View container logs: `docker logs <container-name>`
- Restart container: stop and run BitBot again

### Path Issues
- Set `BITBOT_HOME` environment variable if needed
- Ensure proper permissions on script files
- Check Windows/WSL path conversion

## 🛠️ Development

### Project Philosophy
- **Shared service architecture** - One implementation, multiple deployments
- **Environment-based configuration** - Services adapt via environment variables
- **Container isolation** - Each workspace gets unique containers
- **Session persistence** - tmux sessions survive disconnections
- **Cross-platform** - Works on Linux, macOS, Windows (WSL)

### Contributing
- Follow existing script patterns
- Add tests for new functionality
- Update documentation
- Test across platforms

### Extending Services
1. Add service to `shared/tools/`
2. Update relevant docker-compose files
3. Add to test suite
4. Document usage

---

## 📄 License

BitBot is designed as a development tool. Please ensure compliance with:
- Docker licensing terms
- Claude Code licensing terms
- Any MCP service dependencies

---

**Ready to boost your development workflow with AI-powered containers? Get started with BitBot today!** 🚀