# Automatic CLI-to-GUI Wrappers with Widgets & Markdown

**Research Date**: 2025-11-14
**Purpose**: Research tools that automatically convert CLI to GUI with markdown rendering, input forms, and choice widgets
**Status**: Complete

## Overview

This document covers tools that provide **automatic conversion** from CLI applications to GUI/TUI with built-in support for:
- ✅ **Markdown rendering** (formatted output)
- ✅ **Input widgets** (text fields, password fields, file pickers)
- ✅ **Choice widgets** (dropdowns, checkboxes, radio buttons)
- ✅ **Form builders** (multi-field forms)

These are **higher-level abstractions** than raw terminal emulation (xterm.js + PTY). They parse your CLI's arguments/prompts and automatically create appropriate UI widgets.

---

## Tool Categories

### Category 1: Automatic CLI → GUI Converters
Parse command-line arguments (argparse, flags, etc.) and automatically generate GUI forms.

**Best For**: Existing CLI tools with argument parsers

### Category 2: Interactive Prompt Libraries (with GUI backends)
Build interactive prompts in code, optionally render as GUI instead of TUI.

**Best For**: Building new interactive CLIs with GUI option

### Category 3: Shell Script GUI Dialog Generators
Create GUI dialogs from shell scripts (bash, etc.).

**Best For**: Shell scripts needing user input

### Category 4: TUI Frameworks with Rich Widgets
Terminal UI with native markdown rendering and form widgets.

**Best For**: Staying in terminal but want rich formatting

---

## Category 1: Automatic CLI → GUI Converters

### **Gooey** (Python) ⭐ Top Pick for Python CLI

**Website**: https://github.com/chriskiehl/Gooey
**Language**: Python
**License**: MIT

**Description**: Turn almost any Python command-line program into a full GUI application with one line - literally just add a `@Gooey` decorator.

#### How It Works

**Before** (CLI only):
```python
import argparse

def main():
    parser = argparse.ArgumentParser(description='My CLI Tool')
    parser.add_argument('filename', help='File to process')
    parser.add_argument('--output', help='Output directory')
    parser.add_argument('--verbose', action='store_true')
    args = parser.parse_args()

    # Your CLI logic
    process_file(args.filename, args.output, args.verbose)

if __name__ == '__main__':
    main()
```

**After** (CLI + GUI):
```python
import argparse
from gooey import Gooey

@Gooey  # <-- Only change needed!
def main():
    parser = argparse.ArgumentParser(description='My CLI Tool')
    parser.add_argument('filename', help='File to process')
    parser.add_argument('--output', help='Output directory')
    parser.add_argument('--verbose', action='store_true')
    args = parser.parse_args()

    # Your CLI logic (unchanged)
    process_file(args.filename, args.output, args.verbose)

if __name__ == '__main__':
    main()
```

**Result**: Launches with GUI showing:
- File picker for `filename`
- Directory picker for `--output`
- Checkbox for `--verbose`
- Run button

#### Automatic Widget Mapping

ArgumentParser types are automatically mapped to GUI widgets:

| argparse Type          | GUI Widget           | Example                                    |
|-----------------------|----------------------|-------------------------------------------|
| Positional argument   | Text field           | `parser.add_argument('name')`             |
| `--flag`              | Text field           | `parser.add_argument('--output')`         |
| `action='store_true'` | Checkbox             | `parser.add_argument('--verbose', action='store_true')` |
| `choices=[...]`       | Dropdown             | `parser.add_argument('--format', choices=['json', 'xml'])` |
| File argument         | File picker          | `parser.add_argument('file', widget='FileChooser')` |
| Directory argument    | Directory picker     | `parser.add_argument('dir', widget='DirChooser')` |
| Date argument         | Date picker          | `parser.add_argument('date', widget='DateChooser')` |
| Password              | Password field       | `parser.add_argument('pass', widget='PasswordField')` |
| Multi-file            | Multi-file picker    | `parser.add_argument('files', widget='MultiFileChooser')` |

#### Advanced Customization

