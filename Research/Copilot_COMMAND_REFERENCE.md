# BitBot Command Reference
**Quick CLI Reference | Short Commands**

---

## 🚀 Basic Operations

```bash
bitbot                    # Smart launch - resume existing or start new session
bitbot new                # Force create new session  
bitbot list               # List all active sessions
bitbot stop               # Stop current workspace session
bitbot kill               # Stop all BitBot containers
```

## 🔒 Security Modes (Quick Launch)

```bash
bitbot sketch             # Restricted mode - only /sketch write access
bitbot work               # Default mode - full workspace except .devcontainer
bitbot setup              # Full access mode - complete container control
```

## 🤖 AI Agent Selection

```bash
bitbot claude             # Launch with Claude Code agent
bitbot open               # Launch with OpenCode agent  
bitbot custom myAgent     # Launch with custom agent
```

## ⚙️ Configuration & Management

```bash
bitbot config             # Interactive configuration wizard
bitbot install            # Setup PATH and system integrations
bitbot doctor             # System diagnostics and health check
bitbot version            # Version and component information
```

## 🏗️ Advanced Operations

```bash
bitbot template web       # Use web development template
bitbot template ml        # Use machine learning template
bitbot export             # Export workspace configuration
bitbot import config.yml  # Import workspace configuration
```

## 📋 Workspace Templates

```bash
# Built-in templates
bitbot template basic     # Basic development environment
bitbot template web       # Web development (Node.js, TypeScript)
bitbot template python    # Python development environment
bitbot template ml        # Machine learning environment
bitbot template rust      # Rust development environment
bitbot template go        # Go development environment

# Custom templates
bitbot template my-stack  # Use custom template from ~/.bitbot/templates/
```

## 🔗 Combined Commands

```bash
# Mode + Agent combinations
bitbot sketch claude      # Claude Code in sketch mode
bitbot setup open         # OpenCode in setup mode
bitbot work custom ai     # Custom agent in work mode

# Template + Agent combinations  
bitbot template web claude    # Web template with Claude Code
bitbot template ml open       # ML template with OpenCode
```

## 🆘 Help & Troubleshooting

```bash
bitbot help               # Show command help
bitbot help config        # Help for specific command
bitbot doctor             # Diagnose issues
bitbot logs               # Show recent logs
bitbot debug              # Debug mode with verbose output
```

---

## 💡 Usage Examples

### Quick Start for New Project
```bash
cd my-project
bitbot claude             # Launch Claude Code in work mode (default)
```

### Safe AI Experimentation
```bash
cd my-project  
bitbot sketch claude      # Restricted mode - AI can only modify /sketch/
```

### Project Setup & Configuration
```bash
cd my-project
bitbot setup              # Full access for initial project setup
bitbot config             # Configure workspace preferences
bitbot template web       # Apply web development template
```

### Resume Work
```bash
cd my-project
bitbot                    # Smart resume - connects to existing session
# or
bitbot resume session-2   # Resume specific session by name
```

### Multi-Session Development
```bash
# Terminal 1
cd my-project
bitbot claude             # Main development session

# Terminal 2 (same project)
cd my-project  
bitbot new                # Additional session (bitbot-myproject-2)
```

---

## 🎯 Command Design Principles

### Short & Intuitive
- **No double dashes**: `bitbot sketch` not `bitbot --mode sketch`
- **Common words**: `claude`, `config`, `setup` instead of technical terms
- **Memorable**: `sketch` for safe mode, `doctor` for diagnostics

### Smart Defaults
- **Mode**: `work` mode by default (safest for regular development)
- **Agent**: Uses last configured agent or prompts to choose
- **Session**: Resume existing or create new automatically

### Composable
- **Multiple arguments**: `bitbot sketch claude` for mode + agent
- **Template integration**: `bitbot template web claude` 
- **Context aware**: Commands adapt based on workspace state

### Fail-Safe
- **Invalid combinations**: Clear error messages with suggestions
- **Missing prerequisites**: Automatic setup guidance
- **Recovery**: Always a path back to working state

---

*This concise command structure makes BitBot approachable for daily use while maintaining the full power of the underlying system.*