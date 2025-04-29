#################################
###  NixOS Laptop PC Config  ###
#################################

{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../modules/nixos/nvidia.nix # This is a NVIDIA PC so we'll import it
    ../../modules/home-manager/hyprland/nixos-laptop.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";
}