```python
@Gooey(
    program_name='My Application',
    program_description='Process files with options',
    default_size=(800, 600),
    required_cols=2,
    optional_cols=2,
    image_dir='/path/to/images',
    menu=[{
        'name': 'File',
        'items': [{
            'type': 'AboutDialog',
            'menuTitle': 'About',
            'name': 'My App',
            'description': 'Does cool stuff',
            'version': '1.0',
        }]
    }]
)
def main():
    parser = argparse.ArgumentParser()

    # Custom widget specification
    parser.add_argument(
        '--input-file',
        widget='FileChooser',
        gooey_options={
            'wildcard': "Text files (*.txt)|*.txt|All files (*.*)|*.*",
            'message': "Choose input file"
        }
    )

    # Group related arguments
    group = parser.add_argument_group(
        'Output Options',
        'Configure output settings'
    )
    group.add_argument('--format', choices=['json', 'xml', 'yaml'])
    group.add_argument('--compress', action='store_true')

    args = parser.parse_args()
```

#### CLI/GUI Dual Mode

```python
import sys
from gooey import Gooey

# Run as GUI by default, but allow --ignore-gooey for CLI mode
@Gooey
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ignore-gooey', action='store_true')
    # ... rest of arguments

    args = parser.parse_args()

    # Your logic works the same in both modes
    process(args)

if __name__ == '__main__':
    # Can also check sys.argv to conditionally enable GUI
    if '--cli' in sys.argv:
        main()  # Don't call @Gooey decorator
    else:
        main()  # Calls with @Gooey, shows GUI
```

#### Pros/Cons

**Pros**:
- ✅ **Zero code changes** (just add decorator)
- ✅ Automatic widget selection
- ✅ Supports all argparse features
- ✅ Built-in file/directory pickers
- ✅ Progress bars, console output capture
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Large community, well-documented

**Cons**:
- ❌ Python-only (requires Python installed)
- ❌ Based on wxPython (larger dependency)
- ❌ No markdown rendering (plain text only)
- ❌ Limited styling customization
- ❌ Bundle size (~50+ MB with wxPython)

**Best For**:
- Existing Python CLI tools using argparse
- Quick GUI wrapper for internal tools
- Non-technical users who need GUI

**Not For**:
- Non-Python applications
- Markdown-heavy output
- Highly customized UI requirements

#### Installation

```bash
pip install Gooey
```

#### Related Tools

- **ezgooey** - Simplified Gooey wrapper with easier configuration
- **gooeywrapper** - Manage GUI/CLI execution modes more easily

---

### **inquirer-gui** (SAP)

**Website**: https://github.com/SAP/inquirer-gui
**Language**: JavaScript/TypeScript (Vue.js)
**License**: Apache 2.0

**Description**: Displays Inquirer.js questions in interactive HTML form. Converts CLI prompts to GUI automatically.

#### How It Works

**Inquirer.js Code** (runs in CLI or GUI):
```javascript
const inquirer = require('inquirer');

const questions = [
  {
    type: 'input',
    name: 'username',
    message: 'Enter your username:',
    validate: (input) => input.length >= 3 || 'Username too short'
  },
  {
    type: 'password',
    name: 'password',
    message: 'Enter your password:'
  },
  {
    type: 'list',
    name: 'role',
    message: 'Select your role:',
    choices: ['Admin', 'User', 'Guest']
  },
  {
    type: 'checkbox',
    name: 'features',
    message: 'Select features to enable:',
    choices: ['Logging', 'Monitoring', 'Analytics']
  },
  {
    type: 'confirm',
    name: 'agree',
    message: 'Do you agree to terms?',
    default: false
  }
];

inquirer.prompt(questions).then(answers => {
  console.log(JSON.stringify(answers, null, 2));
});
```

**With inquirer-gui** - Same code, rendered as HTML form:
```javascript
const { InquirerGui } = require('inquirer-gui');

const gui = new InquirerGui({
  questions: questions,  // Same questions object
  onAnswers: (answers) => {
    console.log('Answers:', answers);
  }
});

// Renders as HTML form in browser or VS Code webview
gui.show();
```

#### Widget Mapping

