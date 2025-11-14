# Interactive CLI Frameworks and Tools

**Research Date**: 2025-11-14
**Purpose**: Research frameworks and libraries for building interactive command-line interfaces
**Status**: Complete

## Overview

This document covers frameworks and libraries for building **interactive CLI applications** with:
- ✅ **Interactive prompts** (text input, confirmations, selections)
- ✅ **Forms and wizards** (multi-step input collection)
- ✅ **REPL/Shell modes** (persistent interactive sessions)
- ✅ **Auto-completion** (tab completion, suggestions)
- ✅ **Rich formatting** (colors, tables, progress bars)

These tools make CLIs more user-friendly by allowing interactive input instead of requiring all arguments upfront.

---

## Tool Categories

### Category 1: Prompt Libraries
**Purpose**: Add interactive prompts to existing CLIs
**Examples**: Inquirer.js, questionary, Clack

### Category 2: CLI Frameworks with Prompts
**Purpose**: Complete CLI frameworks with built-in prompt support
**Examples**: Click, Typer, Commander.js

### Category 3: REPL Builders
**Purpose**: Build interactive shell/REPL experiences
**Examples**: Prompt Toolkit, Vorpal

### Category 4: Advanced TUI Frameworks
**Purpose**: Full terminal UI with forms and widgets
**Examples**: Already covered in other research docs (Textual, Bubble Tea, etc.)

---

## Python Interactive CLI Tools

### **Python Prompt Toolkit** ⭐ Most Powerful

**Website**: https://github.com/prompt-toolkit/python-prompt-toolkit
**License**: BSD
**Status**: Active, industry standard

**Description**: Library for building powerful interactive command-line applications and REPLs in Python. Can be a pure Python replacement for GNU readline.

#### Key Features

- **Advanced line editing**: Multi-line input, Vi/Emacs key bindings
- **Auto-completion**: Intelligent tab completion
- **Auto-suggestions**: Fish-style suggestions from history
- **Syntax highlighting**: Real-time syntax highlighting while typing
- **Reverse/forward search**: Search command history
- **Mouse support**: Click to position cursor, scroll
- **Cross-platform**: Windows, Linux, macOS

#### Example: Simple REPL

```python
from prompt_toolkit import prompt
from prompt_toolkit.history import FileHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.completion import WordCompleter

# Define completions
command_completer = WordCompleter(
    ['start', 'stop', 'restart', 'status', 'config', 'help', 'exit'],
    ignore_case=True
)

# Create REPL
def main():
    print("Welcome to MyApp REPL. Type 'exit' to quit.")

    while True:
        try:
            # Prompt with history, auto-suggest, and completion
            user_input = prompt(
                '> ',
                history=FileHistory('.myapp_history'),
                auto_suggest=AutoSuggestFromHistory(),
                completer=command_completer
            )

            if user_input.lower() == 'exit':
                break

            # Process command
            process_command(user_input)

        except KeyboardInterrupt:
            continue
        except EOFError:
            break

if __name__ == '__main__':
    main()
```

#### Example: Advanced Input with Validation

```python
from prompt_toolkit import prompt
from prompt_toolkit.validation import Validator, ValidationError
from prompt_toolkit.styles import Style

# Custom validator
class NumberValidator(Validator):
    def validate(self, document):
        text = document.text
        if text and not text.isdigit():
            raise ValidationError(
                message='Please enter a number',
                cursor_position=len(text)
            )

# Custom style
style = Style.from_dict({
    'prompt': '#00aa00 bold',
    'input': '#ffffff',
})

# Get validated input
number = prompt(
    'Enter a number: ',
    validator=NumberValidator(),
    validate_while_typing=True,
    style=style
)
```

#### Used By

- **IPython** - Interactive Python shell
- **ptpython** - Advanced Python REPL
- **pgcli** - PostgreSQL client
- **mycli** - MySQL client
- Many other interactive CLI tools

#### Pros/Cons

