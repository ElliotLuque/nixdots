{
  pkgs,
  inputs,
  host,
  username,
  catppuccin,
  spicetify-nix,
  nixvim,
  ...
}:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit
        inputs
        host
        username
        catppuccin
        spicetify-nix
        nixvim
        ;
    };
    users.${username} = {
      imports = [
        ../../modules/home-manager
        catppuccin.homeModules.catppuccin
        inputs.spicetify-nix.homeManagerModules.default
        inputs.hyprpanel.homeManagerModules.hyprpanel
        inputs.sops-nix.homeManagerModules.sops
      ];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "24.11";
        sessionVariables = {
          EDITOR = "nvim";
          PF_INFO = "ascii title os cpu uptime pkgs memory shell";
          DOTNET_ROOT = "${pkgs.dotnetCorePackages.dotnet_8.sdk}/bin";
        };
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
      "bluetooth"
    ];
  };
  nix.settings.allowed-users = [ "${username}" ];
}
