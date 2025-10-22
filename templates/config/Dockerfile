FROM ubuntu:22.04

# Install essentials + devcontainer tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    docker.io \
    jq \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install DevContainer CLI
RUN npm install -g @devcontainers/cli

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
