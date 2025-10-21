# Feature 01: The `bitbot` Command (CLI)

## 1. Description

The core entry point for the user to interact with BitBot. It needs to be a single, cross-platform command that is easy to install and use. It will be responsible for parsing user commands and orchestrating the underlying operations.

*Reference: `info.txt` (line 21), `Gemini_BITBOT_PLANNING.md`*

## 2. Chosen Approach

A hybrid approach was selected. For Windows, a native `bitbot.exe` launcher will be created. This launcher's sole responsibility is to call into the Windows Subsystem for Linux (WSL) and execute a `bitbot` bash script, passing along all command-line arguments. This keeps the core logic centralized in the bash script while providing a seamless native experience for Windows users.

### 2.1. Implementation: `bitbot.exe` Launcher

The launcher will be written in C for minimal dependencies and maximum efficiency.

**Source Code (`bitbot.c`):**
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // Start with the base command to execute the bitbot script via WSL.
    // This assumes the 'bitbot' bash script is located in a directory
    // that is part of WSL's $PATH, like /usr/local/bin/.
    char command[4096] = "wsl.exe bitbot ";

    // Append all arguments given to bitbot.exe to the WSL command.
    // We quote each argument to handle spaces correctly.
    for (int i = 1; i < argc; i++) {
        strcat(command, "\"");
        strcat(command, argv[i]);
        strcat(command, "\" ");
    }

    // Execute the fully constructed command.
    int exit_code = system(command);

    // Return the exit code from the WSL script to the Windows terminal.
    return exit_code;
}
```

### 2.2. Compilation

The C code can be compiled into `bitbot.exe` using `gcc` (from MinGW-w64) with the command:
```bash
gcc bitbot.c -o bitbot.exe
```

This approach provides a simple, dependency-free native launcher on Windows that acts as a direct bridge to the core `bitbot` logic within WSL.

## 3. Workspace Detection and Initialization

The `bitbot` CLI needs to identify the correct workspace context for each command. The following logic will be used to discover and initialize workspaces:

1.  **Check Current Directory:** When `bitbot` is executed, it first looks for a `.bitbot` directory in the current working directory.
2.  **Walk Up the Tree:** If a `.bitbot` directory is not found in the current directory, the CLI will traverse up the directory tree, checking each parent directory for the `.bitbot` marker.
3.  **Confirm Parent Workspace:** If a `.bitbot` directory is found in a parent directory, the user will be prompted to confirm that they want to run the command in the context of that parent workspace.
4.  **Initialize New Workspace:** If the directory traversal reaches the root of the filesystem without finding a `.bitbot` directory, the CLI will assume a new workspace is being created and will start the initialization process in the current directory.

## 4. Command Structure

The `bitbot` CLI uses a hybrid model to manage the container lifecycles.

### 4.1. Work Container Commands

These commands operate on the primary **work container** and are wrappers around the standard `@devcontainers/cli`.

*   `bitbot up`: Wraps `devcontainer up` to build and start the work container.
*   `bitbot down`: Wraps `devcontainer down` to stop the work container.
*   `bitbot shell`: Wraps `devcontainer exec` to open a shell inside the work container.
*   `bitbot run <command>`: Wraps `devcontainer exec -- <command>` to execute a command.

### 4.2. Setup Container Command

This command is used to enter the advanced setup and recovery environment.

*   `bitbot setup`: Launches the **setup container** using the custom `docker-compose.yml` located in the workspace's `.bitbot/setup/` directory. This provides a CLI session inside the setup container.

### 4.3. In-Setup Commands

Once inside the setup container, special commands will be available to manage the work container for debugging purposes:

*   `bitbot-test-launch`: Launches the work container as a sibling.
*   `bitbot-test-down`: Stops the work container.
*   `bitbot-test-exec`: Opens a shell inside the running work container.
