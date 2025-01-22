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
  };

  outputs = { nixpkgs, self, catppuccin, ... }@inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      username = "elliot";
    in
    {
      nixosConfigurations = {
        nixos-pc = nixpkgs.lib.nixosSystem {
	  modules = [ 
	    inputs.home-manager.nixosModules.default
	    inputs.stylix.nixosModules.stylix
	    catppuccin.nixosModules.catppuccin
	    ./hosts/nixos-pc 
	  ];
  	  specialArgs = { 
	    host = "nixos-pc";
	    inherit self inputs username catppuccin; 
	  };
        };
      };

	#      homeConfigurations = {
	#        "${username}@nixos-pc" = home-manager.lib.homeManagerConfiguration {
	#          pkgs = nixpkgs.legacyPackages.${system};
	#   extraSpecialArgs = { inherit inputs; };
	#   modules = [ 
	#     catppuccin.homeManagerModules.catppuccin
	#     {
	#       imports = [ ../../modules/home-manager ];
	#       nixpkgs.config.allowUnfree = true;
	#       home.username = "${username}";
	#       home.homeDirectory = "/home/${username}";
	#       home.stateVersion = "24.11";
	#       home.file = { };
	#       home.sessionVariables = {
	#         EDITOR = "nvim";
	#       };
	#       programs.home-manager.enable = true;
	#     }
	#   ];
	# };
	#      };
    };
}
