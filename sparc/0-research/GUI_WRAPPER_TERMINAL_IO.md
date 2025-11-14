# GUI Wrapper for Terminal I/O - Research

**Research Date**: 2025-11-14
**Purpose**: Research wrapping existing TUI/CLI into desktop GUI by capturing stdin/stdout or tmux output
**Status**: Complete

## Problem Statement

**Goal**: Wrap BitBot TUI/CLI into a pretty GUI desktop application without modifying the underlying CLI code.

**Requirements**:
- Capture stdin/stdout from existing CLI application
- Display in modern GUI interface
- Support interactive input/output
- Cross-platform (Windows, macOS, Linux)
- Option to capture tmux output for advanced scenarios

**Constraint**: Do NOT modify existing CLI - pure wrapper approach

---

## Solution Approaches

### Approach 1: Desktop App + Embedded Terminal (xterm.js + PTY)

**Description**: Create desktop app that embeds a full terminal emulator (xterm.js) connected to PTY backend.

**Architecture**:
```
┌─────────────────────────────────────────┐
│  Desktop Application (Electron/Tauri/Wails)│
│  ┌───────────────────────────────────┐  │
│  │  Frontend (Browser UI)            │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  xterm.js                   │  │  │
│  │  │  (Terminal Emulator)        │  │  │
│  │  └───────────┬─────────────────┘  │  │
│  │              │ IPC/WebSocket     │  │
│  └──────────────┼───────────────────┘  │
│                 │                       │
│  ┌──────────────▼───────────────────┐  │
│  │  Backend (Native)                │  │
│  │  ┌─────────────────────────────┐ │  │
│  │  │  PTY (Pseudo-terminal)      │ │  │
│  │  │  ├─ Spawns shell/CLI        │ │  │
│  │  │  ├─ Handles stdin/stdout    │ │  │
│  │  │  └─ Terminal control codes  │ │  │
│  │  └─────────────────────────────┘ │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                 │
                 ▼
         Your CLI Application
```

**Pros**:
- ✅ Full terminal compatibility (colors, cursor, etc.)
- ✅ Works with any CLI/TUI application
- ✅ No modification to CLI code
- ✅ Real terminal behavior (readline, ncurses, etc.)
- ✅ Battle-tested (VS Code uses this approach)

**Cons**:
- ❌ Slightly more complex setup
- ❌ Requires PTY library (platform-specific)
- ❌ Bundle size depends on framework

**Frameworks**:
1. **Electron + xterm.js + node-pty** (mature, heavy)
2. **Tauri + xterm.js + portable-pty** (modern, lightweight)
3. **Wails + xterm.js + pty library** (Go-friendly)

---

### Approach 2: Tmux Capture + GUI Renderer

**Description**: Capture tmux pane output and render in custom GUI.

**Architecture**:
```
┌─────────────────────────────────────────┐
│  Desktop Application                    │
│  ┌───────────────────────────────────┐  │
│  │  Frontend (Browser UI)            │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Custom Terminal Renderer   │  │  │
│  │  │  (Canvas/DOM based)         │  │  │
│  │  └───────────┬─────────────────┘  │  │
│  │              │ IPC/Events        │  │
│  └──────────────┼───────────────────┘  │
│                 │                       │
│  ┌──────────────▼───────────────────┐  │
│  │  Backend (Native)                │  │
│  │  ├─ tmux capture-pane -p         │  │
│  │  ├─ Parse ANSI codes             │  │
│  │  ├─ Send to frontend             │  │
│  │  └─ tmux send-keys (input)       │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                 │
                 ▼
      tmux session running CLI
```

**Pros**:
- ✅ Can leverage tmux's existing infrastructure
- ✅ Session persistence (tmux handles crashes)
- ✅ Can attach/detach from session
- ✅ Multiple clients can view same session

**Cons**:
- ❌ Requires tmux installed
- ❌ Polling-based (less efficient than PTY)
- ❌ More complex input handling
- ❌ Latency from capture/parse cycle
- ❌ Custom ANSI parser required

**Best For**:
- Environments where tmux is already in use
- Read-mostly applications (monitoring, logs)
- Multi-client scenarios

**Not Recommended For**:
- Interactive applications (input latency)
- General-purpose CLI wrapper

---

### Approach 3: Process Spawn + Stream Capture

**Description**: Spawn CLI process directly, capture stdout/stderr streams, send to frontend.

