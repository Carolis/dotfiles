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

The flake itself lives in `~/dotfiles/templates/<name>/` and is the single source of truth. The project only gets a one-line `.envrc` that points at it, so there's no `flake.nix` in the project to risk committing.

```bash
# Drop a .envrc into the project pointing at the template
cd ~/dev/ruby-3.3.6/core
cp ~/dotfiles/templates/ruby-3.3.6/.envrc .envrc

# Hide .envrc and generated files from git (never commit any of them)
echo -e ".envrc\n.direnv\n.corepack\n.pgdata" >> .git/info/exclude

# Allow direnv (one time)
direnv allow
```

After this, the dev environment activates automatically when you `cd` into the project. To change the dev shell (add packages, bump versions, etc.), edit `~/dotfiles/templates/ruby-3.3.6/flake.nix` and commit it to the dotfiles repo — the project picks it up immediately.

### Entering manually (without direnv)

```bash
cd ~/dev/ruby-3.3.6/core && nix develop ~/dotfiles/templates/ruby-3.3.6 --command zsh
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

## Gotchas

### GEM_HOME leaking between projects

If a project's flake sets `GEM_HOME` in its `shellHook` (e.g. `guides` does this to isolate gems), that variable persists in any shell or VS Code window that was opened while that project was active. When direnv switches to another project, it only exports *diffs* — it won't unset `GEM_HOME` unless the new project explicitly does so.

Symptom: Ruby LSP fails to start in VS Code with a `Gem::MissingSpecVersionError`, picking up gems from a completely different project.

Fix: add explicit unsets to the project's `.envrc`, **not** in the flake's `shellHook`. `use flake` goes through `nix print-dev-env` which skips `shellHook` entirely — only `.envrc` additions take effect for direnv.

```bash
# .envrc
use flake ~/dotfiles/templates/ruby-3.3.6
unset GEM_HOME
unset GEM_PATH
```

The `ruby-3.3.6` template `.envrc` already includes these unsets. If you create a new Rails template whose flake doesn't manage gems, add the same lines to its `.envrc`.

After updating a flake, run `direnv reload` in the project and restart VS Code fully (quit + reopen) so it inherits the clean environment.

### Don't include `pkgs.bundler` alongside a pinned Ruby

If your flake pins Ruby from a separate nixpkgs input (like `rubyPkgs.ruby_3_3`), do **not** also include `pkgs.bundler` from the main nixpkgs. The bundler package carries its own Ruby version in its Nix store path — mixing them causes a `CorruptBundlerInstallError` at runtime because two bundler versions end up on `GEM_PATH`.

Ruby ships with bundler as a default gem, so no explicit bundler package is needed.

## Running multiple Claude Code accounts

`common.nix` defines two aliases for using a personal and a work Claude account side by side:

```
claude-personal  →  CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude
claude-work      →  CLAUDE_CONFIG_DIR=$HOME/.claude-work     claude
```

Each `CLAUDE_CONFIG_DIR` is a fully isolated config dir (credentials, settings, sessions, memory, plugins). `CLAUDE_CODE_USE_KEYCHAIN=0` is set on macOS to keep credentials in the config dir instead of the shared system Keychain — without it, both accounts would fight over one Keychain entry.

### First-time setup on a new machine

```bash
mkdir -p ~/.claude-personal ~/.claude-work
# optional: seed each dir with your existing ~/.claude state (memories, sessions)
cp -R ~/.claude/. ~/.claude-personal/
cp -R ~/.claude/. ~/.claude-work/

claude-personal   # then /login with personal account
claude-work       # then /login with work account
```

The two can run simultaneously in separate terminals — they share no state.

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
