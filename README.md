# Dotfiles

Unified development environment: Nix tooling + Devcontainer features + Claude Code skills.

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

AI CLI tools with credential mounting:

- `claude-code` - Anthropic Claude Code CLI
- `codex` - OpenAI Codex CLI
- `gemini-cli` - Google Gemini CLI

### Claude Code Skills (`.claude/skills/`)

Personal workflow skills:

- `advise` - Search project knowledge before starting work
- `retrospective` - Document completed features for future reference
- `autodoc` - Auto-generate documentation from git changes
- `curl-generate` - Generate curl commands from conversation context
- `file-organizer` - Intelligently organize files and folders

## Usage in Devcontainers

See `devcontainer/example.json` or add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code:latest": {}
  },
  "postCreateCommand": "git clone https://github.com/lucasacoutinho/dotfiles.git ~/personal/dotfiles && ~/personal/dotfiles/install.sh"
}
```

## Customizing

### Add Nix packages

Edit `home.nix` and run:

```bash
home-manager switch
```

### Add Claude skills

Create a new skill in `.claude/skills/<skill-name>/SKILL.md` and re-run `./install.sh` to symlink it.

## Structure

```
dotfiles/
├── home.nix                 # Nix/Home Manager config
├── install.sh               # Installation script
├── devcontainer/            # Devcontainer features
│   ├── example.json
│   ├── claude-code/
│   ├── codex/
│   └── gemini-cli/
├── .claude/
│   └── skills/              # Claude Code skills
└── .github/workflows/       # Feature release automation
```
