#################################
###  NixOS Desktop PC Config  ###
#################################

{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/nvidia.nix # this is a NVIDIA PC
    ../../modules/nixos/nvidia-desktop.nix # desktop-specific NVIDIA quirks
    ../../modules/nixos/ollama.nix
  ];

  hardware.nvidia.open = true;

  powerManagement.cpuFreqGovernor = "performance";
}
