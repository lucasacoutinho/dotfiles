<div align="center">
  <h1>Dotfiles</h1>
  <p>Nix-managed command-line tools and auth-isolated agent features for Linux, WSL, and devcontainers.</p>

  <a href="https://github.com/lucasacoutinho/dotfiles/actions/workflows/validate.yml"><img alt="Validation" src="https://img.shields.io/github/actions/workflow/status/lucasacoutinho/dotfiles/validate.yml?branch=main&style=for-the-badge&labelColor=000000"></a>
  <a href="https://github.com/lucasacoutinho/dotfiles/actions/workflows/release.yml"><img alt="Feature release" src="https://img.shields.io/github/actions/workflow/status/lucasacoutinho/dotfiles/release.yml?branch=main&style=for-the-badge&label=features&labelColor=000000"></a>
  <img alt="Nix and Home Manager" src="https://img.shields.io/badge/Nix-Home%20Manager-5277C3?style=for-the-badge&logo=nixos&logoColor=white&labelColor=000000">
</div>

## Getting started

Clone the repository and run the installer:

```bash
git clone https://github.com/lucasacoutinho/dotfiles.git ~/personal/dotfiles
~/personal/dotfiles/install.sh
```

The installer bootstraps Nix when needed, enables flakes, and activates the
Home Manager configuration pinned by `flake.lock`.

## Nix environment

The default profile installs Zsh, Starship, Git, Direnv, Node.js, Bun, Herdr,
and a focused set of shell, data-processing, and code-analysis tools. The full
package list lives in [`home.nix`](./home.nix).

Use the shell aliases after activation:

| Command | Purpose |
| --- | --- |
| `hms` | Rebuild and activate the versions already pinned in `flake.lock` |
| `hmu` | Update flake inputs, build a new generation, and activate it |

You can also run the updater directly:

```bash
./update.sh
./update.sh nixpkgs # update one input only
```

Nix manages the user environment. Ubuntu or Debian packages still use
`sudo apt update && sudo apt upgrade`. Old Home Manager generations remain
available for rollback; run `nix store gc` separately when you want to remove
unreachable store paths.

## Agent features

The shared devcontainer features reuse host authentication without importing
personal agent state. Settings, skills, plugins, MCP configuration, project
context, history, sessions, caches, and memories stay local to the container.

| CLI | Auth-only feature | Isolated feature | Mounted host file |
| --- | --- | --- | --- |
| Claude Code | `claude-code:1` | `claude-code-isolated:1` | `~/.claude/.credentials.json` |
| Codex | `codex:1` | `codex-isolated:1` | `~/.codex/auth.json` |
| Gemini CLI | `gemini-cli:1` | `gemini-cli-isolated:1` | `~/.gemini/oauth_creds.json` and `google_accounts.json` |
| OpenCode | `opencode:1` | `opencode-isolated:1` | `~/.local/share/opencode/auth.json` |

Add a feature to `devcontainer.json` after authenticating that CLI on the host:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/codex:1": {}
  }
}
```

Credential mounts are writable so token refreshes survive rebuilds. A trusted
container can read those tokens. Use the isolated variants for third-party,
untrusted, or customer-controlled images.

Compose-based containers must create their remote user with the same UID and
GID as the host user. Image-based devcontainers normally handle this through
`"updateRemoteUserUID": true`.

## Configuration

Create the gitignored `hosts/local.nix` for machine-specific values:

```nix
{
  git.email = "lucas@work.example";
  kubeconfig = "/home/lucas/.kube/work-config";
}
```

Set `DOTFILES_PROFILE=minimal` in project containers to skip infrastructure
packages such as k9s, Talos, Ansible, and opam. Persist `/nix` with a named
volume if you want Nix packages to survive container rebuilds.

See [`devcontainer.example.json`](./devcontainer.example.json) for a complete
compose-based setup and the individual feature directories under
[`devcontainer/`](./devcontainer/) for tool-specific prerequisites.

## Development

Feature installers are generated from `devcontainer-src/`. After changing a
template or setup script, regenerate and validate the published files:

```bash
./devcontainer-src/generate.sh
./devcontainer-src/validate-auth-boundary.sh
```

GitHub Actions rejects stale generated installers and any shared feature that
mounts more than its credential allowlist.
