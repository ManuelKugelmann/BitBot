FROM ubuntu:22.04

# Install essentials + devcontainer tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    docker.io \
    jq \
    tmux \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install DevContainer CLI
RUN npm install -g @devcontainers/cli

# Configure tmux (mouse mode, frameless)
RUN echo '# tmux Configuration - Mouse Mode (Frameless)' > /etc/tmux.conf && \
    echo 'set -g mouse on                         # Enable mouse scrolling' >> /etc/tmux.conf && \
    echo 'set -g history-limit 10000              # Increase history' >> /etc/tmux.conf && \
    echo 'set -g status off                       # Hide status bar' >> /etc/tmux.conf && \
    echo 'set -g default-terminal "screen-256color"' >> /etc/tmux.conf

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
