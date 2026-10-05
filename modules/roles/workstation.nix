{ config, ... }:
{
  flake.modules.nixos.workstation = {
    imports = with config.flake.modules.nixos; [
      base
      home-manager
      desktop
      development
      network-manager
      ssh-client
    ];
    home-manager.sharedModules = [ config.flake.modules.homeManager.workstation ];
  };
  flake.modules.homeManager.workstation = {
    imports = with config.flake.modules.homeManager; [
      cli
      fish
      desktop
      development
      ai-clients
    ];
  };
}
