{ lib, ... }:
{
  services.xserver.videoDrivers = lib.mkForce [
    "modesetting"
    "nvidia"
  ];

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:2:0:0";

    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };

  hardware.nvidia.powerManagement.enable = lib.mkForce true;
  hardware.nvidia.powerManagement.finegrained = lib.mkForce true;
}
