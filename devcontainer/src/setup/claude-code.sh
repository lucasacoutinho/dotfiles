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
