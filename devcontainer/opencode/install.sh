#!/bin/bash
set -e

# OpenCode CLI Devcontainer Feature
# Installs the OpenCode CLI and ensures host credentials are accessible

echo "Installing OpenCode CLI..."

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

# Install OpenCode CLI globally
if [ "$VERSION" = "latest" ]; then
    echo "Installing OpenCode CLI (latest)..."
    npm install -g opencode-ai
else
    echo "Installing OpenCode CLI version: $VERSION..."
    npm install -g "opencode-ai@$VERSION"
fi

# Verify installation
if command -v opencode &> /dev/null; then
    echo "OpenCode CLI installed successfully!"
    opencode --version || true
else
    echo "WARNING: OpenCode CLI command not found in PATH after installation"
fi

# Create a script that runs at container start to set up symlinks
# (Mounts don't exist at build time, only at runtime)
cat > /usr/local/bin/opencode-setup << 'SETUP_EOF'
#!/bin/bash
# Setup symlinks for OpenCode host mounts
# This runs at container start, when mounts are available

# Ensure ~/.local/bin exists and has opencode symlink (if needed)
mkdir -p "$HOME/.local/bin"
if command -v opencode &> /dev/null && [ ! -e "$HOME/.local/bin/opencode" ]; then
    ln -sf "$(command -v opencode)" "$HOME/.local/bin/opencode"
    echo "Linked ~/.local/bin/opencode -> $(command -v opencode)"
fi

# Handle hardcoded host paths in config files
# Configs may have paths like "/home/lucas/.config/opencode/..." which won't exist in container
# Create compatibility symlink if the host path differs from container path
if [ -d "/mnt/host-opencode" ]; then
    HOST_OPENCODE_PATH=$(grep -o '"/home/[^"]*/.config/opencode' /mnt/host-opencode/opencode.json 2>/dev/null | head -1 | tr -d '"')
    if [ -n "$HOST_OPENCODE_PATH" ] && [ "$HOST_OPENCODE_PATH" != "$HOME/.config/opencode" ]; then
        HOST_USER_HOME=$(dirname "$(dirname "$HOST_OPENCODE_PATH")")
        if [ ! -d "$HOST_USER_HOME/.config" ]; then
            sudo mkdir -p "$HOST_USER_HOME/.config" 2>/dev/null || true
            sudo ln -sf /mnt/host-opencode "$HOST_OPENCODE_PATH" 2>/dev/null || true
            echo "Created compatibility symlink: $HOST_OPENCODE_PATH -> /mnt/host-opencode"
        fi
    fi
fi

# Link global config directory (~/.config/opencode)
if [ -d "/mnt/host-opencode" ] && [ ! -L "$HOME/.config/opencode" ]; then
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/opencode" 2>/dev/null || true
    ln -sf /mnt/host-opencode "$HOME/.config/opencode"
    echo "Linked ~/.config/opencode -> /mnt/host-opencode"
fi

# Link global .opencode directory (for skills, agents, commands shared across projects)
if [ -d "/mnt/host-opencode-project" ] && [ ! -L "$HOME/.opencode" ]; then
    rm -rf "$HOME/.opencode" 2>/dev/null || true
    ln -sf /mnt/host-opencode-project "$HOME/.opencode"
    echo "Linked ~/.opencode -> /mnt/host-opencode-project"
fi
SETUP_EOF
chmod +x /usr/local/bin/opencode-setup

# Add to profile.d so it runs on login
cat > /etc/profile.d/opencode-setup.sh << 'PROFILE_EOF'
#!/bin/bash
# Run opencode-setup once per session
if [ -x /usr/local/bin/opencode-setup ]; then
    /usr/local/bin/opencode-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/opencode-setup.sh

echo "OpenCode feature installation complete!"
echo "Host mounts will be symlinked on first login."
