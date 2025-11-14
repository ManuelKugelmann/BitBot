# Desktop GUI Wrappers for CLI Applications

**Research Date**: 2025-11-14
**Purpose**: Research REAL desktop GUI wrappers for CLI applications (not TUI/terminal-based)
**Status**: Complete

## Overview

This document focuses on **real desktop GUI applications** with windows, buttons, and forms - NOT terminal-based TUIs.

Two categories:
1. **Automatic GUI Generators** - Parse CLI args/config, auto-generate GUI
2. **Manual GUI Frameworks** - Build custom GUI to wrap CLI

---

## Category 1: Automatic GUI Generators

These tools automatically generate desktop GUI from existing CLI definitions.

---

### **Gooey** (Python) ⭐ #1 Most Popular

**Website**: https://github.com/chriskiehl/Gooey
**Language**: Python
**GUI Framework**: wxPython
**License**: MIT
**Status**: Active, well-maintained

**Description**: Turn almost any Python command line program into a full GUI application with one line - literally just add `@Gooey` decorator.

#### How It Works

**Before** (CLI only):
```python
import argparse

parser = argparse.ArgumentParser(description='File Processor')
parser.add_argument('input_file', help='File to process')
parser.add_argument('--output-dir', help='Output directory')
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--format', choices=['json', 'xml', 'csv'])

args = parser.parse_args()
process_file(args.input_file, args.output_dir, args.format, args.verbose)
```

**After** (Desktop GUI):
```python
from gooey import Gooey
import argparse

@Gooey  # <-- Only change!
def main():
    parser = argparse.ArgumentParser(description='File Processor')
    parser.add_argument('input_file', help='File to process')
    parser.add_argument('--output-dir', help='Output directory')
    parser.add_argument('--verbose', action='store_true')
    parser.add_argument('--format', choices=['json', 'xml', 'csv'])

    args = parser.parse_args()
    process_file(args.input_file, args.output_dir, args.format, args.verbose)

if __name__ == '__main__':
    main()
```

**Result**: Opens wxPython window with:
- File picker for `input_file`
- Directory picker for `--output-dir`
- Checkbox for `--verbose`
- Dropdown for `--format`
- "Start" button to run

#### Automatic Widget Mapping

| argparse Type | Desktop Widget | Example |
|--------------|----------------|---------|
| Positional arg | Text field | `parser.add_argument('name')` |
| `--option` | Text field | `parser.add_argument('--output')` |
| `action='store_true'` | Checkbox | `parser.add_argument('--verbose', action='store_true')` |
| `choices=[...]` | Dropdown | `parser.add_argument('--format', choices=['json', 'xml'])` |
| File (custom) | **File picker dialog** | `widget='FileChooser'` |
| Directory | **Directory picker dialog** | `widget='DirChooser'` |
| Multiple files | **Multi-file picker** | `widget='MultiFileChooser'` |
| Date | **Calendar picker** | `widget='DateChooser'` |
| Password | **Password field** (masked) | `widget='PasswordField'` |
| Color | **Color picker** | `widget='ColourChooser'` |
| Textarea | **Multi-line editor** | `widget='Textarea'` |

#### Advanced Customization

