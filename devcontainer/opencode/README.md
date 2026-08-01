# OpenCode CLI

Installs [OpenCode](https://opencode.ai/docs/) and makes the host provider login
available inside a trusted devcontainer.

## Auth boundary

The feature mounts only `~/.local/share/opencode/auth.json`. It does not mount
host settings, themes, providers, skills, agents, commands, plugins, or project
configuration. Those remain local to the container.

The credential mount is writable so OpenCode can persist token changes. The
container can read the token, so use the isolated feature for untrusted images.

## Prerequisite

Authenticate OpenCode on the host and confirm the credential file exists:

```bash
opencode
test -f ~/.local/share/opencode/auth.json
```

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/opencode:1": {}
  }
}
```

The optional `version` setting defaults to `latest`. The container user must
have the same UID as the host user to read and refresh the mounted file.

For no host authentication, use
`ghcr.io/lucasacoutinho/dotfiles/opencode-isolated:1`.
