{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      self,
      catppuccin,
      spicetify-nix,
      nixvim,
      anyrun,
      ...
    }@inputs:
    let
      username = "elliot";
    in
    {
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
            inherit
              self
              inputs
              username
              catppuccin
              spicetify-nix
              nixvim
              anyrun
              ;
          };
        };
      };
    };
}
