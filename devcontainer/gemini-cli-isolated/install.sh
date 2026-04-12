#!/bin/bash
set -e

echo "Installing Google Gemini CLI (isolated mode)..."

VERSION="${VERSION:-latest}"

if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing Node.js..."

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

if [ "$VERSION" = "latest" ]; then
    npm install -g @google/gemini-cli
else
    npm install -g "@google/gemini-cli@$VERSION"
fi

if command -v gemini &> /dev/null; then
    echo "Google Gemini CLI installed successfully!"
    gemini --version || true
else
    echo "WARNING: gemini command not found in PATH after installation"
fi

echo "Gemini isolated feature installation complete."
echo "No host Gemini settings or credentials were mounted into this container."
