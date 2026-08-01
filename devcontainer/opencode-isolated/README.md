# OpenCode CLI (opencode-isolated)

Installs the [OpenCode CLI](https://opencode.ai/docs/) without mounting any host OpenCode configuration, auth, skills, or plugin directories into the devcontainer.

Use this variant when the container must stay isolated from your host `~/.config/opencode` and `~/.opencode` state.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/opencode-isolated:1": {}
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of OpenCode CLI to install |

## Notes

- No host `~/.config/opencode/` or `~/.opencode/` bind mounts are configured
- Authenticate inside the container if needed
- If you want to reuse only your host OpenCode login instead, use the shared `opencode` feature
