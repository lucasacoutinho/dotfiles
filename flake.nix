{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = if builtins ? currentSystem then builtins.currentSystem else "x86_64-linux";
      minimumBunVersion = "1.3.14";
      minimumBunOverlay =
        _final: prev:
        let
          sourceForSystem =
            {
              x86_64-linux = {
                url = "https://github.com/oven-sh/bun/releases/download/bun-v${minimumBunVersion}/bun-linux-x64.zip";
                hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
              };
            }
            .${prev.stdenvNoCC.hostPlatform.system} or null;
        in
        # Use the normal nixpkgs package as soon as it catches up. Until then,
        # this overlay is a version floor rather than a permanent pin.
        nixpkgs.lib.optionalAttrs (sourceForSystem != null) {
          bun = prev.bun.overrideAttrs (
            _finalAttrs: previousAttrs:
            let
              bunSource = prev.fetchurl sourceForSystem;
            in
            nixpkgs.lib.optionalAttrs (prev.lib.versionOlder previousAttrs.version minimumBunVersion) {
              version = minimumBunVersion;
              src = bunSource;
              passthru = previousAttrs.passthru // {
                sources = previousAttrs.passthru.sources // {
                  "${prev.stdenvNoCC.hostPlatform.system}" = bunSource;
                };
              };
            }
          );
        };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ minimumBunOverlay ];
      };
      herdrRecoveryPlugin = import ./nix/herdr-recovery.nix { inherit pkgs; };
    in
    {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };

      checks.${system}.herdr-recovery = pkgs.runCommand "herdr-recovery-check" {
        nativeBuildInputs = [ pkgs.herdr pkgs.jq ];
      } ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_DATA_HOME="$TMPDIR/data"
        export XDG_STATE_HOME="$TMPDIR/state"
        export HERDR_CONFIG_PATH="$XDG_CONFIG_HOME/herdr/config.toml"
        export HERDR_SOCKET_PATH="$XDG_CONFIG_HOME/herdr/offline.sock"

        mkdir -p "$HOME"
        test -x ${herdrRecoveryPlugin}/bin/herdr-recovery
        herdr plugin link ${herdrRecoveryPlugin} --disabled >/dev/null
        jq -e '
          length == 1
          and .[0].plugin_id == "lucas.recovery"
          and .[0].min_herdr_version == "0.7.5"
          and .[0].version == "0.2.0"
          and .[0].enabled == false
        ' "$XDG_CONFIG_HOME/herdr/plugins.json" >/dev/null

        mkdir -p "$out"
        touch "$out/passed"
      '';
    };
}
