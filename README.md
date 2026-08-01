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
- **Development runtimes**: Node.js, Bun, Herdr

### Devcontainer Features (`devcontainer/`)

AI CLI tools in two modes:

- Auth-only sharing: `claude-code`, `codex`, `gemini-cli`, `opencode`
- Isolated/no-host-secrets: `claude-code-isolated`, `codex-isolated`, `gemini-cli-isolated`, `opencode-isolated`

The auth-only features bind only each CLI's credential file. They do not share
host settings, skills, plugins, MCP configuration, project context, history,
sessions, caches, or memories. Each container starts with its own agent setup.

### Claude Code

- Project hooks in `.claude/settings.json` block direct host-side language/package-manager commands and push Claude toward `docker compose exec ...` when you are outside the devcontainer

## Usage in Devcontainers

See `devcontainer.example.json` or add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code:1": {}
  },
  "containerEnv": { "DOTFILES_PROFILE": "minimal" },
  "postCreateCommand": "git clone https://github.com/lucasacoutinho/dotfiles.git ~/personal/dotfiles && ~/personal/dotfiles/install.sh"
}
```

Pin features by major version (`:1`) rather than `:latest` so a new release can't break every project at once. `DOTFILES_PROFILE=minimal` skips the heavy infrastructure packages (k9s, talosctl, ansible, opam) inside project containers — see [Customizing](#customizing).

Keep editor secrets out of tracked config. For example, set `intelephense.licenceKey` only in an untracked local file such as `.vscode/settings.json`.

### UID/GID alignment (important for bind mounts)

The shared features bind-mount host credential files into the container. Token refreshes can fail if the container user's UID/GID differ from yours on the host:

- **Image/Dockerfile-based containers**: the devcontainer default `"updateRemoteUserUID": true` remaps the container user to your UID automatically — nothing to do.
- **Docker-compose-based containers** (like `devcontainer.example.json`): UID remapping does *not* apply. Pass your UID/GID as build args in `docker-compose.yml` and create the user with them:

```yaml
services:
  app:
    build:
      args:
        USER_UID: "${UID:-1000}"
        USER_GID: "${GID:-1000}"
```

Authenticate each CLI on the host before creating the container. File bind
mounts require the credential file to exist. See `devcontainer.example.json`
for an `initializeCommand` that fails early when one is missing.

The container can read the mounted tokens and refresh them on the host. Use
auth-sharing features only with containers you trust. Use an isolated feature
for third-party or customer-controlled images.

### Persisting /nix across rebuilds

`install.sh` reinstalls the whole Nix closure on every container rebuild unless `/nix` is persisted. For compose-based projects, add a named volume in `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      - nix-store:/nix
volumes:
  nix-store:
```

For image-based devcontainers, use `"mounts": ["source=nix-store,target=/nix,type=volume"]` in `devcontainer.json` instead.

For company-managed containers or customer environments, use the isolated features instead of the shared host-auth variants:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code-isolated:1": {},
    "ghcr.io/lucasacoutinho/dotfiles/codex-isolated:1": {},
    "ghcr.io/lucasacoutinho/dotfiles/gemini-cli-isolated:1": {},
    "ghcr.io/lucasacoutinho/dotfiles/opencode-isolated:1": {}
  }
}
```

## Customizing

### Add Nix packages

Edit `home.nix` and run:

```bash
hms
```

`hms` reapplies the versions pinned in `flake.lock`.

### Update Nix packages

Run the repository updater directly, or use `hmu` after Home Manager has loaded
the shell aliases:

```bash
./update.sh
# or
hmu
```

This updates the `nixpkgs` and Home Manager revisions in `flake.lock`, builds a
new generation, and activates it. To refresh one input only, pass its name:

```bash
./update.sh nixpkgs
```

That is the Home Manager equivalent of refreshing package metadata and then
upgrading installed packages. It does not update the Ubuntu or Debian base
system in WSL or a container. Use `sudo apt update && sudo apt upgrade` for
those packages.

Old Home Manager generations provide rollback points. When disk space matters,
remove unreachable Nix store paths separately with `nix store gc`.

Bun currently has a 1.3.14 version floor because the unstable Nixpkgs revision
still packages 1.3.13. The overlay automatically stops overriding Bun once
Nixpkgs reaches that version or a newer one.

### Adjust host-specific settings

`hosts/default.nix` derives username, home directory, and paths from `$USER`/`$HOME`/`$DOTFILES_DIR`/`$KUBECONFIG` at switch time, so the same config works for any user. It also holds the default git identity.

For values that differ per machine (work email, signing key, kubeconfig path), create a gitignored `hosts/local.nix` — any top-level value overrides the default, and `git` is merged key-by-key:

```nix
{
  git.email = "lucas@work.example";
  kubeconfig = "/home/lucas/.kube/work-config";
}
```

### Package profiles

Set `DOTFILES_PROFILE=minimal` (e.g. via `containerEnv` in `devcontainer.json`) to skip the infrastructure/devops packages (k9s, talosctl, ansible, opam) — project containers usually only need the shell tools. The default profile is `full`.

### Developing the devcontainer features

The per-feature `install.sh` files are generated. Edit the sources in `devcontainer-src/` (shared templates, Node bootstrap, per-tool setup scripts) and run:

```bash
./devcontainer-src/generate.sh
```

The sources live outside `devcontainer/` because the publish action treats every subdirectory there as a feature.

CI refuses to publish if generated files are stale. The `devcontainer-feature.json` manifests are hand-authored — mounts and lifecycle hooks genuinely differ per tool.

## Structure

```
dotfiles/
├── home.nix                 # Nix/Home Manager config
├── hosts/default.nix        # Host-specific identity and machine paths
├── install.sh               # Installation script
├── update.sh                # Refresh and activate pinned Nix packages
├── devcontainer.example.json
├── devcontainer-src/        # Feature templates + per-tool setup (edit these)
│   └── generate.sh          # Regenerates every feature's install.sh
├── devcontainer/            # Published devcontainer features
│   ├── claude-code/         # Generated install.sh + hand-authored manifest
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