**Architecture**:
```
┌─────────────────────────────────────────┐
│  Desktop Application                    │
│  ┌───────────────────────────────────┐  │
│  │  Frontend (Browser UI)            │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Text/Log Display           │  │  │
│  │  │  Input Form                 │  │  │
│  │  └───────────┬─────────────────┘  │  │
│  │              │ IPC                │  │
│  └──────────────┼───────────────────┘  │
│                 │                       │
│  ┌──────────────▼───────────────────┐  │
│  │  Backend (Native)                │  │
│  │  ├─ spawn("bitbot", args)        │  │
│  │  ├─ stdout.on('data', send)      │  │
│  │  ├─ stderr.on('data', send)      │  │
│  │  └─ stdin.write(input)           │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                 │
                 ▼
         Your CLI Application
```

**Pros**:
- ✅ Simplest implementation
- ✅ No PTY library needed
- ✅ Direct process control
- ✅ Works for non-interactive CLIs

**Cons**:
- ❌ No TTY (CLI may behave differently)
- ❌ No terminal control codes (colors, cursor)
- ❌ Interactive prompts may not work
- ❌ No readline support

**Best For**:
- Non-interactive CLI tools
- Batch/task runners
- Log viewers
- Build tools

**Not For**:
- TUI applications (ncurses, Textual, etc.)
- Interactive shells
- Applications that detect TTY

---

## Recommended Solution: Electron/Tauri/Wails + xterm.js + PTY

For wrapping **TUI/CLI applications** into GUI, **Approach 1** (Desktop + xterm.js + PTY) is strongly recommended.

---

## Implementation Details by Framework

### Option A: Electron + xterm.js + node-pty

**Maturity**: ⭐⭐⭐⭐⭐ (Most mature, battle-tested)
**Bundle Size**: ❌ Large (~100-150 MB)
**Performance**: ⚠️ Moderate (100+ MB memory)
**Development**: ✅ Easiest (JavaScript/TypeScript only)

#### Working Examples

**Microsoft Official Example**:
- Repository: `microsoft/node-pty` (examples/electron/)
- Minimal working Electron + xterm.js + node-pty

**Community Example**:
- Repository: `princjef/xterm-electron-sample`
- Full-featured with addons

#### Architecture

**Renderer Process** (Frontend):
```javascript
// Renderer: Display terminal
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';

const term = new Terminal();
const fitAddon = new FitAddon();
term.loadAddon(fitAddon);
term.open(document.getElementById('terminal'));
fitAddon.fit();

// Send input to main process
term.onData((data) => {
  ipcRenderer.send('terminal-input', data);
});

// Receive output from main process
ipcRenderer.on('terminal-output', (event, data) => {
  term.write(data);
});
```

**Main Process** (Backend):
```javascript
// Main: Spawn PTY process
const pty = require('node-pty');
const os = require('os');

// Spawn shell or specific command
const shell = os.platform() === 'win32' ? 'powershell.exe' : 'bash';
const ptyProcess = pty.spawn(shell, [], {
  name: 'xterm-color',
  cols: 80,
  rows: 30,
  cwd: process.env.HOME,
  env: process.env
});

// Or spawn your CLI directly:
// const ptyProcess = pty.spawn('bitbot', ['work'], {...});

// Handle output
ptyProcess.onData((data) => {
  mainWindow.webContents.send('terminal-output', data);
});

// Handle input
ipcMain.on('terminal-input', (event, data) => {
  ptyProcess.write(data);
});

// Handle resize
ipcMain.on('terminal-resize', (event, cols, rows) => {
  ptyProcess.resize(cols, rows);
});
```

#### Package Requirements

```json
{
  "dependencies": {
    "xterm": "^5.3.0",
    "xterm-addon-fit": "^0.8.0",
    "xterm-addon-web-links": "^0.9.0",
    "node-pty": "^1.0.0"
  },
  "devDependencies": {
    "electron": "^28.0.0",
    "electron-rebuild": "^3.2.9"
  }
}
```

#### Build Considerations

**Important**: `node-pty` is a native module and requires rebuilding for Electron:

```bash
# Install dependencies
npm install

# Rebuild for Electron
npm install --save-dev electron-rebuild
npx electron-rebuild

# Or use @electron/rebuild
npm install --save-dev @electron/rebuild
npx electron-rebuild
```

#### Pros/Cons

