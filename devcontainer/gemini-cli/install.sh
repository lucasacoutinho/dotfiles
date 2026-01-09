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

# Install Gemini CLI
if [ "$VERSION" = "latest" ]; then
    npm install -g @google/gemini-cli
else
    npm install -g "@google/gemini-cli@$VERSION"
fi

# Create symlinks from user home to mounted host directories
REMOTE_HOME="${_REMOTE_USER_HOME:-/home/${_REMOTE_USER:-dev}}"

if [ -d "/mnt/host-gemini" ]; then
    echo "Linking $REMOTE_HOME/.gemini -> /mnt/host-gemini"
    rm -rf "$REMOTE_HOME/.gemini" 2>/dev/null || true
    ln -sf /mnt/host-gemini "$REMOTE_HOME/.gemini"
    chown -h "${_REMOTE_USER:-dev}:${_REMOTE_USER:-dev}" "$REMOTE_HOME/.gemini" 2>/dev/null || true
fi

echo "Gemini CLI installed. Host ~/.gemini mounted and symlinked."
