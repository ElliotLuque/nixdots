#################################
###  NixOS Desktop PC Config  ###
#################################

{ config, lib, inputs, pkgs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos
    ../../modules/nixos/nvidia.nix # This is a NVIDIA PC
  ];

  powerManagement.cpuFreqGovernor = "performance";
}