**Pros**:
- ✅ Most powerful Python REPL/CLI library
- ✅ Advanced features (auto-suggest, syntax highlighting, multi-line)
- ✅ Excellent documentation
- ✅ Cross-platform
- ✅ Very customizable

**Cons**:
- ❌ Steeper learning curve than simple prompt libraries
- ❌ Overkill for simple yes/no prompts

**Best For**:
- Building full REPL/shell applications
- Advanced CLIs with auto-completion
- Database clients, code editors, interactive tools

---

### **questionary** ⭐ Beautiful & Easy

**Website**: https://github.com/tmbo/questionary
**License**: MIT
**Status**: Active

**Description**: Python library based on Prompt Toolkit to effortlessly build pretty command-line interfaces.

#### Prompt Types

| Type | Purpose | Example |
|------|---------|---------|
| `text` | Free-form text input | Name, email, etc. |
| `password` | Masked password input | Login credentials |
| `confirm` | Yes/No question | "Continue?" |
| `select` | Choose one from list | Pick option from menu |
| `checkbox` | Choose multiple | Select features to enable |
| `path` | File/directory path | File picker with auto-complete |
| `autocomplete` | Text with suggestions | Command with completions |

#### Example: Simple Prompts

```python
import questionary

# Text input
name = questionary.text("What's your name?").ask()

# Password
password = questionary.password("Password:").ask()

# Confirmation
confirmed = questionary.confirm("Continue?").ask()

# Select from list
choice = questionary.select(
    "Choose workspace mode:",
    choices=['work', 'config', 'dev']
).ask()

# Multi-select
features = questionary.checkbox(
    "Select features:",
    choices=[
        'Logging',
        'Monitoring',
        'Analytics',
        'Alerts'
    ]
).ask()

print(f"Selected features: {features}")
```

#### Example: Form (Multiple Questions)

```python
import questionary

# Define questions
questions = [
    {
        'type': 'text',
        'name': 'username',
        'message': 'Username:',
        'validate': lambda x: len(x) >= 3 or 'Username too short'
    },
    {
        'type': 'password',
        'name': 'password',
        'message': 'Password:'
    },
    {
        'type': 'select',
        'name': 'role',
        'message': 'Select role:',
        'choices': ['Admin', 'User', 'Guest']
    },
    {
        'type': 'confirm',
        'name': 'agree',
        'message': 'Agree to terms?',
        'default': False
    }
]

# Prompt for all answers
answers = questionary.prompt(questions)

print(answers)
# {'username': 'john', 'password': '***', 'role': 'Admin', 'agree': True}
```

#### Example: Conditional Questions

```python
import questionary

def ask_questions():
    # Ask first question
    use_docker = questionary.confirm("Use Docker?").ask()

    # Conditional follow-up
    if use_docker:
        image = questionary.text(
            "Docker image:",
            default="python:3.11"
        ).ask()
    else:
        python_version = questionary.select(
            "Python version:",
            choices=['3.9', '3.10', '3.11', '3.12']
        ).ask()
```

#### Styling

```python
from questionary import Style

custom_style = Style([
    ('qmark', 'fg:#673ab7 bold'),       # Question mark
    ('question', 'bold'),                # Question text
    ('answer', 'fg:#f44336 bold'),      # User answer
    ('pointer', 'fg:#673ab7 bold'),     # Selection pointer
    ('highlighted', 'fg:#673ab7 bold'), # Highlighted choice
    ('selected', 'fg:#cc5454'),         # Selected choice
])

answer = questionary.select(
    "Choose option:",
    choices=['Option 1', 'Option 2'],
    style=custom_style
).ask()
```

#### Pros/Cons

**Pros**:
- ✅ Very easy to use
- ✅ Beautiful, modern styling
- ✅ Built on Prompt Toolkit (powerful foundation)
- ✅ Good documentation with examples
- ✅ Path completion built-in
- ✅ Validation support

**Cons**:
- ❌ Less powerful than raw Prompt Toolkit for advanced use cases
- ❌ Limited customization compared to Prompt Toolkit

**Best For**:
- Interactive installers/wizards
- Configuration tools
- User onboarding
- Quick prototyping

