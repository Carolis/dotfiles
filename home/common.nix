{ pkgs, ... }:

{
  home.stateVersion = "25.05";

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
    };
  };

  # --- Starship prompt ---
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
      };
      git_branch.symbol = " ";
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
    };
  };
}
