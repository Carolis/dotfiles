# dotfiles

Nix + Home Manager dotfiles. Works on macOS and WSL.

## Structure

```
flake.nix              # Entry point — defines mac/wsl configurations
home/
  common.nix           # Shared config: git, ssh, zsh, starship, direnv, CLI tools
  mac.nix              # macOS-specific (SSH keychain)
  wsl.nix              # WSL-specific (placeholder)
templates/
  ruby-3.3.6/
    flake.nix           # Dev shell for the ruby-3.3.6 core project
    .envrc              # Direnv auto-activation file
```

## Initial setup on a new machine

```bash
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
git clone git@github.com:<user>/dotfiles.git ~/dotfiles

# 3. Apply Home Manager
cd ~/dotfiles && nix run home-manager -- switch --flake .#mac   # macOS
cd ~/dotfiles && nix run home-manager -- switch --flake .#wsl   # WSL
```

## After changing home config

Edit files in `home/`, then re-apply:

```bash
cd ~/dotfiles && nix run home-manager -- switch --flake .#mac
```

## Per-project dev shells

Each project gets a `flake.nix` that declares its dependencies (Ruby, Node, Postgres, etc.).

### Using an existing template

```bash
# Copy flake + envrc into the project
cp ~/dotfiles/templates/ruby-3.3.6/flake.nix ~/dev/ruby-3.3.6/core/flake.nix
cp ~/dotfiles/templates/ruby-3.3.6/.envrc ~/dev/ruby-3.3.6/core/.envrc

# Track files for Nix but hide from git status
cd ~/dev/ruby-3.3.6/core
git add -f flake.nix .envrc
git update-index --assume-unchanged flake.nix
git update-index --assume-unchanged .envrc

# Exclude generated files
echo -e "flake.lock\n.direnv\n.corepack\n.pgdata" >> .git/info/exclude

# Allow direnv (one time)
direnv allow
```

After this, the dev environment activates automatically when you `cd` into the project.

### Entering manually (without direnv)

```bash
cd ~/dev/ruby-3.3.6/core && nix develop --command zsh
```

### Creating a flake for a new project

Create a `flake.nix` in the project root. Minimal example:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = fn: nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        fn nixpkgs.legacyPackages.${system}
      );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22
            # add more packages here
          ];
        };
      });
    };
}
```

Add a `.envrc` with `use flake` for auto-activation.

### After changing a project flake

If using direnv, it picks up changes automatically. If using `nix develop`, exit and re-enter.

## Updating packages

```bash
cd ~/dotfiles && nix flake update   # updates home manager + nixpkgs
```

For project flakes, run `nix flake update` in the project directory.

## Maintenance

```bash
nix-collect-garbage -d   # free disk space from old generations
```

## Pinning exact package versions

If a project needs an exact version not in current nixpkgs (e.g., Ruby 3.3.6), pin a second nixpkgs input to a specific commit. See `templates/ruby-3.3.6/flake.nix` for an example. Find commits for specific versions at https://lazamar.co.uk/nix-versions/.
