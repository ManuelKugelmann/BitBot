FROM ubuntu:22.04

# Set noninteractive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Install essentials + build tools
# Note: Node.js, Git, and AI tools are installed via devcontainer features
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    build-essential \
    zip \
    unzip \
    file \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create workspace and home directories
RUN mkdir -p /workspace /home/bitbot
WORKDIR /workspace

CMD ["/bin/bash"]
