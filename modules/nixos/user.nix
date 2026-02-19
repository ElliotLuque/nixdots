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
        inputs.sops-nix.homeManagerModules.sops
        inputs.caelestia-shell.homeManagerModules.default
      ];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "24.11";
        sessionVariables = {
          EDITOR = "nvim";
          PF_INFO = "ascii title os cpu uptime pkgs memory shell";
          DOTNET_ROOT = "${pkgs.dotnetCorePackages.dotnet_8.sdk}/bin";
          JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
          JDK_JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
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
      "docker"
    ];
  };
  nix.settings.allowed-users = [ "${username}" ];
}
