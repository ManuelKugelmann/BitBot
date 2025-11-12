FROM ubuntu:22.04

# Set noninteractive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Install essentials + configuration tools
# Note: Node.js and Claude Code are installed via devcontainer features
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    docker.io \
    jq \
    tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install DevContainer CLI (requires Node.js from devcontainer feature)
# This is installed via postCreateCommand to ensure Node.js is available

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
