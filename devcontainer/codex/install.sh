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

# Create a script that runs at container start to set up symlinks
cat > /usr/local/bin/codex-setup << 'SETUP_EOF'
#!/bin/bash
if [ -d "/mnt/host-codex" ] && [ ! -L "$HOME/.codex" ]; then
    rm -rf "$HOME/.codex" 2>/dev/null || true
    ln -sf /mnt/host-codex "$HOME/.codex"
    echo "Linked ~/.codex -> /mnt/host-codex"
fi
SETUP_EOF
chmod +x /usr/local/bin/codex-setup

cat > /etc/profile.d/codex-setup.sh << 'PROFILE_EOF'
#!/bin/bash
if [ -x /usr/local/bin/codex-setup ]; then
    /usr/local/bin/codex-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/codex-setup.sh

echo "Codex CLI installed. Host mounts will be symlinked on first login."
