#!/bin/bash
set -e

echo "Installing dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create ~/.dotfiles symlink for compatibility
if [ ! -L "$HOME/.dotfiles" ]; then
    echo "Creating ~/.dotfiles symlink..."
    rm -rf "$HOME/.dotfiles" 2>/dev/null || true
    ln -sf "$DOTFILES_DIR" "$HOME/.dotfiles"
fi

# Install Nix if not present
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --no-daemon --yes
    . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Add Home Manager channel if not present
if ! nix-channel --list | grep -q home-manager; then
    echo "Adding Home Manager channel..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
fi

# Link home.nix BEFORE installing home-manager (it runs switch internally)
echo "Linking home.nix..."
mkdir -p ~/.config/home-manager
ln -sf "$DOTFILES_DIR/home.nix" ~/.config/home-manager/home.nix

# Install Home Manager if not present
if ! command -v home-manager &> /dev/null; then
    echo "Installing Home Manager..."
    nix-shell '<home-manager>' -A install
else
    # Apply configuration if home-manager already installed
    echo "Applying Home Manager configuration..."
    home-manager switch
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    ZSH_PATH=$(which zsh)
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "$ZSH_PATH" "$USER"
fi

# Install Claude Code skills (skip if ~/.claude is mounted from host with existing skills)
if [ -d "$DOTFILES_DIR/.claude/skills" ]; then
    # Check if ~/.claude/skills already has content (likely mounted from host)
    if [ -d "$HOME/.claude/skills" ] && [ "$(ls -A $HOME/.claude/skills 2>/dev/null)" ]; then
        echo "Skipping skill installation - ~/.claude/skills already populated (mounted from host)"
    else
        echo "Installing Claude Code skills..."
        mkdir -p ~/.claude/skills
        for skill_dir in "$DOTFILES_DIR/.claude/skills"/*; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")
                ln -sf "$skill_dir" "$HOME/.claude/skills/$skill_name"
            fi
        done
    fi
fi

echo "Done! Restart your shell or run: exec zsh"
