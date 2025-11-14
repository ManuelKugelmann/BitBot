FROM ubuntu:22.04

# Set noninteractive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Install essentials + build tools + MinGW for Windows cross-compilation
# Note: Node.js and Claude Code are installed via devcontainer features
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    git \
    build-essential \
    mingw-w64 \
    gcc-mingw-w64-x86-64 \
    g++-mingw-w64-x86-64 \
    binutils-mingw-w64-x86-64 \
    zip \
    unzip \
    file \
    jq \
    tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify MinGW installation
RUN x86_64-w64-mingw32-gcc --version

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
