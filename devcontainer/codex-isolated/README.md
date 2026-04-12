# OpenAI Codex CLI (codex-isolated)

Installs the [OpenAI Codex CLI](https://github.com/openai/codex) without mounting host Codex credentials into the devcontainer.

Use this variant when the container must not inherit your host `~/.codex` state.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/codex-isolated:1": {}
  }
}
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `latest` | Version to install |

## Notes

- No host `~/.codex` bind mount is configured
- Authenticate inside the container if needed
- If you want to reuse your host Codex session instead, use the shared `codex` feature
