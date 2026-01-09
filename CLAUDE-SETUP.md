# Claude Code Environment Setup

Last updated: 2026-01-08

## Quick Start

```bash
chmod +x claude-setup.sh
./claude-setup.sh
```

## Marketplaces

| Name | Repository | Description |
|------|------------|-------------|
| claude-plugins-official | anthropics/claude-plugins-official | Official Anthropic plugins (built-in) |
| anthropic-agent-skills | anthropics/skills | Official skill templates |
| superpowers-marketplace | obra/superpowers-marketplace | Community superpowers plugins |

### Manual marketplace setup

```bash
claude /plugin marketplace add anthropics/skills
claude /plugin marketplace add obra/superpowers-marketplace
```

## Installed Plugins (30)

### From claude-plugins-official

| Plugin | Purpose |
|--------|---------|
| context7 | Up-to-date library documentation lookup |
| security-guidance | Security best practices |
| greptile | Code review integration |
| pinecone | Vector database integration |
| playwright | Browser automation/testing |
| explanatory-output-style | Educational response style |
| learning-output-style | Interactive learning mode |
| code-review | Code review tools |
| pr-review-toolkit | PR review specialized agents |
| ralph-wiggum | Personality plugin |
| ralph-loop | Loop automation |
| frontend-design | UI/UX design skills |
| typescript-lsp | TypeScript language server |
| pyright-lsp | Python language server |
| gopls-lsp | Go language server |
| rust-analyzer-lsp | Rust language server |
| clangd-lsp | C/C++ language server |
| csharp-lsp | C# language server |
| php-lsp | PHP language server |
| swift-lsp | Swift language server |
| lua-lsp | Lua language server |

### From anthropic-agent-skills

| Plugin | Purpose |
|--------|---------|
| document-skills | PDF, DOCX, XLSX, PPTX manipulation |
| example-skills | Skill template examples |

### From superpowers-marketplace

| Plugin | Purpose |
|--------|---------|
| superpowers | Core skills (TDD, debugging, brainstorming, etc.) |
| double-shot-latte | Enhanced workflows |
| elements-of-style | Writing quality improvements |
| episodic-memory | Cross-session memory via conversation search |
| superpowers-chrome | Chrome browser automation |
| superpowers-developing-for-claude-code | Plugin development tools |
| superpowers-lab | Experimental features |

## Settings

```json
{
  "alwaysThinkingEnabled": true
}
```

## Personal Skills

Location: `~/.claude/skills/`

Currently: None configured

To add a personal skill:
```bash
mkdir -p ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Description of what this skill does
---

# My Skill

Instructions here...
EOF
```

## Backup Strategy

To backup your Claude Code setup:

```bash
# Backup entire config (includes history, credentials, etc.)
tar -czvf claude-backup.tar.gz ~/.claude/

# Or backup just reproducible config
cp ~/.claude/settings.json ./
cp ~/.claude/plugins/known_marketplaces.json ./
# Custom skills
cp -r ~/.claude/skills/ ./claude-skills-backup/ 2>/dev/null || true
```

## Restore on New Machine

1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. Run: `./claude-setup.sh`
3. Restore personal skills: `cp -r ./claude-skills-backup/* ~/.claude/skills/`
4. Restart Claude Code
