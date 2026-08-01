# Claude Code CLI

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and makes
the host login available inside a trusted devcontainer.

## Auth boundary

The feature mounts only `~/.claude/.credentials.json`. It does not mount
`~/.claude.json` or the rest of `~/.claude`, so host settings, skills, plugins,
projects, history, caches, and session data stay outside the container.

The credential mount is writable so Claude can persist token refreshes. The
container can read the token, so use the isolated feature for untrusted images.

## Prerequisite

Authenticate Claude Code on the host and confirm the credential file exists:

```bash
claude
test -f ~/.claude/.credentials.json
```

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code:1": {}
  }
}
```

The optional `version` setting defaults to `latest`. The container user must
have the same UID as the host user to read and refresh the mounted file.

For no host authentication, use
`ghcr.io/lucasacoutinho/dotfiles/claude-code-isolated:1`.