| Inquirer Type  | GUI Widget                | Features                           |
|---------------|---------------------------|-----------------------------------|
| `input`       | Text input field          | Validation, default value         |
| `password`    | Password field            | Masked input                      |
| `number`      | Number input              | Min/max validation                |
| `list`        | Dropdown select           | Single choice                     |
| `rawlist`     | Radio buttons             | Single choice, visible options    |
| `checkbox`    | Checkboxes                | Multiple selection                |
| `confirm`     | Yes/No toggle             | Boolean input                     |
| `editor`      | Textarea                  | Multi-line text                   |

#### Advanced Features

- **Conditional visibility**: Questions shown/hidden based on previous answers
- **Validation**: Real-time validation with error messages
- **Dependencies**: Questions depend on other answers
- **Plugins**: Extensible with custom question types

#### Usage in VS Code Extension

```javascript
// VS Code extension using inquirer-gui
import { InquirerGui } from 'inquirer-gui';

const panel = vscode.window.createWebviewPanel(
  'myForm',
  'Configuration Form',
  vscode.ViewColumn.One,
  { enableScripts: true }
);

const gui = new InquirerGui({
  questions: myQuestions,
  webview: panel.webview,
  onAnswers: (answers) => {
    // Process answers
    saveConfig(answers);
  }
});
```

#### Pros/Cons

**Pros**:
- ✅ Works in browser AND VS Code
- ✅ Automatic HTML form generation
- ✅ Full validation support
- ✅ Conditional question display
- ✅ Can embed in other Vue apps
- ✅ Good for VS Code extensions

**Cons**:
- ❌ JavaScript/Node.js only
- ❌ Requires Vue.js dependency
- ❌ No markdown rendering
- ❌ Limited to Inquirer.js question types
- ❌ Smaller community than Gooey

**Best For**:
- VS Code extensions
- Inquirer.js users wanting GUI
- Browser-based configuration forms

---

## Category 2: Interactive Prompt Libraries (with GUI backends)

### **Charm Gum** (Go) ⭐ Beautiful Shell Script UIs

**Website**: https://github.com/charmbracelet/gum
**Language**: Go (used from bash/sh)
**License**: MIT

**Description**: A tool for glamorous shell scripts. Provides TUI components that can be called from bash scripts - makes shell scripts interactive and beautiful.

#### Components

Gum provides individual commands for different UI elements:

| Command        | Purpose                          | Example Output                     |
|---------------|----------------------------------|-----------------------------------|
| `gum input`   | Text input prompt                | Single-line text entry            |
| `gum write`   | Multi-line text editor           | Full text editor in terminal      |
| `gum choose`  | Selection menu                   | Arrow-key selectable list         |
| `gum filter`  | Fuzzy finder                     | Type-to-filter list               |
| `gum confirm` | Yes/No confirmation              | y/n prompt                        |
| `gum spin`    | Spinner for long tasks           | Loading animation                 |
| `gum format`  | Format/render markdown, code, etc| Styled output                     |
| `gum style`   | Style text with colors, borders  | Fancy text boxes                  |
| `gum join`    | Join text horizontally/vertically| Layout tool                       |
| `gum pager`   | Scrollable content viewer        | Less-like pager                   |

#### Markdown Rendering

**Built-in markdown rendering**:
```bash
# Render markdown file
gum format < README.md

# Render markdown string
gum format <<EOF
# My Title

This is **bold** and this is *italic*.

- Item 1
- Item 2

\`\`\`python
print("Hello, World!")
\`\`\`
EOF
```

Output: Beautifully formatted markdown in terminal (colors, headers, code blocks with syntax highlighting)

#### Shell Script Example

```bash
#!/bin/bash

# Beautiful shell script with Gum

# Display title with styling
gum style \
    --foreground 212 \
    --border-foreground 212 \
    --border double \
    --align center \
    --width 50 \
    --margin "1 2" \
    --padding "2 4" \
    'Welcome to My Installer'

# Get user input
NAME=$(gum input --placeholder "Enter your name")

# Choose from list
ENVIRONMENT=$(gum choose "Development" "Staging" "Production")

# Checkbox multi-select
FEATURES=$(gum choose --no-limit \
    "Logging" \
    "Monitoring" \
    "Analytics" \
    "Alerts")

# Confirm
gum confirm "Install with these settings?" && {

    # Show spinner while installing
    gum spin --spinner dot --title "Installing..." -- sleep 3

    # Format results as markdown
    gum format <<EOF
## Installation Complete! ✓

**User**: $NAME
**Environment**: $ENVIRONMENT
**Features**:
$(echo "$FEATURES" | sed 's/^/- /')

Run \`myapp start\` to begin.
EOF

} || {
    echo "Installation cancelled"
    exit 1
}
```

