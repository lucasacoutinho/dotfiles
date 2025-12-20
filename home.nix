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
  ];

  # Shell - Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    completionInit = ''
      # Cache compinit - only regenerate once per day
      autoload -Uz compinit
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
    '';

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
      EZA_COLORS = "di=1;34:ln=1;36:ex=1;32";
    };

    initContent = ''
      # Source Nix profile (must be first to add ~/.nix-profile/bin to PATH)
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi

      # Cargo
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

      # Load user-defined PATH extensions if file exists
      [ -f "$HOME/.zsh_extra_path" ] && source "$HOME/.zsh_extra_path"

      # NVM - Lazy loading for faster shell startup
      export NVM_DIR="$HOME/.nvm"
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Add node to PATH without loading nvm (if default version exists)
        [ -d "$NVM_DIR/versions/node" ] && PATH="$NVM_DIR/versions/node/$(ls -1 $NVM_DIR/versions/node | tail -1)/bin:$PATH"

        # Lazy load nvm when first called
        nvm() {
          unset -f nvm node npm npx
          source "$NVM_DIR/nvm.sh"
          nvm "$@"
        }
        node() {
          unset -f nvm node npm npx
          source "$NVM_DIR/nvm.sh"
          node "$@"
        }
        npm() {
          unset -f nvm node npm npx
          source "$NVM_DIR/nvm.sh"
          npm "$@"
        }
        npx() {
          unset -f nvm node npm npx
          source "$NVM_DIR/nvm.sh"
          npx "$@"
        }
      fi

      # Initialize zoxide
      eval "$(zoxide init zsh)"

      # Better history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_DUPS

      # Custom PATH additions
      export PATH="$HOME/.local/bin:$PATH"
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
  programs.delta = {
    enable = true;
    enableGitIntegration = true;  # required now
    options = {
      navigate = true;
      side-by-side = true;
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
