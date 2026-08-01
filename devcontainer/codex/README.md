# OpenAI Codex CLI

Installs the [OpenAI Codex CLI](https://github.com/openai/codex) and makes the
host login available inside a trusted devcontainer.

## Auth boundary

The feature mounts only `~/.codex/auth.json`. It does not mount Codex config,
skills, plugins, MCP configuration, sessions, memories, history, or caches.
Those remain local to the container.

The credential mount is writable so Codex can persist token refreshes. The
container can read the token, so use the isolated feature for untrusted images.

## Prerequisite

Use file-backed credential storage and authenticate Codex on the host:

```bash
codex login
test -f ~/.codex/auth.json
```

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/codex:1": {}
  }
}
```

The optional `version` setting defaults to `latest`. The container user must
have the same UID as the host user to read and refresh the mounted file.

For no host authentication, use
`ghcr.io/lucasacoutinho/dotfiles/codex-isolated:1`.