**Pros**:
- ✅ Mature ecosystem (VS Code uses this exact stack)
- ✅ Extensive documentation and examples
- ✅ All JavaScript/TypeScript (no Rust/Go needed)
- ✅ Rich addon ecosystem (search, links, images)
- ✅ Excellent debugging tools (Chrome DevTools)

**Cons**:
- ❌ Large bundle size (~100-150 MB)
- ❌ High memory usage (~100+ MB idle)
- ❌ Slower startup (1-2 seconds)
- ❌ Security considerations (disable nodeIntegration, use contextBridge)

**Best For**:
- Teams familiar with JavaScript/TypeScript
- Complex applications requiring rich ecosystem
- When bundle size is not critical
- Rapid prototyping

---

### Option B: Tauri + xterm.js + portable-pty

**Maturity**: ⭐⭐⭐⭐ (Mature, rapidly growing)
**Bundle Size**: ✅ Small (~10-20 MB)
**Performance**: ✅ Excellent (30-40 MB memory, fast startup)
**Development**: ⚠️ Requires Rust + JavaScript/TypeScript

#### Architecture

**Frontend** (Web - React/Vue/Svelte/Vanilla):
```javascript
// src/terminal.js
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';

const term = new Terminal();
const fitAddon = new FitAddon();
term.loadAddon(fitAddon);
term.open(document.getElementById('terminal'));
fitAddon.fit();

// Start PTY session
await invoke('start_pty', { rows: 30, cols: 80 });

// Send input to backend
term.onData(async (data) => {
  await invoke('pty_write', { data });
});

// Listen for output from backend
await listen('pty-output', (event) => {
  term.write(event.payload);
});

// Handle resize
await invoke('pty_resize', { cols, rows });
```

**Backend** (Rust):
```rust
// src-tauri/src/main.rs
use portable_pty::{native_pty_system, CommandBuilder, PtySize};
use tauri::{Manager, State, Window};
use std::sync::Mutex;
use std::io::Write;

struct PtySession {
    writer: Mutex<Option<Box<dyn std::io::Write + Send>>>,
}

#[tauri::command]
async fn start_pty(
    window: Window,
    state: State<'_, PtySession>,
    rows: u16,
    cols: u16,
) -> Result<(), String> {
    let pty_system = native_pty_system();

    // Create PTY with size
    let pair = pty_system
        .openpty(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })
        .map_err(|e| e.to_string())?;

    // Spawn your CLI (or shell)
    let mut cmd = CommandBuilder::new("bitbot");
    cmd.arg("work");
    // Or spawn shell: CommandBuilder::new("bash")

    let mut child = pair.slave.spawn_command(cmd)
        .map_err(|e| e.to_string())?;

    // Store writer for input
    let writer = pair.master.take_writer()
        .map_err(|e| e.to_string())?;
    *state.writer.lock().unwrap() = Some(writer);

    // Read output in background thread
    let mut reader = pair.master.try_clone_reader()
        .map_err(|e| e.to_string())?;

    std::thread::spawn(move || {
        let mut buf = [0u8; 8192];
        loop {
            match reader.read(&mut buf) {
                Ok(n) if n > 0 => {
                    let data = String::from_utf8_lossy(&buf[..n]).to_string();
                    window.emit("pty-output", data).ok();
                }
                _ => break,
            }
        }
    });

    Ok(())
}

#[tauri::command]
async fn pty_write(
    state: State<'_, PtySession>,
    data: String,
) -> Result<(), String> {
    if let Some(writer) = state.writer.lock().unwrap().as_mut() {
        writer.write_all(data.as_bytes())
            .map_err(|e| e.to_string())?;
        writer.flush().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
async fn pty_resize(
    state: State<'_, PtySession>,
    cols: u16,
    rows: u16,
) -> Result<(), String> {
    // Implementation depends on storing master PTY reference
    Ok(())
}

fn main() {
    tauri::Builder::default()
        .manage(PtySession {
            writer: Mutex::new(None),
        })
        .invoke_handler(tauri::generate_handler![
            start_pty,
            pty_write,
            pty_resize
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**Cargo.toml**:
```toml
[dependencies]
tauri = { version = "1.5", features = ["api-all"] }
portable-pty = "0.8"
```

**Frontend package.json**:
```json
{
  "dependencies": {
    "@tauri-apps/api": "^1.5.0",
    "xterm": "^5.3.0",
    "xterm-addon-fit": "^0.8.0"
  }
}
```

#### Pros/Cons

**Pros**:
- ✅ Small bundle size (10-20 MB vs 100+ MB)
- ✅ Low memory usage (30-40 MB vs 100+ MB)
- ✅ Fast startup (<500ms vs 1-2s)
- ✅ Good security model (Rust enforced)
- ✅ Mobile support (iOS/Android in v2+)
- ✅ Active development, growing community

**Cons**:
- ❌ Requires Rust knowledge for backend
- ❌ Smaller ecosystem than Electron
- ❌ More complex build setup
- ❌ Debugging harder than Electron

**Best For**:
- Performance-critical applications
- Size-constrained deployments
- Teams with Rust expertise (or willing to learn)
- Modern platform targets (may not support older OS versions)

---

### Option C: Wails + xterm.js + pty library

**Maturity**: ⭐⭐⭐ (Good, smaller community than Electron/Tauri)
**Bundle Size**: ✅ Small (~15-25 MB)
**Performance**: ✅ Good (40-50 MB memory, fast startup)
**Development**: ⚠️ Requires Go + JavaScript/TypeScript

#### Working Example

**Repository**: `pomdtr/wails-terminal`
- Full working example of Wails + xterm.js + PTY
- Demonstrates terminal integration patterns

#### Architecture

**Frontend** (JavaScript/TypeScript):
```javascript
// frontend/src/terminal.js
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { StartPty, WritePty, ResizePty } from '../wailsjs/go/main/App';
import { EventsOn } from '../wailsjs/runtime/runtime';

