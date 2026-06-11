#!/bin/bash
# Regenerates the install.sh of every feature from the sources in src/.
# Shared logic (Node bootstrap, npm install, profile.d wrapper) lives in the
# templates; per-tool runtime setup lives in src/setup/<tool>.sh.
# The devcontainer-feature.json manifests are hand-authored: mounts and
# lifecycle hooks genuinely differ per tool and cannot be parameterized.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

render() {
    local tmpl="$1" out="$2" name="$3" npm_pkg="$4" bin="$5" setup_bin="$6" setup_body="$7"
    sed -e "s|__TOOL_NAME__|$name|g" \
        -e "s|__NPM_PKG__|$npm_pkg|g" \
        -e "s|__BIN__|$bin|g" \
        -e "s|__SETUP_BIN__|$setup_bin|g" \
        "src/$tmpl" |
    awk -v nb="src/node-bootstrap.sh" -v sb="$setup_body" '
        $0 == "__NODE_BOOTSTRAP__" { while ((getline l < nb) > 0) print l; close(nb); next }
        $0 == "__SETUP_BODY__"     { while ((getline l < sb) > 0) print l; close(sb); next }
        { print }
    ' > "$out"
    chmod +x "$out"
    echo "generated $out"
}

generate() {
    local tool="$1" name="$2" npm_pkg="$3" bin="$4" setup_bin="$5"
    render install-shared.tmpl   "$tool/install.sh"          "$name" "$npm_pkg" "$bin" "$setup_bin" "src/setup/$tool.sh"
    render install-isolated.tmpl "$tool-isolated/install.sh" "$name" "$npm_pkg" "$bin" "$setup_bin" /dev/null
}

#        tool         display name        npm package                  binary    setup script
generate claude-code "Claude Code CLI"   "@anthropic-ai/claude-code"  claude    claude-code-setup
generate codex       "OpenAI Codex CLI"  "@openai/codex"              codex     codex-setup
generate gemini-cli  "Gemini CLI"        "@google/gemini-cli"         gemini    gemini-setup
generate opencode    "OpenCode CLI"      "opencode-ai"                opencode  opencode-setup
