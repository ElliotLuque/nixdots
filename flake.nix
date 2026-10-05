{
  description = "nixos configuration";

  inputs = {
    # core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    # desktop
    hyprland.url = "github:hyprwm/Hyprland/34eb03bd8da01024596c367fba66485a8c9b8ca7";

    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";
    catppuccin.url = "github:catppuccin/nix";

    caelestia-shell = {
      url = "github:caelestia-dots/shell/6d3e6a96492b0e9c668464875ac34150113ede5f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # applications
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:ElliotLuque/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.9.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:earendil-works/pi/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agent skills
    agent-skills.url = "path:./agent-skills";
  };

  outputs =
    inputs@{
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "elliot";

      pkgs = nixpkgs.legacyPackages.${system};

      commonModules = [
        inputs.home-manager.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.catppuccin.nixosModules.catppuccin
      ];

      mkHost =
        { host }:
        nixpkgs.lib.nixosSystem {
          modules = commonModules ++ [
            (./hosts + "/${host}")
          ];

          specialArgs = inputs // {
            inherit
              inputs
              username
              host
              ;
          };
        };
    in
    {
      devShells.${system}.default = import ./shells/dotnet_shell.nix {
        inherit pkgs;
      };

      nixosConfigurations = {
        nixos-pc = mkHost {
          host = "nixos-pc";
        };

        nixos-laptop = mkHost {
          host = "nixos-laptop";
        };
      };
    };
}
