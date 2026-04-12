# Dotfiles

Unified development environment: Nix tooling + devcontainer features.

## Quick Install

```bash
git clone https://github.com/lucasacoutinho/dotfiles.git ~/personal/dotfiles
~/personal/dotfiles/install.sh
```

## What's Included

### Nix/Home Manager (`home.nix`)

- **Zsh** with autosuggestions and syntax highlighting
- **Starship** prompt (minimal, fast)
- **Modern CLI tools**: ripgrep, fd, bat, eza, fzf, zoxide, jq, htop, tree
- **Data processing**: yq, qsv
- **Code analysis**: tokei, tree-sitter, universal-ctags

### Devcontainer Features (`devcontainer/`)

AI CLI tools in two modes:

- Shared-host-auth: `claude-code`, `codex`, `gemini-cli`, `opencode`
- Isolated/no-host-secrets: `claude-code-isolated`, `codex-isolated`, `gemini-cli-isolated`, `opencode-isolated`

### Claude Code

- Project hooks in `.claude/settings.json` block direct host-side language/package-manager commands and push Claude toward `docker compose exec ...` when you are outside the devcontainer

## Usage in Devcontainers

See `devcontainer.example.json` or add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code:latest": {}
  },
  "postCreateCommand": "git clone https://github.com/lucasacoutinho/dotfiles.git ~/personal/dotfiles && ~/personal/dotfiles/install.sh"
}
```

Keep editor secrets out of tracked config. For example, set `intelephense.licenceKey` only in an untracked local file such as `.vscode/settings.json`.

For company-managed containers or customer environments, use the isolated features instead of the shared host-auth variants:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/claude-code-isolated:1": {},
    "ghcr.io/lucasacoutinho/devcontainer-features/codex-isolated:1": {},
    "ghcr.io/lucasacoutinho/devcontainer-features/gemini-cli-isolated:1": {},
    "ghcr.io/lucasacoutinho/devcontainer-features/opencode-isolated:1": {}
  }
}
```

## Customizing

### Add Nix packages

Edit `home.nix` and run:

```bash
home-manager switch
```

### Adjust host-specific settings

Edit `hosts/default.nix` for user, home directory, git identity, signing key, and machine-specific paths like `KUBECONFIG`.

## Structure

```
dotfiles/
├── home.nix                 # Nix/Home Manager config
├── hosts/default.nix        # Host-specific identity and machine paths
├── install.sh               # Installation script
├── devcontainer.example.json
├── devcontainer/            # Devcontainer features
│   ├── claude-code/
│   ├── claude-code-isolated/
│   ├── codex/
│   ├── codex-isolated/
│   ├── gemini-cli/
│   ├── gemini-cli-isolated/
│   ├── opencode/
│   └── opencode-isolated/
├── .claude/settings.json    # Claude Code project hooks
└── .github/workflows/       # Feature release automation
```
