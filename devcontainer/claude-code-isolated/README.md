# Claude Code CLI (claude-code-isolated)

Installs the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) without mounting any host Claude configuration, session, or credential files into the devcontainer.

Use this variant when the container must stay isolated from personal host credentials, such as company-managed projects or customer environments.

## Usage

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/dotfiles/claude-code-isolated:1": {}
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of Claude Code CLI to install |

## Notes

- No host `~/.claude/` or `~/.claude.json` bind mounts are configured
- Authentication must be performed inside the container if you want to use Claude there
- If you want to reuse your host login instead, use the shared `claude-code` feature
