# Dotfiles

Reproducible shell environment using Nix + Home Manager.

## Quick Install

```bash
git clone https://github.com/lucasacoutinho/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## What's Included

- **Zsh** with autosuggestions and syntax highlighting
- **Starship** prompt (minimal, fast)
- **Modern CLI tools**: ripgrep, fd, bat, eza, fzf, zoxide, jq, htop, delta

## Usage in Devcontainers

Add to your devcontainer.json:

```json
{
  "postCreateCommand": "git clone https://github.com/lucasacoutinho/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh"
}
```

Or use the `--no-daemon` Nix install for containers without systemd.

## Customizing

Edit `home.nix` and run:

```bash
home-manager switch
```