```python
from gooey import Gooey, GooeyParser

@Gooey(
    program_name='BitBot Launcher',
    program_description='Secure AI Development Environment',
    default_size=(800, 600),
    image_dir='./images',  # Custom icons/logo
    menu=[{
        'name': 'File',
        'items': [{
            'type': 'AboutDialog',
            'menuTitle': 'About',
            'name': 'BitBot',
            'description': 'AI Development Environment',
            'version': '1.0.0',
        }, {
            'type': 'MessageDialog',
            'menuTitle': 'Help',
            'message': 'Visit docs.bitbot.com'
        }]
    }],
    navigation='TABBED',  # or 'SIDEBAR'
    tabbed_groups=True,
    show_success_modal=True,
    progress_regex=r"^Progress: (\d+)%$",  # Parse progress from output
    timing_options={
        'show_time_remaining': True,
        'hide_time_remaining_on_complete': False
    }
)
def main():
    parser = GooeyParser(description='BitBot Configuration')

    # Group 1: Workspace Settings
    workspace_group = parser.add_argument_group(
        'Workspace Settings',
        'Configure your workspace'
    )
    workspace_group.add_argument(
        '--mode',
        choices=['work', 'config', 'dev'],
        default='work',
        help='Workspace mode'
    )
    workspace_group.add_argument(
        '--workspace-name',
        default='my-workspace',
        help='Workspace name'
    )

    # Group 2: Advanced Options
    advanced_group = parser.add_argument_group(
        'Advanced Options',
        'Optional configuration'
    )
    advanced_group.add_argument(
        '--config-file',
        widget='FileChooser',
        gooey_options={
            'wildcard': "Config files (*.json;*.yaml)|*.json;*.yaml|All files (*.*)|*.*",
            'message': "Select configuration file"
        }
    )
    advanced_group.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        default='INFO'
    )

    args = parser.parse_args()

    # Your CLI logic
    launch_bitbot(args.mode, args.workspace_name, args.config_file, args.log_level)
```

#### Screenshots

**Simple Form**:
```
┌─────────────────────────────────────────┐
│ File Processor                      ─ □ ×│
├─────────────────────────────────────────┤
│ input_file:    [Browse...]              │
│ output_dir:    [Browse...]              │
│ ☑ verbose                               │
│ format:        [json ▼]                 │
│                                         │
│           [ Start ]  [ Cancel ]         │
└─────────────────────────────────────────┘
```

**With Groups/Tabs**:
```
┌─────────────────────────────────────────┐
│ BitBot Launcher                     ─ □ ×│
├─────────────────────────────────────────┤
│ [Workspace] [Advanced] [Output]         │
│                                         │
│ Workspace Settings                      │
│ ─────────────────────────────────────── │
│ mode:           [work ▼]                │
│ workspace-name: [my-workspace_____]     │
│                                         │
│           [ Start ]  [ Cancel ]         │
└─────────────────────────────────────────┘
```

#### Pros/Cons

**Pros**:
- ✅ **Zero code changes** to existing CLI (just add decorator)
- ✅ **Automatic widget selection** based on argparse types
- ✅ Native desktop GUI (wxPython - looks native on Windows/Mac/Linux)
- ✅ File/directory/color/date pickers built-in
- ✅ Progress bar support (parses stdout)
- ✅ Console output capture (shows in scrollable text area)
- ✅ Dual mode (can still run as CLI with `--ignore-gooey`)
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Large community, extensive documentation
- ✅ Menu bar support (File, Help menus)
- ✅ Tabbed/sidebar navigation for complex forms

