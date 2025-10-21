# Feature 05: Terminal Session Management

## 1. Description

This feature provides persistent, resumable terminal sessions inside the devcontainer. The primary goal is to ensure that a user's work is not lost if their connection to the container is interrupted. The session should be restored automatically when the user reconnects.

*Reference: `info.txt` (lines 32-34)*

## 2. Chosen Approach

The selected approach is **"Zero-Interaction Resumability"** using `tmux`.

The goal is to make session management completely transparent to the user. `tmux` will run in the background to provide session persistence, but the user will not need to interact with it directly in any way.

### 2.1. Core Behavior

*   **Always-On Session:** Every shell provided by BitBot (whether via `bitbot shell` or inside a VS Code terminal) will be an automatically created or resumed `tmux` session.
*   **Automatic Detach:** When the user closes their terminal window or disconnects, the `tmux` client detaches, but the session and any running processes within it continue to live on the server (inside the container).
*   **Automatic Resume:** When the user runs `bitbot shell` again for that workspace, it will automatically find and re-attach to the existing `tmux` session, restoring the shell to its previous state.

### 2.2. `tmux` Configuration

To achieve a completely transparent experience, BitBot will configure `tmux` with a "zero-interaction" profile. The `.tmux.conf` file will be set up to:

1.  **Disable the Status Bar:** The `tmux` status bar will be hidden, so it does not use any screen real estate.
2.  **Disable Mouse Mode:** `tmux`'s mouse handling will be turned off, allowing the host terminal's native mouse selection and scrolling to function perfectly.
3.  **Unbind All Keys:** All `tmux` key bindings, including the prefix key (`Ctrl+B`), will be unbound.

### 2.3. User Experience

The user experience will be identical to a standard shell, with the invisible benefit of session persistence.

1.  User runs `bitbot shell`. They get a terminal and start a long-running process.
2.  User closes the terminal window.
3.  Later, the user runs `bitbot shell` again.
4.  The terminal restores exactly as they left it, with the long-running process still running and its output visible.

The user does not need to know that `tmux` exists or learn any new commands. It serves as a pure background service for session persistence.
