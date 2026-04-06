{
  description = "ruby-3.3.6 Core dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pinned to the exact nixpkgs commit that ships Ruby 3.3.6
    nixpkgs-ruby336.url = "github:NixOS/nixpkgs/c5dd43934613ae0f8ff37c59f61c507c2e8f980d";
  };

  outputs = { nixpkgs, nixpkgs-ruby336, ... }:
    let
      forAllSystems = fn: nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        fn {
          pkgs = nixpkgs.legacyPackages.${system};
          rubyPkgs = nixpkgs-ruby336.legacyPackages.${system};
        }
      );
    in
    {
      devShells = forAllSystems ({ pkgs, rubyPkgs }: {
        default = pkgs.mkShell {
          packages = [
            rubyPkgs.ruby_3_3
            pkgs.bundler
            pkgs.nodejs_22
            pkgs.corepack
            pkgs.postgresql_16
            pkgs.libffi
            pkgs.libyaml
            pkgs.zlib
            pkgs.pkg-config
            pkgs.openssl
          ];

          shellHook = ''
            export PGDATA="$PWD/.pgdata"
            export LANG=en_US.UTF-8
            export COREPACK_INSTALL_DIR="$PWD/.corepack"
            mkdir -p "$COREPACK_INSTALL_DIR"
            corepack enable --install-directory "$COREPACK_INSTALL_DIR" 2>/dev/null || true
            export PATH="$COREPACK_INSTALL_DIR:$PATH"

            if [ ! -d "$PGDATA" ]; then
              echo "Initializing PostgreSQL database..."
              initdb -D "$PGDATA" --no-locale --encoding=UTF8
            fi
            if ! pg_ctl -D "$PGDATA" status > /dev/null 2>&1; then
              pg_ctl -D "$PGDATA" -l "$PGDATA/postgresql.log" start
            fi
          '';
        };
      });
    };
}
