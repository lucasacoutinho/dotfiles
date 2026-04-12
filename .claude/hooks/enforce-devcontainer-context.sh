#!/bin/bash
set -euo pipefail

INPUT="$(cat)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"

if [ -z "$COMMAND" ]; then
    exit 0
fi

inside_devcontainer() {
    [ -n "${DEVCONTAINER:-}" ] \
        || [ -n "${REMOTE_CONTAINERS:-}" ] \
        || [ -n "${CODESPACES:-}" ] \
        || [ "${container:-}" = "docker" ] \
        || [ -f "/.dockerenv" ] \
        || [ -f "/run/.containerenv" ]
}

find_compose_service() {
    local candidate
    local service

    for candidate in ".devcontainer/devcontainer.json" "devcontainer.json" "devcontainer.example.json"; do
        if [ -f "$candidate" ]; then
            service="$(jq -r '.service // empty' "$candidate" 2>/dev/null || true)"
            if [ -n "$service" ]; then
                printf '%s\n' "$service"
                return 0
            fi
        fi
    done

    return 1
}

normalize_command() {
    local normalized="$1"

    while [[ "$normalized" =~ ^[[:space:]]*(sudo|command|time)[[:space:]]+(.+)$ ]]; do
        normalized="${BASH_REMATCH[2]}"
    done

    while [[ "$normalized" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=([^[:space:]]+|\"[^\"]*\"|\'[^\']*\')[[:space:]]+(.+)$ ]]; do
        normalized="${BASH_REMATCH[2]}"
    done

    printf '%s\n' "$normalized"
}

is_container_aware_command() {
    local normalized="$1"

    [[ "$normalized" =~ ^(docker([[:space:]]+compose)?|docker-compose|devcontainer)([[:space:]]|$) ]]
}

is_host_language_command() {
    local normalized="$1"

    [[ "$normalized" =~ (^|[\"\'\(\{;[:space:]])(php|composer|artisan|symfony|node|npm|npx|pnpm|yarn|bun|python|python3|pip|pip3|uv|pytest|poetry|ruby|bundle|gem|rails|go|cargo|rustc|java|javac|mvn|gradle|dotnet|mix|iex|deno|ts-node|\.?/vendor/bin/[^[:space:]]+|vendor/bin/[^[:space:]]+|node_modules/\.bin/[^[:space:]]+)([[:space:]]|$) ]]
}

if inside_devcontainer; then
    exit 0
fi

NORMALIZED_COMMAND="$(normalize_command "$COMMAND")"

if is_container_aware_command "$NORMALIZED_COMMAND"; then
    exit 0
fi

if ! is_host_language_command "$NORMALIZED_COMMAND"; then
    exit 0
fi

SERVICE="$(find_compose_service || true)"

if [ -n "$SERVICE" ]; then
    printf 'Blocked: run language/package-manager commands inside the devcontainer or via: docker compose exec -T %s sh -lc %q\n' "$SERVICE" "$COMMAND" >&2
else
    printf 'Blocked: run language/package-manager commands inside the devcontainer instead of directly on the host.\n' >&2
fi

exit 2
