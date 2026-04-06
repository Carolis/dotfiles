# Project Templates

Nix-based dev environment templates. Copy one into a new directory and you get
a reproducible shell with everything you need — no global installs.

## Quick start

The `newproject` shell function (defined in your zsh config) does the copy for you:

```bash
# Scaffold a new Rails app
newproject rails myapp

# Scaffold from the ruby-3.3.6 template
newproject ruby-3.3.6 some-feature
```

This creates `~/projects/<name>/`, copies the template files, and `cd`s you in.
Because direnv is configured, the Nix shell activates automatically.

### First time in a new Rails project

```bash
newproject rails myapp
# shell activates automatically via direnv
gem install rails
rails new . --database=postgresql
```

### One-off scratch shell (no project, no files)

If you just want a quick throwaway shell to test something:

```bash
# Jump into a Rails-ready shell without creating any files
nix develop ~/dotfiles/templates/rails

# Or a bare Ruby shell
nix develop ~/dotfiles/templates/rails

# Run a single command and exit
nix develop ~/dotfiles/templates/rails --command ruby -e "puts RUBY_VERSION"
```

## Available templates

| Template     | What's in it                              |
|-------------|-------------------------------------------|
| `rails`      | Ruby 3.4, Node 22, PostgreSQL 17, bundler |
| `ruby-3.3.6` | Ruby 3.3.6 (pinned), Node 22, PostgreSQL 16, corepack |

## How Nix package versions work

Templates pull packages from **nixpkgs-unstable**, which tracks the latest
packaged versions. The version you get depends on when you last updated the
flake lock file.

### Checking available versions

```bash
# See what version a package resolves to right now
nix eval nixpkgs#ruby_3_4.version

# See all Ruby packages available
nix search nixpkgs "ruby_3"
```

### Updating to latest versions

```bash
cd ~/projects/myapp

# Update all flake inputs (pulls latest nixpkgs-unstable)
nix flake update

# Or update only nixpkgs
nix flake update nixpkgs
```

This rewrites `flake.lock`, pinning to the latest commit of nixpkgs-unstable.
Every collaborator (or your future self) running `nix develop` against that lock
gets the exact same versions.

### Pinning a specific version

If nixpkgs-unstable doesn't have the version you need, pin to a specific
nixpkgs commit (like the ruby-3.3.6 template does for Ruby 3.3.6):

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # Pinned to a commit that ships Ruby X.Y.Z
  nixpkgs-pinned.url = "github:NixOS/nixpkgs/<commit-hash>";
};
```

Find the right commit on https://www.nixhub.io or by searching the nixpkgs
repo history.

## Using templates with existing repos (e.g. ruby-3.3.6)

When you copy nix files into an existing repo that doesn't track them (like
`ruby-3.3.6/core`), you need to tell git to ignore them locally so they don't
block git operations like `pull --rebase`.

After copying the template files into the repo, add them to `.git/info/exclude`:

```bash
echo -e '.envrc\nflake.nix\nflake.lock\n.direnv\n.corepack\n.pgdata' >> .git/info/exclude
```

If you accidentally `git add` these files, remove them from the index without
deleting them:

```bash
git rm --cached .envrc flake.nix
```

## PostgreSQL

Templates that include PostgreSQL (rails, ruby-3.3.6) set `$PGDATA` to
`$PWD/.pgdata` in their shell hook. The database is **not** auto-started — you
need to initialize and start it yourself the first time:

```bash
# First time only — initialize the data directory
initdb -D "$PGDATA" --no-locale --encoding=UTF8

# Start the server (run this each time you enter the shell)
pg_ctl -D "$PGDATA" -l "$PGDATA/postgresql.log" start

# Stop it when you're done
pg_ctl -D "$PGDATA" stop
```

If you see `ActiveRecord::ConnectionNotEstablished` or "connection refused on
port 5432", PostgreSQL isn't running — start it with the `pg_ctl` command above.

## Creating a new template

1. Create a directory under `~/dotfiles/templates/<name>/`
2. Add a `flake.nix` with a `devShells.default` output
3. Add a `.envrc` containing `use flake`
4. Optionally add a `.gitignore` for Nix artifacts