const term = new Terminal();
const fitAddon = new FitAddon();
term.loadAddon(fitAddon);
term.open(document.getElementById('terminal'));
fitAddon.fit();

// Start PTY
StartPty(30, 80);

// Send input
term.onData((data) => {
  WritePty(data);
});

// Receive output
EventsOn('pty-output', (data) => {
  term.write(data);
});

// Handle resize
ResizePty(cols, rows);
```

**Backend** (Go):
```go
// app.go
package main

import (
    "context"
    "io"
    "os"
    "os/exec"

    "github.com/creack/pty"
    "github.com/wailsapp/wails/v2/pkg/runtime"
)

type App struct {
    ctx context.Context
    ptmx *os.File
}

func NewApp() *App {
    return &App{}
}

func (a *App) startup(ctx context.Context) {
    a.ctx = ctx
}

func (a *App) StartPty(rows, cols int) error {
    // Spawn shell or specific command
    cmd := exec.Command("bash")
    // Or your CLI: exec.Command("bitbot", "work")

    // Start with PTY
    ptmx, err := pty.Start(cmd)
    if err != nil {
        return err
    }
    a.ptmx = ptmx

    // Set initial size
    pty.Setsize(ptmx, &pty.Winsize{
        Rows: uint16(rows),
        Cols: uint16(cols),
    })

    // Read output in goroutine
    go func() {
        buf := make([]byte, 8192)
        for {
            n, err := ptmx.Read(buf)
            if err != nil {
                if err != io.EOF {
                    runtime.LogError(a.ctx, err.Error())
                }
                return
            }
            if n > 0 {
                runtime.EventsEmit(a.ctx, "pty-output", string(buf[:n]))
            }
        }
    }()

    return nil
}

func (a *App) WritePty(data string) error {
    if a.ptmx == nil {
        return nil
    }
    _, err := a.ptmx.Write([]byte(data))
    return err
}

func (a *App) ResizePty(cols, rows int) error {
    if a.ptmx == nil {
        return nil
    }
    return pty.Setsize(a.ptmx, &pty.Winsize{
        Rows: uint16(rows),
        Cols: uint16(cols),
    })
}
```

**go.mod**:
```go
module yourapp

go 1.21

