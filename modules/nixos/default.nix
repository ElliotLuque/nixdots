{ self, pkgs, lib, config, inputs, username, host, ... }:
{
  imports = [
    ./system.nix
    ./boot.nix
    ./user.nix
    ./locale.nix
    ./services.nix
    ./pipewire.nix
    ./programs.nix
    ./networking.nix
    ./graphics.nix
  ];
}
