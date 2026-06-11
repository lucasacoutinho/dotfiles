let
  env = name: builtins.getEnv name;
  username =
    let value = env "USER";
    in if value != "" then value else "lucas";
  homeDirectory =
    let value = env "HOME";
    in if value != "" then value else "/home/${username}";
  dotfilesDir =
    let value = env "DOTFILES_DIR";
    in if value != "" then value else "${homeDirectory}/personal/dotfiles";
  kubeconfig =
    let value = env "KUBECONFIG";
    in if value != "" then value else "${homeDirectory}/personal/cloud/.kube/config";
  # "full" installs everything; "minimal" skips infra/devops tools — meant for
  # project devcontainers that only need shell quality-of-life.
  profile =
    let value = env "DOTFILES_PROFILE";
    in if value != "" then value else "full";
  base = {
    inherit username homeDirectory dotfilesDir kubeconfig profile;

    git = {
      name = "Lucas Coutinho";
      email = "lucasalvcoutinho@gmail.com";
      signingKey = "~/.ssh/id_rsa.pub";
      signByDefault = true;
    };
  };

  # Optional per-machine overrides, kept out of git (see .gitignore).
  # hosts/local.nix may redefine any top-level value; its `git` attrset is
  # merged key-by-key so a machine can override just the email or signing key.
  local = if builtins.pathExists ./local.nix then import ./local.nix else { };
in
base // local // {
  git = (base.git or { }) // (local.git or { });
}
