{ config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.modules.nixos.elliot = { pkgs, ... }: {
    imports = [ modules.nixos.home-manager ];
    programs.fish.enable = true;
    # Writable checkout used by `nh os` / `system-rebuild` when no flake is given.
    programs.nh.flake = "/home/elliot/dotfiles/nixdots";
    users.users.elliot = {
      isNormalUser = true;
      description = "elliot";
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
    };
    home-manager.users.elliot.imports = [ modules.homeManager.elliot ];
  };

  # Personal workstation permissions and autologin are not OS defaults.
  flake.modules.nixos.elliot-workstation = { pkgs, ... }: {
    imports = [ modules.nixos.elliot ];
    users.users.elliot.extraGroups = [
      "networkmanager"
      "audio"
      "bluetooth"
      "docker"
    ];
    services.greetd.settings.initial_session = {
      # Match the desktop login path: log to the journal, not the boot console.
      command = "${pkgs.systemd}/bin/systemd-cat --identifier=hyprland start-hyprland";
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
