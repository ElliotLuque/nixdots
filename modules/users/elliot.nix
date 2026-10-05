{ config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.modules.nixos.elliot = { pkgs, ... }: {
    imports = [ modules.nixos.home-manager ];
    programs.fish.enable = true;
    users.users.elliot = {
      isNormalUser = true;
      description = "elliot";
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
    };
    home-manager.users.elliot.imports = [ modules.homeManager.elliot ];
  };

  # Personal workstation permissions and autologin are not OS defaults.
  flake.modules.nixos.elliot-workstation = {
    imports = [ modules.nixos.elliot ];
    users.users.elliot.extraGroups = [
      "networkmanager"
      "audio"
      "bluetooth"
      "docker"
    ];
    services.greetd.settings.initial_session = {
      command = "start-hyprland";
      user = "elliot";
    };
  };

  flake.modules.homeManager.elliot = {
    home = {
      username = "elliot";
      homeDirectory = "/home/elliot";
      stateVersion = "24.11";
      sessionPath = [ "$HOME/.local/bin" ];
    };
    programs.home-manager.enable = true;
    programs.git.settings.user = {
      name = "ElliotLuque";
      email = "git@elliotluque.com";
    };
  };
}
