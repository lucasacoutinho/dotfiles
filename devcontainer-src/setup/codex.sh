# Link only Codex authentication. The container keeps its own config, skills,
# sessions, memories, plugins, and other state.
if [ -f "/mnt/host-codex-auth.json" ]; then
    mkdir -p "$HOME/.codex"
    ln -sfn /mnt/host-codex-auth.json "$HOME/.codex/auth.json"
    echo "Linked Codex credentials; container settings and context remain isolated"
fi
