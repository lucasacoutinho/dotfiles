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

# Create a script that runs at container start to set up symlinks
# (Mounts don't exist at build time, only at runtime)
cat > /usr/local/bin/claude-code-setup << 'SETUP_EOF'
#!/bin/bash
# Setup symlinks for Claude Code host mounts
# This runs at container start, when mounts are available

if [ -d "/mnt/host-claude" ] && [ ! -L "$HOME/.claude" ]; then
    rm -rf "$HOME/.claude" 2>/dev/null || true
    ln -sf /mnt/host-claude "$HOME/.claude"
    echo "Linked ~/.claude -> /mnt/host-claude"
fi

if [ -f "/mnt/host-claude.json" ] && [ ! -L "$HOME/.claude.json" ]; then
    rm -f "$HOME/.claude.json" 2>/dev/null || true
    ln -sf /mnt/host-claude.json "$HOME/.claude.json"
    echo "Linked ~/.claude.json -> /mnt/host-claude.json"
fi
SETUP_EOF
chmod +x /usr/local/bin/claude-code-setup

# Add to profile.d so it runs on login
cat > /etc/profile.d/claude-code-setup.sh << 'PROFILE_EOF'
#!/bin/bash
# Run claude-code-setup once per session
if [ -x /usr/local/bin/claude-code-setup ]; then
    /usr/local/bin/claude-code-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/claude-code-setup.sh

echo "Claude Code feature installation complete!"
echo "Host mounts will be symlinked on first login."