---

### **Click** - CLI Framework with Prompts

**Website**: https://click.palletsprojects.com/
**License**: BSD
**Status**: Active (Pallets project - same as Flask)

**Description**: Composable command-line interface framework for Python with built-in prompt support.

#### Example: Basic Prompts

```python
import click

@click.command()
@click.option('--name', prompt='Your name', help='The person to greet')
@click.option('--count', prompt='Number of greetings', type=int, default=1)
def hello(name, count):
    """Simple program that greets NAME."""
    for _ in range(count):
        click.echo(f'Hello, {name}!')

if __name__ == '__main__':
    hello()
```

**Running**:
```bash
$ python greet.py
Your name: Alice
Number of greetings: 3
Hello, Alice!
Hello, Alice!
Hello, Alice!
```

#### Example: Password Prompt

```python
import click

@click.command()
@click.option('--username', prompt=True)
@click.password_option()  # Automatically prompts and confirms
def login(username, password):
    click.echo(f'Logging in as {username}...')
```

#### Example: Confirmation Prompt

```python
import click

@click.command()
@click.option('--yes', is_flag=True, callback=abort_if_false,
              expose_value=False,
              prompt='Are you sure you want to delete?')
def delete():
    click.echo('Deleting...')

def abort_if_false(ctx, param, value):
    if not value:
        ctx.abort()
```

#### Example: Choice Prompt

```python
import click

@click.command()
@click.option('--environment',
              type=click.Choice(['dev', 'staging', 'prod']),
              prompt='Select environment')
def deploy(environment):
    click.echo(f'Deploying to {environment}')
```

#### Pros/Cons

**Pros**:
- ✅ Full-featured CLI framework (not just prompts)
- ✅ Composable commands and groups
- ✅ Well-documented, widely used
- ✅ Prompts integrate seamlessly with options
- ✅ Testing support built-in

**Cons**:
- ❌ Prompts are basic (not as rich as questionary)
- ❌ No built-in list selection (use questionary with Click)

**Best For**:
- Building complete CLI applications
- When you need command grouping/nesting
- Applications with both interactive and non-interactive modes

---

### **Typer** - Modern CLI Framework

**Website**: https://typer.tiangolo.com/
**License**: MIT
**Status**: Active (by creator of FastAPI)

**Description**: Modern CLI framework based on Click with Python type hints. Easier than Click with similar functionality.

#### Example: Interactive Prompts

```python
import typer

def main():
    # Simple prompt
    name = typer.prompt("What's your name?")

    # Typed prompt (validates automatically)
    age = typer.prompt("What's your age?", type=int)

    # Password prompt
    password = typer.prompt("Password", hide_input=True)

    # Confirmation prompt
    typer.confirm("Are you sure?", abort=True)

    typer.echo(f"Hello {name}, age {age}")

if __name__ == "__main__":
    typer.run(main)
```

#### Example: CLI Options with Prompts

```python
import typer

def main(
    name: str = typer.Option(..., prompt=True),
    workspace: str = typer.Option("default", prompt="Workspace name"),
    verbose: bool = typer.Option(False, prompt="Enable verbose mode?")
):
    typer.echo(f"Name: {name}, Workspace: {workspace}, Verbose: {verbose}")

if __name__ == "__main__":
    typer.run(main)
```

#### Example: Password with Confirmation

```python
import typer

def main():
    password = typer.prompt(
        "Password",
        hide_input=True,
        confirmation_prompt=True  # Ask twice to confirm
    )
    typer.echo("Password set!")

if __name__ == "__main__":
    typer.run(main)
```

#### Pros/Cons

**Pros**:
- ✅ Modern, uses type hints
- ✅ Easier than Click
- ✅ Great documentation
- ✅ Auto-generates help from docstrings
- ✅ Built on Click (solid foundation)

**Cons**:
- ❌ Prompts still basic (like Click)
- ❌ Newer than Click (smaller ecosystem)

**Best For**:
- New projects preferring modern Python style
- FastAPI users (same author, similar philosophy)
- Type-hinted CLI applications

