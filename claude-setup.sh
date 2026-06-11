#!/bin/bash
# Claude Code setup - restore plugins & settings
set -e

# Marketplaces
claude /plugin marketplace add anthropics/skills
claude /plugin marketplace add obra/superpowers-marketplace

# Plugins
for p in context7 security-guidance greptile pinecone playwright \
         explanatory-output-style learning-output-style code-review \
         pr-review-toolkit ralph-wiggum ralph-loop frontend-design \
         typescript-lsp pyright-lsp gopls-lsp rust-analyzer-lsp \
         clangd-lsp csharp-lsp php-lsp swift-lsp lua-lsp; do
  claude /plugin install "$p@claude-plugins-official"
done

for p in document-skills example-skills; do
  claude /plugin install "$p@anthropic-agent-skills"
done

for p in superpowers double-shot-latte elements-of-style episodic-memory \
         superpowers-chrome superpowers-developing-for-claude-code superpowers-lab; do
  claude /plugin install "$p@superpowers-marketplace"
done

# Settings — merge instead of overwrite so statusLine, hooks, etc. survive
mkdir -p ~/.claude
if [ -s ~/.claude/settings.json ]; then
  tmp="$(mktemp)"
  jq '. + {alwaysThinkingEnabled: true}' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
else
  echo '{"alwaysThinkingEnabled":true}' > ~/.claude/settings.json
fi

echo "Done! Restart Claude Code."
