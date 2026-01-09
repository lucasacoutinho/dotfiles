# Claude Code CLI (claude-code)

Installs the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) and shares your host machine's Claude credentials with the devcontainer.

## Features

- **Credential Sharing**: Mounts your host's `~/.claude/` and `~/.claude.json` into the container
- **CLI Installation**: Installs the `@anthropic-ai/claude-code` npm package globally
- **No Re-authentication**: Use your existing Claude session across all devcontainers

## Prerequisites

**You must authenticate Claude Code on your HOST machine first:**

```bash
# On your host terminal (not in devcontainer)
claude
# Follow the authentication prompts
```

This creates `~/.claude/` and `~/.claude.json` which will be mounted into your devcontainers.

## Usage

Add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/claude-code:1": {}
  }
}
```

### With Options

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/claude-code:1": {
      "version": "1.0.3"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of Claude Code CLI to install |

## How It Works

This feature:

1. **Mounts credentials**: Binds your host's Claude config directories into the container
   - `~/.claude/` - Settings, agents, session data
   - `~/.claude.json` - OAuth tokens and authentication

2. **Installs CLI**: Installs the Claude Code CLI via npm so you can run `claude` in the container

3. **Preserves sessions**: Your authenticated session persists across container rebuilds

## Troubleshooting

### "Claude not authenticated" errors

Ensure you've run `claude` on your **host machine** first and completed the authentication flow. Then rebuild your devcontainer.

### Mount permission issues

If you encounter permission errors, ensure your host's `~/.claude/` directory has appropriate permissions:

```bash
# On host
chmod -R 755 ~/.claude
chmod 644 ~/.claude.json
```

### Node.js not found

This feature will attempt to install Node.js if not present. For best results, also include the Node.js feature:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/lucasacoutinho/devcontainer-features/claude-code:1": {}
  }
}
```

## Notes

- This feature is designed for **Linux/macOS hosts** (including WSL)
- The mounted directories use bind mounts, so changes in the container affect the host
- Works with VS Code devcontainers, GitHub Codespaces*, and other devcontainer-compatible tools

*GitHub Codespaces may have limited support for host mounts depending on your configuration.
