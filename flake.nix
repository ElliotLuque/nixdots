{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

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
      url = "github:caelestia-dots/shell";
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
              ;
          };
        };

        nixos-laptop = nixpkgs.lib.nixosSystem {
          modules = [
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            inputs.spicetify-nix.nixosModules.default
            catppuccin.nixosModules.catppuccin
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
              ;
          };
        };
      };
    };
}
