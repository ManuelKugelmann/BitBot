# Feature 07: Smart Entrypoint Workflow

## 1. Description

This feature defines the primary workflow when a user runs the `bitbot` command. It combines workspace detection and project initialization into a single, intuitive process, eliminating the need for a separate `bitbot init` command. This specification supersedes the previous "Workspace Management" (`03-Workspace-Management.md`) specification.

## 2. Chosen Approach

A "Smart Entrypoint" workflow will be implemented. The `bitbot` command will intelligently determine the correct action based on the context of the current directory.

### 2.1. Execution Logic

When the user runs any `bitbot` command (e.g., `bitbot shell`, `bitbot up`):

1.  **Check for Local `.bitbot`:** BitBot first checks if a `.bitbot` directory exists in the **current directory**.
    *   If **yes**, it immediately uses the current directory as the workspace root and proceeds with the requested command.

2.  **Search Upwards:** If no local `.bitbot` is found, it searches upwards from the current directory to the filesystem root.
    *   If a `.bitbot` directory is found in a **parent directory**:
        *   BitBot will **prompt the user** to resolve the ambiguity:
            ```
            ? A BitBot workspace was found at '/path/to/parent'. What would you like to do?
            > Use this existing workspace
              Initialize a new workspace in the current directory
            ```
        *   If the user chooses "Use this existing workspace", that location is used as the workspace root for the command.
        *   If the user chooses "Initialize a new workspace", BitBot proceeds to the "Implicit Init" step below.

3.  **Implicit `init`:** If no `.bitbot` directory is found after checking locally and searching upwards, BitBot assumes this is a new project.
    *   It automatically triggers the **project initialization process** in the current directory.
    *   This process will use the official `devcontainer` CLI's "Templates" and "Features" to guide the user through creating a new `devcontainer.json`, as specified in the "Project Initialization & Templating" discussion.
    *   The `bitbot` command that the user originally ran will be executed after the initialization is complete.

### 2.2. Benefits

*   **Intuitive:** The user only needs to know the main `bitbot` command. The tool does the right thing whether they are starting a new project or working within an existing one.
*   **No `init` command:** The `bitbot init` command is no longer necessary.
*   **Elegant Disambiguation:** The interactive prompt provides a clear and user-friendly way to handle the case of running in a subdirectory.