---

## JavaScript/TypeScript Interactive CLI Tools

### **Inquirer.js** ⭐ Industry Standard

**Website**: https://github.com/SBoudrias/Inquirer.js
**License**: MIT
**Status**: Active (legacy), Modern: @inquirer/prompts

**Description**: Collection of common interactive command-line user interfaces for Node.js.

#### Prompt Types

- `input` - Text input
- `number` - Number input
- `confirm` - Yes/no
- `list` - Select from list (arrow keys)
- `rawlist` - Numbered list
- `expand` - Compact list (single key selection)
- `checkbox` - Multi-select
- `password` - Masked input
- `editor` - Opens external editor

#### Example: Basic Usage

```javascript
const inquirer = require('inquirer');

inquirer.prompt([
  {
    type: 'input',
    name: 'username',
    message: 'Enter your username:',
    validate: (input) => input.length >= 3 || 'Too short'
  },
  {
    type: 'password',
    name: 'password',
    message: 'Enter your password:',
    mask: '*'
  },
  {
    type: 'list',
    name: 'environment',
    message: 'Select environment:',
    choices: ['Development', 'Staging', 'Production']
  },
  {
    type: 'checkbox',
    name: 'features',
    message: 'Select features:',
    choices: [
      'Logging',
      'Monitoring',
      'Analytics',
      'Alerts'
    ]
  },
  {
    type: 'confirm',
    name: 'proceed',
    message: 'Proceed with installation?',
    default: false
  }
]).then(answers => {
  console.log(JSON.stringify(answers, null, 2));
});
```

#### Example: Conditional Questions

```javascript
const questions = [
  {
    type: 'confirm',
    name: 'useDocker',
    message: 'Use Docker?'
  },
  {
    type: 'input',
    name: 'dockerImage',
    message: 'Docker image:',
    when: (answers) => answers.useDocker,  // Only ask if useDocker is true
    default: 'node:18'
  }
];

inquirer.prompt(questions).then(answers => {
  console.log(answers);
});
```

#### Modern Version (@inquirer/prompts)

```javascript
import { input, select, confirm, checkbox } from '@inquirer/prompts';

// Individual prompts
const name = await input({ message: 'Enter your name:' });
const env = await select({
  message: 'Select environment:',
  choices: ['dev', 'staging', 'prod']
});
const proceed = await confirm({ message: 'Continue?' });
```

#### Pros/Cons

**Pros**:
- ✅ Industry standard (most popular Node.js prompt library)
- ✅ Rich prompt types
- ✅ Validation, filtering, transformation
- ✅ Conditional questions (when/skip)
- ✅ Large ecosystem of plugins

**Cons**:
- ❌ Legacy API can be verbose
- ❌ Modern version (@inquirer/prompts) not backward compatible

**Best For**:
- Node.js CLI applications
- Interactive installers (create-react-app uses it)
- Configuration wizards

---

### **Clack** ⭐ Modern & Beautiful

**Website**: https://www.npmjs.com/package/@clack/prompts
**License**: MIT
**Status**: Active, modern alternative to Inquirer

**Description**: Effortlessly build beautiful command-line apps with modern design.

#### Components

- `text()` - Text input
- `password()` - Password input
- `confirm()` - Yes/no
- `select()` - Single selection
- `multiselect()` - Multiple selections
- `spinner()` - Loading indicator
- `intro()` / `outro()` - Session messages
- `group()` - Group related prompts

#### Example: Beautiful CLI

