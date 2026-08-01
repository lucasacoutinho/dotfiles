{ pkgs }:

let
  system = pkgs.stdenvNoCC.hostPlatform.system;
  bunSource = pkgs.bun.passthru.sources.${system} or (
    throw "The Bun package does not expose an upstream executable for ${system}"
  );
  bunArchiveDirectory =
    {
      x86_64-linux = "bun-linux-x64";
    }
    .${system} or (throw "The Herdr recovery plugin does not support ${system}");
  glibcLoader = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";
  pristineBun = pkgs.runCommand "bun-pristine-${pkgs.bun.version}" {
    nativeBuildInputs = [ pkgs.unzip ];
  } ''
    unzip -q ${bunSource} -d unpacked
    install -Dm755 unpacked/${bunArchiveDirectory}/bun "$out/bin/bun"
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "herdr-recovery-plugin";
  version = "0.2.0";
  src = ../herdr-plugins/recovery;

  nativeBuildInputs = [ pkgs.bun ];
  dontConfigure = true;
  dontFixup = true;

  buildPhase = ''
    runHook preBuild

    bun test
    mkdir -p dist
    bun run build --compile-executable-path=${pristineBun}/bin/bun

    test -x dist/herdr-recovery
    set +e
    smoke_output="$(
      HERDR_PLUGIN_CONFIG_DIR="$TMPDIR/config" \
        HERDR_PLUGIN_STATE_DIR="$TMPDIR/state" \
        ${glibcLoader} --library-path ${pkgs.glibc}/lib \
          dist/herdr-recovery invalid 2>&1
    )"
    smoke_status="$?"
    set -e
    test "$smoke_status" -eq 1
    printf '%s\n' "$smoke_output" | grep -F "Usage: herdr-recovery"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/herdr-recovery "$out/bin/herdr-recovery"
    install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
    install -Dm644 config.example.json "$out/config.example.json"
    install -Dm644 README.md "$out/README.md"

    runHook postInstall
  '';
}
