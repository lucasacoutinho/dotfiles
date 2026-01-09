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

echo "Claude Code feature installation complete!"
echo ""
echo "IMPORTANT: Make sure you have authenticated Claude Code on your HOST machine first:"
echo "  1. Run 'claude' on your host terminal"
echo "  2. Complete the authentication flow"
echo "  3. Rebuild your devcontainer"
echo ""
echo "Your host ~/.claude.json (auth) will be mounted into this container."
echo "Skills and plugins will be managed inside the container via your dotfiles."
