# Google Gemini CLI (gemini-cli-isolated)

Installs the [Google Gemini CLI](https://github.com/google-gemini/gemini-cli) without mounting host credentials into the devcontainer.

Use this variant when the container must stay isolated from your personal `~/.gemini` config.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/gemini-cli-isolated:1": {}
  }
}
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `latest` | Version to install |

## Notes

- No host `~/.gemini` bind mount is configured
- Authenticate inside the container if needed
- If you want to reuse your host Gemini session instead, use the shared `gemini-cli` feature
