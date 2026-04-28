{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.sessionVariables = {
  LANG = "pt_BR.UTF-8";
  LC_ALL = "pt_BR.UTF-8";
};

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # --- CLI tools ---
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tree
    htop
    curl
    wget
    unzip
  ];

  # --- Git ---
  programs.git = {
    enable = true;
    settings = {
      user.name = "Carolis";
      user.email = "redrumjedi@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  # --- SSH ---
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      identityFile = "~/.ssh/id_ed25519";
      extraOptions = {
        AddKeysToAgent = "yes";
      };
    };
  };

  # --- Direnv (auto-activates nix develop) ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # --- Extra paths (non-Nix tools like Claude CLI) ---
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # --- Zsh ---
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline -20";
      claude-personal = "CLAUDE_CONFIG_DIR=$HOME/.claude-personal CLAUDE_CODE_USE_KEYCHAIN=0 claude";
      claude-work     = "CLAUDE_CONFIG_DIR=$HOME/.claude-work     CLAUDE_CODE_USE_KEYCHAIN=0 claude";
    };
    initExtra = ''
      # Scaffold a new project from a dotfiles template
      # Usage: newproject <template> <name>
      newproject() {
        if [ -z "$1" ] || [ -z "$2" ]; then
          echo "Usage: newproject <template> <name>"
          echo "Available templates:"
          ls ~/dotfiles/templates | grep -v README
          return 1
        fi
        local tmpl="$HOME/dotfiles/templates/$1"
        if [ ! -d "$tmpl" ]; then
          echo "Template '$1' not found in ~/dotfiles/templates/"
          return 1
        fi
        local dest="$HOME/projects/$2"
        mkdir -p "$dest"
        cp -r "$tmpl"/. "$dest"/
        cd "$dest"
        direnv allow
        echo "Project '$2' ready at $dest"
      }
    '';
  };

  # --- Starship prompt ---
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  xdg.configFile."starship.toml".source = ./starship.toml;
}
