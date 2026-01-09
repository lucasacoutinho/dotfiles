#!/bin/bash
set -e

VERSION="${VERSION:-latest}"

# Ensure Node.js is available
if ! command -v node &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y nodejs npm
    elif command -v apk &> /dev/null; then
        apk add --no-cache nodejs npm
    else
        echo "ERROR: Node.js required. Add: \"ghcr.io/devcontainers/features/node:1\": {}"
        exit 1
    fi
fi

# Install Codex CLI
if [ "$VERSION" = "latest" ]; then
    npm install -g @openai/codex
else
    npm install -g "@openai/codex@$VERSION"
fi

# Create symlinks from user home to mounted host directories
REMOTE_HOME="${_REMOTE_USER_HOME:-/home/${_REMOTE_USER:-dev}}"

if [ -d "/mnt/host-codex" ]; then
    echo "Linking $REMOTE_HOME/.codex -> /mnt/host-codex"
    rm -rf "$REMOTE_HOME/.codex" 2>/dev/null || true
    ln -sf /mnt/host-codex "$REMOTE_HOME/.codex"
    chown -h "${_REMOTE_USER:-dev}:${_REMOTE_USER:-dev}" "$REMOTE_HOME/.codex" 2>/dev/null || true
fi

echo "Codex CLI installed. Host ~/.codex mounted and symlinked."
