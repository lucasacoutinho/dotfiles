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

echo "Gemini CLI installed. Authenticate on host first, then rebuild container."
