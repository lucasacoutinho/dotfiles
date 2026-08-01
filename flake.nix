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
    in
    {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
