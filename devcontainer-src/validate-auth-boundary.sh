#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_mounts() {
    local feature="$1"
    local expected="$2"
    local manifest="$REPO_DIR/devcontainer/$feature/devcontainer-feature.json"
    local actual

    actual="$(jq -c '.mounts' "$manifest")"
    if [ "$actual" != "$expected" ]; then
        echo "ERROR: $feature crosses the auth-only mount boundary" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        return 1
    fi
}

check_mounts claude-code \
    '[{"source":"${localEnv:HOME}/.claude/.credentials.json","target":"/mnt/host-claude-credentials.json","type":"bind"}]'
check_mounts codex \
    '[{"source":"${localEnv:HOME}/.codex/auth.json","target":"/mnt/host-codex-auth.json","type":"bind"}]'
check_mounts gemini-cli \
    '[{"source":"${localEnv:HOME}/.gemini/oauth_creds.json","target":"/mnt/host-gemini-oauth-creds.json","type":"bind"},{"source":"${localEnv:HOME}/.gemini/google_accounts.json","target":"/mnt/host-gemini-google-accounts.json","type":"bind"}]'
check_mounts opencode \
    '[{"source":"${localEnv:HOME}/.local/share/opencode/auth.json","target":"/mnt/host-opencode-auth.json","type":"bind"}]'

for feature in claude-code codex gemini-cli opencode; do
    isolated_manifest="$REPO_DIR/devcontainer/$feature-isolated/devcontainer-feature.json"
    jq -e '.mounts == null or .mounts == []' "$isolated_manifest" >/dev/null
done

echo "Shared features mount authentication only; isolated features mount nothing."