#### More Examples

**Fuzzy file picker**:
```bash
# Let user filter and select file
FILE=$(find . -type f | gum filter)
echo "Selected: $FILE"
```

**Multi-line editor**:
```bash
# Get commit message with editor
COMMIT_MSG=$(gum write --placeholder "Enter commit message...")
git commit -m "$COMMIT_MSG"
```

**Styled output**:
```bash
# Create fancy boxes
gum join --vertical \
    "$(gum style --border rounded --padding '1 2' 'Box 1')" \
    "$(gum style --border rounded --padding '1 2' 'Box 2')"
```

#### Pros/Cons

**Pros**:
- ✅ **Built-in markdown rendering** (`gum format`)
- ✅ Beautiful, modern TUI components
- ✅ Works from ANY shell script (bash, zsh, fish)
- ✅ Single binary (easy to install)
- ✅ Composable (pipe components together)
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Part of Charm ecosystem (Bubble Tea, Glow, etc.)

**Cons**:
- ❌ TUI only (not full GUI - stays in terminal)
- ❌ Requires terminal with color support
- ❌ Each component is separate command (not framework)
- ❌ More verbose than Gooey for Python

**Best For**:
- Shell scripts needing user interaction
- Bash-based installers/wizards
- DevOps tools and automation
- Git hooks, CI/CD scripts

**Not For**:
- Desktop GUI applications
- Users uncomfortable with terminal

#### Installation

```bash
# macOS/Linux
brew install gum

# Go
go install github.com/charmbracelet/gum@latest

# Windows
scoop install gum
# or
winget install charmbracelet.gum
```

#### Related Charm Tools

- **Glow** - Markdown viewer/browser for terminal
- **Bubble Tea** - Go TUI framework (Gum is built on it)
- **Lip Gloss** - Styling library for terminal output
- **Bubbles** - Reusable TUI components

---

### **Textual** (Python) ⭐ Full TUI Framework with Markdown

**Website**: https://textual.textualize.io/
**Language**: Python
**License**: MIT

**Description**: Modern TUI framework for Python with built-in markdown rendering, rich widgets, and CSS-like styling.

#### Markdown Widget

Built-in markdown rendering widget:

```python
from textual.app import App, ComposeResult
from textual.widgets import Markdown

MARKDOWN_EXAMPLE = """
# My Application

This is **bold** and this is *italic*.

## Features
- Fast rendering
- Syntax highlighting
- Tables
- Links

## Code Example
\`\`\`python
def hello():
    print("Hello, World!")
\`\`\`

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
"""

class MarkdownApp(App):
    def compose(self) -> ComposeResult:
        yield Markdown(MARKDOWN_EXAMPLE)

if __name__ == "__main__":
    app = MarkdownApp()
    app.run()
```

**Output**: Beautifully rendered markdown in terminal with:
- Styled headers
- Bold/italic text
- Syntax-highlighted code blocks
- Formatted tables
- Clickable links

#### MarkdownViewer Widget

Enhanced markdown with navigation and table of contents:

```python
from textual.app import App, ComposeResult
from textual.widgets import MarkdownViewer

class MarkdownBrowserApp(App):
    def compose(self) -> ComposeResult:
        # Shows markdown with TOC sidebar and navigation
        yield MarkdownViewer(show_table_of_contents=True)

    def on_mount(self) -> None:
        # Load markdown file or string
        self.query_one(MarkdownViewer).document.update("# Content...")
        # Or load file:
        # self.query_one(MarkdownViewer).go("README.md")

if __name__ == "__main__":
    app = MarkdownBrowserApp()
    app.run()
```

**Features**:
- Table of contents sidebar
- Link navigation (click to follow)
- Scrollable content
- Code fence scrolling
- Dynamic updates (streaming text)

#### Form Widgets

