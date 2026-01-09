#!/bin/bash
set -e

# Claude Code CLI Devcontainer Feature
# Installs the Claude Code CLI and ensures host credentials are accessible

echo "Installing Claude Code CLI..."

# VERSION option from devcontainer-feature.json (default: "latest")
VERSION="${VERSION:-latest}"

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing Node.js..."

    # Detect package manager and install Node.js
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y nodejs npm
    elif command -v apk &> /dev/null; then
        apk add --no-cache nodejs npm
    elif command -v yum &> /dev/null; then
        yum install -y nodejs npm
    elif command -v dnf &> /dev/null; then
        dnf install -y nodejs npm
    else
        echo "ERROR: Unable to install Node.js. Please add the Node.js feature first:"
        echo '  "features": { "ghcr.io/devcontainers/features/node:1": {} }'
        exit 1
    fi
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install Claude Code CLI globally
if [ "$VERSION" = "latest" ]; then
    echo "Installing Claude Code CLI (latest)..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Installing Claude Code CLI version: $VERSION..."
    npm install -g "@anthropic-ai/claude-code@$VERSION"
fi

# Verify installation
if command -v claude &> /dev/null; then
    echo "Claude Code CLI installed successfully!"
    claude --version || true
else
    echo "WARNING: Claude CLI command not found in PATH after installation"
fi

# Create symlinks from user home to mounted host directories
# _REMOTE_USER_HOME is set by devcontainer during feature install
REMOTE_HOME="${_REMOTE_USER_HOME:-/home/${_REMOTE_USER:-dev}}"

echo "Setting up symlinks for remote user home: $REMOTE_HOME"

# Symlink ~/.claude -> /mnt/host-claude (if mount exists)
if [ -d "/mnt/host-claude" ]; then
    echo "Linking $REMOTE_HOME/.claude -> /mnt/host-claude"
    rm -rf "$REMOTE_HOME/.claude" 2>/dev/null || true
    ln -sf /mnt/host-claude "$REMOTE_HOME/.claude"
    # Fix ownership for the symlink
    chown -h "${_REMOTE_USER:-dev}:${_REMOTE_USER:-dev}" "$REMOTE_HOME/.claude" 2>/dev/null || true
fi

# Symlink ~/.claude.json -> /mnt/host-claude.json (if mount exists)
if [ -f "/mnt/host-claude.json" ]; then
    echo "Linking $REMOTE_HOME/.claude.json -> /mnt/host-claude.json"
    rm -f "$REMOTE_HOME/.claude.json" 2>/dev/null || true
    ln -sf /mnt/host-claude.json "$REMOTE_HOME/.claude.json"
    chown -h "${_REMOTE_USER:-dev}:${_REMOTE_USER:-dev}" "$REMOTE_HOME/.claude.json" 2>/dev/null || true
fi

echo "Claude Code feature installation complete!"
echo ""
echo "Host ~/.claude and ~/.claude.json are mounted and symlinked."
echo "Your skills, plugins, and auth from the host are now available."
