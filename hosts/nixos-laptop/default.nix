#################################
###  NixOS Laptop PC Config  ###
#################################

{ inputs, ... }:

{
  imports = [
    ../../modules/home-manager/hyprland/nixos-laptop.nix
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../modules/nixos/power-laptop.nix # Laptop host
    ../../modules/nixos/nvidia.nix # This is a NVIDIA PC so we'll import it
    ../../modules/nixos/nvidia-prime.nix # NVIDIA Laptop
  ];

  hardware.nvidia.open = true;
}
