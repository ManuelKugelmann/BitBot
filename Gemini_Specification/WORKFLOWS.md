# BitBot Usage Workflows

This document outlines common user scenarios to test the completeness of the specifications and ensure a coherent user experience.

---

### Scenario 1: The First-Time User

**Goal:** A new user wants to start a project with BitBot.

1.  **Installation:** The user downloads `bitbot.exe` and places it in their PATH.
2.  **Initialization:** The user opens a terminal in an empty directory `c:\Projects\new-project` and runs `bitbot init`.
    *   *Open Point:* What happens? Does `bitbot` prompt the user to choose from a list of project templates (e.g., Python, Node.js, Generic)? How is the initial `.devcontainer` and `.bitbot/setup` configuration created?
3.  **Start Work Environment:** The user runs `bitbot up`.
    *   The `@devcontainers/cli` downloads the required images and starts the **work container**.
    *   A `postCreateCommand` script runs inside the container to set up the default `bitbot-work` user and its file permissions.
4.  **Enter Container:** The user's terminal is now a shell inside the work container, running as the `bitbot-work` user.
5.  **File Ownership:** The user creates a file. It is owned by `bitbot-work` (UID 2001) inside the container.
    *   *Open Point:* What ownership is visible on the Windows host? How are potential file permission conflicts between the host user and the container user managed?

---

### Scenario 3: The Developer Debugging a Devcontainer

**Goal:** A developer needs to add a new tool to their devcontainer configuration and test it.

1.  **Launch Setup Session:** The user runs `bitbot setup` from their host terminal.
    *   The **setup container** starts, and the user is placed in a shell inside it. The workspace is mounted at `/target`.
2.  **Edit Configuration:** The user edits the work container's configuration at `/target/.devcontainer/devcontainer.json`.
3.  **Test Launch:** From the setup shell, the user runs `bitbot-test-launch`.
    *   The command invokes `@devcontainers/cli` to build and launch the work container as a sibling to the setup container.
    *   *Open Point:* Are the build and launch logs from `@devcontainers/cli` streamed into the setup session terminal for debugging?
4.  **Debug and Iterate:** The build fails. The user reads the logs, edits the configuration again, and re-runs `bitbot-test-launch`.
5.  **Verify Success:** The build succeeds. The user runs `bitbot-test-exec` to get a shell in the new work container and confirms the new tool is available.
6.  **Exit:** Satisfied, the user exits the setup session. The updated `devcontainer.json` is saved on their host machine.

---

### Scenario 4: The Git Protection Safety Net

**Goal:** An AI agent, even with `work` permissions, should be prevented from performing destructive Git operations.

1.  **Attempt Force Push:** An AI agent, running as the `bitbot-work` user, attempts to run `git push --force origin main`.
2.  **Intercept Command:** A pre-installed Git hook or a wrapper script intercepts the command before execution.
3.  **Block Operation:** The script identifies the command as destructive and causes it to fail.
4.  **Provide Feedback:** The user sees an error message like: "Error: Destructive Git operations like 'push --force' are blocked by BitBot's safety policy."
    *   *Open Point:* What is the exact implementation of this interception (hook vs. wrapper)? How does it avoid being bypassed?
