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
in
{
  inherit username homeDirectory dotfilesDir kubeconfig;

  git = {
    name = "Lucas Coutinho";
    email = "lucasalvcoutinho@gmail.com";
    signingKey = "~/.ssh/id_rsa.pub";
    signByDefault = true;
  };
}
