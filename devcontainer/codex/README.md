# OpenAI Codex CLI

Installs the [OpenAI Codex CLI](https://github.com/openai/codex) and shares host credentials with devcontainers.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/codex:1": {}
  }
}
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `latest` | Version to install |

## How It Works

- Mounts host `~/.codex/` into the container
- Installs `@openai/codex` CLI globally
- No re-authentication needed across devcontainers

## Prerequisites

1. Authenticate on your **host machine** first:
   ```bash
   npm install -g @openai/codex
   codex  # Complete OAuth or API key setup
   ```
2. Rebuild your devcontainer
