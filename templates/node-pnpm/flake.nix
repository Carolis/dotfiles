{
  description = "Generic Node.js + pnpm dev environment";

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
            nodejs_22
            pnpm
          ];
        };
      });
    };
}
