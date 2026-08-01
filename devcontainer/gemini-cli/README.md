# Google Gemini CLI

Installs the [Gemini CLI](https://github.com/google-gemini/gemini-cli) and
makes the host login available inside a trusted devcontainer.

## Auth boundary

The feature mounts only `~/.gemini/oauth_creds.json` and
`~/.gemini/google_accounts.json`. It does not mount host settings, projects,
history, extensions, or caches.

The credential mounts are writable so Gemini can persist token refreshes. The
container can read the tokens, so use the isolated feature for untrusted images.

## Prerequisite

Authenticate Gemini on the host and confirm the files exist:

```bash
gemini
test -f ~/.gemini/oauth_creds.json
test -f ~/.gemini/google_accounts.json
```

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/gemini-cli:1": {}
  }
}
```

The optional `version` setting defaults to `latest`. The container user must
have the same UID as the host user to read and refresh the mounted files.

For no host authentication, use
`ghcr.io/lucasacoutinho/dotfiles/gemini-cli-isolated:1`.