require (
    github.com/wailsapp/wails/v2 v2.8.0
    github.com/creack/pty v1.1.21
)
```

**Frontend package.json**:
```json
{
  "dependencies": {
    "xterm": "^5.3.0",
    "xterm-addon-fit": "^0.8.0"
  }
}
```

#### Pros/Cons

**Pros**:
- ✅ Go is easier than Rust for many developers
- ✅ Small bundle size (15-25 MB)
- ✅ Good performance (fast, moderate memory)
- ✅ Simple, clean API
- ✅ Auto-generated TypeScript bindings
- ✅ Excellent developer experience

**Cons**:
- ❌ Smaller community than Electron/Tauri
- ❌ No mobile support (desktop only)
- ❌ Less mature than Electron
- ❌ Fewer examples and resources

**Best For**:
- Go developers
- Teams wanting balance of ease and performance
- Desktop-only applications
- Moderate complexity needs

---

## Framework Comparison Table

| Criteria              | Electron + node-pty | Tauri + portable-pty | Wails + creack/pty |
|----------------------|---------------------|----------------------|-------------------|
| **Backend Language** | JavaScript/TypeScript| Rust                | Go                |
| **Frontend**         | Web (Chromium)      | Web (OS WebView)     | Web (OS WebView)  |
| **Bundle Size**      | 100-150 MB          | 10-20 MB             | 15-25 MB          |
| **Memory Usage**     | 100-200 MB          | 30-40 MB             | 40-50 MB          |
| **Startup Time**     | 1-2 seconds         | <500ms               | <500ms            |
| **Maturity**         | ⭐⭐⭐⭐⭐          | ⭐⭐⭐⭐             | ⭐⭐⭐            |
| **Learning Curve**   | Easy                | Moderate             | Easy-Moderate     |
| **Ecosystem**        | Huge                | Growing              | Moderate          |
| **Mobile Support**   | ❌                  | ✅ (v2+)             | ❌                |
| **Working Examples** | Many                | Some                 | Few (wails-terminal)|
| **Build Complexity** | Moderate            | High                 | Low               |
| **Cross-Platform**   | ✅✅✅              | ✅✅✅               | ✅✅✅            |

---

## Recommended Approach for BitBot

### For BitBot Specifically

**Context**:
- BitBot is written primarily in Bash (shell scripts)
- Has sophisticated CLI with commands like `bitbot work`, `bitbot config`
- Uses Claude Code TUI (already a terminal application)
- Container-based development environment

**Recommendation**: **Tauri + xterm.js + portable-pty**

**Reasoning**:
1. **Performance**: Small bundle, fast startup (important for developer tool)
2. **Security**: Rust security model aligns with BitBot's focus
3. **Size**: 10-20 MB vs 100+ MB (better for distribution)
4. **Modern**: Actively developed, growing community
5. **BitBot Alignment**: Can integrate Rust utilities alongside Bash scripts
6. **Future**: Mobile support (Tauri v2+) enables remote workspace access

**Alternative**: **Wails** if team prefers Go over Rust

**Not Recommended**: Electron (too heavy for a developer tool, CLI wrapper)

---

## Implementation Roadmap

### Phase 1: Proof of Concept (1-2 days)

**Goal**: Basic terminal window running BitBot CLI

1. **Choose Framework** (Tauri recommended)
2. **Set up project**:
   ```bash
   # Tauri
   npm create tauri-app bitbot-gui
   cd bitbot-gui
   ```
3. **Add dependencies**:
   ```bash
   # Frontend
   npm install xterm xterm-addon-fit

   # Backend (Rust Cargo.toml)
   # Add: portable-pty = "0.8"
   ```
4. **Implement basic terminal**:
   - Frontend: xterm.js instance
   - Backend: Spawn shell with portable-pty
   - Connect: IPC events for I/O
5. **Test**: Open terminal, see shell prompt, type commands

**Success Criteria**: Can interact with basic shell in GUI

---

### Phase 2: BitBot Integration (2-3 days)

**Goal**: Run actual BitBot commands in terminal

1. **Modify backend to spawn BitBot**:
   ```rust
   // Instead of shell:
   let mut cmd = CommandBuilder::new("bitbot");
   cmd.arg("work"); // or other command
   ```
2. **Handle environment variables**:
   - Pass `BITBOT_HOME`
   - Set working directory
   - Configure `$PATH`
3. **Test BitBot commands**:
   - `bitbot work`
   - `bitbot config`
   - `bitbot help`
4. **Handle exit/restart**:
   - Clean up PTY on exit
   - Support restarting session

**Success Criteria**: BitBot CLI runs fully in GUI terminal

---

### Phase 3: UI Polish (3-5 days)

**Goal**: Professional GUI wrapper with BitBot branding

1. **Add UI chrome**:
   - Menu bar (File, Edit, View, Help)
   - Toolbar (common commands)
   - Status bar (session info, git branch)
   - Tabs (multiple terminals)
2. **BitBot branding**:
   - Logo in titlebar/about
   - Color scheme (teal #51, navy #24, yellow #226)
   - Custom icon
3. **Settings**:
   - Font size/family
   - Color scheme
   - Key bindings
   - Default command
4. **xterm.js addons**:
   - Fit addon (window resize)
   - Web links addon (clickable URLs)
   - Search addon (Ctrl+F)
   - Ligatures addon (programming fonts)

**Success Criteria**: Professional-looking desktop app

---

### Phase 4: Advanced Features (Optional, 5+ days)

**Goal**: Enhanced functionality beyond basic wrapper

1. **Session management**:
   - Save/restore sessions
   - Multiple workspaces
   - Session persistence
2. **Integration**:
   - File picker for project selection
   - Visual settings editor
   - Template browser
   - Container status dashboard
3. **System integration**:
   - Tray icon
   - Notifications
   - Global hotkeys
   - Auto-updates
4. **Performance**:
   - GPU acceleration
   - Efficient rendering
   - Memory management

**Success Criteria**: Feature-rich desktop application

---

## Technical Considerations

### PTY vs Pipe

**PTY (Pseudo-terminal)** - **REQUIRED** for TUI applications:
- ✅ CLI detects TTY and enables colors, interactive features
- ✅ Handles terminal control codes (ANSI, cursor movement)
- ✅ Supports readline, ncurses, raw mode
- ✅ Proper signal handling (Ctrl+C, Ctrl+Z)

**Pipe (stdin/stdout)** - **NOT SUFFICIENT** for TUI:
- ❌ No TTY detected (CLI may disable features)
- ❌ No terminal control codes
- ❌ No interactive input (readline won't work)
- ❌ Buffer issues with interactive prompts

**Conclusion**: Must use PTY, not pipes

---

### Terminal Emulation

**xterm.js is industry standard**:
- Used by VS Code, CodeSandbox, Gitpod, etc.
- Full VT100/xterm compatibility
- GPU-accelerated rendering
- Extensive addon ecosystem
- Well-maintained and documented

**Alternatives exist but not recommended**:
- hterm (Google) - less maintained
- Terminal.js - minimal, not production-ready
- Custom canvas renderer - huge effort, reinventing wheel

**Conclusion**: Use xterm.js

---

### Cross-Platform Considerations

**PTY Libraries**:
- **node-pty**: Works on Windows, macOS, Linux (mature)
- **portable-pty** (Rust): Cross-platform (newer)
- **creack/pty** (Go): Unix-only (need separate Windows support)

**Windows Specifics**:
- Windows 10+ has ConPTY (native PTY support)
- Older Windows requires winpty shim
- All three libraries handle this automatically

**Testing Required**:
- Windows 10/11
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Fedora, Arch)

---

### Performance Optimization

**xterm.js**:
- Enable GPU renderer (WebGL) for smooth scrolling
- Use FitAddon for proper sizing
- Debounce resize events
- Limit scrollback buffer (10,000 lines default)

**PTY**:
- Buffer reads (8KB chunks)
- Throttle writes if needed
- Clean up processes on exit

**Memory**:
- Limit scrollback buffer
- Release resources on tab close
- Monitor memory leaks (Rust/Go less prone than JS)

---

## Code Examples Repository

Create example implementations in `dev/poc-gui-wrapper/`:

```
dev/poc-gui-wrapper/
├── electron-xterm-pty/      # Electron example
│   ├── main.js
│   ├── renderer.js
│   └── package.json
├── tauri-xterm-pty/         # Tauri example (recommended)
│   ├── src-tauri/
│   │   └── src/main.rs
│   ├── src/
│   │   └── terminal.js
│   └── package.json
└── wails-xterm-pty/         # Wails example
    ├── app.go
    ├── frontend/
    │   └── terminal.js
    └── wails.json