Full set of input widgets:

```python
from textual.app import App, ComposeResult
from textual.widgets import (
    Input, Button, Checkbox, RadioButton, RadioSet,
    Select, TextArea, Label, Static
)
from textual.containers import Container

class FormApp(App):
    def compose(self) -> ComposeResult:
        yield Label("User Registration")

        # Text input
        yield Input(placeholder="Username", id="username")

        # Password input
        yield Input(
            placeholder="Password",
            password=True,
            id="password"
        )

        # Dropdown select
        yield Select(
            options=[
                ("Development", "dev"),
                ("Staging", "staging"),
                ("Production", "prod")
            ],
            prompt="Select environment",
            id="environment"
        )

        # Checkboxes
        yield Checkbox("Enable logging", id="logging")
        yield Checkbox("Enable monitoring", id="monitoring")

        # Radio buttons
        with RadioSet(id="role"):
            yield RadioButton("Admin")
            yield RadioButton("User")
            yield RadioButton("Guest")

        # Multi-line text
        yield TextArea(id="notes")

        # Submit button
        yield Button("Submit", id="submit", variant="primary")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "submit":
            # Collect form data
            data = {
                "username": self.query_one("#username", Input).value,
                "password": self.query_one("#password", Input).value,
                "environment": self.query_one("#environment", Select).value,
                "logging": self.query_one("#logging", Checkbox).value,
                "monitoring": self.query_one("#monitoring", Checkbox).value,
                "role": self.query_one(RadioSet).pressed_button.label,
                "notes": self.query_one("#notes", TextArea).text
            }

            # Process form
            self.process_registration(data)
```

#### CSS-like Styling

```python
# styles.css (or inline)
Input {
    border: solid blue;
    width: 100%;
}

Button {
    background: green;
    color: white;
}

#submit {
    margin: 1;
    background: blue;
}
```

```python
class FormApp(App):
    CSS_PATH = "styles.css"  # Load external CSS

    # Or inline:
    CSS = """
    Input {
        border: solid blue;
    }
    """
```

#### Pros/Cons

**Pros**:
- ✅ **Built-in markdown rendering** (Markdown, MarkdownViewer widgets)
- ✅ Comprehensive widget library (inputs, buttons, tables, trees, etc.)
- ✅ CSS-like styling
- ✅ Reactive programming model
- ✅ Hot reload for development
- ✅ **Runs in terminal AND browser** (WebAssembly support)
- ✅ Async/await support
- ✅ Great documentation

**Cons**:
- ❌ Python only
- ❌ TUI (not desktop GUI - stays in terminal)
- ❌ Requires modern terminal
- ❌ More complex than Gum for simple scripts

**Best For**:
- Python TUI applications
- Markdown-heavy interfaces (docs, help, content)
- Complex forms and data entry
- Developer tools, monitors, dashboards

---

### **Rich** (Python) - Markdown + Prompts Library

**Website**: https://github.com/Textualize/rich
**Language**: Python
**License**: MIT

**Description**: Library for rich text and beautiful formatting in the terminal. Textual is built on top of Rich.

#### Markdown Rendering

```python
from rich.console import Console
from rich.markdown import Markdown

console = Console()

MARKDOWN = """
# Hello, World!

This is **Rich** markdown rendering.

## Features
- Syntax highlighting
- Tables
- Lists
- Code blocks

\`\`\`python
def greet(name):
    print(f"Hello, {name}!")
\`\`\`
"""

md = Markdown(MARKDOWN)
console.print(md)
```

#### Interactive Prompts

```python
from rich.console import Console
from rich.prompt import Prompt, Confirm, IntPrompt

console = Console()

# Text input
name = Prompt.ask("Enter your name")

# Text input with default
email = Prompt.ask("Enter email", default="user@example.com")

# Choices (validation)
env = Prompt.ask(
    "Select environment",
    choices=["dev", "staging", "prod"],
    default="dev"
)

# Integer input
age = IntPrompt.ask("Enter your age")

# Confirmation
if Confirm.ask("Proceed with installation?"):
    console.print("[green]Installing...[/green]")
else:
    console.print("[red]Cancelled[/red]")
```

#### Rich Display Features

