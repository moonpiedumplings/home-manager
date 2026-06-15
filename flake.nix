{
  # Must activate flake with --impure!!!
  description = "Home Manager configuration of moonpie";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com"  "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-kubectl.url = "github:nixos/nixpkgs/e6f23dc08d3624daab7094b701aa3954923c6bbb";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      # inputs.nixpkgs.follows = "nixpkgs";
      };
    
    # llm agents and stuff
    hermes = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # llama-cpp flake:
     llamacpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
            nixgl,
            nixpkgs, pkgs-kubectl, hermes, llm-agents,
            home-manager, ... }:
    let
      system = "${builtins.currentSystem}";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
        config.allowUnfree = true;
        };
      # pkgs-kbctl = pkgs-kubectl.legacyPackages.${system};

    in {
      homeConfigurations."${builtins.getEnv "USER"}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
           inherit inputs system hermes llm-agents nixgl;
          pkgs-kbctl = import pkgs-kubectl { inherit system; };
        };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix

      };
    };
}
