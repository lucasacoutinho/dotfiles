{ config, pkgs, ... }:

let
  username = builtins.getEnv "USER";
  homeDir = builtins.getEnv "HOME";
in
{
  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "25.05";

  # Packages
  home.packages = with pkgs; [
    # Modern CLI tools
    ripgrep      # Fast grep
    fd           # Fast find
    bat          # Better cat
    eza          # Modern ls
    fzf          # Fuzzy finder
    zoxide       # Smart cd
    jq           # JSON processor
    htop         # Process viewer
    tree         # Directory tree
    delta        # Better git diff
  ];

  # Shell - Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      lt = "eza --tree";
      cat = "bat";
      grep = "rg";
      find = "fd";
      cd = "z";
    };

    initExtra = ''
      # Initialize zoxide
      eval "$(zoxide init zsh)"

      # FZF keybindings
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # Better history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_DUPS
    '';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";

      directory = {
        style = "blue bold";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "purple";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "red";
        format = "[$all_status$ahead_behind]($style) ";
      };

      cmd_duration = {
        min_time = 2000;
        style = "yellow";
        format = "[$duration]($style) ";
      };

      character = {
        success_symbol = "[>](green)";
        error_symbol = "[>](red)";
      };
    };
  };

  # Git config
  programs.git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
