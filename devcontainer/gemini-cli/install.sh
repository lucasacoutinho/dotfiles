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

# Create a script that runs at container start to set up symlinks
cat > /usr/local/bin/gemini-setup << 'SETUP_EOF'
#!/bin/bash
if [ -d "/mnt/host-gemini" ] && [ ! -L "$HOME/.gemini" ]; then
    rm -rf "$HOME/.gemini" 2>/dev/null || true
    ln -sf /mnt/host-gemini "$HOME/.gemini"
    echo "Linked ~/.gemini -> /mnt/host-gemini"
fi
SETUP_EOF
chmod +x /usr/local/bin/gemini-setup

cat > /etc/profile.d/gemini-setup.sh << 'PROFILE_EOF'
#!/bin/bash
if [ -x /usr/local/bin/gemini-setup ]; then
    /usr/local/bin/gemini-setup 2>/dev/null
fi
PROFILE_EOF
chmod +x /etc/profile.d/gemini-setup.sh

echo "Gemini CLI installed. Host mounts will be symlinked on first login."