```javascript
import * as p from '@clack/prompts';

async function main() {
  console.clear();

  p.intro('🚀 Welcome to MyApp Setup');

  const answers = await p.group({
    name: () => p.text({
      message: 'What is your name?',
      placeholder: 'John Doe',
      validate: (value) => {
        if (value.length < 3) return 'Name too short';
      }
    }),

    mode: () => p.select({
      message: 'Pick a project mode:',
      options: [
        { value: 'work', label: 'Work Mode' },
        { value: 'config', label: 'Configuration' },
        { value: 'dev', label: 'Development' }
      ]
    }),

    features: () => p.multiselect({
      message: 'Select features:',
      options: [
        { value: 'logging', label: 'Logging' },
        { value: 'monitoring', label: 'Monitoring' },
        { value: 'analytics', label: 'Analytics' }
      ]
    }),

    proceed: () => p.confirm({
      message: 'Ready to proceed?'
    })
  }, {
    onCancel: () => {
      p.cancel('Operation cancelled');
      process.exit(0);
    }
  });

  // Show spinner during operation
  const s = p.spinner();
  s.start('Setting up project...');

  await doSetup(answers);

  s.stop('Setup complete!');

  p.outro('✨ All done!');
}

main().catch(console.error);
```

#### Pros/Cons

**Pros**:
- ✅ Modern, beautiful design
- ✅ TypeScript-first
- ✅ Excellent UX (animations, spinners)
- ✅ Group prompts together
- ✅ Clean, minimal API

**Cons**:
- ❌ Newer than Inquirer (smaller ecosystem)
- ❌ Fewer prompt types than Inquirer

**Best For**:
- Modern Node.js/TypeScript projects
- Beautiful user experience
- CLIs needing polish

---

### **Commander.js** - CLI Framework

**Website**: https://www.npmjs.com/package/commander
**License**: MIT
**Status**: Active, very popular

**Description**: Complete solution for Node.js command-line interfaces. Doesn't include prompts but pairs well with Inquirer/Clack.

#### Example: Commander + Inquirer

```javascript
const { program } = require('commander');
const inquirer = require('inquirer');

program
  .command('init')
  .description('Initialize project')
  .action(async () => {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'name',
        message: 'Project name:'
      },
      {
        type: 'list',
        name: 'template',
        message: 'Select template:',
        choices: ['React', 'Vue', 'Angular']
      }
    ]);

    console.log(`Creating ${answers.name} with ${answers.template}...`);
  });

program.parse();
```

#### Interactive Commander (All-in-One)

**Package**: `interactive-commander`

Extends Commander.js with automatic prompts for missing options:

```javascript
const { InteractiveCommand } = require('interactive-commander');

const program = new InteractiveCommand();

program
  .option('-n, --name <name>', 'Project name')
  .option('-t, --template <template>', 'Template type')
  .action(async (options) => {
    // Automatically prompts for missing options!
    console.log(options);
  });

program.parse();
```

#### Pros/Cons

**Pros**:
- ✅ Most popular Node.js CLI framework
- ✅ Comprehensive feature set (sub-commands, options, etc.)
- ✅ Pairs well with any prompt library
- ✅ Large ecosystem

**Cons**:
- ❌ No built-in prompts (need separate library)
- ❌ More verbose than some alternatives

**Best For**:
- Complex CLI applications with sub-commands
- When you need mature, battle-tested framework

---

## Go Interactive CLI Tools

### **Cobra** - CLI Framework

**Website**: https://github.com/spf13/cobra
**License**: Apache 2.0
**Status**: Active (used by Kubernetes, Docker, GitHub CLI)

**Description**: Modern Go CLI framework. No built-in prompts but pairs with prompt libraries.

#### Example: Cobra + promptui

```go
package main

import (
    "github.com/spf13/cobra"
    "github.com/manifoldco/promptui"
)

func main() {
    var rootCmd = &cobra.Command{
        Use:   "myapp",
        Short: "My application",
        Run: func(cmd *cobra.Command, args []string) {
            // Text prompt
            namePrompt := promptui.Prompt{
                Label: "Your name",
            }
            name, _ := namePrompt.Run()

            // Select prompt
            selectPrompt := promptui.Select{
                Label: "Select Environment",
                Items: []string{"Development", "Staging", "Production"},
            }
            _, env, _ := selectPrompt.Run()

            // Confirm prompt
            confirmPrompt := promptui.Prompt{
                Label:     "Proceed",
                IsConfirm: true,
            }
            _, _ = confirmPrompt.Run()

            fmt.Printf("Hello %s, deploying to %s\n", name, env)
        },
    }

    rootCmd.Execute()
}
```

