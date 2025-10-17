#!/bin/bash
# Simple script to check workspace mount without path conversion
CONTAINER_NAME="$1"
docker exec "$CONTAINER_NAME" bash -c 'ls -la /workspace/ 2>/dev/null || echo "Workspace directory not accessible"'
docker exec "$CONTAINER_NAME" bash -c 'find /workspace -name "*.txt" 2>/dev/null | head -5 || echo "No files found"'
docker exec "$CONTAINER_NAME" bash -c 'test -f /workspace/bitbot-integration-test-marker.txt && echo "Marker file found" || echo "Marker file not found"'