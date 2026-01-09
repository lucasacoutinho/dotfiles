# Google Gemini CLI

Installs the [Google Gemini CLI](https://github.com/google-gemini/gemini-cli) and shares host credentials with devcontainers.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/gemini-cli:1": {}
  }
}
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `latest` | Version to install |

## How It Works

- Mounts host `~/.gemini/` into the container
- Installs `@google/gemini-cli` CLI globally
- No re-authentication needed across devcontainers

## Prerequisites

1. Authenticate on your **host machine** first:
   ```bash
   npm install -g @google/gemini-cli
   gemini  # Complete OAuth setup
   ```
2. Rebuild your devcontainer