```python
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.syntax import Syntax

console = Console()

# Tables
table = Table(title="User Data")
table.add_column("Name", style="cyan")
table.add_column("Age", justify="right")
table.add_row("Alice", "30")
table.add_row("Bob", "25")
console.print(table)

# Panels/Boxes
console.print(Panel("Important message", title="Alert", border_style="red"))

# Syntax highlighting
code = '''
def hello():
    print("Hello!")
'''
syntax = Syntax(code, "python", theme="monokai", line_numbers=True)
console.print(syntax)

# Progress bars, spinners, etc.
```

#### Pros/Cons

**Pros**:
- ✅ **Markdown rendering**
- ✅ Interactive prompts
- ✅ Tables, panels, syntax highlighting
- ✅ Progress bars, status
- ✅ Lighter than Textual (library vs framework)
- ✅ Works with existing CLI code

**Cons**:
- ❌ Not a full framework (just a library)
- ❌ No complex widgets (use Textual for that)
- ❌ TUI only (stays in terminal)

**Best For**:
- Adding rich output to existing CLI
- Simple interactive prompts with markdown
- When Textual is overkill

---

## Category 3: Shell Script GUI Dialog Generators

### **YAD** (Yet Another Dialog)

**Website**: https://github.com/v1cont/yad
**Platform**: Linux (GTK+)
**License**: GPL

**Description**: Fork of Zenity with more features. Creates GTK+ GUI dialogs from shell scripts.

#### Form Builder

```bash
#!/bin/bash

# Multi-field form
yad --form \
    --title="User Registration" \
    --text="Enter your details:" \
    --field="Username" "" \
    --field="Password:H" "" \
    --field="Email" "" \
    --field="Country:CB" "USA!Canada!UK!Other" \
    --field="Admin:CHK" FALSE \
    --field="Notes:TXT" "" \
    --button="Register:0" \
    --button="Cancel:1"

# Capture output (fields separated by |)
IFS='|' read -r USERNAME PASSWORD EMAIL COUNTRY ADMIN NOTES <<< "$?"

echo "Username: $USERNAME"
echo "Email: $EMAIL"
echo "Country: $COUNTRY"
echo "Admin: $ADMIN"
```

#### Widget Types

| YAD Option         | Widget Type           | Example                                    |
|-------------------|----------------------|-------------------------------------------|
| `--entry`         | Text input           | `yad --entry --text="Enter name"`         |
| `--password`      | Password field       | `yad --entry --hide-text`                 |
| `--file`          | File picker          | `yad --file --filename=/path`             |
| `--calendar`      | Date picker          | `yad --calendar`                          |
| `--color`         | Color picker         | `yad --color`                             |
| `--list`          | List/table           | `yad --list --column=Name --column=Age`   |
| `--progress`      | Progress bar         | `yad --progress`                          |
| `--text-info`     | Text viewer          | `yad --text-info --filename=log.txt`      |
| `--form`          | Multi-field form     | `yad --form --field=Name --field=Email`   |

#### Advanced Form Example

```bash
#!/bin/bash

# Complex form with tabs
yad --notebook \
    --title="Application Settings" \
    --tab="General" \
    --tab="Advanced" \
    --form \
    --field="Name" "" \
    --field="Email" "" \
    --field="Enable logging:CHK" TRUE \
    --field="Log level:CB" "INFO!DEBUG!WARN!ERROR" \
    --form \
    --field="Max connections:NUM" "100!1..1000!10" \
    --field="Timeout:NUM" "30!1..300!5" \
    --field="Cache size:NUM" "1024!0..10240!256"
```

#### Pros/Cons

**Pros**:
- ✅ Rich form builder (multi-field, tabs, validation)
- ✅ Native GTK+ dialogs
- ✅ Works from any shell script
- ✅ File/directory/color pickers
- ✅ Tables, lists, progress bars

**Cons**:
- ❌ Linux/GTK+ only (not Windows/macOS without X11)
- ❌ No markdown rendering
- ❌ Dated appearance (GTK+2/3)
- ❌ Requires X11/Wayland display

**Best For**:
- Linux shell scripts
- System administration tools
- Installers for Linux applications

---

### **Zenity**

