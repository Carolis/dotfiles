{
  description = "Rails 7.1 dev environment (Rails itself is auto-installed by .envrc)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = fn: nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        fn { pkgs = nixpkgs.legacyPackages.${system}; }
      );
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ruby_3_4
            bundler
            nodejs_22
            postgresql_17
            postgresql_17.pg_config
            sqlite
            libffi
            libyaml
            zlib
            pkg-config
            openssl
          ];
        };
      });
    };
}
