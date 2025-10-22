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

# Configure tmux (BitBot status bar)
RUN echo '# tmux Configuration - BitBot Status Bar' > /etc/tmux.conf && \
    echo 'set -g mouse on' >> /etc/tmux.conf && \
    echo 'set -g history-limit 1000' >> /etc/tmux.conf && \
    echo 'set -g status on' >> /etc/tmux.conf && \
    echo 'set -g status-interval 1' >> /etc/tmux.conf && \
    echo 'set -g status-justify left' >> /etc/tmux.conf && \
    echo 'set -g status-style bg=black,fg=white' >> /etc/tmux.conf && \
    echo "set -g status-left \"#[fg=cyan]BitBot #[fg=yellow]#{?BITBOT_MODE,#{BITBOT_MODE},#[fg=white]work}#[fg=white] │ #[fg=colour240]#{b:pane_current_path} \"" >> /etc/tmux.conf && \
    echo 'set -g status-left-length 50' >> /etc/tmux.conf && \
    echo "set -g status-right \" #{?pane_in_mode,#[fg=yellow]▼,#[fg=green]●}\"" >> /etc/tmux.conf && \
    echo 'set -g status-right-length 3' >> /etc/tmux.conf && \
    echo 'set -g default-terminal "screen-256color"' >> /etc/tmux.conf && \
    echo 'unbind-key -a' >> /etc/tmux.conf

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
