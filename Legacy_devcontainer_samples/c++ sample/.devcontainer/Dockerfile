ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

ARG TZ
ENV TZ="${TZ:-UTC}"

ARG CLAUDE_CODE_VERSION=latest
ARG GIT_DELTA_VERSION=0.18.2
ARG ZSH_IN_DOCKER_VERSION=1.2.0
ARG NODE_VERSION=20

# Copy and run the generic AI devcontainer setup script
COPY setup-ai-devcontainer.sh /tmp/setup-ai-devcontainer.sh
RUN chmod +x /tmp/setup-ai-devcontainer.sh && \
    NODE_VERSION=${NODE_VERSION} \
    GIT_DELTA_VERSION=${GIT_DELTA_VERSION} \
    ZSH_IN_DOCKER_VERSION=${ZSH_IN_DOCKER_VERSION} \
    CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    /tmp/setup-ai-devcontainer.sh && \
    rm /tmp/setup-ai-devcontainer.sh

# Copy and run the C++ specific setup script
COPY setup-cpp.sh /tmp/setup-cpp.sh
RUN chmod +x /tmp/setup-cpp.sh && \
    /tmp/setup-cpp.sh && \
    rm /tmp/setup-cpp.sh

# Set up environment paths
ENV PATH="${PATH}:/usr/local/lib/nodejs/node-v${NODE_VERSION}/bin"
ENV NODE_PATH="/usr/local/lib/nodejs/node-v${NODE_VERSION}/lib/node_modules"

# Switch to non-root user
USER user

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