**Platform**: Linux (GTK+)
**License**: GPL

**Description**: Simple dialog boxes for shell scripts (YAD is more powerful fork).

#### Examples

```bash
# Text entry
NAME=$(zenity --entry --text="Enter your name:")

# File picker
FILE=$(zenity --file-selection --title="Select file")

# Yes/No confirmation
if zenity --question --text="Delete file?"; then
    rm "$FILE"
fi

# Progress bar
(
  echo "10"; sleep 1
  echo "50"; sleep 1
  echo "100"; sleep 1
) | zenity --progress --title="Processing" --text="Please wait..."

# Notification
zenity --notification --text="Task complete!"

# Multi-field form (limited compared to YAD)
zenity --forms \
    --title="User Info" \
    --text="Enter details" \
    --add-entry="Name" \
    --add-entry="Email" \
    --add-password="Password"
```

**Best For**: Simple dialogs, less complex than YAD

---

## Comparison Matrix

### Automatic CLI → GUI Converters

| Tool           | Language | Markdown | Forms | Widgets | Auto-Gen | Platform    | Bundle Size |
|---------------|----------|----------|-------|---------|----------|-------------|-------------|
| **Gooey**     | Python   | ❌       | ✅    | ✅      | ✅ (argparse) | Cross-platform | ~50 MB |
| **inquirer-gui** | JS/TS | ❌       | ✅    | ✅      | ✅ (Inquirer) | Browser/VSCode | Small |
| **YAD**       | Shell    | ❌       | ✅    | ✅      | ❌        | Linux/GTK+  | Small |
| **Zenity**    | Shell    | ❌       | ⚠️    | ⚠️      | ❌        | Linux/GTK+  | Small |

### TUI with Rich Widgets

| Tool           | Language | Markdown | Forms | Widgets | Browser | Platform    | Complexity |
|---------------|----------|----------|-------|---------|---------|-------------|-----------|
| **Textual**   | Python   | ✅ Full  | ✅    | ✅      | ✅      | Cross-platform | Medium |
| **Rich**      | Python   | ✅ Basic | ⚠️    | ❌      | ❌      | Cross-platform | Low |
| **Gum**       | Go/Shell | ✅ Basic | ⚠️    | ⚠️      | ❌      | Cross-platform | Low |

---

## Use Case Recommendations

### "I have existing Python CLI with argparse"
→ **Use Gooey** - Add `@Gooey` decorator, instant GUI

### "I have shell script needing user input with markdown"
→ **Use Charm Gum** - Call `gum choose`, `gum format`, etc.

### "I'm building new Python TUI with rich markdown rendering"
→ **Use Textual** - Full framework with Markdown widget

### "I need simple Linux GUI dialogs from bash"
→ **Use YAD** (or Zenity for basics)

### "I have Inquirer.js prompts, want GUI for VS Code extension"
→ **Use inquirer-gui** - Converts to HTML form

### "I want beautiful terminal output with markdown and prompts"
→ **Use Rich** - Lightweight library for existing CLI

---

## BitBot Specific Recommendations

**For BitBot CLI wrapper with markdown support:**

### Option 1: Gum (Shell Scripts) ⭐ Easiest
Since BitBot is primarily bash-based:

```bash
#!/bin/bash
# bitbot-interactive.sh

# Show welcome with markdown
gum format <<EOF
# Welcome to BitBot

Choose your workspace mode:
EOF

# Choose mode
MODE=$(gum choose "work" "config" "dev")

# Get workspace name
WORKSPACE=$(gum input --placeholder "Workspace name")

# Show settings as markdown
gum format <<EOF
## Configuration

- **Mode**: $MODE
- **Workspace**: $WORKSPACE

Ready to start?
EOF

# Confirm and launch
gum confirm "Start workspace?" && {
    bitbot $MODE $WORKSPACE
}
```

**Pros**:
- ✅ Works with existing bash scripts
- ✅ Markdown rendering built-in
- ✅ Beautiful, modern UI
- ✅ Minimal changes to BitBot

---

### Option 2: Textual (Python) - More Powerful

Build Python wrapper for BitBot with full TUI:

