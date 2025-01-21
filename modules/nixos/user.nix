{ pkgs, lib, inputs, username, catppuccin, ... }:
{
  home-manager = {
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports = [ ../../modules/home-manager ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "24.11";
      home.sessionVariables = {
        EDITOR = "nvim";
      };
      home.file = { };
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

