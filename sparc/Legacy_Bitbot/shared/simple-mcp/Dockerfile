FROM python:3.11-slim

# Set timezone
ARG TZ=UTC
ENV TZ="${TZ}"

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -s /bin/bash mcp && \
    chown -R mcp:mcp /app

USER mcp

EXPOSE 3000

CMD ["python", "echo_server.py"]