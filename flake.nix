{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:ElliotLuque/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell/6d3e6a96492b0e9c668464875ac34150113ede5f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      catppuccin,
      spicetify-nix,
      nixvim,
      sops-nix,
      ...
    }@inputs:
    let
      username = "elliot";
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in
    {
      devShells."x86_64-linux".default = import ./shells/dotnet_shell.nix { inherit pkgs; };

      nixosConfigurations = {
        nixos-pc = nixpkgs.lib.nixosSystem {
          modules = [
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            inputs.spicetify-nix.nixosModules.default
            catppuccin.nixosModules.catppuccin
            sops-nix.nixosModules.sops
            ./hosts/nixos-pc
          ];
          specialArgs = {
            host = "nixos-pc";
            hyprlandLowPerformance = false;
            inherit
              self
              inputs
              username
              catppuccin
              spicetify-nix
              nixvim
              sops-nix
              ;
          };
        };

        nixos-laptop = nixpkgs.lib.nixosSystem {
          modules = [
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            inputs.spicetify-nix.nixosModules.default
            catppuccin.nixosModules.catppuccin
            sops-nix.nixosModules.sops
            ./hosts/nixos-laptop
          ];
          specialArgs = {
            host = "nixos-laptop";
            hyprlandLowPerformance = true;
            inherit
              self
              inputs
              username
              catppuccin
              spicetify-nix
              nixvim
              sops-nix
              ;
          };
        };
      };
    };
}
