#!/bin/bash
set -euo pipefail

echo "Installing dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"

# Create ~/.dotfiles symlink for compatibility
if [ -L "$HOME/.dotfiles" ]; then
    ln -snf "$DOTFILES_DIR" "$HOME/.dotfiles"
elif [ -e "$HOME/.dotfiles" ]; then
    echo "Skipping ~/.dotfiles symlink because $HOME/.dotfiles already exists and is not a symlink."
else
    echo "Creating ~/.dotfiles symlink..."
    ln -s "$DOTFILES_DIR" "$HOME/.dotfiles"
fi

# Install Nix if not present
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon --yes
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Enable flakes
mkdir -p "$NIX_CONF_DIR"
if ! grep -Eq '(^|[[:space:]])flakes([[:space:]]|$)' "$NIX_CONF_FILE" 2>/dev/null; then
    echo "Enabling Nix flakes..."
    printf '\nexperimental-features = nix-command flakes\n' >> "$NIX_CONF_FILE"
fi

# Build/apply Home Manager from the flake lock instead of a moving branch.
echo "Applying Home Manager configuration from the pinned flake..."
ACTIVATION_PACKAGE="$(nix build --impure --no-link --print-out-paths "path:$DOTFILES_DIR#homeConfigurations.default.activationPackage")"
"$ACTIVATION_PACKAGE/activate"

# Optionally set zsh as the default shell.
if [ "$SHELL" != "$(command -v zsh)" ]; then
    ZSH_PATH="$(command -v zsh)"
    if [ "${SET_DEFAULT_SHELL:-0}" = "1" ]; then
        echo "Setting zsh as default shell..."
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        sudo chsh -s "$ZSH_PATH" "$USER"
    else
        echo "zsh is installed at $ZSH_PATH but not set as your login shell."
        echo "Run SET_DEFAULT_SHELL=1 ./install.sh if you want this script to update your shell."
    fi
fi

# Install repository Claude Code skills if present (copy instead of symlink for container compatibility)
if [ -d "$DOTFILES_DIR/.claude/skills" ]; then
    echo "Installing Claude Code skills..."
    mkdir -p ~/.claude/skills
    for skill_dir in "$DOTFILES_DIR/.claude/skills"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            # Remove existing symlink or directory, then copy fresh
            rm -rf "$HOME/.claude/skills/$skill_name"
            cp -r "$skill_dir" "$HOME/.claude/skills/$skill_name"
            echo "  Installed skill: $skill_name"
        fi
    done
fi

echo "Done! Restart your shell or run: exec zsh"
