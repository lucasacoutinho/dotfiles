{ config, lib, pkgs, ... }:

let
  local = import ./hosts/default.nix;
  gitConfig = local.git or { };
  kubeconfig = local.kubeconfig or null;
  dotfilesDir = local.dotfilesDir or "${local.homeDirectory}/personal/dotfiles";
  hmSwitchCommand = "home-manager switch --flake path:${dotfilesDir}#default";
in
{
  home.username = local.username;
  home.homeDirectory = local.homeDirectory;
  home.stateVersion = "25.05";
  home.sessionPath = [
    "${local.homeDirectory}/.nix-profile/bin"
    "${local.homeDirectory}/.local/bin"
    "${local.homeDirectory}/bin"
    "${local.homeDirectory}/.cargo/bin"
    "/snap/bin"
  ];
  home.sessionVariables = {
    EZA_COLORS = "di=1;34:ln=1;36:ex=1;32";
    EDITOR = "nano";
    VISUAL = "nano";
    NVM_DIR = "${local.homeDirectory}/.nvm";
  } // lib.optionalAttrs (kubeconfig != null && kubeconfig != "") {
    KUBECONFIG = kubeconfig;
  };

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

    # Data processing
    yq-go        # YAML processor (like jq for YAML)
    qsv          # CSV toolkit (maintained fork of xsv)

    # Code analysis
    tokei        # Code statistics
    tree-sitter  # Incremental parsing
    universal-ctags  # Code navigation tags

    # Infrastructure / DevOps
    k9s          # Kubernetes TUI
    talosctl     # Talos Linux management
    ansible      # Configuration management
    ansible-lint # Ansible linting
    opam         # OCaml package manager
    bun
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

    history = {
      size = 50000;
      save = 50000;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ls = "eza --color=auto";
      ll = "eza -la --color=auto";
      lt = "eza --tree --color=auto";
      hms = hmSwitchCommand;
    };

    initContent = ''
      # NVM - Lazy loading for faster shell startup
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Add node to PATH without loading nvm (if default version exists)
        if [ -d "$NVM_DIR/versions/node" ]; then
          node_bin="$(command ls -1d "$NVM_DIR"/versions/node/*/bin 2>/dev/null | tail -1)"
          if [ -n "$node_bin" ]; then
            case ":$PATH:" in
              *":$node_bin:"*) ;;
              *) export PATH="$node_bin:$PATH" ;;
            esac
          fi
          unset node_bin
        fi

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

      # Only load fzf widgets in real interactive TTY shells.
      if [[ -o interactive && -t 0 && -t 1 ]]; then
        source <(${pkgs.fzf}/bin/fzf --zsh)
      fi

      # envman
      [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

      # --- Helper functions: nix-search, nix-add, nix-remove ---

      nix-search() {
        if [ -z "''${1}" ]; then
          echo "Usage: nix-search <package-name>"
          return 1
        fi
        nix search nixpkgs "''${1}"
      }

      nix-add() {
        if [ -z "''${1}" ]; then
          echo "Usage: nix-add <package-name>"
          return 1
        fi
        local pkg="''${1}"
        local home_nix="${dotfilesDir}/home.nix"

        if grep -q "^    $pkg " "$home_nix" || grep -q "^    $pkg$" "$home_nix"; then
          echo "$pkg is already in home.nix"
          return 1
        fi

        # Insert before the closing bracket of home.packages
        sed -i "/^  \];$/i\\    $pkg" "$home_nix"
        echo "Added $pkg to home.nix"

        echo "Running home-manager switch..."
        ${hmSwitchCommand}
        if [ $? -eq 0 ]; then
          echo ""
          read -r "reply?Auto-commit this change? [y/N] "
          if [[ "$reply" =~ ^[Yy]$ ]]; then
            git -C "${dotfilesDir}" add home.nix
            git -C "${dotfilesDir}" commit -m "nix-add: $pkg"
          fi
        fi
      }

      nix-remove() {
        if [ -z "''${1}" ]; then
          echo "Usage: nix-remove <package-name>"
          return 1
        fi
        local pkg="''${1}"
        local home_nix="${dotfilesDir}/home.nix"

        if ! grep -q "^    $pkg" "$home_nix"; then
          echo "$pkg not found in home.nix"
          return 1
        fi

        sed -i "/^    $pkg/d" "$home_nix"
        echo "Removed $pkg from home.nix"

        echo "Running home-manager switch..."
        ${hmSwitchCommand}
        if [ $? -eq 0 ]; then
          echo ""
          read -r "reply?Auto-commit this change? [y/N] "
          if [[ "$reply" =~ ^[Yy]$ ]]; then
            git -C "${dotfilesDir}" add home.nix
            git -C "${dotfilesDir}" commit -m "nix-remove: $pkg"
          fi
        fi
      }

      # Initialize zoxide after the rest of the shell setup.
      eval "$(zoxide init zsh)"
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

  # Git
  programs.git = {
    enable = true;
    signing = lib.optionalAttrs (gitConfig ? signingKey) {
      key = gitConfig.signingKey;
      signByDefault = gitConfig.signByDefault or true;
    };
    settings = {
      gpg.format = "ssh";
      init.defaultBranch = "main";
    } // lib.optionalAttrs (gitConfig ? name) {
      user.name = gitConfig.name;
    } // lib.optionalAttrs (gitConfig ? email) {
      user.email = gitConfig.email;
    };
    includes = [
      { path = "~/.gitconfig.local"; }
    ];
  };

  # Git diff viewer
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Bash (minimal, for scripts/fallback)
  programs.bash = {
    enable = true;
    historySize = 50000;
    historyFileSize = 50000;
    historyControl = [ "ignoreboth" ];
    shellOptions = [ "histappend" "checkwinsize" ];
    initExtra = ''
      [[ -e "$HOME/lib/oracle-cli/lib/python3.12/site-packages/oci_cli/bin/oci_autocomplete.sh" ]] && \
        source "$HOME/lib/oracle-cli/lib/python3.12/site-packages/oci_cli/bin/oci_autocomplete.sh"
      export PATH="$HOME/bin:$PATH"
    '';
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
