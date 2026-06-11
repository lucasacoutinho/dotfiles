#!/bin/bash
set -e

# GENERATED FILE — do not edit. Edit devcontainer-src/* and run devcontainer-src/generate.sh.
# Claude Code CLI Devcontainer Feature
# Installs the Claude Code CLI and shares host credentials/config with the devcontainer

echo "Installing Claude Code CLI..."

# VERSION option from devcontainer-feature.json (default: "latest")
VERSION="${VERSION:-latest}"

# Ensure Node.js >= 18 is available. When missing, install current LTS from
# NodeSource on deb/rpm distros (their own repos lag years behind); Alpine
# tracks upstream closely so its repo package is fine.
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing Node.js 24.x..."
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl ca-certificates
        curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
        apt-get install -y nodejs
    elif command -v apk &> /dev/null; then
        # Alpine 3.18+ ships Node >= 18; the version check below catches older releases
        apk add --no-cache nodejs npm
    elif command -v dnf &> /dev/null; then
        command -v curl &> /dev/null || dnf install -y curl
        curl -fsSL https://rpm.nodesource.com/setup_24.x | bash -
        dnf install -y nodejs
    elif command -v yum &> /dev/null; then
        command -v curl &> /dev/null || yum install -y curl
        curl -fsSL https://rpm.nodesource.com/setup_24.x | bash -
        yum install -y nodejs
    else
        echo "ERROR: Unable to install Node.js. Please add the Node.js feature first:"
        echo '  "features": { "ghcr.io/devcontainers/features/node:1": {} }'
        exit 1
    fi
fi

# A preexisting Node belongs to the image; refuse rather than replace it.
NODE_MAJOR="$(node --version | sed 's/^v\([0-9]*\).*/\1/')"
if [ "${NODE_MAJOR:-0}" -lt 18 ]; then
    echo "ERROR: Node.js $(node --version) is too old (need >= 18)."
    echo "Add the Node.js feature to your devcontainer.json:"
    echo '  "features": { "ghcr.io/devcontainers/features/node:1": {} }'
    exit 1
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
    echo "WARNING: claude not found in PATH after installation"
fi

# Create a script that runs at container start to set up symlinks
# (Mounts don't exist at build time, only at runtime)
cat > /usr/local/bin/claude-code-setup << 'SETUP_EOF'
#!/bin/bash
# Setup symlinks for Claude Code host mounts
# This runs at container start, when mounts are available

# Ensure ~/.local/bin exists and has claude symlink (required when installMethod is "native")
mkdir -p "$HOME/.local/bin"
if command -v claude &> /dev/null && [ ! -e "$HOME/.local/bin/claude" ]; then
    ln -sf "$(command -v claude)" "$HOME/.local/bin/claude"
    echo "Linked ~/.local/bin/claude -> $(command -v claude)"
fi

# Handle hardcoded host paths in plugin configs
# Plugins may have installPath like "/home/lucas/.claude/..." which won't exist in container
# Create compatibility symlink if the host path differs from container path
if [ -d "/mnt/host-claude" ]; then
    HOST_CLAUDE_PATH=$(grep -o '"/home/[^"]*/.claude' /mnt/host-claude/plugins/installed_plugins.json 2>/dev/null | head -1 | tr -d '"')
    if [ -n "$HOST_CLAUDE_PATH" ] && [ "$HOST_CLAUDE_PATH" != "$HOME/.claude" ]; then
        HOST_USER_HOME=$(dirname "$HOST_CLAUDE_PATH")
        if [ ! -d "$HOST_USER_HOME" ]; then
            if sudo -n mkdir -p "$HOST_USER_HOME" 2>/dev/null && \
               sudo -n ln -sf /mnt/host-claude "$HOST_CLAUDE_PATH" 2>/dev/null; then
                echo "Created compatibility symlink: $HOST_CLAUDE_PATH -> /mnt/host-claude"
            else
                echo "WARNING: could not create $HOST_CLAUDE_PATH (no passwordless sudo)."
                echo "         Plugins installed with host paths under $HOST_USER_HOME may fail to load."
            fi
        fi
    fi
fi

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

# profile.d fallback for plain-docker runs; devcontainers also run this via
# the feature's postStartCommand, which works regardless of login shell.
cat > /etc/profile.d/claude-code-setup.sh << 'PROFILE_EOF'
#!/bin/bash
if [ -x /usr/local/bin/claude-code-setup ]; then
    /usr/local/bin/claude-code-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/claude-code-setup.sh

echo "Claude Code CLI feature installation complete!"
echo "Host mounts will be symlinked at container start."
