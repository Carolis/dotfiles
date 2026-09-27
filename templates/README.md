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

> **Gems are isolated per project.** The rails template sets `GEM_HOME` to
> `$PWD/.gems`, so gems you install in one project won't leak into another.
> Each project can have its own Rails version. The `.gems/` directory is
> already in the template's `.gitignore`.

### New Rails 7.1 project (Rails pre-installed)

```bash
newproject rails-7.1 myapp
rails new .
bundle add minitest --version "~> 5.25" --group test
```

- `rails new .` asks whether to overwrite `.gitignore` — answer `Y`, then
  re-add the Nix lines: `cat ~/dotfiles/templates/rails-7.1/.gitignore >> .gitignore`
- The minitest pin is required: Rails 7.1's test runner crashes with
  minitest 6 (`wrong number of arguments (given 3, expected 1..2)`).
- The auto-install only runs while there's no `Gemfile`. After `rails new`,
  `Gemfile.lock` decides the Rails version. To bootstrap a different version,
  change `RAILS_VERSION` in the project's `.envrc`.

### New Rails 7.1 + React + TypeScript project

```bash
newproject rails-7.1-react myapp
rails-react-init            # extra args go to `rails new`, e.g. --database=postgresql
bin/dev                     # http://localhost:3000
```

`rails-react-init` (in `rails-7.1-react/bin/`, put on PATH by the `.envrc`)
runs `rails new . --javascript=esbuild` and then does all of the above
fix-ups for you, plus:

- adds `react`, `react-dom`, `typescript`, `@types/react*` and a `tsconfig.json`
- `app/javascript/components/App.tsx` — your first component
- `app/javascript/react/index.tsx` — mounts `<App />` into `#react-root` on `turbo:load`
- `HomeController#index` as the root page, with a test for the mount point
- `yarn typecheck` runs `tsc --noEmit` (esbuild strips types, it doesn't check them)
- `Procfile.dev` uses `--watch=forever`; plain `--watch` makes esbuild exit
  when stdin closes, and foreman then stops the Rails server too

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

| Template      | What's in it                              |
|--------------|-------------------------------------------|
| `rails`       | Ruby 3.4, Node 22, PostgreSQL 17, bundler |
| `rails-7.1`   | Same as `rails` + sqlite, and `.envrc` auto-installs Rails 7.1 into `.gems` |
| `rails-7.1-react` | `rails-7.1` + yarn, and a `rails-react-init` command that sets up React + TypeScript via esbuild |
| `ruby-3.3.6`  | Ruby 3.3.6 (pinned), Node 22, PostgreSQL 16, corepack |
| `macos-xcode` | Node 22, GraphicsMagick, ImageMagick, xcbeautify peripheral tooling for native macOS/Xcode apps (the app itself builds via Xcode, not Nix) |
| `node-pnpm`   | Node 22, pnpm for generic JS/TS projects with no other runtime deps |

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
nixpkgs commit (like the `ruby-3.3.6` template does):

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # Pinned to a commit that ships Ruby X.Y.Z
  nixpkgs-pinned.url = "github:NixOS/nixpkgs/<commit-hash>";
};
```

Find the right commit on https://www.nixhub.io or by searching the nixpkgs
repo history.

## Using templates with existing repos

Drop a `.envrc` into the repo that points at the template. The template's
`flake.nix` stays at `~/dotfiles/templates/<name>/` — don't copy it into the
project, that's the whole point of the single-source-of-truth setup.

```bash
cp ~/dotfiles/templates/rails/.envrc .envrc
direnv allow
```

If the repo doesn't track Nix files, hide them from git locally so they don't
block operations like `pull --rebase`:

```bash
echo -e '.envrc\n.direnv\n.gems\n.corepack\n.pgdata' >> .git/info/exclude
```

If you accidentally `git add .envrc`, remove it from the index without
deleting it:

```bash
git rm --cached .envrc
```

## PostgreSQL

Templates that include PostgreSQL (rails, ruby-3.3.6) set `$PGDATA` to
`$PWD/.pgdata` so each project gets its own isolated data directory. The
database is **not** auto-started — you need to initialize and start it yourself
the first time:

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
3. Add a `.envrc` whose first line is `use flake ~/dotfiles/templates/<name>`
   (the absolute path matters — projects only get the `.envrc`, the flake stays
   in the template dir as the single source of truth)
4. Optionally add a `.gitignore` for Nix artifacts (`.direnv/`, `.gems/`, etc.)
5. Per-project env vars (`GEM_HOME="$PWD/.gems"`, `PGDATA="$PWD/.pgdata"`,
   etc.) belong in the **template's `.envrc`**, NOT in the flake's `shellHook`.
   `use flake` goes through `nix print-dev-env`, which skips `shellHook`
   entirely — anything you put there will silently not run. See the "GEM_HOME
   leaking between projects" gotcha in the parent `dotfiles/README.md` for
   the full story.
