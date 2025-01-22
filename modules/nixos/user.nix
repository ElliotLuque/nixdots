{ pkgs, inputs, host, username, catppuccin, ... }:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs host username catppuccin; };
    users.${username} = {
      imports = [ 
        ../../modules/home-manager 
	catppuccin.homeManagerModules.catppuccin
      ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "24.11";
      home.sessionVariables = {
        EDITOR = "nvim";
	PF_INFO = "ascii title os cpu uptime pkgs memory shell";
      };
      programs.home-manager.enable = true;
    };
  };
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    shell = pkgs.fish;
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "audio"
    ];
  };
  nix.settings.allowed-users = [ "${username}" ];
}

