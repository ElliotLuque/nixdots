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
    ../../modules/nixos/nvidia-desktop.nix # Desktop-specific NVIDIA quirks
  ];

  hardware.nvidia.open = true;

  powerManagement.cpuFreqGovernor = "performance";
}
