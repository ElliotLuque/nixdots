#################################
###  NixOS Laptop PC Config  ###
#################################

{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/power-laptop.nix # Laptop host
    ../../modules/nixos/nvidia.nix # This is a NVIDIA PC
    ../../modules/nixos/nvidia-prime.nix # NVIDIA Laptop PRIME offload
  ];

  boot.kernelParams = [
    "nvidia.NVreg_DynamicPowerManagement=0x02"
  ];

  hardware.nvidia.open = false;
}
