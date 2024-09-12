{
  description = "Home Manager configuration of moonpie";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-kubectl.url = "github:nixos/nixpkgs/7a339d87931bba829f68e94621536cad9132971a";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      # inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = {
            nixgl,
            nixpkgs, pkgs-kubectl,
            home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
        };
      # pkgs-kbctl = pkgs-kubectl.legacyPackages.${system};

    in {
      homeConfigurations."moonpie" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          pkgs-kbctl = import pkgs-kubectl {inherit system;};
        };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix

      };
    };
}
