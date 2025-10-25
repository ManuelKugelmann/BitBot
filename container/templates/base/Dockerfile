FROM ubuntu:22.04

# Install essentials
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    jq \
    tmux \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Configure tmux (shared configuration)
COPY ../shared/configs/tmux.conf /etc/tmux.conf

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
