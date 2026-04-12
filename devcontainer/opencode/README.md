# OpenCode CLI (opencode)

Installs the [OpenCode CLI](https://opencode.ai/docs/) and shares your host machine's OpenCode credentials and configuration with the devcontainer.

If you need a container that does not inherit any host OpenCode auth, skills, or settings, use `ghcr.io/lucasacoutinho/devcontainer-features/opencode-isolated:1` instead.

## Features

- **Credential Sharing**: Mounts your host's `~/.config/opencode/` into the container
- **Skills Sharing**: Mounts your host's `~/.opencode/` for global skills, agents, and commands
- **CLI Installation**: Installs the `opencode-ai` npm package globally
- **No Re-authentication**: Use your existing OpenCode session across all devcontainers

## Prerequisites

**You must authenticate OpenCode on your HOST machine first:**

```bash
# On your host terminal (not in devcontainer)
opencode
# Use /connect to authenticate with your provider
```

This creates `~/.config/opencode/` which will be mounted into your devcontainers.

## Usage

Add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/opencode:1": {}
  }
}
```

### With Options

```json
{
  "features": {
    "ghcr.io/lucasacoutinho/devcontainer-features/opencode:1": {
      "version": "1.0.0"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of OpenCode CLI to install |

## How It Works

This feature:

1. **Mounts config**: Binds your host's OpenCode config directories into the container
   - `~/.config/opencode/` - Global settings, themes, providers, and authentication
   - `~/.opencode/` - Global skills, agents, commands, and plugins

2. **Installs CLI**: Installs the OpenCode CLI via npm so you can run `opencode` in the container

3. **Preserves sessions**: Your authenticated session persists across container rebuilds

## Directory Structure

OpenCode uses the following config locations:

| Location | Purpose |
|----------|---------|
| `~/.config/opencode/opencode.json` | Global configuration |
| `~/.config/opencode/skill/` | Global skills |
| `~/.config/opencode/agent/` | Global agents |
| `~/.config/opencode/command/` | Global commands |
| `~/.config/opencode/plugin/` | Global plugins |
| `~/.opencode/` | Alternative global config directory |
| `.opencode/` (project) | Project-specific configuration |

## Skills Support

OpenCode supports skills similar to Claude Code. Your global skills from `~/.config/opencode/skill/` and `~/.opencode/skill/` will be available in the container.

Skills are defined as `SKILL.md` files with YAML frontmatter:

```markdown
---
name: my-skill
description: Description of what this skill does
---

# My Skill

Instructions for the agent...
```

## Troubleshooting

### "OpenCode not authenticated" errors

Ensure you've run `opencode` on your **host machine** first and completed the `/connect` authentication flow with your provider. Then rebuild your devcontainer.

### Mount permission issues

If you encounter permission errors, ensure your host's config directories have appropriate permissions:

```bash
# On host
chmod -R 755 ~/.config/opencode
chmod -R 755 ~/.opencode
```

### Node.js not found

This feature will attempt to install Node.js if not present. For best results, also include the Node.js feature:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/lucasacoutinho/devcontainer-features/opencode:1": {}
  }
}
```

### Config directories don't exist

If the mount directories don't exist on your host, create them:

```bash
mkdir -p ~/.config/opencode
mkdir -p ~/.opencode
```

## Notes

- This feature is designed for **Linux/macOS hosts** (including WSL)
- The mounted directories use bind mounts, so changes in the container affect the host
- Works with VS Code devcontainers, GitHub Codespaces*, and other devcontainer-compatible tools
- OpenCode also supports Claude-compatible skill paths (`.claude/skills/`)

*GitHub Codespaces may have limited support for host mounts depending on your configuration.

## Related Documentation

- [OpenCode Documentation](https://opencode.ai/docs/)
- [OpenCode Config](https://opencode.ai/docs/config/)
- [OpenCode Skills](https://opencode.ai/docs/skills/)
- [OpenCode Agents](https://opencode.ai/docs/agents/)
