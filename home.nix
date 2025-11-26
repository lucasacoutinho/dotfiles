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
      ls = "eza --color=auto";
      ll = "eza -la --color=auto";
      lt = "eza --tree --color=auto";
      cat = "bat";
      grep = "rg";
      find = "fd";
      cd = "z";
    };

    sessionVariables = {
      # eza colors - bright blue directories for dark terminals
      EZA_COLORS = "di=1;34:ln=1;36:ex=1;32";
    };

    initExtra = ''
      # Source Nix profile (must be first to add ~/.nix-profile/bin to PATH)
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi

      # Cargo
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

      # Initialize zoxide
      eval "$(zoxide init zsh)"

      # Better history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_DUPS
    '';
  };

  # Starship prompt - bash-like style
  programs.starship = {
    enable = true;
    settings = {
      format = "$username$hostname$directory$git_branch$git_status$character";
      add_newline = false;

      username = {
        show_always = true;
        style_user = "bright-green bold";
        format = "[$user]($style)@";
      };

      hostname = {
        ssh_only = false;
        style = "bright-green bold";
        format = "[$hostname]($style):";
      };

      directory = {
        style = "bright-blue bold";
        truncation_length = 0;
        truncate_to_repo = false;
      };

      git_branch = {
        style = "bright-yellow";
        format = " [$branch]($style)";
      };

      git_status = {
        style = "bright-yellow";
        format = "[$all_status$ahead_behind]($style)";
      };

      character = {
        success_symbol = "[\\$](white)";
        error_symbol = "[\\$](bright-red)";
        format = " $symbol ";
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
