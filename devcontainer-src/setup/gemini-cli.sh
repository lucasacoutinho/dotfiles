if [ -d "/mnt/host-gemini" ] && [ ! -L "$HOME/.gemini" ]; then
    rm -rf "$HOME/.gemini" 2>/dev/null || true
    ln -sf /mnt/host-gemini "$HOME/.gemini"
    echo "Linked ~/.gemini -> /mnt/host-gemini"
fi
