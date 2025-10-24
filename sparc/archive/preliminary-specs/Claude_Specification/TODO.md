# BitBot Specification TODO List

This document tracks items that have been discussed but are not yet fully documented in the official specification files.

### 1. Git Protection Strategy
- **Task:** Document the strategy for Git-based workspace protection.
- **Details:**
    - Specify how `bitbot` will initialize a Git repository in a new workspace if one doesn't exist.
    - Define the mechanism for preventing destructive Git operations (e.g., `git push --force`, history rewriting) by the AI agent, even in high-permission modes.
    - Clarify how this Git protection layer interacts with the `sketch` and `work` security modes.
- **Relevant Files:** `Specification/02_SECURITY_MODE_SYSTEM.md`, `info.txt`

### 2. User ID (UID/GID) Synchronization Strategy
- **Task:** Clarify and document the decision regarding user ID mapping between the host and the container.
- **Details:**
    - The current specification defines static UIDs (`2001`, `2002`) for in-container users (`bitbot-sketch`, `bitbot-work`).
    - This contradicts the common dev container practice of syncing the container user's UID/GID with the host user's UID/GID.
    - The specification should explicitly state that static UIDs are used and justify this decision. The justification should explain why UID/GID synchronization was not chosen (e.g., it conflicts with the multi-user security model which is central to BitBot's design).
- **Relevant Files:** `Specification/02_SECURITY_MODE_SYSTEM.md`, `info.txt`

### 3. CLI Initialization and Workspace Detection Logic
- **Task:** Document the detailed process for how the `bitbot` command discovers and initializes a workspace.
- **Details:**
    - The specification should include the following logic:
        1. When `bitbot` is run, it checks for a `.bitbot` directory in the current folder.
        2. If not found, it walks up the directory tree until a `.bitbot` directory is found or the root is reached.
        3. If a `.bitbot` directory is found in a parent directory, prompt the user to confirm they want to use that existing workspace.
        4. If no `.bitbot` directory is found, start the initialization process for a new workspace in the current directory.
- **Relevant Files:** `Gemini_Specification/01-CLI.md`