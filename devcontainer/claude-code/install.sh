#!/bin/bash
set -e

# GENERATED FILE — do not edit. Edit devcontainer-src/* and run devcontainer-src/generate.sh.
# Claude Code CLI Devcontainer Feature
# Installs the Claude Code CLI and shares only host authentication with the devcontainer

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
# Link only Claude Code authentication. Settings, skills, plugins, projects,
# history, and other state remain local to the container.

# Ensure ~/.local/bin exists and has claude symlink (required when installMethod is "native")
mkdir -p "$HOME/.local/bin"
if command -v claude &> /dev/null && [ ! -e "$HOME/.local/bin/claude" ]; then
    ln -sf "$(command -v claude)" "$HOME/.local/bin/claude"
    echo "Linked ~/.local/bin/claude -> $(command -v claude)"
fi

if [ -f "/mnt/host-claude-credentials.json" ]; then
    mkdir -p "$HOME/.claude"
    ln -sfn /mnt/host-claude-credentials.json "$HOME/.claude/.credentials.json"
    echo "Linked Claude credentials; container settings and context remain isolated"
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
echo "Host authentication will be linked at container start."