```python
from textual.app import App, ComposeResult
from textual.widgets import (
    Header, Footer, Markdown, Button,
    Select, Input, RadioSet, RadioButton
)
from textual.containers import Container
import subprocess

class BitBotTUI(App):
    """TUI for BitBot with markdown rendering."""

    CSS = """
    Container {
        padding: 1;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header()

        # Welcome markdown
        yield Markdown("""
        # Welcome to BitBot

        BitBot provides **secure AI development environments**
        using DevContainers.

        ## Choose Your Mode:
        """)

        # Mode selection
        with RadioSet(id="mode"):
            yield RadioButton("work - AI-powered workspace")
            yield RadioButton("config - Configuration tools")
            yield RadioButton("dev - BitBot development")

        # Workspace input
        yield Input(placeholder="Workspace name", id="workspace")

        # Action buttons
        with Container():
            yield Button("Start", id="start", variant="primary")
            yield Button("Cancel", id="cancel")

        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "start":
            mode = self.query_one(RadioSet).pressed_button.label.split()[0]
            workspace = self.query_one("#workspace", Input).value

            # Launch bitbot
            subprocess.run(["bitbot", mode, workspace])
            self.exit()

        elif event.button.id == "cancel":
            self.exit()

if __name__ == "__main__":
    app = BitBotTUI()
    app.run()
```

**Pros**:
- ✅ Full markdown rendering
- ✅ Rich form widgets
- ✅ Can run in browser (WebAssembly)
- ✅ Professional TUI

**Cons**:
- ❌ Requires Python dependency
- ❌ More complex than Gum

---

### Option 3: Gooey (Python) - Full Desktop GUI

If you want actual desktop GUI (not TUI):

```python
from gooey import Gooey, GooeyParser
import subprocess

@Gooey(
    program_name='BitBot',
    program_description='Secure AI Development Environment',
    default_size=(600, 500)
)
def main():
    parser = GooeyParser(description='BitBot Launcher')

    parser.add_argument(
        'mode',
        choices=['work', 'config', 'dev'],
        help='Workspace mode'
    )

    parser.add_argument(
        '--workspace',
        help='Workspace name',
        default='my-workspace'
    )

    args = parser.parse_args()

    # Launch bitbot
    subprocess.run(['bitbot', args.mode, args.workspace])

if __name__ == '__main__':
    main()
```

**Pros**:
- ✅ Desktop GUI (not terminal)
- ✅ Automatic widget generation
- ✅ Easy implementation

**Cons**:
- ❌ No markdown rendering
- ❌ Larger bundle (~50 MB)

---

## Summary

### Top Picks by Need:

| Need                          | Recommended Tool  | Why                                           |
|------------------------------|------------------|-----------------------------------------------|
| Python CLI → GUI             | **Gooey**        | One decorator, automatic widget mapping       |
| Shell script + markdown      | **Charm Gum**    | Built-in markdown, beautiful components       |
| Python TUI with markdown     | **Textual**      | Full framework, Markdown widget, rich forms   |
| Quick terminal markdown      | **Rich**         | Lightweight, simple API                       |
| Inquirer.js → GUI            | **inquirer-gui** | Direct conversion to HTML forms               |
| Linux shell dialogs          | **YAD**          | Rich form builder, GTK+ native                |

### For BitBot:
1. **Quick win**: Use **Charm Gum** in bash scripts (built-in markdown)
2. **Rich TUI**: Use **Textual** Python wrapper (full markdown + widgets)
3. **Desktop GUI**: Use **Gooey** for actual GUI application

All three support your requirement for markdown rendering and form inputs!

---

## Installation Quick Reference

```bash
# Gooey (Python)
pip install Gooey

# Gum (Go)
brew install gum          # macOS
scoop install gum         # Windows
sudo apt install gum      # Ubuntu/Debian

# Textual (Python)
pip install textual
pip install textual-dev   # Development tools

# Rich (Python)
pip install rich

# YAD (Linux)
sudo apt install yad

# Zenity (Linux)
sudo apt install zenity
```

---

## Revision History

| Date       | Version | Changes                              |
|-----------|---------|--------------------------------------|
| 2025-11-14| 1.0     | Initial research compilation         |

---

**End of Research Document**
