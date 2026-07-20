{
  description = "Peripheral tooling for native macOS / Xcode apps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = fn: nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (system:
        fn { pkgs = nixpkgs.legacyPackages.${system}; }
      );
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22      # `npx create-dmg` in scripts/build-dmg.sh
            graphicsmagick # DMG icon compositing
            imagemagick    # DMG icon compositing
            xcbeautify     # prettify `xcodebuild` output
          ];

          shellHook = ''
            if ! command -v xcodebuild >/dev/null 2>&1; then
              echo "WARNING: full Xcode not found — install it from the App Store to build the app."
            fi
          '';
        };
      });
    };
}
