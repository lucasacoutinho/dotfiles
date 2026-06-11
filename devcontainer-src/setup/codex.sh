if [ -d "/mnt/host-codex" ] && [ ! -L "$HOME/.codex" ]; then
    rm -rf "$HOME/.codex" 2>/dev/null || true
    ln -sf /mnt/host-codex "$HOME/.codex"
    echo "Linked ~/.codex -> /mnt/host-codex"
fi
