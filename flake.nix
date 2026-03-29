{
  description = "Carolis dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      systems = {
        mac = {
          system = "aarch64-darwin";
          username = "carolis";
          homeDirectory = "/Users/carolis";
        };
        wsl = {
          system = "x86_64-linux";
          username = "carolis";
          homeDirectory = "/home/carolis";
        };
      };

      mkHome = name: { system, username, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home/common.nix
            ./home/${name}.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      homeConfigurations = builtins.mapAttrs mkHome systems;
    };
}
