#!/bin/bash
set -e

# Reusable AI DevContainer Setup Script
# Generic setup for AI development with Claude, Node.js, and essential tools
# This script can be sourced by other Dockerfiles for common AI dev setup

echo "Starting AI DevContainer setup..."

# Set noninteractive frontend for apt
export DEBIAN_FRONTEND=noninteractive

# Configure timezone before installing tzdata to avoid prompts
echo "Configuring timezone..."
TZ="${TZ:-UTC}"
echo "Using timezone: $TZ"
if [ -d "/usr/share/zoneinfo/$TZ" ] || [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime || true
    echo $TZ > /etc/timezone
else
    echo "Warning: Timezone $TZ not found, using UTC"
    ln -snf /usr/share/zoneinfo/UTC /etc/localtime || true
    echo "UTC" > /etc/timezone
fi

# Update and install essential tools
echo "Installing essential tools..."
apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    jq \
    nano \
    vim \
    curl \
    wget \
    ca-certificates \
    xz-utils \
    tzdata \
    openssh-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js
echo "Installing Node.js..."
NODE_VERSION="${NODE_VERSION:-20}"
NODE_ARCH="x64"

# Detect latest version in major release
LATEST_NODE=$(curl -s https://nodejs.org/dist/latest-v${NODE_VERSION}.x/ | grep -oP 'node-v\K[0-9.]+' | head -1)
NODE_URL="https://nodejs.org/dist/v${LATEST_NODE}/node-v${LATEST_NODE}-linux-${NODE_ARCH}.tar.xz"

mkdir -p /usr/local/lib/nodejs
curl -fsSL "${NODE_URL}" | tar -xJ -C /usr/local/lib/nodejs
mv /usr/local/lib/nodejs/node-v${LATEST_NODE}-linux-${NODE_ARCH} /usr/local/lib/nodejs/node-v${NODE_VERSION}

# Create symlinks
ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}/bin/node /usr/local/bin/node
ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}/bin/npm /usr/local/bin/npm
ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}/bin/npx /usr/local/bin/npx

# Create non-root user if doesn't exist
if ! id -u user > /dev/null 2>&1; then
    echo "Creating user 'user'..."

    # Check if UID 1000 is already taken
    if id -u 1000 > /dev/null 2>&1; then
        echo "UID 1000 already exists, finding next available UID..."
        AVAILABLE_UID=$(awk -F: '{print $3}' /etc/passwd | sort -n | tail -1)
        AVAILABLE_UID=$((AVAILABLE_UID + 1))
        echo "Using UID: $AVAILABLE_UID"
    else
        AVAILABLE_UID=1000
    fi

    # Check if group with GID 1000 exists
    if ! getent group 1000 > /dev/null 2>&1; then
        groupadd --gid 1000 user
    else
        # Create group with auto GID
        groupadd user
    fi

    useradd --uid $AVAILABLE_UID --gid user --shell /bin/bash --create-home user
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p /commandhistory
mkdir -p /home/user/.claude
mkdir -p /home/user/.claude-flow
mkdir -p /home/user/.ssh

# Setup bash history persistence
echo "Setting up bash history..."
SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history"
echo "$SNIPPET" >> /home/user/.bashrc

# Install git-delta for better diffs
echo "Installing git-delta..."
GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}"
wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_amd64.deb" -O /tmp/git-delta.deb
dpkg -i /tmp/git-delta.deb
rm /tmp/git-delta.deb

# Configure git to use delta (setup for user)
runuser -u user -- git config --global core.pager delta
runuser -u user -- git config --global interactive.diffFilter "delta --color-only"
runuser -u user -- git config --global delta.navigate true
runuser -u user -- git config --global merge.conflictstyle diff3
runuser -u user -- git config --global diff.colorMoved default

# Install and configure zsh with Oh My Zsh
echo "Installing zsh with Oh My Zsh..."
ZSH_IN_DOCKER_VERSION="${ZSH_IN_DOCKER_VERSION:-1.2.0}"
wget -q "https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh" -O /tmp/zsh-in-docker.sh
chmod +x /tmp/zsh-in-docker.sh

# Run as root first, then switch ownership to user
/tmp/zsh-in-docker.sh \
    -t robbyrussell \
    -p git \
    -p ssh-agent \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting

# Copy zsh config to user home
if [ -f "/root/.zshrc" ]; then
    cp /root/.zshrc /home/user/.zshrc
    # Replace root paths with user paths in .zshrc
    sed -i 's|/root/|/home/user/|g' /home/user/.zshrc
    chown user:user /home/user/.zshrc
fi
if [ -d "/root/.oh-my-zsh" ]; then
    cp -r /root/.oh-my-zsh /home/user/.oh-my-zsh
    chown -R user:user /home/user/.oh-my-zsh
fi

rm /tmp/zsh-in-docker.sh

# Configure zsh history
echo "export HISTFILE=/commandhistory/.zsh_history" >> /home/user/.zshrc

# Add user to sudoers with no password (safe for dev containers)
echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/user
chmod 0440 /etc/sudoers.d/user

# Set proper permissions
chown -R user:user /home/user/.claude
chown -R user:user /home/user/.claude-flow
chown -R user:user /home/user/.ssh
chown -R user:user /commandhistory || true

# Install Claude Code globally as the user
echo "Installing Claude Code..."
CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"
runuser -u user -- npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Install Claude Flow MCP servers (if available)
echo "Installing Claude Flow..."
npm install -g @anthropic-ai/claude-flow@latest || echo "Claude Flow not available via npm, skipping..."

echo "AI DevContainer setup completed successfully!"
