#!/bin/bash
set -e

echo "Installing dotfiles..."

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

# Install Home Manager if not present
if ! command -v home-manager &> /dev/null; then
    echo "Installing Home Manager..."
    nix-shell '<home-manager>' -A install
fi

# Link home.nix
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config/home-manager
ln -sf "$DOTFILES_DIR/home.nix" ~/.config/home-manager/home.nix

# Apply configuration
echo "Applying Home Manager configuration..."
home-manager switch

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    ZSH_PATH=$(which zsh)
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "$ZSH_PATH" "$USER"
fi

echo "Done! Restart your shell or run: exec zsh"