**Cons**:
- ❌ Python-only (won't work for non-Python CLIs)
- ❌ wxPython dependency (large - ~50+ MB)
- ❌ **No markdown rendering** (plain text only)
- ❌ Limited styling customization (wxPython look)
- ❌ Startup time ~1-2 seconds (Python + wxPython)

**Best For**:
- Existing Python CLI tools using argparse
- Internal tools needing GUI for non-technical users
- Rapid prototyping (instant GUI)
- Scripts that need file/directory pickers

**Not For**:
- Non-Python applications
- Highly customized UI requirements
- Applications requiring markdown rendering
- Performance-critical startup (<500ms)

#### Distribution

**Standalone Executable**:
```bash
# Using PyInstaller
pip install pyinstaller
pyinstaller --onefile --windowed --clean your_app.py

# Result: Single .exe (Windows), .app (macOS), binary (Linux)
# Size: ~50-100 MB (includes Python + wxPython)
```

**Installation**:
```bash
pip install Gooey
```

**Related Projects**:
- **ezgooey** - Simplified wrapper around Gooey
- **gooeywrapper** - Manage GUI/CLI dual mode easily

---

### **FreeSimpleGUI** (Python) - PySimpleGUI Fork

**Website**: https://github.com/spyoungtech/FreeSimpleGUI
**Language**: Python
**GUI Frameworks**: tkinter, Qt, WxPython, Remi (web)
**License**: Free forever (PySimpleGUI fork after it went commercial)
**Status**: Active community fork

**Description**: Python GUI framework that wraps tkinter/Qt/WxPython with much simpler API. Not automatic like Gooey - you manually define GUI layout, but it's very easy.

#### Example: CLI Wrapper

```python
import FreeSimpleGUI as sg
import subprocess

# Define layout
layout = [
    [sg.Text('File Processor', font=('Helvetica', 16))],
    [sg.Text('Input File:'), sg.Input(key='input_file'), sg.FileBrowse()],
    [sg.Text('Output Dir:'), sg.Input(key='output_dir'), sg.FolderBrowse()],
    [sg.Checkbox('Verbose', key='verbose')],
    [sg.Text('Format:'), sg.Combo(['json', 'xml', 'csv'], default_value='json', key='format')],
    [sg.Button('Process'), sg.Button('Cancel')],
    [sg.Multiline(size=(60, 10), key='output', disabled=True, autoscroll=True)]
]

# Create window
window = sg.Window('File Processor', layout)

# Event loop
while True:
    event, values = window.read()

    if event in (sg.WIN_CLOSED, 'Cancel'):
        break

    if event == 'Process':
        # Build command
        cmd = [
            'python', 'process.py',
            values['input_file'],
            '--output-dir', values['output_dir'],
            '--format', values['format']
        ]
        if values['verbose']:
            cmd.append('--verbose')

        # Run command and capture output
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        # Stream output to GUI
        for line in process.stdout:
            window['output'].print(line, end='')
            window.refresh()

window.close()
```

#### Pros/Cons

**Pros**:
- ✅ Multiple GUI backends (tkinter, Qt, WxPython, Remi)
- ✅ Very simple API (easier than raw tkinter)
- ✅ Free forever (community fork)
- ✅ Rich widget set (sliders, graphs, tabs, etc.)
- ✅ Live output streaming
- ✅ Themes/styling support

**Cons**:
- ❌ Not automatic (must manually define GUI)
- ❌ More code than Gooey for simple cases
- ❌ Still requires Python runtime
- ❌ PySimpleGUI documentation often more complete (original project)

**Best For**:
- Custom GUI layouts
- Real-time output display
- When you need specific UI design
- Multiple backend support (switch between tkinter/Qt)

---

### **cligui** (Python) - Lightweight Alternative

**Website**: https://github.com/codypiersall/cligui
**Language**: Python
**GUI Framework**: tkinter (built-in to Python)
**License**: MIT
**Status**: Less maintained, simpler alternative to Gooey

**Description**: Turn argparse CLI into tkinter GUI. Lighter than Gooey but less featured.

#### Example

```python
import argparse
import cligui

parser = argparse.ArgumentParser(description='My Tool')
parser.add_argument('input_file')
parser.add_argument('--output', default='output.txt')
parser.add_argument('--verbose', action='store_true')

# Generate GUI
cligui.generate_gui(parser)
```

**Pros**:
- ✅ Lighter than Gooey (uses built-in tkinter)
- ✅ Similar automatic generation concept
- ✅ No heavy dependencies

**Cons**:
- ❌ Less maintained than Gooey
- ❌ Fewer features (no file pickers, progress bars, etc.)
- ❌ Basic tkinter look (less polished than wxPython)
- ❌ Smaller community

**Recommendation**: Use Gooey instead unless you specifically need lightweight/no dependencies.

---

### **bioGUI** - Template-Based Universal GUI

**Website**: https://github.com/mjoppich/bioGUI
**Language**: XML templates + any CLI
**GUI Framework**: Cross-platform (Qt)
**License**: GPL
**Status**: Active (bioinformatics focus)

**Description**: Create desktop GUI for ANY command-line tool (not just Python) using XML templates. Widely used in bioinformatics.

#### How It Works

**1. Create XML Template** describing your CLI:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<template description="File Processor" title="Process Files">

    <!-- Define UI elements -->
    <window title="File Processor">

        <!-- Input file picker -->
        <group title="Input/Output">
            <filedialog id="input_file"
                        label="Input File:"
                        mode="open"
                        filter="*.txt;*.csv"/>

            <filedialog id="output_dir"
                        label="Output Directory:"
                        mode="directory"/>
        </group>

        <!-- Options -->
        <group title="Options">
            <combobox id="format"
                      label="Format:"
                      selected="0">
                <option>json</option>
                <option>xml</option>
                <option>csv</option>
            </combobox>

            <checkbox id="verbose"
                      label="Verbose output"
                      value="false"/>
        </group>

        <!-- Action button -->
        <action program="process_files">Process</action>
    </window>

    <!-- Define command to execute -->
    <execution>
        <program id="process_files">
            <executable>python</executable>
            <arg>process.py</arg>
            <arg>--input</arg>
            <arg>${input_file}</arg>
            <arg>--output-dir</arg>
            <arg>${output_dir}</arg>
            <arg>--format</arg>
            <arg>${format}</arg>
            <arg if="${verbose}==true">--verbose</arg>
        </program>
    </execution>
</template>
```

**2. Load template in bioGUI**: GUI is automatically generated!

#### Auto-Generation from argparse

bioGUI includes **argparse2biogui** tool:

```bash
# Automatically generate XML template from Python argparse script
python argparse2biogui.py your_script.py > your_template.xml
```

Then load template in bioGUI application.

#### Pros/Cons

**Pros**:
- ✅ **Works with ANY CLI** (Python, bash, C++, whatever)
- ✅ Cross-platform desktop GUI
- ✅ Auto-generate from argparse (argparse2biogui)
- ✅ Auto-generate from CWL (Common Workflow Language)
- ✅ Rich widget set (file pickers, dropdowns, checkboxes, etc.)
- ✅ Conditional logic (show/hide based on values)
- ✅ Install modules (can package CLI dependencies)

**Cons**:
- ❌ Requires bioGUI application installed
- ❌ XML template creation (more effort than Gooey)
- ❌ Primarily focused on bioinformatics
- ❌ Not as polished as Gooey for general use

**Best For**:
- Non-Python CLI tools
- Bioinformatics applications
- Complex workflows with dependencies
- When you need portable templates

**Use Case**:
If BitBot was a compiled binary (not bash), bioGUI could wrap it with XML template.

---

### **UGUI** - Universal GUI (HTML/CSS/JS)

**Website**: https://ugui.io/
**Language**: HTML/CSS/JavaScript (web-based UI)
**Status**: Appears to be newer project (limited info)

**Description**: Create web-based GUI for CLI applications using HTML forms. Browser-based interface.

**Concept**: Similar to inquirer-gui but more general - define HTML forms that call CLI tools.

**Pros**:
- ✅ Web-based (runs in browser)
- ✅ HTML/CSS for customization
- ✅ Cross-platform (any browser)

**Cons**:
- ❌ Limited documentation found
- ❌ Requires web server
- ❌ Not native desktop (browser-based)

**Note**: May be overlapping with web-based terminal wrappers (see GUI_WRAPPER_TERMINAL_IO.md).

---

## Category 2: Manual GUI Frameworks

Build custom desktop GUI to wrap CLI - requires more code but maximum flexibility.

---

### **Qt/PyQt** - Industry Standard

**Languages**: Python (PyQt/PySide), C++ (Qt)
**GUI Framework**: Qt (native-looking on all platforms)
**Tools**: Qt Designer (visual form builder)

#### Using Qt Designer + QProcess

**Workflow**:
1. Design form visually in **Qt Designer**
2. Load form in Python
3. Use **QProcess** to execute CLI and capture output

**Example** (Python + PyQt):

```python
from PyQt5 import QtWidgets, QtCore, uic
import sys

class CLIWrapper(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()

        # Load form from Qt Designer (.ui file)
        uic.loadUi('form.ui', self)

        # Connect button
        self.process_button.clicked.connect(self.run_cli)

        # QProcess for running CLI
        self.process = QtCore.QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handle_output)
        self.process.finished.connect(self.process_finished)

    def run_cli(self):
        # Get form values
        input_file = self.input_file_edit.text()
        output_dir = self.output_dir_edit.text()
        verbose = self.verbose_checkbox.isChecked()

        # Build command
        args = [
            'process.py',
            '--input', input_file,
            '--output-dir', output_dir
        ]
        if verbose:
            args.append('--verbose')

        # Execute
        self.process.start('python', args)

    def handle_output(self):
        # Stream output to text widget
        data = self.process.readAllStandardOutput()
        text = bytes(data).decode('utf-8')
        self.output_text.appendPlainText(text)

    def process_finished(self):
        self.status_label.setText('Done!')

app = QtWidgets.QApplication(sys.argv)
window = CLIWrapper()
window.show()
app.exec_()
```

**Pros**:
- ✅ Professional, native-looking GUI
- ✅ Visual form designer (Qt Designer)
- ✅ Excellent QProcess for CLI integration
- ✅ Cross-platform
- ✅ Rich widget library
- ✅ Can embed terminal widget (QTermWidget)

**Cons**:
- ❌ Manual coding required (not automatic)
- ❌ Steeper learning curve
- ❌ Larger applications (~20-50 MB)

---

### **tkinter** - Built-in Python GUI

**Language**: Python
**GUI Framework**: tkinter (built-in to Python)
**Tools**: Various visual builders (PAGE, pygubu, etc.)

**Example**:

```python
import tkinter as tk
from tkinter import ttk, filedialog
import subprocess

class CLIWrapper:
    def __init__(self, root):
        self.root = root
        root.title("File Processor")

        # Input file
        ttk.Label(root, text="Input File:").grid(row=0, column=0)
        self.input_var = tk.StringVar()
        ttk.Entry(root, textvariable=self.input_var, width=40).grid(row=0, column=1)
        ttk.Button(root, text="Browse", command=self.browse_input).grid(row=0, column=2)

        # Output dir
        ttk.Label(root, text="Output Dir:").grid(row=1, column=0)
        self.output_var = tk.StringVar()
        ttk.Entry(root, textvariable=self.output_var, width=40).grid(row=1, column=1)
        ttk.Button(root, text="Browse", command=self.browse_output).grid(row=1, column=2)

        # Verbose checkbox
        self.verbose_var = tk.BooleanVar()
        ttk.Checkbutton(root, text="Verbose", variable=self.verbose_var).grid(row=2, column=0)

        # Process button
        ttk.Button(root, text="Process", command=self.run_cli).grid(row=3, column=1)

        # Output text
        self.output_text = tk.Text(root, width=60, height=15)
        self.output_text.grid(row=4, column=0, columnspan=3)

    def browse_input(self):
        filename = filedialog.askopenfilename()
        self.input_var.set(filename)

    def browse_output(self):
        dirname = filedialog.askdirectory()
        self.output_var.set(dirname)

    def run_cli(self):
        cmd = [
            'python', 'process.py',
            '--input', self.input_var.get(),
            '--output-dir', self.output_var.get()
        ]
        if self.verbose_var.get():
            cmd.append('--verbose')

        # Run and capture output
        result = subprocess.run(cmd, capture_output=True, text=True)
        self.output_text.insert('end', result.stdout)

root = tk.Tk()
app = CLIWrapper(root)
root.mainloop()
```

**Pros**:
- ✅ Built-in (no extra dependencies)
- ✅ Lightweight
- ✅ Simple for basic GUIs
- ✅ Visual designers available (PAGE, pygubu)

**Cons**:
- ❌ Basic look (not native)
- ❌ Manual coding
- ❌ Less widgets than Qt

---

### **wxPython** - Native Look & Feel

Similar to PyQt but uses wxWidgets. Gooey is built on wxPython.

**Pros**:
- ✅ Native look on all platforms
- ✅ Rich widget library

**Cons**:
- ❌ Manual coding
- ❌ Large dependency

---

## For Non-Python CLIs

### Options for Wrapping Bash/Binary CLIs:

| Approach | Tool | Effort | Flexibility |
|----------|------|--------|-------------|
| **XML Templates** | bioGUI | Medium | High |
| **Manual Qt GUI** | Qt/C++ | High | Maximum |
| **Manual Python GUI** | PyQt + QProcess | Medium | High |
| **Web UI** | UGUI, custom | Medium | Medium |
| **Electron/Tauri + xterm.js** | See GUI_WRAPPER_TERMINAL_IO.md | High | Maximum |

**For BitBot specifically** (bash-based):

1. **bioGUI** - Create XML template, wrap BitBot binary/script
2. **PyQt + QProcess** - Python GUI that calls `bitbot` commands
3. **Tauri + xterm.js** - Full desktop app with embedded terminal (see other research doc)

---

## Comparison Matrix

### Automatic Generators

| Tool | Language | Auto-Gen | Customization | Native Look | Bundle Size | Best For |
|------|----------|----------|---------------|-------------|-------------|----------|
| **Gooey** | Python | ✅ argparse | Medium | ✅ wxPython | ~50 MB | Python CLIs |
| **FreeSimpleGUI** | Python | ❌ | High | ⚠️ Varies | ~10-50 MB | Custom layouts |
| **cligui** | Python | ✅ argparse | Low | ⚠️ tkinter | ~10 MB | Simple CLIs |
| **bioGUI** | Any | ⚠️ Templates | High | ✅ Qt | Varies | Non-Python |
| **UGUI** | Any | ⚠️ Config | High | ❌ Web | Small | Web-based |

### Manual Frameworks

| Framework | Language | Learning Curve | Native Look | Flexibility | Best For |
|-----------|----------|----------------|-------------|-------------|----------|
| **Qt/PyQt** | Python/C++ | High | ✅ | Maximum | Professional apps |
| **tkinter** | Python | Low | ⚠️ | Good | Simple GUIs |
| **wxPython** | Python | Medium | ✅ | High | Native feel |

---

## Recommendations by Use Case

### "I have Python CLI with argparse, need GUI fast"
→ **Gooey** - Add `@Gooey` decorator, done

### "I have Python CLI, need custom layout"
→ **FreeSimpleGUI** or **PyQt** - Build custom GUI

### "I have bash script / non-Python CLI"
→ **bioGUI** (templates) or **PyQt + QProcess** (custom)

### "I need professional, native-looking GUI"
→ **Qt/PyQt** - Industry standard

### "I need lightweight, no dependencies"
→ **tkinter** - Built-in to Python

### "I want embedded terminal in desktop app"
→ **Electron/Tauri + xterm.js** (see GUI_WRAPPER_TERMINAL_IO.md)

---

## For BitBot Specifically

**BitBot Context**:
- Bash-based CLI
- Commands: `bitbot work`, `bitbot config`, etc.
- Docker/DevContainer orchestration
- Not Python-based

**Desktop GUI Options**:

### Option 1: Python Wrapper with PyQt ⭐ Recommended

Create Python desktop app that calls BitBot:

```python
from PyQt5 import QtWidgets, QtCore
import subprocess

class BitBotGUI(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('BitBot Launcher')

        # Mode selection
        self.mode_combo = QtWidgets.QComboBox()
        self.mode_combo.addItems(['work', 'config', 'dev'])

        # Workspace name
        self.workspace_input = QtWidgets.QLineEdit()
        self.workspace_input.setPlaceholderText('my-workspace')

        # Launch button
        self.launch_btn = QtWidgets.QPushButton('Launch Workspace')
        self.launch_btn.clicked.connect(self.launch_bitbot)

        # Output terminal (embedded)
        self.terminal = QtWidgets.QPlainTextEdit()
        self.terminal.setReadOnly(True)

        # Layout
        layout = QtWidgets.QVBoxLayout()
        layout.addWidget(QtWidgets.QLabel('Mode:'))
        layout.addWidget(self.mode_combo)
        layout.addWidget(QtWidgets.QLabel('Workspace:'))
        layout.addWidget(self.workspace_input)
        layout.addWidget(self.launch_btn)
        layout.addWidget(self.terminal)

        container = QtWidgets.QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        # QProcess for BitBot
        self.process = QtCore.QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handle_output)

    def launch_bitbot(self):
        mode = self.mode_combo.currentText()
        workspace = self.workspace_input.text()

        # Execute BitBot
        self.process.start('bitbot', [mode, workspace])

    def handle_output(self):
        data = self.process.readAllStandardOutput()
        text = bytes(data).decode('utf-8')
        self.terminal.appendPlainText(text)

app = QtWidgets.QApplication([])
window = BitBotGUI()
window.show()
app.exec_()
```

**Pros**:
- ✅ Native desktop GUI
- ✅ Calls BitBot directly (no modification needed)
- ✅ Can show output
- ✅ Cross-platform

**Cons**:
- ❌ Manual coding required
- ❌ No full terminal emulation (use Tauri + xterm.js for that)

---

### Option 2: bioGUI Template

Create XML template for BitBot:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<template description="BitBot Launcher" title="BitBot">
    <window title="BitBot - AI Development Environment">
        <group title="Workspace Configuration">
            <combobox id="mode" label="Mode:" selected="0">
                <option>work</option>
                <option>config</option>
                <option>dev</option>
            </combobox>

            <input id="workspace"
                   label="Workspace Name:"
                   default="my-workspace"/>
        </group>

        <action program="launch_bitbot">Launch Workspace</action>
    </window>

    <execution>
        <program id="launch_bitbot">
            <executable>bitbot</executable>
            <arg>${mode}</arg>
            <arg>${workspace}</arg>
        </program>
    </execution>
</template>
```

**Pros**:
- ✅ No coding required (just XML)
- ✅ Cross-platform
- ✅ Can package with bioGUI installer

**Cons**:
- ❌ Requires bioGUI installed
- ❌ Not as polished as custom app

---

### Option 3: Tauri + xterm.js (Full Terminal)

See **GUI_WRAPPER_TERMINAL_IO.md** for details.

Creates real desktop app with embedded terminal - best for full BitBot experience.

**Pros**:
- ✅ Full terminal emulation (colors, cursor, etc.)
- ✅ Small bundle (~10-20 MB)
- ✅ Professional desktop app

**Cons**:
- ❌ Most complex to implement
- ❌ Requires Rust + JavaScript knowledge

---

## Summary

### Top Picks:

1. **Gooey** - Best for Python argparse CLIs (automatic)
2. **FreeSimpleGUI** - Best for custom Python GUI layouts
3. **PyQt** - Best for professional, native desktop GUI
4. **bioGUI** - Best for non-Python CLIs with templates

### For BitBot:

**Quick**: PyQt wrapper calling `bitbot` commands
**Professional**: Tauri + xterm.js with full terminal
**Template-based**: bioGUI XML template

All options create **real desktop applications** with windows, not terminal UIs.

---

## Installation References

```bash
# Gooey
pip install Gooey

# FreeSimpleGUI
pip install FreeSimpleGUI

# PyQt
pip install PyQt5

# tkinter (built-in to Python)
# No installation needed

# bioGUI
# Download from: https://github.com/mjoppich/bioGUI
```

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-14 | 1.0 | Initial research compilation |

---

**End of Research Document**
