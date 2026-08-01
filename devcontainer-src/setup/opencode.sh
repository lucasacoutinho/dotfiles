# Link only OpenCode authentication. Settings, skills, agents, commands,
# plugins, and other state remain local to the container.

# Ensure ~/.local/bin exists and has opencode symlink (if needed)
mkdir -p "$HOME/.local/bin"
if command -v opencode &> /dev/null && [ ! -e "$HOME/.local/bin/opencode" ]; then
    ln -sf "$(command -v opencode)" "$HOME/.local/bin/opencode"
    echo "Linked ~/.local/bin/opencode -> $(command -v opencode)"
fi

if [ -f "/mnt/host-opencode-auth.json" ]; then
    mkdir -p "$HOME/.local/share/opencode"
    ln -sfn /mnt/host-opencode-auth.json "$HOME/.local/share/opencode/auth.json"
    echo "Linked OpenCode credentials; container settings and context remain isolated"
fi
