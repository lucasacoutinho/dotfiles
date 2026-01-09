---
name: ai-dev-toolkit-v1
description: Initial setup of AI development toolkit with devcontainer features and Claude Code skills. Relevant when adding new CLI tools, creating skills, or extending the knowledge management system.
---

# AI Dev Toolkit v1

## Overview

| Item | Details |
|------|---------|
| **Date** | 2026-01-08 |
| **PR** | N/A (initial creation) |
| **Goal** | Create reproducible AI dev environment with devcontainer features + knowledge management skills |
| **Files Changed** | 50+ files across src/, skills/, docs/ |
| **Key Areas** | Devcontainer features, Claude Code skills, knowledge management |

## Decisions Made

| Decision | Why | Alternatives Considered |
|----------|-----|-------------------------|
| Individual features per CLI tool | Maximum flexibility, users pick what they need | Bundled "dev-tools" mega-feature (less flexible) |
| qsv over xsv for CSV | qsv is actively maintained fork with 50+ commands | xsv (unmaintained since 2018) |
| Skills in project repo | Version controlled, shareable, grows with codebase | ~/.claude/skills (personal only, not portable) |
| Detect-and-confirm for autodoc | Safer, educational, prevents wrong doc generation | Auto-detect-and-run (could write to wrong location) |
| Feature skills in .claude/skills/features/ | Follows Claude Code conventions, discoverable | docs/features/ (not Claude-native) |
| No git tool features | Already have gh CLI, avoid duplication | Include lazygit, delta (redundant) |

## Failed Attempts

| Attempt | Why it Failed | Lesson Learned |
|---------|---------------|----------------|
| Initially created skills in ~/.claude/skills/ | Not version controlled, can't share with team | Always put shareable skills in project repo |
| Started with xsv for CSV | Realized xsv is unmaintained | Check repo activity before choosing tools |
| Considered bundled "dev-tools" feature | Too opinionated, users want control | Individual features > bundles for CLI tools |

## Implementation

### Approach

1. **AI CLI features** (3): Mount host credentials + install CLI
2. **CLI tool features** (11): Individual install.sh per tool with multi-distro support
3. **Skills** (4): Knowledge management (advise/retrospective) + utilities (autodoc/curl-generate)
4. **Templates** (1): Feature skill template for consistency

### Key Files

- `src/<tool>/install.sh` - Multi-distro installers (apt, apk, dnf, pacman, GitHub releases)
- `src/<tool>/devcontainer-feature.json` - Feature metadata with version option
- `skills/advise/SKILL.md` - Pre-work knowledge search
- `skills/retrospective/SKILL.md` - Post-work documentation generator
- `skills/templates/feature-skill/SKILL.md` - Template for feature skills

### Directory Structure

```
devcontainer-features/
├── src/                          # Devcontainer features
│   ├── claude-code/              # AI CLI + credentials
│   ├── codex/
│   ├── gemini-cli/
│   ├── fzf/                      # CLI tools
│   ├── ripgrep/
│   ├── fd/
│   ├── jq/
│   ├── yq/
│   ├── qsv/
│   ├── bat/
│   ├── eza/
│   ├── tokei/
│   ├── tree-sitter/
│   └── ctags/
├── skills/                       # Claude Code skills
│   ├── advise/                   # Knowledge management
│   ├── retrospective/
│   ├── autodoc/                  # Development utilities
│   ├── curl-generate/
│   └── templates/
│       └── feature-skill/
├── .claude/skills/features/      # Project feature knowledge
└── docs/plans/                   # Design documents
```

## Patterns Discovered

### Multi-Distro Install Pattern

```bash
#!/bin/bash
set -e

if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y <package>
elif command -v apk &> /dev/null; then
    apk add --no-cache <package>
elif command -v dnf &> /dev/null; then
    dnf install -y <package>
elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm <package>
else
    # Fallback to GitHub releases
    curl -LO "https://github.com/.../<binary>.tar.gz"
    tar xzf <binary>.tar.gz && mv <binary> /usr/local/bin/
fi
```

**When to use:** Any devcontainer feature that installs a CLI tool.

### Knowledge Management Workflow

```
/advise → search past work → surface decisions/failures
    ↓
implement feature
    ↓
/retrospective → document → .claude/skills/features/<name>/
```

**When to use:** Every non-trivial feature to build institutional knowledge.

### Credential Mount Pattern (AI CLIs)

```json
{
  "mounts": [
    {
      "source": "${localEnv:HOME}/.<tool>",
      "target": "/home/${_REMOTE_USER}/.<tool>",
      "type": "bind"
    }
  ]
}
```

**When to use:** Any devcontainer feature that needs host credentials.

## Gotchas

- **WSL paths**: `${localEnv:HOME}` resolves based on where VS Code launches from. Open from WSL terminal for correct paths.
- **Debian fd/bat naming**: Installed as `fdfind`/`batcat`, need symlinks to `fd`/`bat`
- **qsv needs unzip**: Install unzip before downloading qsv from GitHub releases
- **tree-sitter CLI**: Best installed via npm or cargo, not package managers
- **Skills need restart**: After adding skills, restart Claude Code to load them

## Related

- [Sionic AI Skills Article](https://huggingface.co/blog/sionic-ai/claude-code-skills-training) - Inspiration for knowledge management approach
- [Dev Container Features Spec](https://containers.dev/implementors/features/)
- [Claude Code Skills Docs](https://docs.anthropic.com/claude-code/skills)
