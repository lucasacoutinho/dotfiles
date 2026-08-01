#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

echo "Updating pinned Nix inputs..."
nix flake update --flake "path:$DOTFILES_DIR" "$@"

echo "Building the updated Home Manager generation..."
ACTIVATION_PACKAGE="$(
    nix build --impure --no-link --print-out-paths \
        "path:$DOTFILES_DIR#homeConfigurations.default.activationPackage"
)"

echo "Activating the updated Home Manager generation..."
"$ACTIVATION_PACKAGE/activate"

echo "Done. Review the package-source update with:"
echo "  git -C $DOTFILES_DIR diff -- flake.lock"
