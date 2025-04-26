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
  ];

  powerManagement.cpuFreqGovernor = "performance";
}