```

---

## Testing Strategy

### Manual Testing

1. **Basic functionality**:
   - Open terminal
   - Type commands
   - See output
   - Colors work
   - Cursor visible

2. **BitBot CLI**:
   - `bitbot work` launches correctly
   - Claude Code TUI displays properly
   - Interactive prompts work
   - Ctrl+C handling
   - Exit works cleanly

3. **Window operations**:
   - Resize terminal
   - Minimize/maximize
   - Multiple windows
   - Close/reopen

4. **Platform testing**:
   - Windows 10/11
   - macOS (Intel + Apple Silicon)
   - Linux (Ubuntu, Fedora)

### Automated Testing

1. **Unit tests**:
   - PTY spawn/cleanup
   - IPC message handling
   - Event emitters

2. **Integration tests**:
   - Launch CLI
   - Send input
   - Verify output
   - Clean shutdown

3. **E2E tests**:
   - Full app lifecycle
   - User scenarios
   - Platform-specific behavior

---

## Distribution

### Build Outputs

**Electron**:
- Windows: `.exe` installer, portable
- macOS: `.dmg`, `.app` bundle
- Linux: `.deb`, `.rpm`, `.AppImage`

**Tauri**:
- Windows: `.exe`, `.msi`
- macOS: `.dmg`, `.app` (code-signed)
- Linux: `.deb`, `.AppImage`

**Wails**:
- Windows: `.exe`
- macOS: `.app`
- Linux: binary

### Code Signing

**macOS**: Required for distribution (Developer ID)
**Windows**: Recommended (Authenticode)
**Linux**: Not required

### Auto-Updates

**Electron**: electron-updater (built-in)
**Tauri**: Built-in updater (v1.5+)
**Wails**: Custom implementation needed

---

## Estimated Effort

### Minimal MVP (Basic Terminal Wrapper)

**Effort**: 2-3 days
**Deliverable**:
- Desktop app
- Embedded xterm.js terminal
- Spawns BitBot CLI
- Basic I/O working
- Cross-platform build

### Polished v1.0

**Effort**: 1-2 weeks
**Deliverable**:
- Professional UI
- BitBot branding
- Settings/preferences
- Multiple tabs
- Installers for all platforms
- Documentation

### Production-Ready v2.0

**Effort**: 3-4 weeks
**Deliverable**:
- All v1.0 features
- Session management
- Visual workspace picker
- Container status dashboard
- Auto-updates
- Extensive testing
- User documentation

---

## Recommended Next Steps

1. **Decision**: Choose framework (Tauri recommended)
2. **POC**: Build minimal example (1 day)
3. **Validate**: Test with BitBot CLI (1 day)
4. **Decide**: Proceed to MVP or iterate on POC
5. **Implement**: Full MVP (1-2 weeks)
6. **Test**: Cross-platform testing
7. **Distribute**: Build installers, publish

---

## Resources

### Official Documentation

**Tauri**:
- Tauri Docs: https://tauri.app/v1/guides/
- portable-pty: https://docs.rs/portable-pty/

**Wails**:
- Wails Docs: https://wails.io/docs/introduction/
- Example: https://github.com/pomdtr/wails-terminal

**Electron**:
- Electron Docs: https://www.electronjs.org/docs/
- node-pty: https://github.com/microsoft/node-pty
- Example: https://github.com/microsoft/node-pty/tree/main/examples/electron

**xterm.js**:
- xterm.js Docs: https://xtermjs.org/docs/
- Addons: https://github.com/xtermjs/xterm.js/tree/master/addons

### Tutorials

**Tauri Terminal App**:
- Build terminal emulator with Tauri (search for tutorials)

**Electron Terminal**:
- Browser-based terminals with Electron.js and Xterm.js: https://www.opcito.com/blogs/browser-based-terminals-with-xtermjs-and-electronjs
- How to create web-based terminals: https://saisandeepvaddi.com/blog/how-to-create-web-based-terminals

**Wails Terminal**:
- pomdtr/wails-terminal: Working example repository

---

## Conclusion

For wrapping BitBot TUI/CLI into a desktop GUI:

**Recommended Solution**: **Tauri + xterm.js + portable-pty**

**Why**:
1. Small bundle size (10-20 MB)
2. Low memory usage (30-40 MB)
3. Fast startup (<500ms)
4. Modern, actively developed
5. Security-focused (Rust)
6. Cross-platform (desktop + mobile future)

**Alternative**: Wails (if team prefers Go over Rust)

**Implementation Path**:
1. Build POC (1-2 days)
2. Validate with BitBot (1 day)
3. Implement MVP (1-2 weeks)
4. Polish and distribute

**Key Technology**: xterm.js + PTY (industry-standard terminal emulation)

**Avoid**: Tmux capture (too complex, latency), Simple pipes (no TTY support)

---

## Revision History

| Date       | Version | Changes                              |
|-----------|---------|--------------------------------------|
| 2025-11-14| 1.0     | Initial research document            |

---

**End of Research Document**
