#!/bin/bash
set -e

# GENERATED FILE — do not edit. Edit devcontainer-src/* and run devcontainer-src/generate.sh.
# OpenCode CLI Devcontainer Feature
# Installs the OpenCode CLI and shares host credentials/config with the devcontainer

echo "Installing OpenCode CLI..."

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
    echo "WARNING: opencode not found in PATH after installation"
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
            if sudo -n mkdir -p "$HOST_USER_HOME/.config" 2>/dev/null && \
               sudo -n ln -sf /mnt/host-opencode "$HOST_OPENCODE_PATH" 2>/dev/null; then
                echo "Created compatibility symlink: $HOST_OPENCODE_PATH -> /mnt/host-opencode"
            else
                echo "WARNING: could not create $HOST_OPENCODE_PATH (no passwordless sudo)."
                echo "         Configs referencing host paths under $HOST_USER_HOME may fail to load."
            fi
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

# profile.d fallback for plain-docker runs; devcontainers also run this via
# the feature's postStartCommand, which works regardless of login shell.
cat > /etc/profile.d/opencode-setup.sh << 'PROFILE_EOF'
#!/bin/bash
if [ -x /usr/local/bin/opencode-setup ]; then
    /usr/local/bin/opencode-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/opencode-setup.sh

echo "OpenCode CLI feature installation complete!"
echo "Host mounts will be symlinked at container start."
