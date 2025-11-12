FROM ubuntu:22.04

# Set noninteractive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Install minimal essentials
# Note: Node.js and Claude Code are installed via devcontainer features
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    jq \
    tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
