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

See `devcontainer.example.json` for a complete example, or add to your devcontainer.json:

```json
{
  "postCreateCommand": "git clone https://github.com/lucasacoutinho/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "terminal.integrated.profiles.linux": {
          "zsh": { "path": "~/.nix-profile/bin/zsh" }
        }
      }
    }
  }
}
```

## Customizing

Edit `home.nix` and run:

```bash
home-manager switch
```
