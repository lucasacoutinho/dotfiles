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
