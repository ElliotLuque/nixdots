#################################
###  NixOS Desktop PC Config  ###
#################################

{ inputs, ... }:

{
  imports = [
    ../../modules/home-manager/hyprland/nixos-pc.nix
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../modules/nixos/nvidia.nix # This is a NVIDIA PC so we'll import it
  ];

  hardware.nvidia.open = true;

  powerManagement.cpuFreqGovernor = "performance";
}