#### Example: Cobra + survey

```go
package main

import (
    "github.com/AlecAivazis/survey/v2"
    "github.com/spf13/cobra"
)

func main() {
    var rootCmd = &cobra.Command{
        Use: "myapp",
        Run: func(cmd *cobra.Command, args []string) {
            var qs = []*survey.Question{
                {
                    Name: "name",
                    Prompt: &survey.Input{
                        Message: "What is your name?",
                    },
                    Validate: survey.Required,
                },
                {
                    Name: "environment",
                    Prompt: &survey.Select{
                        Message: "Choose environment:",
                        Options: []string{"dev", "staging", "prod"},
                    },
                },
                {
                    Name: "features",
                    Prompt: &survey.MultiSelect{
                        Message: "Select features:",
                        Options: []string{"Logging", "Monitoring", "Analytics"},
                    },
                },
            }

            answers := struct {
                Name        string
                Environment string
                Features    []string
            }{}

            survey.Ask(qs, &answers)
            fmt.Printf("%+v\n", answers)
        },
    }

    rootCmd.Execute()
}
```

#### Prompt Libraries for Go

| Library | Purpose | Features |
|---------|---------|----------|
| **promptui** | Simple prompts | Text, select, confirm |
| **survey** | Rich prompts | Multi-select, validation, help text |
| **go-prompt** | REPL/autocomplete | Advanced readline-like experience |
| **huh** | Charm Bubble Tea forms | Beautiful TUI forms (from Charm ecosystem) |

---

## REPL/Shell Builders

### **Vorpal** (Node.js) - Immersive CLI

**Website**: https://github.com/dthree/vorpal
**Status**: Unmaintained (use alternatives like oclif + Inquirer)

**Description**: Framework for building immersive CLI applications with persistent shell sessions.

**Concept**: Unlike Commander which requires re-running for each command, Vorpal maintains session state.

```javascript
const vorpal = require('vorpal')();

vorpal
  .command('start [service]', 'Start a service')
  .action(function(args, callback) {
    this.log(`Starting ${args.service}...`);
    callback();
  });

vorpal
  .command('status', 'Check status')
  .action(function(args, callback) {
    this.log('Status: running');
    callback();
  });

vorpal
  .delimiter('myapp$')
  .show();
```

**Output**:
```
myapp$ start api
Starting api...
myapp$ status
Status: running
myapp$ exit
```

