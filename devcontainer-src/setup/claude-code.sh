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
