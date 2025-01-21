{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { nixpkgs, self, ... }@inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      username = "elliot";
    in
    {
      nixosConfigurations = {
        nixos-pc = nixpkgs.lib.nixosSystem {
	  modules = [ 
	    ./hosts/nixos-pc 
	    inputs.home-manager.nixosModules.default
	  ];
  	  specialArgs = { 
	    host = "nixos-pc";
	    inherit inputs; 
	  };
        };
      };
    };
}