**Note**: Vorpal is unmaintained - consider using **oclif** (Salesforce's CLI framework) or building custom REPL with Inquirer.

---

### **Python cmd Module** - Built-in REPL

Python's built-in `cmd` module for simple REPL/shell applications:

```python
import cmd

class MyShell(cmd.Cmd):
    intro = 'Welcome to MyApp. Type help or ? to list commands.\n'
    prompt = 'myapp> '

    def do_start(self, arg):
        """Start a service: start <service>"""
        print(f'Starting {arg}...')

    def do_status(self, arg):
        """Show status"""
        print('Status: running')

    def do_exit(self, arg):
        """Exit the shell"""
        print('Goodbye!')
        return True

if __name__ == '__main__':
    MyShell().cmdloop()
```

---

## Comparison Matrix

### Python Prompt Libraries

| Tool | Complexity | Features | Best Use Case |
|------|-----------|----------|---------------|
| **Prompt Toolkit** | High | REPL, autocomplete, syntax highlighting | Advanced REPLs, database clients |
| **questionary** | Low | Beautiful prompts, forms | Installers, wizards |
| **Click** | Medium | Full CLI framework + basic prompts | Complete CLI apps |
| **Typer** | Low-Medium | Modern CLI framework + prompts | New projects, type-hinted CLIs |

### JavaScript/TypeScript Prompt Libraries

| Tool | Complexity | Features | Best Use Case |
|------|-----------|----------|---------------|
| **Inquirer.js** | Low | Rich prompt types, validation | Mature projects, complex forms |
| **@inquirer/prompts** | Low | Modern Inquirer, promises | New projects (modern) |
| **Clack** | Low | Beautiful UX, spinners | Modern CLIs, great UX |
| **Commander.js** | Medium | Full CLI framework | Complex CLIs with sub-commands |

### Go Prompt Libraries

| Tool | Complexity | Features | Best Use Case |
|------|-----------|----------|---------------|
| **promptui** | Low | Simple prompts | Basic interactive input |
| **survey** | Medium | Rich prompts, validation | Complex forms |
| **go-prompt** | High | REPL, autocomplete | Interactive shells |
| **huh** | Medium | TUI forms (Bubble Tea) | Beautiful terminal forms |

---

## For BitBot Specifically

Since BitBot is bash-based, here are interactive options:

### Option 1: **Gum** (Already Mentioned) ⭐ Best for Bash

```bash
#!/bin/bash

# Interactive BitBot launcher using Gum
MODE=$(gum choose "work" "config" "dev")
WORKSPACE=$(gum input --placeholder "workspace-name")

if gum confirm "Start workspace $WORKSPACE in $MODE mode?"; then
    bitbot $MODE $WORKSPACE
fi
```

**Pros**: Works directly in bash, beautiful prompts

---

### Option 2: **Python Wrapper with questionary**

```python
#!/usr/bin/env python3
import questionary
import subprocess

mode = questionary.select(
    "Select mode:",
    choices=['work', 'config', 'dev']
).ask()

workspace = questionary.text(
    "Workspace name:",
    default="my-workspace"
).ask()

if questionary.confirm(f"Start {workspace} in {mode} mode?").ask():
    subprocess.run(['bitbot', mode, workspace])
```

**Pros**: More features than Gum, easier validation

---

### Option 3: **Node.js Wrapper with Clack**

```javascript
#!/usr/bin/env node
import * as p from '@clack/prompts';
import { spawn } from 'child_process';

async function main() {
  p.intro('🤖 BitBot Launcher');

  const answers = await p.group({
    mode: () => p.select({
      message: 'Select mode:',
      options: [
        { value: 'work', label: 'Work Mode' },
        { value: 'config', label: 'Configuration' },
        { value: 'dev', label: 'Development' }
      ]
    }),
    workspace: () => p.text({
      message: 'Workspace name:',
      placeholder: 'my-workspace'
    })
  });

  if (await p.confirm({ message: 'Start workspace?' })) {
    spawn('bitbot', [answers.mode, answers.workspace], { stdio: 'inherit' });
  }

  p.outro('✨ Done!');
}

main().catch(console.error);
```

**Pros**: Beautiful UX, modern design

---

## Summary

### Top Picks by Language:

| Language | Best Interactive Tool | Why |
|----------|----------------------|-----|
| **Python** | questionary | Beautiful, easy, feature-rich |
| **JavaScript/TypeScript** | Clack | Modern, beautiful UX |
| **Go** | survey | Rich features, validation |
| **Bash** | Gum | Works directly in shell scripts |

### For Different Use Cases:

- **Simple prompts**: questionary (Python), Clack (JS), promptui (Go)
- **Complex forms**: Inquirer.js (JS), Prompt Toolkit (Python), survey (Go)
- **REPL/Shell**: Prompt Toolkit (Python), go-prompt (Go)
- **CLI Frameworks**: Typer (Python), Commander.js (JS), Cobra (Go)

### For BitBot:

1. **Quick**: Gum in bash scripts
2. **Python wrapper**: questionary for rich prompts
3. **Node.js wrapper**: Clack for beautiful UX

All provide interactive prompts without requiring desktop GUI!

---

## Installation Quick Reference

```bash
# Python
pip install prompt-toolkit questionary click typer

# Node.js
npm install inquirer @inquirer/prompts @clack/prompts commander

# Go
go get github.com/manifoldco/promptui
go get github.com/AlecAivazis/survey/v2
go get github.com/spf13/cobra

# Gum (standalone)
brew install gum  # macOS
scoop install gum # Windows
```

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-14 | 1.0 | Initial research compilation |

---

**End of Research Document**
